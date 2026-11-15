// @title Password Generator App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show PasswordMakerView() in ContentView's body.
// @keywords swiftui password generator, swiftui copy to clipboard, swiftui uipasteboard, swiftui strength meter
// @about Makes strong random passwords with a length slider and options, then copies them to the clipboard.

import SwiftUI
import UIKit

struct PasswordMakerView: View {
    @State private var length = 14.0
    @State private var useNumbers = true
    @State private var useSymbols = true
    @State private var useCapitals = true
    @State private var password = ""
    @State private var copied = false

    // A rough idea of how strong the password is
    var strength: (label: String, color: Color) {
        var score = Int(length) / 4
        if useNumbers { score += 1 }
        if useSymbols { score += 1 }
        if useCapitals { score += 1 }
        if score >= 6 { return ("Strong", Color.green) }
        if score >= 4 { return ("OK", Color.orange) }
        return ("Weak", Color.red)
    }

    var body: some View {
        Form {
            Section("Your password") {
                Text(password.isEmpty ? "Tap Generate" : password)
                    .font(.system(.title2, design: .monospaced))
                    .textSelection(.enabled)
                Text(strength.label).foregroundStyle(strength.color).bold()
            }
            Section("Options") {
                Slider(value: $length, in: 6...32, step: 1) {
                    Text("Length")
                }
                Text("Length: \(Int(length)) characters")
                Toggle("Capital letters", isOn: $useCapitals)
                Toggle("Numbers", isOn: $useNumbers)
                Toggle("Symbols", isOn: $useSymbols)
            }
            Section {
                Button("Generate") { generate() }
                Button(copied ? "Copied!" : "Copy to clipboard") {
                    UIPasteboard.general.string = password
                    copied = true
                }
                .disabled(password.isEmpty)
            }
        }
        .onAppear(perform: generate)
    }

    func generate() {
        var characters = "abcdefghijkmnopqrstuvwxyz"
        if useCapitals { characters += "ABCDEFGHJKLMNPQRSTUVWXYZ" }
        if useNumbers { characters += "23456789" }
        if useSymbols { characters += "!@#$%&*?-+" }
        let pool = Array(characters)
        var result = ""
        for _ in 0..<Int(length) {
            result.append(pool.randomElement() ?? "x")
        }
        password = result
        copied = false
    }
}
