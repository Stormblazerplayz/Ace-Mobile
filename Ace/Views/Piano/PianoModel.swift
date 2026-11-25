import SwiftUI

/// What opens Ace Piano (see `AceCore.pianoScreen`).
struct PianoScreen: Identifiable {
    let id = UUID()
    var start: PianoStart
}

/// Everything happening on the piano: free play, a lesson, or Ace playing a song.
@MainActor
final class PianoModel: ObservableObject {
    enum Mode: Equatable {
        case free
        case learn(PianoLesson)
        case listen(PianoSong)
    }

    /// A little sparkle where a note was hit.
    struct Burst: Identifiable {
        let id = UUID()
        let midi: Int
        let born: Date
        let right: Bool
    }

    /// A music note that floats up from a key you played.
    struct Floater: Identifiable {
        let id = UUID()
        let midi: Int
        let born: Date
        let drift: Double
        let symbol: String
    }

    /// The end of a lesson.
    struct Finish: Equatable {
        let song: PianoSong
        let stars: Int
        let accuracy: Double
        let mistakes: Int
        let newBest: Bool
    }

    @Published private(set) var mode: Mode = .free
    /// Keys your fingers are on.
    @Published private(set) var held: Set<Int> = []
    /// Keys Ace is playing (when it plays a song for you).
    @Published private(set) var aceHeld: Set<Int> = []
    /// The key that was wrong just now, so it flashes red.
    @Published private(set) var wrongKey: Int?
    @Published private(set) var bursts: [Burst] = []
    @Published private(set) var floaters: [Floater] = []
    /// The colors of the last few notes, for the glow behind everything.
    @Published private(set) var glowHues: [Double] = [0.58, 0.83, 0.5]
    @Published var finish: Finish?
    /// Ace finished playing a song for you.
    @Published private(set) var listenDone = false
    /// Free play: which C the keyboard starts on (48 is C3, 60 is middle C).
    @Published var freeLow = PianoTheory.middleC

    // Where the falling notes are, in beats: they glide from `beatFrom` to `beatTo`.
    private(set) var beatFrom = 0.0
    private(set) var beatTo = 0.0
    private(set) var moveStart = Date()
    private(set) var moveSeconds = 0.0
    private(set) var listenStart: Date?
    /// Beats shown before a song starts, so the first notes fall in from the top.
    static let leadInBeats = 3.0

    private let synth = PianoSynth.shared
    private var playTask: Task<Void, Never>?
    private var wrongTask: Task<Void, Never>?
    let progress: PianoProgress
    /// Things move (sparkles, floating notes, gliding) unless Bouncy animations is off or Reduce Motion is on.
    var moves = true
    /// Called when a lesson is finished, with whether it beat your best.
    var onLessonDone: ((PianoSong, Int, Bool) -> Void)?

    init(progress: PianoProgress = .shared) {
        self.progress = progress
    }

    // MARK: The keyboard's range

    /// The lowest and highest key on the keyboard right now.
    var range: ClosedRange<Int> {
        switch mode {
        case .free: return freeLow...(freeLow + 24)
        case .learn, .listen: return PianoTheory.middleC...(PianoTheory.middleC + 24)
        }
    }

    var song: PianoSong? {
        switch mode {
        case .free: return nil
        case .learn(let l): return l.song
        case .listen(let s): return s
        }
    }

    var lesson: PianoLesson? {
        if case .learn(let l) = mode { return l }
        return nil
    }

    /// The key to press next in a lesson.
    var hintKey: Int? { lesson?.expected?.midi }

    func shiftOctave(_ by: Int) {
        let next = freeLow + by * 12
        guard (36...72).contains(next) else { return }
        releaseAll()
        freeLow = next
    }

    // MARK: Playing

    func press(_ midi: Int, velocity: Float = 0.8) {
        synth.noteOn(midi, velocity: velocity)
        held.insert(midi)
        addGlow(midi)
        if moves {
            let now = Date()
            floaters.removeAll { now.timeIntervalSince($0.born) > 2.2 }
            floaters.append(Floater(midi: midi, born: now, drift: Double.random(in: -24...24),
                                    symbol: ["♪", "♫", "♩", "♬"].randomElement() ?? "♪"))
        }
        guard case .learn(var lesson) = mode else { return }
        let result = lesson.press(midi)
        mode = .learn(lesson)
        switch result {
        case .right:
            addBurst(midi, right: true)
            glide(to: lesson.expected?.beat ?? lesson.song.beats, song: lesson.song)
        case .finished:
            addBurst(midi, right: true)
            glide(to: lesson.song.beats, song: lesson.song)
            finishLesson(lesson)
        case .wrong:
            flashWrong(midi)
        case .ignored:
            break
        }
    }

    func release(_ midi: Int) {
        synth.noteOff(midi)
        held.remove(midi)
    }

    func releaseAll() {
        for m in held { synth.noteOff(m) }
        held = []
    }

