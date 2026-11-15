import Foundation

/// What changed in each build, from the bundled changelog.json. The chat shows a What's new card
/// the first time the app opens on a new build, and Settings can show it again any time.
enum WhatsNew {
    struct Release: Codable, Equatable {
        var build: Int
        var date: String
        var items: [String]
    }

    private struct File: Codable {
        var builds: [Release]
    }

    /// Every release in the changelog, newest first.
    static func load(data: Data? = nil) -> [Release] {
        var raw = data
        if raw == nil, let url = Bundle.main.url(forResource: "changelog", withExtension: "json") {
            raw = try? Data(contentsOf: url)
        }
        guard let raw, let file = try? JSONDecoder().decode(File.self, from: raw) else { return [] }
        return file.builds.filter { !$0.items.isEmpty }.sorted { $0.build > $1.build }
    }

    /// This app's build number (the TestFlight build).
    static var currentBuild: Int {
        Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 1
    }

    /// The notes for a build: the newest ones at or below it (a build with no notes of its own
    /// gets the ones before it).
    static func release(forBuild build: Int, in releases: [Release]) -> Release? {
        releases.filter { $0.build <= build }.max { $0.build < $1.build }
    }

    /// The notes to show when the app opens, or nil when they were shown already.
    /// `lastShown` is the release whose card was shown last (0 for never).
    static func due(currentBuild: Int, lastShown: Int, releases: [Release]) -> Release? {
        guard let r = release(forBuild: currentBuild, in: releases), r.build > lastShown else { return nil }
        return r
    }

    /// The line that comes with the card.
    @MainActor
    static func intro(build: Int, sassy: Bool, level: SassLevel = .extra, pack: SassPack = .shared) -> String {
        if sassy {
            let line = pack.line("whatsnew", level: level, fill: ["build": "\(build)"])
            if !line.isEmpty { return line }
        }
        return "Here's what's new in build \(build)."
    }
}
