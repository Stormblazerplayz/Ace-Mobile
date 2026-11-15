import SwiftUI

/// Settings > Scripts: every built-in Roblox Lua, C++, Python and Swift script, by category, with search.
struct ScriptsView: View {
    @State private var language = "Lua"
    @State private var search = ""

    static func footer(_ language: String) -> String {
        switch language {
        case "Lua": return "Scripts for Roblox Studio. Each one says where to put it."
        case "Python": return "Console games, turtle drawings, handy tools and Raspberry Pi programs."
        case "Swift": return "SwiftUI views and small apps for Xcode or Swift Playgrounds."
        default: return "Arduino sketches, console games, C++ basics and Unreal Engine classes."
        }
    }

    private var matches: [ScriptLibrary.Script] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        let pool = ScriptLibrary.all.filter { $0.language == language }
        guard !q.isEmpty else { return pool }
        return pool.filter { s in
            s.title.lowercased().contains(q) || s.category.lowercased().contains(q) || s.about.lowercased().contains(q)
                || s.keywords.contains { $0.contains(q) }
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Language", selection: $language) {
                    Text("Roblox Lua").tag("Lua")
                    Text("C++").tag("C++")
                    Text("Python").tag("Python")
                    Text("Swift").tag("Swift")
                }
                .pickerStyle(.segmented)
            } footer: {
                Text(Self.footer(language))
            }

            let shown = matches
            if shown.isEmpty {
                Section {
                    Text(search.isEmpty ? "No scripts here yet." : "No scripts match \"\(search)\".")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(ScriptLibrary.categories(language), id: \.self) { category in
                let inCategory = shown.filter { $0.category == category }
                if !inCategory.isEmpty {
                    Section(category) {
                        ForEach(inCategory) { s in
                            NavigationLink {
                                ScriptDetailView(script: s)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.title)
                                    Text(s.about)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Search scripts")
        .navigationTitle("Scripts")
    }
}

/// One script, full size, with Copy and Share.
struct ScriptDetailView: View {
    let script: ScriptLibrary.Script

    var body: some View {
        ScrollView {
            CodeCardView(card: script.card, startOpen: true)
                .padding()
        }
        .background(AceTheme.background.ignoresSafeArea())
        .navigationTitle(script.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(item: script.code, subject: Text(script.title)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}
