import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Learning a song one note at a time: the song waits for you to press the right key.
struct PianoLesson: Equatable {
    enum Press: Equatable {
        case right
        case wrong(expected: Int)
        case finished
        /// The song is already over, so the press doesn't count.
        case ignored
    }

    let song: PianoSong
    private(set) var index = 0
    private(set) var hits = 0
    private(set) var mistakes = 0

    init(song: PianoSong) {
        self.song = song
    }

    var done: Bool { index >= song.notes.count }
    /// The note to play next, or nil when the song is over.
    var expected: PianoNote? { done ? nil : song.notes[index] }
    var progress: Double { song.notes.isEmpty ? 1 : Double(index) / Double(song.notes.count) }

    mutating func press(_ midi: Int) -> Press {
        guard let want = expected else { return .ignored }
        guard midi == want.midi else {
            mistakes += 1
            return .wrong(expected: want.midi)
        }
        hits += 1
        index += 1
        return done ? .finished : .right
    }

    /// How many of your presses were right, from 0 to 1.
    var accuracy: Double {
        hits + mistakes == 0 ? 1 : Double(hits) / Double(hits + mistakes)
    }

    /// 3 stars for 90% right or better, 2 for 70%, otherwise 1. No stars until it's finished.
    var stars: Int {
        guard done else { return 0 }
        if accuracy >= 0.9 { return 3 }
        if accuracy >= 0.7 { return 2 }
        return 1
    }
}

/// When each note starts and stops while Ace plays a song, in seconds from the start.
struct PianoCue: Equatable {
    var time: Double
    var midi: Int
    var on: Bool
}

extension PianoSong {
    /// The note-on and note-off times for playing the song. A note lets go a moment early,
    /// so the same note twice in a row sounds like two notes. Offs come before ons at the same time.
    func cues(leadIn: Double = 0) -> [PianoCue] {
        let gap = min(0.06, secondsPerBeat * 0.12)
        var cues: [PianoCue] = []
        for n in notes {
            let start = leadIn + n.beat * secondsPerBeat
            let end = leadIn + (n.beat + n.length) * secondsPerBeat - gap
            cues.append(PianoCue(time: start, midi: n.midi, on: true))
            cues.append(PianoCue(time: max(start + 0.02, end), midi: n.midi, on: false))
        }
        return cues.sorted { $0.time == $1.time ? (!$0.on && $1.on) : $0.time < $1.time }
    }

    /// The notes sounding at a moment (in beats from the start).
    func notes(at beat: Double) -> [PianoNote] {
        notes.filter { $0.beat <= beat && beat < $0.beat + $0.length }
    }
}

/// Where each key sits on screen. White keys share the width; black keys sit on top between them.
struct PianoLayout: Equatable {
    let low: Int
    let high: Int
    let size: CGSize
    /// How tall the black keys are, as a part of the white keys.
    static let blackHeight: CGFloat = 0.62
    static let blackWidth: CGFloat = 0.6

    init(low: Int, high: Int, size: CGSize) {
        // The keyboard always starts and ends on a white key.
        var lo = min(low, high), hi = max(low, high)
        if PianoTheory.isBlack(lo) { lo -= 1 }
        if PianoTheory.isBlack(hi) { hi += 1 }
        self.low = lo
        self.high = hi
        self.size = size
    }

    var whiteKeys: [Int] { (low...high).filter { !PianoTheory.isBlack($0) } }
    var blackKeys: [Int] { (low...high).filter { PianoTheory.isBlack($0) } }
    var whiteWidth: CGFloat { size.width / CGFloat(max(1, whiteKeys.count)) }

    /// The key's rectangle, or nil when it isn't on this keyboard.
    func rect(_ midi: Int) -> CGRect? {
        guard midi >= low, midi <= high else { return nil }
        let w = whiteWidth
        if PianoTheory.isBlack(midi) {
            // A black key sits on the line after the white key just below it.
            guard let below = whiteKeys.firstIndex(of: midi - 1) else { return nil }
            let bw = w * PianoLayout.blackWidth
            return CGRect(x: CGFloat(below + 1) * w - bw / 2, y: 0, width: bw, height: size.height * PianoLayout.blackHeight)
        }
        guard let i = whiteKeys.firstIndex(of: midi) else { return nil }
        return CGRect(x: CGFloat(i) * w, y: 0, width: w, height: size.height)
    }

    /// The middle of the key, side to side (where its falling notes line up).
    func centerX(_ midi: Int) -> CGFloat? {
        rect(midi)?.midX
    }

    /// Which key a finger is on. Black keys are on top, so they're checked first.
    func key(at p: CGPoint) -> Int? {
        guard p.x >= 0, p.x < size.width, p.y >= 0, p.y <= size.height else { return nil }
        for k in blackKeys {
            if let r = rect(k), r.contains(p) { return k }
        }
        let i = Int(p.x / whiteWidth)
        let whites = whiteKeys
        return i >= 0 && i < whites.count ? whites[i] : nil
    }
}

/// Your best stars for each song, saved on the iPad.
final class PianoProgress {
    static let shared = PianoProgress(key: "ace.piano.stars")
    private let key: String
    private(set) var stars: [String: Int]

    init(key: String) {
        self.key = key
        stars = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    func best(_ songID: String) -> Int { stars[songID] ?? 0 }

    /// Saves a finished lesson's stars. True when it beat your best.
    @discardableResult
    func record(_ songID: String, stars new: Int) -> Bool {
        let n = max(0, min(3, new))
        guard n > best(songID) else { return false }
        stars[songID] = n
        UserDefaults.standard.set(stars, forKey: key)
        return true
    }

    var totalStars: Int { stars.values.reduce(0, +) }
    var songsLearned: Int { stars.values.filter { $0 > 0 }.count }

    func clearAll() {
        stars = [:]
        UserDefaults.standard.removeObject(forKey: key)
    }
}
