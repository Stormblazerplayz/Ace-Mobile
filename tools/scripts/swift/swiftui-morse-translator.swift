// @title Morse Code Translator
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show MorseTranslatorView() in ContentView's body.
// @keywords swiftui morse code, swiftui translator, swiftui flashing light, swiftui async sequence
// @about Turns your message into Morse code and can flash it on screen like a signal lamp.

import SwiftUI

struct MorseTranslatorView: View {
    @State private var message = "SOS"
    @State private var lampOn = false
    @State private var playing = false

    let codes: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.",
        "G": "--.", "H": "....", "I": "..", "J": ".---", "K": "-.-", "L": ".-..",
        "M": "--", "N": "-.", "O": "---", "P": ".--.", "Q": "--.-", "R": ".-.",
        "S": "...", "T": "-", "U": "..-", "V": "...-", "W": ".--", "X": "-..-",
        "Y": "-.--", "Z": "--..", "0": "-----", "1": ".----", "2": "..---",
        "3": "...--", "4": "....-", "5": ".....", "6": "-....", "7": "--...",
        "8": "---..", "9": "----.", " ": "/",
    ]

    // Look up each letter and join the codes with spaces
    var morse: String {
        message.uppercased().compactMap { codes[$0] }.joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: 24) {
            TextField("Message", text: $message)
                .textFieldStyle(.roundedBorder)
                .font(.title2)

            Text(morse.isEmpty ? " " : morse)
                .font(.system(.title, design: .monospaced))
                .textSelection(.enabled)

            Circle()
                .fill(lampOn ? Color.yellow : Color.gray.opacity(0.3))
                .frame(width: 160, height: 160)
                .shadow(color: lampOn ? Color.yellow : Color.clear, radius: 30)

            Button(playing ? "Flashing..." : "Flash it") {
                Task { await flash() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(playing || morse.isEmpty)
        }
        .padding()
    }

    // A dot is a short flash, a dash is a long one
    func flash() async {
        playing = true
        let unit = 0.2  // seconds
        for symbol in morse {
            switch symbol {
            case ".":
                await light(for: unit)
            case "-":
                await light(for: unit * 3)
            default:
                try? await Task.sleep(for: .seconds(unit * 2))  // gap between letters or words
            }
            try? await Task.sleep(for: .seconds(unit))
        }
        playing = false
    }

    func light(for seconds: Double) async {
        lampOn = true
        try? await Task.sleep(for: .seconds(seconds))
        lampOn = false
    }
}
