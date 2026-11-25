import SwiftUI

/// What opens typing practice (see `AceCore.typingScreen`).
struct TypingScreen: Identifiable {
    let id = UUID()
    var lesson: TypingLesson?
}

/// How a finished run went, for the finish card.
struct TypingResult: Equatable {
    let wpm: Int
    let accuracy: Int
    let stars: Int
    let newBest: Bool
    /// The first finished run of this lesson.
    let firstTime: Bool
    let best: Int
}

/// Everything on the typing screen: the lesson, the run, Shift, and the keys you've missed this time.
@MainActor
final class TypingModel: ObservableObject {
    @Published private(set) var lesson: TypingLesson
    @Published private(set) var run: TypingRun
    /// Shift on the on-screen keyboard (one letter, then it turns itself off).
    @Published var shift = false
    /// Goes up on every mistake, so the text can shake.
    @Published private(set) var shakes = 0
    /// How many times each key was pressed, so the pressed key can pop.
    @Published private(set) var keyHits: [String: Int] = [:]
    @Published private(set) var result: TypingResult?
    /// Missed keys since the screen opened, for the keyboard's heat map.
    @Published private(set) var misses: [String: Int] = [:]

    private let bests: TypingBests

    init(lesson: TypingLesson = .homeRow, bests: TypingBests = .shared, seed: UInt64 = .random(in: 1...UInt64.max)) {
        self.lesson = lesson
        self.bests = bests
        run = TypingRun(text: lesson.text(seed: seed))
    }

    var best: Int { Int(bests.best(lesson).rounded()) }

    /// The key that should be pressed next, and whether it needs Shift.
    var nextKey: (key: String, shift: Bool)? { run.next.flatMap(TypingKeys.key(for:)) }

    func choose(_ lesson: TypingLesson) {
        self.lesson = lesson
        fresh()
    }

    /// A new text in the same lesson.
    func fresh(seed: UInt64 = .random(in: 1...UInt64.max)) {
        run = TypingRun(text: lesson.text(seed: seed))
        result = nil
        shift = false
    }

    /// A tap on the on-screen keyboard.
    func tap(_ key: String, at now: Date = Date()) {
        switch key {
        case TypingKeys.shift:
            shift.toggle()
            Haptics.shared.play(.blink)
        case TypingKeys.delete:
            backspace()
        default:
            guard let c = TypingKeys.character(for: key, shift: shift) else { return }
            shift = false
            type(c, at: now)
        }
    }

    /// A character from a real keyboard (or a tap), already in the right case.
    func type(_ c: Character, at now: Date = Date()) {
        guard result == nil else { return }
        let press = run.type(c, at: now)
        guard press != .ignored else { return }
        if let key = TypingKeys.key(for: c)?.key { keyHits[key, default: 0] += 1 }
        switch press {
        case .right:
            Haptics.shared.play(.tick)
        case .wrong(let expected):
            shakes += 1
            if let key = TypingKeys.key(for: expected)?.key { misses[key, default: 0] += 1 }
            Haptics.shared.play(.alert)
        case .finished:
            if !(run.typed.last == run.target.last) {
                shakes += 1
                if let want = run.target.last, let key = TypingKeys.key(for: want)?.key { misses[key, default: 0] += 1 }
            }
            finish(at: now)
        case .ignored:
            break
        }
    }

    func backspace() {
        guard result == nil, run.position > 0 else { return }
        run.backspace()
        keyHits[TypingKeys.delete, default: 0] += 1
    }

    private func finish(at now: Date) {
        let wpm = run.wordsPerMinute(at: now)
        let old = best
        let newBest = bests.record(wpm, for: lesson)
        result = TypingResult(wpm: Int(wpm.rounded()), accuracy: Int(run.accuracy.rounded()),
                              stars: run.stars(at: now), newBest: newBest && old > 0, firstTime: old == 0, best: max(old, Int(wpm.rounded())))
        Haptics.shared.play(.success)
    }
}
