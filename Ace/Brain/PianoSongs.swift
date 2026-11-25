import Foundation

/// Note names, numbers and pitches for Ace Piano. Notes are MIDI numbers: 60 is middle C (C4).
enum PianoTheory {
    static let middleC = 60
    private static let sharps = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    private static let letters: [Character: Int] = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]

    /// The pitch in hertz (A4, note 69, is 440 Hz).
    static func frequency(_ midi: Int) -> Double {
        440 * pow(2, Double(midi - 69) / 12)
    }

    /// "C4", "F#5"...
    static func name(_ midi: Int) -> String {
        sharps[((midi % 12) + 12) % 12] + String(midi / 12 - 1)
    }

    /// Just the letter, with no octave ("C", "F#").
    static func letter(_ midi: Int) -> String {
        sharps[((midi % 12) + 12) % 12]
    }

    /// The black keys are the sharps and flats.
    static func isBlack(_ midi: Int) -> Bool {
        [1, 3, 6, 8, 10].contains(((midi % 12) + 12) % 12)
    }

    /// Reads "C4", "F#5", "Bb3" (sharps with #, flats with b). Nil if it isn't a note.
    static func midi(_ name: String) -> Int? {
        var chars = Array(name.trimmingCharacters(in: .whitespaces))
        guard let first = chars.first, let base = letters[Character(first.uppercased())] else { return nil }
        chars.removeFirst()
        var shift = 0
        while let c = chars.first, c == "#" || c == "b" {
            shift += c == "#" ? 1 : -1
            chars.removeFirst()
        }
        guard !chars.isEmpty, let octave = Int(String(chars)), (0...8).contains(octave) else { return nil }
        return (octave + 1) * 12 + base + shift
    }

    /// A color hue (0 to 1) for each note letter, so C is always red, E yellow, G blue, and so on.
    static func hue(_ midi: Int) -> Double {
        Double(((midi % 12) + 12) % 12) / 12
    }
}

/// One note of a song: which key, when it starts and how long it lasts (in beats).
struct PianoNote: Equatable {
    var midi: Int
    var beat: Double
    var length: Double
}

/// A song Ace can play and teach, from its melody written as "E4:1 D4:1 C4:2" (note:beats, R for a rest).
struct PianoSong: Identifiable, Equatable {
    enum Level: String, CaseIterable {
        case easy = "Easy", medium = "Medium", tricky = "Tricky"
    }

    let id: String
    let title: String
    let level: Level
    /// Beats per minute when Ace plays it.
    let tempo: Double
    /// Other ways people say its name ("twinkle twinkle", "are you sleeping").
    let names: [String]
    let notes: [PianoNote]

    init(id: String, title: String, level: Level, tempo: Double, names: [String], melody: String) {
        self.id = id
        self.title = title
        self.level = level
        self.tempo = tempo
        self.names = names
        self.notes = PianoSong.parse(melody) ?? []
    }

    /// Reads a melody. Nil when any token isn't "note:beats" or "R:beats".
    static func parse(_ melody: String) -> [PianoNote]? {
        var beat = 0.0
        var notes: [PianoNote] = []
        for token in melody.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "|" }) {
            let parts = token.split(separator: ":")
            guard parts.count == 2, let length = Double(parts[1]), length > 0 else { return nil }
            if parts[0] == "R" {
                beat += length
                continue
            }
            guard let midi = PianoTheory.midi(String(parts[0])) else { return nil }
            notes.append(PianoNote(midi: midi, beat: beat, length: length))
            beat += length
        }
        return notes.isEmpty ? nil : notes
    }

    /// How many beats long the song is.
    var beats: Double { notes.last.map { $0.beat + $0.length } ?? 0 }
    var secondsPerBeat: Double { 60 / tempo }
    /// How long it takes when Ace plays it.
    var seconds: Double { beats * secondsPerBeat }
    var lowest: Int { notes.map(\.midi).min() ?? PianoTheory.middleC }
    var highest: Int { notes.map(\.midi).max() ?? PianoTheory.middleC }
}

