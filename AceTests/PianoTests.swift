import XCTest
@testable import Ace

/// Ace Piano: the songs, asking for the piano, lessons and stars, the keyboard layout and the sound math.
@MainActor
final class PianoTests: XCTestCase {
    private let starsKey = "ace.piano.stars.tests"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: starsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: starsKey)
        super.tearDown()
    }

    // MARK: Notes

    func testNoteNamesAndPitches() {
        XCTAssertEqual(PianoTheory.midi("C4"), 60)
        XCTAssertEqual(PianoTheory.midi("A4"), 69)
        XCTAssertEqual(PianoTheory.midi("Bb3"), 58)
        XCTAssertEqual(PianoTheory.midi("D#5"), 75)
        XCTAssertNil(PianoTheory.midi("H2"))
        XCTAssertNil(PianoTheory.midi("C"))
        XCTAssertEqual(PianoTheory.frequency(69), 440, accuracy: 0.0001)
        XCTAssertEqual(PianoTheory.frequency(60), 261.6256, accuracy: 0.001)
        XCTAssertEqual(PianoTheory.name(61), "C#4")
        XCTAssertEqual(PianoTheory.name(84), "C6")
        XCTAssertEqual((60...71).filter(PianoTheory.isBlack), [61, 63, 66, 68, 70])
        for midi in 21...108 {
            XCTAssertEqual(PianoTheory.midi(PianoTheory.name(midi)), midi, "Every name reads back as the same key")
        }
    }

    func testMelodiesRead() {
        XCTAssertNil(PianoSong.parse("C4:1 X9:1"))
        XCTAssertNil(PianoSong.parse("C4:0"))
        XCTAssertNil(PianoSong.parse(""))
        let notes = try? XCTUnwrap(PianoSong.parse("R:1 C4:1 | E4:0.5 G4:2"))
        XCTAssertEqual(notes, [PianoNote(midi: 60, beat: 1, length: 1), PianoNote(midi: 64, beat: 2, length: 0.5),
                               PianoNote(midi: 67, beat: 2.5, length: 2)])
    }

    // MARK: Songs

    func testEverySongIsRealAndFitsTheKeys() {
        XCTAssertEqual(PianoSongs.all.count, 12)
        XCTAssertEqual(Set(PianoSongs.all.map(\.id)).count, PianoSongs.all.count, "Song ids are different")
        for song in PianoSongs.all {
            XCTAssertGreaterThanOrEqual(song.notes.count, 15, song.title)
            XCTAssertGreaterThanOrEqual(song.lowest, 60, "\(song.title) fits the lesson keyboard (C4 to C6)")
            XCTAssertLessThanOrEqual(song.highest, 84, song.title)
            XCTAssertGreaterThan(song.seconds, 5, song.title)
            XCTAssertLessThan(song.seconds, 60, song.title)
            // Notes come one after another, with no overlaps.
            for (a, b) in zip(song.notes, song.notes.dropFirst()) {
                XCTAssertLessThanOrEqual(a.beat + a.length, b.beat + 0.0001, song.title)
            }
        }
    }

    func testFamousOpenings() {
        let names = { (id: String, count: Int) in PianoSongs.song(id)!.notes.prefix(count).map { PianoTheory.name($0.midi) } }
        XCTAssertEqual(names("twinkle", 7), ["C4", "C4", "G4", "G4", "A4", "A4", "G4"])
        XCTAssertEqual(names("ode-to-joy", 8), ["E4", "E4", "F4", "G4", "G4", "F4", "E4", "D4"])
        XCTAssertEqual(names("fur-elise", 9), ["E5", "D#5", "E5", "D#5", "E5", "B4", "D5", "C5", "A4"])
        XCTAssertEqual(names("mary", 7), ["E4", "D4", "C4", "D4", "E4", "E4", "E4"])
        XCTAssertEqual(names("happy-birthday", 6), ["G4", "G4", "A4", "G4", "C5", "B4"])
        XCTAssertEqual(names("jingle-bells", 11), ["E4", "E4", "E4", "E4", "E4", "E4", "E4", "G4", "C4", "D4", "E4"])
    }

    func testFindingSongsByName() {
        for song in PianoSongs.all {
            XCTAssertEqual(PianoSongs.find(in: song.title)?.id, song.id, song.title)
            for name in song.names {
                XCTAssertEqual(PianoSongs.find(in: name)?.id, song.id, name)
            }
        }
        XCTAssertEqual(PianoSongs.find(in: "Für Elise")?.id, "fur-elise")
        XCTAssertNil(PianoSongs.find(in: "bohemian rhapsody"))
        XCTAssertTrue(PianoSongs.spokenList.hasSuffix("and Für Elise"))
    }

    // MARK: Asking

    private func pianoAsk(_ text: String) -> String? {
        if case .piano(let ask)? = IntentRouter.parse(text) { return ask }
        return nil
    }

    func testPianoAsksRoute() {
        let cases: [(String, String)] = [
            ("play piano", "open"),
            ("Open the piano", "open"),
            ("let's play the piano", "open"),
            ("piano", "open"),
            ("can I play the piano?", "open"),
            ("teach me twinkle twinkle little star on piano", "learn:twinkle"),
            ("How do I play Ode to Joy on the piano", "learn:ode-to-joy"),
            ("teach me how to play jingle bells", "learn:jingle-bells"),
            ("can you teach me Für Elise", "learn:fur-elise"),
            ("play happy birthday", "listen:happy-birthday"),
            ("play jingle bells on the piano", "listen:jingle-bells"),
            ("play me twinkle twinkle", "listen:twinkle"),
            ("play are you sleeping", "listen:frere-jacques"),
            ("teach me piano", "lessons"),
            ("piano lessons", "lessons"),
            ("I want to learn the piano", "lessons"),
            ("what songs can you play on the piano", "list"),
            ("what piano songs do you know", "list"),
        ]
        for (text, want) in cases {
            XCTAssertEqual(pianoAsk(text), want, text)
        }
    }

    func testOtherAsksAreNotThePiano() {
        for text in ["how many keys does a piano have", "who invented the piano", "what is a piano",
                     "play some music", "play jingle bells on youtube", "play happy birthday by stevie wonder",
                     "how do i play minecraft", "teach me spanish", "learn about pianos", "open youtube",
                     "set a timer for 5 minutes", "what is the capital of france"] {
            XCTAssertNil(pianoAsk(text), text)
        }
    }

    func testPianoStartsFromAsks() {
        XCTAssertEqual(PianoStart(ask: "open"), .free)
        XCTAssertEqual(PianoStart(ask: "lessons"), .songs)
        XCTAssertEqual(PianoStart(ask: "learn:twinkle"), .learn("twinkle"))
        XCTAssertEqual(PianoStart(ask: "listen:saints"), .listen("saints"))
        XCTAssertNil(PianoStart(ask: "learn:nope"))
        XCTAssertNil(PianoStart(ask: "list"))
    }

    // MARK: Lessons

    func testALessonWaitsForTheRightKey() {
        var lesson = PianoLesson(song: PianoSongs.song("hot-cross-buns")!)
        XCTAssertEqual(lesson.expected?.midi, 64)
        XCTAssertEqual(lesson.press(62), .wrong(expected: 64))
        XCTAssertEqual(lesson.index, 0, "A wrong key doesn't move on")
        XCTAssertEqual(lesson.press(64), .right)
        XCTAssertEqual(lesson.index, 1)
        var last = PianoLesson.Press.ignored
        for note in lesson.song.notes.dropFirst() { last = lesson.press(note.midi) }
        XCTAssertEqual(last, .finished)
        XCTAssertTrue(lesson.done)
        XCTAssertEqual(lesson.progress, 1)
        XCTAssertEqual(lesson.mistakes, 1)
        XCTAssertEqual(lesson.stars, 3, "17 of 18 right is still 3 stars")
        XCTAssertEqual(lesson.press(60), .ignored)
    }

    func testStars() {
        func play(_ id: String, misses: Int) -> Int {
            var lesson = PianoLesson(song: PianoSongs.song(id)!)
            for _ in 0..<misses { _ = lesson.press(1) }
            for note in lesson.song.notes { _ = lesson.press(note.midi) }
            return lesson.stars
        }
        XCTAssertEqual(play("ode-to-joy", misses: 0), 3)
        XCTAssertEqual(play("ode-to-joy", misses: 10), 2, "30 of 40 right")
        XCTAssertEqual(play("ode-to-joy", misses: 30), 1, "Half right")
        XCTAssertEqual(PianoLesson(song: PianoSongs.song("mary")!).stars, 0, "No stars before the end")
    }

    func testProgressKeepsYourBest() {
        let progress = PianoProgress(key: starsKey)
        XCTAssertTrue(progress.record("mary", stars: 2))
        XCTAssertFalse(progress.record("mary", stars: 1))
        XCTAssertTrue(progress.record("mary", stars: 3))
        XCTAssertTrue(progress.record("twinkle", stars: 1))
        XCTAssertEqual(PianoProgress(key: starsKey).best("mary"), 3, "Stars are saved")
        XCTAssertEqual(progress.totalStars, 4)
        XCTAssertEqual(progress.songsLearned, 2)
        progress.clearAll()
        XCTAssertEqual(PianoProgress(key: starsKey).totalStars, 0)
    }

    func testAcePlaysEveryNoteOnce() {
        for song in PianoSongs.all {
            let cues = song.cues(leadIn: 1)
            XCTAssertEqual(cues.count, song.notes.count * 2, song.title)
            XCTAssertEqual(cues.first?.time, 1, song.title)
            var held = Set<Int>()
            for cue in cues {
                if cue.on {
                    XCTAssertFalse(held.contains(cue.midi), "\(song.title): a note lets go before it plays again")
                    held.insert(cue.midi)
                } else {
                    XCTAssertTrue(held.contains(cue.midi), song.title)
                    held.remove(cue.midi)
                }
            }
            XCTAssertTrue(held.isEmpty, song.title)
        }
    }

    // MARK: Keyboard

    func testKeysUnderFingers() {
        let layout = PianoLayout(low: 60, high: 84, size: CGSize(width: 750, height: 200))
        XCTAssertEqual(layout.whiteKeys.count, 15)
        XCTAssertEqual(layout.blackKeys.count, 10)
        XCTAssertEqual(layout.key(at: CGPoint(x: 10, y: 190)), 60)
        XCTAssertEqual(layout.key(at: CGPoint(x: 50, y: 40)), 61, "The top half between C and D is C sharp")
        XCTAssertEqual(layout.key(at: CGPoint(x: 749, y: 150)), 84)
        XCTAssertNil(layout.key(at: CGPoint(x: -5, y: 10)))
        for midi in 60...84 {
            let r = try! XCTUnwrap(layout.rect(midi))
            XCTAssertEqual(layout.key(at: CGPoint(x: r.midX, y: r.minY + 5)), midi, PianoTheory.name(midi))
        }
        XCTAssertEqual(PianoLayout(low: 61, high: 70, size: .zero).low, 60, "The keyboard starts on a white key")
    }

    // MARK: Sound

    func testTheSoundIsLoudButNeverClips() {
        for sound in PianoSound.allCases {
            var mixer = PianoMixer(sampleRate: 48_000, sound: sound)
            for k in [48, 55, 60, 62, 64, 65, 67, 69, 71, 72, 76, 79, 84] { mixer.noteOn(k, velocity: 1) }
            XCTAssertEqual(mixer.voices.count, PianoMixer.maxVoices, "\(sound): at most 12 notes at once")
            var buffer = [Float](repeating: 0, count: 4_800)
            buffer.withUnsafeMutableBufferPointer { mixer.render(into: $0.baseAddress!, frames: 4_800) }
            let peak = buffer.map(abs).max() ?? 0
            XCTAssertGreaterThan(peak, 0.1, sound.rawValue)
            XCTAssertLessThanOrEqual(peak, 1, sound.rawValue)
            XCTAssertFalse(buffer.contains { $0.isNaN }, sound.rawValue)
            mixer.allOff()
            for _ in 0..<100 { buffer.withUnsafeMutableBufferPointer { mixer.render(into: $0.baseAddress!, frames: 4_800) } }
            XCTAssertTrue(mixer.isSilent, "\(sound): let-go notes fade away")
        }
    }

    func testPianoNotesRingOutButOrganNotesHold() {
        var buffer = [Float](repeating: 0, count: 44_100)
        var piano = PianoMixer(sampleRate: 44_100, sound: .grand)
        piano.noteOn(60)
        for _ in 0..<20 { buffer.withUnsafeMutableBufferPointer { piano.render(into: $0.baseAddress!, frames: 44_100) } }
        XCTAssertTrue(piano.isSilent, "A held piano note dies away by itself")
        var organ = PianoMixer(sampleRate: 44_100, sound: .organ)
        organ.noteOn(60)
        for _ in 0..<4 { buffer.withUnsafeMutableBufferPointer { organ.render(into: $0.baseAddress!, frames: 44_100) } }
        XCTAssertEqual(organ.heldNotes, [60], "An organ note keeps going while it's held")
    }

    func testChangelogHasThePiano() {
        let releases = WhatsNew.load()
        XCTAssertEqual(releases.first?.build, 64)
        XCTAssertTrue(releases.first?.items.contains { $0.contains("Ace Piano") } == true)
    }
}