    // MARK: Modes

    func freePlay() {
        stopPlayback()
        mode = .free
        finish = nil
    }

    func learn(_ song: PianoSong) {
        stopPlayback()
        finish = nil
        mode = .learn(PianoLesson(song: song))
        beatFrom = -PianoModel.leadInBeats
        beatTo = -PianoModel.leadInBeats
        glide(to: song.notes.first?.beat ?? 0, song: song)
    }

    func listen(_ song: PianoSong) {
        stopPlayback()
        finish = nil
        listenDone = false
        mode = .listen(song)
        let lead = PianoModel.leadInBeats * song.secondsPerBeat
        let start = Date()
        listenStart = start
        let cues = song.cues(leadIn: lead)
        playTask = Task { @MainActor [weak self] in
            for cue in cues {
                let wait = cue.time - Date().timeIntervalSince(start)
                if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
                guard let self, !Task.isCancelled else { return }
                if cue.on {
                    self.synth.noteOn(cue.midi, velocity: 0.72)
                    self.aceHeld.insert(cue.midi)
                    self.addGlow(cue.midi)
                    self.addBurst(cue.midi, right: true)
                } else {
                    self.synth.noteOff(cue.midi)
                    self.aceHeld.remove(cue.midi)
                }
            }
            guard let self, !Task.isCancelled else { return }
            self.listenDone = true
        }
    }

    /// Stops Ace's playing and lets its notes go.
    func stopPlayback() {
        playTask?.cancel()
        playTask = nil
        for m in aceHeld { synth.noteOff(m) }
        aceHeld = []
        listenStart = nil
    }

    func open(_ start: PianoStart) {
        switch start {
        case .free, .songs: freePlay()
        case .learn(let id): if let s = PianoSongs.song(id) { learn(s) }
        case .listen(let id): if let s = PianoSongs.song(id) { listen(s) }
        }
    }

    func close() {
        stopPlayback()
        wrongTask?.cancel()
        releaseAll()
        synth.allOff()
    }

    /// Where the song is right now, in beats (the falling notes line up with it).
    func beat(at now: Date) -> Double {
        switch mode {
        case .free:
            return 0
        case .listen(let song):
            guard let listenStart else { return song.beats + PianoModel.leadInBeats }
            return now.timeIntervalSince(listenStart) / song.secondsPerBeat - PianoModel.leadInBeats
        case .learn:
            guard moveSeconds > 0 else { return beatTo }
            let t = min(1, max(0, now.timeIntervalSince(moveStart) / moveSeconds))
            // Eases out, so the notes settle onto the line.
            let eased = 1 - (1 - t) * (1 - t)
            return beatFrom + (beatTo - beatFrom) * eased
        }
    }

    // MARK: Helpers

    private func glide(to beat: Double, song: PianoSong) {
        let now = Date()
        let from = self.beat(at: now)
        beatFrom = from
        beatTo = beat
        moveStart = now
        // Quicker than the song's own speed, so you never wait for the notes.
        moveSeconds = moves ? min(1.2, max(0.15, (beat - from) * song.secondsPerBeat * 0.55)) : 0
        if from < 0 && moves { moveSeconds = max(moveSeconds, 1.2) }
    }

    private func finishLesson(_ lesson: PianoLesson) {
        let stars = lesson.stars
        let newBest = progress.record(lesson.song.id, stars: stars)
        let result = Finish(song: lesson.song, stars: stars, accuracy: lesson.accuracy, mistakes: lesson.mistakes, newBest: newBest)
        Haptics.shared.play(.success)
        onLessonDone?(lesson.song, stars, newBest)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.7))
            guard let self, case .learn(let l) = self.mode, l.done else { return }
            withAnimation(AceMotion.now(.bouncy)) { self.finish = result }
        }
    }

    private func flashWrong(_ midi: Int) {
        wrongKey = midi
        addBurst(midi, right: false)
        wrongTask?.cancel()
        wrongTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.35))
            guard let self, !Task.isCancelled else { return }
            self.wrongKey = nil
        }
    }

    private func addBurst(_ midi: Int, right: Bool) {
        guard moves else { return }
        let now = Date()
        bursts.removeAll { now.timeIntervalSince($0.born) > 0.9 }
        bursts.append(Burst(midi: midi, born: now, right: right))
    }

    private func addGlow(_ midi: Int) {
        let hue = PianoTheory.hue(midi)
        withAnimation(moves ? .easeOut(duration: 0.9) : nil) {
            glowHues = Array(([hue] + glowHues).prefix(3))
        }
    }
}

extension PianoTheory {
    /// A key's own color: C red, E yellow, G cyan, and so on around the rainbow.
    static func color(_ midi: Int, brightness: Double = 1, saturation: Double = 0.72) -> Color {
        Color(hue: hue(midi), saturation: saturation, brightness: brightness)
    }
}
