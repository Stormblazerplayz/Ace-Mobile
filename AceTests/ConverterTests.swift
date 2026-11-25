import XCTest
@testable import Ace

final class ConverterTests: XCTestCase {
    private func unit(_ id: String, _ kind: MeasureKind) -> MeasureUnit {
        guard let found = Converter.unit(id, in: kind) else {
            XCTFail("Missing unit \(id) in \(kind)")
            return MeasureUnit(id: id, name: id, short: id, perBase: 1)
        }
        return found
    }

    private func convert(_ value: Double, _ from: String, _ to: String, _ kind: MeasureKind) -> Double {
        Converter.convert(value, from: unit(from, kind), to: unit(to, kind), kind: kind)
    }

    func testEveryKindHasGoodUnitsAndDefaults() {
        for kind in MeasureKind.allCases {
            let units = Converter.units(kind)
            XCTAssertGreaterThanOrEqual(units.count, 3, "\(kind) needs units")
            XCTAssertEqual(Set(units.map(\.id)).count, units.count, "\(kind) unit ids must be unique")
            XCTAssertTrue(units.allSatisfy { $0.perBase > 0 })
            XCTAssertNotNil(Converter.unit(kind.defaultPair.from, in: kind), "\(kind) default from")
            XCTAssertNotNil(Converter.unit(kind.defaultPair.to, in: kind), "\(kind) default to")
            XCTAssertNotEqual(kind.defaultPair.from, kind.defaultPair.to)
        }
    }

    func testKnownConversions() {
        XCTAssertEqual(convert(1, "m", "ft", .length), 3.280839895, accuracy: 1e-8)
        XCTAssertEqual(convert(5280, "ft", "mi", .length), 1, accuracy: 1e-12)
        XCTAssertEqual(convert(1, "in", "cm", .length), 2.54, accuracy: 1e-12)
        XCTAssertEqual(convert(1, "lb", "oz", .weight), 16, accuracy: 1e-9)
        XCTAssertEqual(convert(1, "kg", "lb", .weight), 2.20462262, accuracy: 1e-7)
        XCTAssertEqual(convert(1, "cup", "ml", .volume), 236.5882365, accuracy: 1e-7)
        XCTAssertEqual(convert(1, "gal", "qt", .volume), 4, accuracy: 1e-12)
        XCTAssertEqual(convert(3, "tsp", "tbsp", .volume), 1, accuracy: 1e-12)
        XCTAssertEqual(convert(100, "kmh", "mph", .speed), 62.1371192, accuracy: 1e-6)
        XCTAssertEqual(convert(1, "ac", "ft2", .area), 43_560, accuracy: 1e-6)
        XCTAssertEqual(convert(1, "ha", "m2", .area), 10_000, accuracy: 1e-9)
        XCTAssertEqual(convert(2, "h", "min", .time), 120, accuracy: 1e-12)
        XCTAssertEqual(convert(1, "wk", "day", .time), 7, accuracy: 1e-12)
        XCTAssertEqual(convert(1000, "mb", "gb", .data), 1, accuracy: 1e-12)
        XCTAssertEqual(convert(1, "gib", "mib", .data), 1024, accuracy: 1e-9)
        XCTAssertEqual(convert(1, "b", "bit", .data), 8, accuracy: 1e-12)
    }

    func testTemperatures() {
        XCTAssertEqual(convert(100, "c", "f", .temperature), 212, accuracy: 1e-9)
        XCTAssertEqual(convert(98.6, "f", "c", .temperature), 37, accuracy: 1e-9)
        XCTAssertEqual(convert(-40, "c", "f", .temperature), -40, accuracy: 1e-9)
        XCTAssertEqual(convert(0, "k", "c", .temperature), -273.15, accuracy: 1e-9)
        XCTAssertEqual(convert(32, "f", "k", .temperature), 273.15, accuracy: 1e-9)
        XCTAssertEqual(convert(20, "c", "c", .temperature), 20)
    }

    func testEveryPairRoundTrips() {
        for kind in MeasureKind.allCases {
            let units = Converter.units(kind)
            for a in units {
                for b in units {
                    let there = Converter.convert(12.5, from: a, to: b, kind: kind)
                    let back = Converter.convert(there, from: b, to: a, kind: kind)
                    XCTAssertEqual(back, 12.5, accuracy: 1e-6, "\(kind) \(a.id) to \(b.id) and back")
                }
            }
        }
    }

    func testFormatting() {
        XCTAssertEqual(Converter.format(0), "0")
        XCTAssertEqual(Converter.format(-0.0), "0")
        XCTAssertEqual(Converter.format(0.5), "0.5")
        XCTAssertEqual(Converter.format(3.280839895013123), "3.28084")
        XCTAssertEqual(Converter.format(62.1371192237334), "62.13712")
        XCTAssertEqual(Converter.format(43_560), "43,560")
        XCTAssertEqual(Converter.format(1_234_567.891), "1,234,568")
        XCTAssertEqual(Converter.format(-40), "-40")
        XCTAssertEqual(Converter.format(1e20), "1 × 10²⁰")
        XCTAssertEqual(Converter.format(1.5e-7), "1.5 × 10⁻⁷")
        XCTAssertEqual(Converter.format(.infinity), "—")
        XCTAssertEqual(Converter.superscript(-12), "⁻¹²")
    }