/// The songs, all old enough to be free for anyone to play.
enum PianoSongs {
    static let all: [PianoSong] = [
        PianoSong(id: "hot-cross-buns", title: "Hot Cross Buns", level: .easy, tempo: 100,
                  names: ["hot cross buns"],
                  melody: "E4:1 D4:1 C4:2 | E4:1 D4:1 C4:2 | C4:0.5 C4:0.5 C4:0.5 C4:0.5 D4:0.5 D4:0.5 D4:0.5 D4:0.5 | E4:1 D4:1 C4:2"),
        PianoSong(id: "mary", title: "Mary Had a Little Lamb", level: .easy, tempo: 110,
                  names: ["mary had a little lamb", "mary had a lamb", "mary"],
                  melody: "E4:1 D4:1 C4:1 D4:1 | E4:1 E4:1 E4:2 | D4:1 D4:1 D4:2 | E4:1 G4:1 G4:2 | E4:1 D4:1 C4:1 D4:1 | E4:1 E4:1 E4:1 E4:1 | D4:1 D4:1 E4:1 D4:1 | C4:4"),
        PianoSong(id: "twinkle", title: "Twinkle Twinkle Little Star", level: .easy, tempo: 100,
                  names: ["twinkle twinkle little star", "twinkle twinkle", "twinkle"],
                  melody: """
                  C4:1 C4:1 G4:1 G4:1 | A4:1 A4:1 G4:2 | F4:1 F4:1 E4:1 E4:1 | D4:1 D4:1 C4:2
                  G4:1 G4:1 F4:1 F4:1 | E4:1 E4:1 D4:2 | G4:1 G4:1 F4:1 F4:1 | E4:1 E4:1 D4:2
                  C4:1 C4:1 G4:1 G4:1 | A4:1 A4:1 G4:2 | F4:1 F4:1 E4:1 E4:1 | D4:1 D4:1 C4:2
                  """),
        PianoSong(id: "ode-to-joy", title: "Ode to Joy", level: .easy, tempo: 108,
                  names: ["ode to joy", "beethoven ode to joy", "beethovens ode to joy", "beethoven's ode to joy"],
                  melody: """
                  E4:1 E4:1 F4:1 G4:1 | G4:1 F4:1 E4:1 D4:1 | C4:1 C4:1 D4:1 E4:1 | E4:1.5 D4:0.5 D4:2
                  E4:1 E4:1 F4:1 G4:1 | G4:1 F4:1 E4:1 D4:1 | C4:1 C4:1 D4:1 E4:1 | D4:1.5 C4:0.5 C4:2
                  """),
        PianoSong(id: "old-macdonald", title: "Old MacDonald Had a Farm", level: .easy, tempo: 116,
                  names: ["old macdonald had a farm", "old macdonald", "old mcdonald had a farm", "old mcdonald"],
                  melody: """
                  G4:1 G4:1 G4:1 D4:1 | E4:1 E4:1 D4:2 | B4:1 B4:1 A4:1 A4:1 | G4:3 D4:1
                  G4:1 G4:1 G4:1 D4:1 | E4:1 E4:1 D4:2 | B4:1 B4:1 A4:1 A4:1 | G4:4
                  """),
        PianoSong(id: "london-bridge", title: "London Bridge", level: .easy, tempo: 108,
                  names: ["london bridge is falling down", "london bridge"],
                  melody: """
                  G4:1.5 A4:0.5 G4:1 F4:1 | E4:1 F4:1 G4:2 | D4:1 E4:1 F4:2 | E4:1 F4:1 G4:2
                  G4:1.5 A4:0.5 G4:1 F4:1 | E4:1 F4:1 G4:2 | D4:2 G4:2 | E4:1 C4:3
                  """),
        PianoSong(id: "row-your-boat", title: "Row, Row, Row Your Boat", level: .easy, tempo: 100,
                  names: ["row row row your boat", "row row your boat", "row your boat"],
                  melody: """
                  C4:1.5 C4:1.5 | C4:1 D4:0.5 E4:1.5 | E4:1 D4:0.5 E4:1 F4:0.5 | G4:3
                  C5:0.5 C5:0.5 C5:0.5 G4:0.5 G4:0.5 G4:0.5 | E4:0.5 E4:0.5 E4:0.5 C4:0.5 C4:0.5 C4:0.5
                  G4:1 F4:0.5 E4:1 D4:0.5 | C4:3
                  """),
        PianoSong(id: "frere-jacques", title: "Frère Jacques", level: .medium, tempo: 112,
                  names: ["frere jacques", "frère jacques", "are you sleeping", "are you sleeping brother john", "brother john"],
                  melody: """
                  G4:1 A4:1 B4:1 G4:1 | G4:1 A4:1 B4:1 G4:1 | B4:1 C5:1 D5:2 | B4:1 C5:1 D5:2
                  D5:0.5 E5:0.5 D5:0.5 C5:0.5 B4:1 G4:1 | D5:0.5 E5:0.5 D5:0.5 C5:0.5 B4:1 G4:1
                  G4:1 D4:1 G4:2 | G4:1 D4:1 G4:2
                  """),
        PianoSong(id: "jingle-bells", title: "Jingle Bells", level: .medium, tempo: 120,
                  names: ["jingle bells", "jingle bells jingle bells", "jingle all the way"],
                  melody: """
                  E4:1 E4:1 E4:2 | E4:1 E4:1 E4:2 | E4:1 G4:1 C4:1 D4:1 | E4:4
                  F4:1 F4:1 F4:1.5 F4:0.5 | F4:1 E4:1 E4:1 E4:0.5 E4:0.5 | E4:1 D4:1 D4:1 E4:1 | D4:2 G4:2
                  E4:1 E4:1 E4:2 | E4:1 E4:1 E4:2 | E4:1 G4:1 C4:1 D4:1 | E4:4
                  F4:1 F4:1 F4:1 F4:1 | F4:1 E4:1 E4:1 E4:0.5 E4:0.5 | G4:1 G4:1 F4:1 D4:1 | C4:4
                  """),
        PianoSong(id: "happy-birthday", title: "Happy Birthday", level: .medium, tempo: 100,
                  names: ["happy birthday", "happy birthday to you", "the birthday song", "birthday song"],
                  melody: """
                  G4:0.75 G4:0.25 A4:1 G4:1 C5:1 B4:2
                  G4:0.75 G4:0.25 A4:1 G4:1 D5:1 C5:2
                  G4:0.75 G4:0.25 G5:1 E5:1 C5:1 B4:1 A4:2
                  F5:0.75 F5:0.25 E5:1 C5:1 D5:1 C5:3
                  """),
        PianoSong(id: "saints", title: "When the Saints Go Marching In", level: .medium, tempo: 132,
                  names: ["when the saints go marching in", "when the saints", "the saints go marching in", "oh when the saints"],
                  melody: """
                  C4:1 E4:1 F4:1 G4:4 R:1 | C4:1 E4:1 F4:1 G4:4 R:1
                  C4:1 E4:1 F4:1 G4:2 E4:2 | C4:2 E4:2 D4:4
                  E4:1 E4:1 D4:1 C4:3 C4:1 | E4:2 G4:2 G4:1 F4:3
                  E4:1 F4:1 G4:2 E4:2 | C4:2 D4:2 C4:4
                  """),
        PianoSong(id: "fur-elise", title: "Für Elise", level: .tricky, tempo: 84,
                  names: ["fur elise", "für elise", "fuer elise", "beethoven fur elise", "beethoven für elise"],
                  melody: """
                  E5:0.5 D#5:0.5 E5:0.5 D#5:0.5 E5:0.5 B4:0.5 D5:0.5 C5:0.5 | A4:1.5
                  C4:0.5 E4:0.5 A4:0.5 | B4:1.5 E4:0.5 G#4:0.5 B4:0.5 | C5:1.5
                  E4:0.5 E5:0.5 D#5:0.5 E5:0.5 D#5:0.5 E5:0.5 B4:0.5 D5:0.5 C5:0.5 | A4:1.5
                  C4:0.5 E4:0.5 A4:0.5 | B4:1.5 E4:0.5 C5:0.5 B4:0.5 | A4:3
                  """),
    ]

