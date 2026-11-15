// @title Password Generator
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Passwords.swift and run in Terminal: swiftc -parse-as-library Passwords.swift -o passwords && ./passwords
// @keywords swift password generator, swift random string, swift random element, swift strong password
// @about Makes strong random passwords of any length and checks that each one has letters, numbers and symbols.

import Foundation

@main
struct PasswordGeneratorProgram {
    static let lowercase = Array("abcdefghijklmnopqrstuvwxyz")
    static let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    static let digits = Array("0123456789")
    static let symbols = Array("!@#$%^&*?")

    static func makePassword(length: Int) -> String {
        let all = lowercase + uppercase + digits + symbols
        // Start with one of each kind so the password is always strong
        var characters: [Character] = [
            lowercase.randomElement()!, uppercase.randomElement()!,
            digits.randomElement()!, symbols.randomElement()!,
        ]
        while characters.count < length {
            characters.append(all.randomElement()!)
        }
        return String(characters.shuffled())
    }

    static func strength(of password: String) -> String {
        var score = 0
        if password.count >= 12 { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { symbols.contains($0) }) { score += 1 }
        return ["very weak", "weak", "okay", "good", "strong", "super strong"][score]
    }

    static func main() {
        for length in [8, 12, 16, 24] {
            let password = makePassword(length: length)
            print("\(length) characters: \(password)  (\(strength(of: password)))")
        }
        print("Strength of 'password': \(strength(of: "password"))")
        print("Tip: use a different password for every account!")
    }
}
