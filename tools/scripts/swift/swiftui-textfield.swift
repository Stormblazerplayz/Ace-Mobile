// @title TextField and SecureField
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show TextFieldDemoView() in ContentView's body.
// @keywords swiftui textfield, swiftui securefield, swiftui focusstate, swiftui keyboard type, swiftui onsubmit
// @about Shows text boxes for typing, a hidden password box, keyboard types and moving focus between fields.

import SwiftUI

struct TextFieldDemoView: View {
    @State private var name = ""
    @State private var age = ""
    @State private var password = ""
    @State private var submitted = false

    // Which field has the keyboard right now
    enum Field { case name, age, password }
    @FocusState private var focus: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($focus, equals: .name)
                .submitLabel(.next)
                .onSubmit { focus = .age }  // pressing return jumps to the next box

            TextField("Age", text: $age)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .focused($focus, equals: .age)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .focused($focus, equals: .password)
                .onSubmit { submitted = true }

            Text("Password strength: \(password.count >= 8 ? "good" : "too short") (\(password.count) characters)")
                .font(.caption)
                .foregroundStyle(password.count >= 8 ? Color.green : Color.orange)

            Button("Sign up") {
                submitted = true
                focus = nil  // hide the keyboard
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.isEmpty || password.count < 8)

            if submitted {
                Text("Welcome, \(displayName)! Age: \(ageText)")
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
    }

    var displayName: String { name.isEmpty ? "friend" : name }

    // Int(age) is nil if the age box doesn't hold a number
    var ageText: String {
        if let number = Int(age) {
            return String(number)
        }
        return "unknown"
    }
}
