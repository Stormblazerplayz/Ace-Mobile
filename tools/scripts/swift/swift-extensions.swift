// @title Extensions
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Extensions.swift and run in Terminal: swiftc -parse-as-library Extensions.swift -o extensions && ./extensions
// @keywords swift extension, swift add methods to int, swift extend string, swift computed property extension
// @about Adds your own new abilities to types that already exist, like Int, String and Array.

import Foundation

extension Int {
    var isEven: Bool { self % 2 == 0 }
    var squared: Int { self * self }

    func times(_ action: () -> Void) {
        for _ in 0..<self {
            action()
        }
    }
}

extension String {
    var reversedText: String { String(self.reversed()) }
    var isPalindrome: Bool {
        let letters = self.lowercased().filter { $0.isLetter }
        return !letters.isEmpty && letters == String(letters.reversed())
    }
    func shout() -> String { uppercased() + "!!!" }
}

extension Array where Element == Int {
    var average: Double {
        isEmpty ? 0 : Double(reduce(0, +)) / Double(count)
    }
}

@main
struct ExtensionsProgram {
    static func main() {
        print("Is 8 even? \(8.isEven)")
        print("7 squared is \(7.squared)")
        3.times {
            print("Hip hip hooray!")
        }

        print("\"robot\" backwards is \"\("robot".reversedText)\"")
        print("Is \"Race car\" a palindrome? \("Race car".isPalindrome)")
        print("hello".shout())

        let scores = [90, 85, 77, 100]
        print("Average score: \(scores.average)")
    }
}
