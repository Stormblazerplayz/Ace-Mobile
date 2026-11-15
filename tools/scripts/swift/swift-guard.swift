// @title Guard Statements
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Guard.swift and run in Terminal: swiftc -parse-as-library Guard.swift -o guarddemo && ./guarddemo
// @keywords swift guard, swift guard let, swift early exit, swift input validation
// @about Uses guard to check things at the start of a function and leave early if something is wrong.

import Foundation

struct SignUpForm {
    var username: String
    var age: String
    var password: String
}

@main
struct GuardProgram {
    // guard says "this must be true, or else leave right now"
    static func check(_ form: SignUpForm) -> String {
        guard !form.username.isEmpty else {
            return "Please type a username."
        }
        guard form.username.count >= 3 else {
            return "Usernames need at least 3 characters."
        }
        guard let age = Int(form.age) else {
            return "Age must be a number."
        }
        guard age >= 13 else {
            return "You must be 13 or older (ask a parent to help you sign up)."
        }
        guard form.password.count >= 8, form.password.contains(where: { $0.isNumber }) else {
            return "Passwords need 8+ characters and at least one number."
        }
        // After the guards, we know everything is good, and 'age' is a real Int
        return "Welcome, \(form.username)! Account created for age \(age)."
    }

    static func main() {
        let forms = [
            SignUpForm(username: "", age: "15", password: "rocket123"),
            SignUpForm(username: "ab", age: "15", password: "rocket123"),
            SignUpForm(username: "storm", age: "twelve", password: "rocket123"),
            SignUpForm(username: "storm", age: "11", password: "rocket123"),
            SignUpForm(username: "storm", age: "15", password: "rocket"),
            SignUpForm(username: "storm", age: "15", password: "rocket123"),
        ]
        for form in forms {
            print(check(form))
        }
    }
}
