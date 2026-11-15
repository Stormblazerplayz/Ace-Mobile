// @title Forms
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show SignUpFormView() in ContentView's body.
// @keywords swiftui form, swiftui section, swiftui sign up form, swiftui form validation, swiftui labeledcontent
// @about A sign up form with sections, different controls, live checks and a summary.

import SwiftUI

struct SignUpFormView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -12, to: .now) ?? .now
    @State private var favoriteGame = "Minecraft"
    @State private var newsletter = false
    @State private var agreed = false
    @State private var submitted = false

    let games = ["Minecraft", "Roblox", "Fortnite", "Terraria"]

    var emailLooksOK: Bool { email.contains("@") && email.contains(".") }
    var canSubmit: Bool { username.count >= 3 && emailLooksOK && agreed }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    if !email.isEmpty && !emailLooksOK {
                        Text("That email doesn't look right.").foregroundStyle(.red).font(.caption)
                    }
                }
                Section("About you") {
                    DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                    Picker("Favorite game", selection: $favoriteGame) {
                        ForEach(games, id: \.self) { game in Text(game).tag(game) }
                    }
                    Toggle("Send me news", isOn: $newsletter)
                }
                Section {
                    Toggle("I agree to the rules", isOn: $agreed)
                    Button("Create account") { submitted = true }
                        .disabled(!canSubmit)
                }
                if submitted {
                    Section("Summary") {
                        LabeledContent("Username", value: username)
                        LabeledContent("Email", value: email)
                        LabeledContent("Favorite", value: favoriteGame)
                        LabeledContent("News", value: newsletter ? "Yes" : "No")
                    }
                }
            }
            .navigationTitle("Sign Up")
        }
    }
}