    static func song(_ id: String) -> PianoSong? {
        all.first { $0.id == id }
    }

    /// Finds the song a sentence names ("teach me twinkle twinkle" finds Twinkle Twinkle Little Star).
    /// The longest matching name wins, so "jingle bells" never loses to a shorter one.
    static func find(in text: String) -> PianoSong? {
        let t = " " + simple(text) + " "
        var best: (song: PianoSong, length: Int)?
        for song in all {
            for name in song.names + [song.title] {
                let n = simple(name)
                if t.contains(" " + n + " "), n.count > (best?.length ?? 0) {
                    best = (song, n.count)
                }
            }
        }
        return best?.song
    }

    /// Lowercase letters, numbers and single spaces only ("Row, Row, Row Your Boat" is "row row row your boat").
    static func simple(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
        let kept = folded.map { $0.isLetter || $0.isNumber ? $0 : " " }
        return String(kept).split(separator: " ").joined(separator: " ")
    }

    /// The songs as one line for Ace to say ("Hot Cross Buns, Mary Had a Little Lamb, ... and Für Elise").
    static var spokenList: String {
        let titles = all.map(\.title)
        guard titles.count > 1 else { return titles.first ?? "" }
        return titles.dropLast().joined(separator: ", ") + " and " + titles[titles.count - 1]
    }
}

