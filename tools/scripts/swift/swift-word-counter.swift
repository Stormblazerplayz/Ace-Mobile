// @title Word Counter
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as WordCounter.swift and run in Terminal: swiftc -parse-as-library WordCounter.swift -o words && ./words
// @keywords swift word counter, swift count words, swift most common words, swift text stats
// @about Counts words, sentences and the most common words in a piece of text.

import Foundation

@main
struct WordCounterProgram {
    static func main() {
        let text = """
        Swift is a powerful language. Swift is also fun! People use Swift to build apps
        for iPhone, iPad and Mac. Once you learn Swift, you can build almost anything.
        """

        // Split on anything that isn't a letter or an apostrophe
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.letters.union(CharacterSet(charactersIn: "'")).inverted)
            .filter { !$0.isEmpty }

        let sentences = text.split(whereSeparator: { ".!?".contains($0) })
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var counts: [String: Int] = [:]
        for word in words {
            counts[word, default: 0] += 1
        }

        print("Words: \(words.count)")
        print("Different words: \(counts.count)")
        print("Sentences: \(sentences.count)")
        print("Characters (no spaces): \(text.filter { !$0.isWhitespace }.count)")
        print("Longest word: \(words.max { $0.count < $1.count } ?? "")")

        print("\nMost common words:")
        let top = counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }.prefix(5)
        for (word, count) in top {
            print("  \(word.padding(toLength: 8, withPad: " ", startingAt: 0)) \(String(repeating: "#", count: count)) \(count)")
        }
    }
}
