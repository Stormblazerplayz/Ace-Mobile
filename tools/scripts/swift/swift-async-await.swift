// @title Async and Await
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as AsyncDemo.swift and run in Terminal: swiftc -parse-as-library AsyncDemo.swift -o asyncdemo && ./asyncdemo
// @keywords swift async await, swift task sleep, swift async let, swift concurrency basics
// @about Shows async functions that wait without freezing, and async let to run several jobs at the same time.

import Foundation

@main
struct AsyncAwaitProgram {
    // async means this function can pause while it waits
    static func download(_ name: String, seconds: Double) async -> String {
        print("Starting \(name)...")
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        print("Finished \(name)")
        return "\(name) (\(seconds)s)"
    }

    // main can be async too
    static func main() async {
        let clock = Date()

        // One after another: about 1 + 1 = 2 seconds
        let first = await download("song.mp3", seconds: 1)
        let second = await download("photo.png", seconds: 1)
        print("In order: \(first), \(second)")
        print(String(format: "Took %.1f seconds\n", Date().timeIntervalSince(clock)))

        // At the same time with async let: about 1 second total
        let start = Date()
        async let a = download("level1.map", seconds: 1)
        async let b = download("level2.map", seconds: 1)
        async let c = download("music.ogg", seconds: 1)
        let results = await [a, b, c]
        print("Together: \(results.joined(separator: ", "))")
        print(String(format: "Took %.1f seconds", Date().timeIntervalSince(start)))
    }
}