/// Understands piano asks: "play piano", "teach me ode to joy", "play jingle bells", "what songs can you play".
/// Returns "open", "lessons", "list", "learn:<song id>" or "listen:<song id>".
enum PianoAsk {
    private static let polite = #"^(?:(?:please|ok|okay|alright|hey ace|ace|yo|can we|could we|can i|could i|let us|lets|i want to|i wanna|want to|i would like to|i'd like to|time to|go|now)\s+)*"#
    private static let end = #"(?:\s+(?:please|now|with me|for me|together|for a bit|for a while|again|on ace|in ace))*$"#
    private static let instrument = #"(?:the |a |my |your |ace )?(?:piano|piano keyboard|ace piano|keyboard piano)"#
    private static let onPiano = #"(?:\s+(?:on|with|using)\s+(?:the |a |my |your |ace )?(?:piano|keyboard))?"#

    static func parse(_ t: String) -> String? {
        // "what songs can you play on the piano", "what piano songs do you know"
        if Rx.matches(#"^(?:what|which) (?:piano )?songs (?:can|do) (?:you|i|we) (?:play|know|teach(?: me)?|learn)"# + onPiano + #"(?: please)?$"#, t)
            || Rx.matches(#"^(?:list|show me|tell me)(?: all)? (?:the |your )?piano songs(?: please)?$"#, t)
            || Rx.matches(#"^what piano songs (?:do you know|can you play|are there|do you have)$"#, t) {
            return "list"
        }
        // "teach me twinkle twinkle on the piano", "how do i play ode to joy"
        if let g = Rx.groups(polite + #"(?:can you |could you |will you |please )?(?:teach me(?: how)?(?: to play)?|show me how to play|how do (?:i|you) play|help me (?:learn|play)|learn(?: how)?(?: to play)?|i want to learn(?: how)?(?: to play)?|give me a (?:piano )?lesson (?:on|for)|piano lesson (?:on|for))\s+(?:the song |the tune |the melody )?(.+?)"# + onPiano + end, t),
           let song = PianoSongs.find(in: g[0]), PianoSongs.simple(g[0]) == matchedName(song, in: g[0]) {
            return "learn:" + song.id
        }
        // "teach me piano", "piano lessons", "i want to learn the piano"
        if Rx.matches(polite + #"(?:can you |could you |will you )?(?:teach me(?: how)?(?: to play)?|learn(?: how)?(?: to play)?|give me|start|do|have)\s+"# + instrument + #"(?: lessons?| songs?)?"# + end, t)
            || Rx.matches(#"^(?:ace )?piano (?:lessons?|songs?|class)(?: please)?$"#, t) {
            return "lessons"
        }
        // "play jingle bells", "play happy birthday on the piano", "can you play fur elise"
        if let g = Rx.groups(polite + #"(?:can you |could you |will you |please )?play(?: me| us)?\s+(?:the song |the tune |the melody )?(.+?)"# + onPiano + end, t),
           let song = PianoSongs.find(in: g[0]), PianoSongs.simple(g[0]) == matchedName(song, in: g[0]) {
            return "listen:" + song.id
        }
        // "play piano", "open the piano", "piano"
        if Rx.matches(polite + #"(?:play|open|start|launch|show(?: me)?|bring up|pull up|get out|use|go to|try)\s+"# + instrument + end, t)
            || Rx.matches(#"^(?:ace )?piano(?: time| mode)?$"#, t) {
            return "open"
        }
        return nil
    }

    /// The name of the song exactly as said, so "play jingle bells" counts but "play jingle bells by some band" doesn't.
    private static func matchedName(_ song: PianoSong, in text: String) -> String? {
        let said = PianoSongs.simple(text)
        return (song.names + [song.title]).map(PianoSongs.simple).first { $0 == said }
    }
}
