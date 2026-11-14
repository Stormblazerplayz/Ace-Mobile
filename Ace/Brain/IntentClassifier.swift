import Foundation
import NaturalLanguage

/// A small neural intent classifier. It compares the meaning of what you said
/// (Apple's on-device sentence embedding) with example sentences for each skill,
/// so "I'm craving pasta tonight" can still find the recipe skill.
@MainActor
final class IntentClassifier {
    enum Skill: String, CaseIterable {
        case recipe, weather, timer, reminder, calendarAdd, calendarList, check, battery, storage, bedtime, joke, webSearch
    }

    private let examples: [Skill: [String]] = [
        .recipe: ["how do i make pancakes", "i want to cook pasta", "what should i make for dinner", "give me a recipe",
                  "i am craving tacos", "how to bake cookies", "ingredients for lasagna"],
        .weather: ["is it going to rain", "how cold is it outside", "do i need a jacket", "what is the forecast",
                   "will it be sunny tomorrow", "is it hot today"],
        .timer: ["set a timer", "count down five minutes", "time my pizza for twelve minutes", "start a countdown"],
        .reminder: ["remind me to feed the dog", "do not let me forget my homework", "ping me later about the trash",
                    "make sure i remember to call grandma"],
        .calendarAdd: ["put soccer practice on my calendar", "schedule a meeting tomorrow", "i have a dentist appointment friday",
                       "add an event", "book time for homework on monday"],
        .calendarList: ["what is on my schedule", "am i busy tomorrow", "what do i have today", "what is next on my calendar",
                        "any plans this weekend"],
        .check: ["is everything okay with my ipad", "check on things", "how is my tablet doing", "anything need my attention",
                 "give me a status report"],
        .battery: ["how much charge do i have", "is my ipad dying", "do i need to plug in", "power level"],
        .storage: ["is my ipad full", "how much space do i have left", "am i running out of room"],
        .bedtime: ["when should i sleep", "what time should i go to bed", "am i staying up too late", "help me sleep better"],
        .joke: ["make me laugh", "say something funny", "tell me a joke", "cheer me up with a joke"],
        .webSearch: ["look this up online", "search the internet", "find out about", "what is the latest news on"],
    ]

    private var centroids: [Skill: [Double]] = [:]
    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)

    var available: Bool { embedding != nil }

    private func buildIfNeeded() {
        guard centroids.isEmpty, let embedding else { return }
        for (skill, list) in examples {
            let vecs = list.compactMap { embedding.vector(for: $0) }
            guard let first = vecs.first else { continue }
            var sum = [Double](repeating: 0, count: first.count)
            for v in vecs where v.count == sum.count {
                for i in 0..<v.count { sum[i] += v[i] }
            }
            centroids[skill] = sum.map { $0 / Double(vecs.count) }
        }
    }

    /// The closest skill and how close it is (cosine, -1...1).
    func classify(_ text: String) -> (skill: Skill, score: Double)? {
        buildIfNeeded()
        guard let embedding, let v = embedding.vector(for: TextKit.normalize(text)) else { return nil }
        var best: (Skill, Double)?
        for (skill, c) in centroids {
            let s = cosine(v, c)
            if best == nil || s > best!.1 { best = (skill, s) }
        }
        return best.map { (skill: $0.0, score: $0.1) }
    }

    private func cosine(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot = 0.0, na = 0.0, nb = 0.0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            na += a[i] * a[i]
            nb += b[i] * b[i]
        }
        let d = na.squareRoot() * nb.squareRoot()
        return d == 0 ? 0 : dot / d
    }
}