    func testTypingAndParsing() {
        XCTAssertEqual(Converter.cleanTyping("12a.3.4", allowNegative: false), "12.34")
        XCTAssertEqual(Converter.cleanTyping("3,5", allowNegative: false), "3.5")
        XCTAssertEqual(Converter.cleanTyping("-5", allowNegative: false), "5")
        XCTAssertEqual(Converter.cleanTyping("-5", allowNegative: true), "-5")
        XCTAssertEqual(Converter.cleanTyping("1-2", allowNegative: true), "12")
        XCTAssertEqual(Converter.cleanTyping(String(repeating: "9", count: 30), allowNegative: false).count, Converter.maxDigits)
        XCTAssertEqual(Converter.parse("1,000"), 1000)
        XCTAssertEqual(Converter.parse(" 2.5 "), 2.5)
        XCTAssertEqual(Converter.parse("-3"), -3)
        XCTAssertNil(Converter.parse(""))
        XCTAssertNil(Converter.parse("-"))
        XCTAssertNil(Converter.parse("."))
    }

    func testEveryUnitList() {
        let rows = Converter.everyUnit(1, from: unit("km", .length), kind: .length)
        XCTAssertEqual(rows.count, Converter.units(.length).count)
        XCTAssertEqual(rows.first { $0.unit.id == "m" }?.value ?? 0, 1000, accuracy: 1e-9)
        XCTAssertEqual(rows.first { $0.unit.id == "km" }?.value ?? 0, 1, accuracy: 1e-12)
    }

    func testComparisons() {
        XCTAssertTrue(Converter.compare(base: 0, kind: .length).isEmpty)
        XCTAssertTrue(Converter.compare(base: 5, kind: .temperature).isEmpty)
        for kind in MeasureKind.allCases where kind != .temperature {
            let refs = Converter.references(kind)
            XCTAssertGreaterThanOrEqual(refs.count, 3, "\(kind) needs things to compare with")
            XCTAssertTrue(refs.allSatisfy { $0.base > 0 })
            let list = Converter.compare(base: 10, kind: kind)
            XCTAssertEqual(list.map(\.reference.base), list.map(\.reference.base).sorted(), "Smallest first")
        }
        // Half a marathon is 21,097.5 m.
        let half = Converter.compare(base: 21_097.5, kind: .length)
        guard let marathon = half.first(where: { $0.reference.name == "marathon" }) else {
            return XCTFail("Marathon should be there")
        }
        XCTAssertEqual(marathon.times, 0.5, accuracy: 1e-12)
        XCTAssertEqual(Converter.sentence(marathon), "Half a marathon")
        // The headline picks a thing you need at least one of, closest to one.
        XCTAssertEqual(Converter.headline(half)?.reference.name, "Mount Everest")
    }

    func testSentences() {
        let everest = MeasureReference(name: "Mount Everest", symbol: "mountain.2.fill", base: 8849, rough: false)
        let tub = MeasureReference(name: "bathtub", symbol: "bathtub.fill", base: 150, rough: true)
        let pool = MeasureReference(name: "Olympic pool", symbol: "figure.pool.swim", base: 2_500_000, rough: true)
        XCTAssertEqual(Converter.sentence(MeasureComparison(reference: everest, times: 1)), "One Mount Everest")
        XCTAssertEqual(Converter.sentence(MeasureComparison(reference: everest, times: 0.12)), "12% of Mount Everest")
        XCTAssertEqual(Converter.sentence(MeasureComparison(reference: tub, times: 3.21)), "About 3.2 × bathtub")
        XCTAssertEqual(Converter.sentence(MeasureComparison(reference: tub, times: 230.7)), "About 231 × bathtub")
        XCTAssertEqual(Converter.sentence(MeasureComparison(reference: pool, times: 0.5)), "About half an Olympic pool")
        XCTAssertEqual(Converter.sentence(MeasureComparison(reference: pool, times: 0.0001)), "About 1% of an Olympic pool")
        XCTAssertEqual(Converter.article("HD movie"), "an")
        XCTAssertEqual(Converter.article("soda can"), "a")
    }

    func testBarsAndThermometer() {
        XCTAssertEqual(Converter.barFill(1), 0.5, accuracy: 1e-12)
        XCTAssertEqual(Converter.barFill(1000), 1, accuracy: 1e-12)
        XCTAssertEqual(Converter.barFill(1e9), 1)
        XCTAssertEqual(Converter.barFill(0), 0)
        XCTAssertEqual(Converter.thermometerFill(celsius: 40), 0.5, accuracy: 1e-12)
        XCTAssertEqual(Converter.thermometerFill(celsius: -100), 0)
        XCTAssertEqual(Converter.thermometerFill(celsius: 500), 1)
        XCTAssertEqual(Converter.feel(celsius: 37), "Hot")
        XCTAssertEqual(Converter.feel(celsius: 20), "Comfy")
        XCTAssertEqual(Converter.feel(celsius: -300), "Colder than anything can be")
        XCTAssertEqual(Converter.landmarks.map(\.celsius), [0, 20, 37, 100])
    }

    func testRememberedPairs() {
        let text = Converter.encodePairs([.weight: ("kg", "lb"), .length: ("m", "ft")])
        XCTAssertEqual(text, "length=m>ft;weight=kg>lb")
        let back = Converter.decodePairs("length=m>ft;weight=kg>zz;bogus=a>b;time=h>min;junk")
        XCTAssertEqual(back.count, 2)
        XCTAssertEqual(back[.length]?.from, "m")
        XCTAssertEqual(back[.length]?.to, "ft")
        XCTAssertEqual(back[.time]?.to, "min")
        XCTAssertNil(back[.weight], "An unknown unit is skipped")
        XCTAssertTrue(Converter.decodePairs("").isEmpty)
    }

    func testWhatsNewMentionsTheConverter() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 74 }) else {
            return XCTFail("Build 74 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("Converter") })
        XCTAssertEqual(releases.map(\.build), releases.map(\.build).sorted(by: >))
    }
}
