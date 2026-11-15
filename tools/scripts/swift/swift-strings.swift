// @title Working with Strings
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Strings.swift and run in Terminal: swiftc -parse-as-library Strings.swift -o strings && ./strings
// @keywords swift strings, swift string methods, swift split string, swift characters, swift multiline string
// @about Shows the handy things you can do with text in Swift: case, splitting, searching, replacing and counting.

import Foundation

@main
struct StringsProgram {
    static func main() {
        let sentence = "The quick brown fox jumps over the lazy dog"

        print(sentence.uppercased())
        print(sentence.lowercased())
        print("Characters: \(sentence.count)")
        print("Has 'fox'? \(sentence.contains("fox"))")
        print("Starts with 'The'? \(sentence.hasPrefix("The"))")
        print(sentence.replacingOccurrences(of: "dog", with: "cat"))

        // Split into words
        let words = sentence.split(separator: " ").map(String.init)
        print("Words: \(words.count), longest: \(words.max { $0.count < $1.count } ?? "")")
        print("Joined with dashes: \(words.joined(separator: "-"))")

        // Loop over each character
        var vowels = 0
        for character in sentence.lowercased() where "aeiou".contains(character) {
            vowels += 1
        }
        print("Vowels: \(vowels)")

        // Trim spaces from the ends
        let messy = "   hello there   "
        print("[\(messy.trimmingCharacters(in: .whitespaces))]")

        // First letters and slices
        let word = "skateboard"
        print("First letter: \(word.first.map { String($0) } ?? "")")
        print("First 5: \(word.prefix(5)), last 5: \(word.suffix(5))")
        print("Reversed: \(String(word.reversed()))")

        // Multi-line strings use three quotes
        let poem = """
        Roses are red,
        Swift is fast,
        Learning to code
        Is a blast!
        """
        print(poem)
        print("The poem has \(poem.split(separator: "\n").count) lines")
    }
}
