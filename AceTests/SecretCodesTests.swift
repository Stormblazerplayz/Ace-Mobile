import XCTest
@testable import Ace

@MainActor
final class SecretCodesTests: XCTestCase {
    func testCodeWheel() {
        XCTAssertEqual(Caesar.encode("Hello, World!", shift: 3), "Khoor, Zruog!")
        XCTAssertEqual(Caesar.decode("Khoor, Zruog!", shift: 3), "Hello, World!")
        XCTAssertEqual(Caesar.encode("xyz", shift: 3), "abc", "Wraps around after Z")
        XCTAssertEqual(Caesar.encode("abc", shift: -1), "zab")
        XCTAssertEqual(Caesar.encode("Abc", shift: 29), "Def", "29 is the same as 3")
        XCTAssertEqual(Caesar.encode("Abc", shift: 0), "Abc")
        XCTAssertEqual(Caesar.encode("Café 123", shift: 1), "Dbgé 123", "Only A to Z moves")
        XCTAssertEqual(Caesar.normalize(-1), 25)
        XCTAssertEqual(Caesar.normalize(52), 0)
        for shift in -30...30 {
            XCTAssertEqual(Caesar.decode(Caesar.encode("The Quick Brown Fox", shift: shift), shift: shift), "The Quick Brown Fox")
        }
    }

    func testCrackingTheWheel() throws {
        let cases: [(String, Int)] = [
            ("Hello, world! This is a secret message.", 3),
            ("Meet me at the park after school", 7),
            ("The quick brown fox jumps over the lazy dog", 13),
            ("Ace is my favorite helper", 20)
        ]
        for (plain, shift) in cases {
            let found = try XCTUnwrap(Caesar.crack(Caesar.encode(plain, shift: shift)))
            XCTAssertEqual(found.shift, shift, plain)
            XCTAssertEqual(found.text, plain)
        }
        XCTAssertNil(Caesar.crack("Hi"), "Too few letters to guess")
        XCTAssertNil(Caesar.crack("12 !!"))
        XCTAssertEqual(Caesar.letterCount("Hi, 2 u!"), 3)
        XCTAssertLessThan(Caesar.score("this reads like english"), Caesar.score("guvf ernqf yvxr ratyvfu"))
        XCTAssertEqual(Caesar.englishFrequency.count, 26)
    }

    func testMirrorCode() {
        XCTAssertEqual(MirrorCode.apply("abc XYZ"), "zyx CBA")
        XCTAssertEqual(MirrorCode.apply("Hello!"), "Svool!")
        XCTAssertEqual(MirrorCode.apply(MirrorCode.apply("Meet at 3pm")), "Meet at 3pm", "Twice gives it back")
        XCTAssertEqual(MirrorCode.flipped("m"), "n")
    }

    func testMorseCode() {
        XCTAssertEqual(Morse.encode("SOS"), "... --- ...")
        XCTAssertEqual(Morse.encode("hi there"), ".... .. / - .... . .-. .")
        XCTAssertEqual(Morse.encode("  ok  "), "--- -.-")
        XCTAssertEqual(Morse.encode("é"), "", "Letters Morse doesn't have are left out")
        XCTAssertEqual(Morse.decode("... --- ..."), "SOS")
        XCTAssertEqual(Morse.decode(".... .. / - .... . .-. ."), "HI THERE")
        XCTAssertEqual(Morse.decode("•••  ——— •••"), "SOS", "Other dot and dash marks work")
        XCTAssertEqual(Morse.decode("........ ."), "?E", "A code Morse doesn't have is ?")
        XCTAssertEqual(Morse.decode("...|---"), "S O")
        XCTAssertEqual(Morse.decode(Morse.encode("Meet me at 5, ok?")), "MEET ME AT 5, OK?")
        XCTAssertTrue(Morse.looksLikeMorse("... --- / ..."))
        XCTAssertFalse(Morse.looksLikeMorse("sos"))
        XCTAssertFalse(Morse.looksLikeMorse(" / "))
        XCTAssertEqual(Morse.table.count, 54)
        XCTAssertEqual(Set(Morse.table.values).count, Morse.table.count, "Every code is different")
        for (letter, code) in Morse.table {
            XCTAssertEqual(Morse.reverse[code], letter)
        }
    }

    func testMorseTiming() {
        // A dot is 1 beat, a dash 3, 1 between signals, 3 between letters, 7 between words.
        let sos = Morse.signals("... --- ...")
        XCTAssertEqual(Morse.totalUnits(sos), 27)
        XCTAssertEqual(sos.filter(\.on).count, 9)
        XCTAssertEqual(sos.compactMap(\.symbol), Array(0..<9))
        let words = Morse.signals(". / -")
        XCTAssertEqual(words, [
            MorseSignal(on: true, units: 1, symbol: 0),
            MorseSignal(on: false, units: 7),
            MorseSignal(on: true, units: 3, symbol: 1)
        ])
        XCTAssertTrue(Morse.signals("").isEmpty)
        XCTAssertTrue(Morse.signals(" / ").isEmpty)
    }

    func testRunningACode() {
        XCTAssertEqual(SecretCodes.run(.caesar, text: "abc", hiding: true, shift: 1), "bcd")
        XCTAssertEqual(SecretCodes.run(.caesar, text: "bcd", hiding: false, shift: 1), "abc")
        XCTAssertEqual(SecretCodes.run(.morse, text: "sos", hiding: true, shift: 0), "... --- ...")
        XCTAssertEqual(SecretCodes.run(.morse, text: "... --- ...", hiding: false, shift: 0), "SOS")
        XCTAssertEqual(SecretCodes.run(.mirror, text: "abc", hiding: true, shift: 0), "zyx")
        XCTAssertEqual(SecretCodes.run(.mirror, text: "zyx", hiding: false, shift: 0), "abc")
        let long = String(repeating: "a", count: 1000)
        XCTAssertEqual(SecretCodes.run(.caesar, text: long, hiding: true, shift: 1).count, SecretCodes.maxLength)
        XCTAssertEqual(SecretCode.allCases.count, 3)
        for code in SecretCode.allCases {
            XCTAssertFalse(code.title.isEmpty)
            XCTAssertFalse(code.howItWorks.isEmpty)
        }
    }

    func testWhatsNewMentionsSecretCodes() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 60 }) else {
            return XCTFail("Build 60 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("Secret codes") })
        XCTAssertEqual(releases.first?.build, releases.map(\.build).max())
    }
}
