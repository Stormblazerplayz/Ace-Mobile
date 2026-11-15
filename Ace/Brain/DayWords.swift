import Foundation

/// Day words in a question: "tomorrow", "on saturday", "this weekend".
/// Used for "what's the weather tomorrow" and follow-ups like "what about saturday?".
enum DayWords {
    struct Found: Equatable {
        /// Days from today (0 is today).
        var offset: Int
        /// How Ace says it: "today", "tomorrow", "Saturday", "this weekend".
        var label: String
        /// How many days it covers (2 for the weekend).
        var length: Int
        /// The question without the day words.
        var rest: String
    }

    static let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

    /// Finds the first day word in the text.
    static func find(in text: String, today: Date = Date(), calendar: Calendar = .current) -> Found? {
        let t = TextKit.normalize(text)
        let todayIndex = calendar.component(.weekday, from: today) - 1   // 0 is Sunday
        let toSaturday = todayIndex == 0 ? 0 : 6 - todayIndex
        var rules: [(pattern: String, offset: Int, label: String, length: Int)] = [
            (#"(?:for |on )?the day after tomorrow"#, 2, "the day after tomorrow", 1),
            (#"(?:for |on )?tomorrow(?: morning| afternoon| evening| night)?"#, 1, "tomorrow", 1),
            (#"(?:for |on )?(?:this |the )weekend|(?:for |on )?weekend"#, toSaturday, "this weekend", todayIndex == 0 ? 1 : 2),
            (#"(?:for )?tonight|(?:for )?today|(?:for )?this (?:morning|afternoon|evening)|right now"#, 0, "today", 1),
        ]
        for (i, day) in weekdays.enumerated() {
            let ahead = (i - todayIndex + 7) % 7
            rules.append(("(?:for |on |this )?" + day, ahead, day.capitalized, 1))
            rules.append(("(?:for |on )?next " + day, ahead == 0 ? 7 : ahead, "next " + day.capitalized, 1))
        }
        // Earliest match wins; for a tie, the longer one ("next saturday" beats "saturday").
        var best: (range: Range<String.Index>, rule: (pattern: String, offset: Int, label: String, length: Int))?
        for rule in rules {
            guard let r = t.range(of: #"(?<![a-z'])(?:"# + rule.pattern + #")(?![a-z'])"#, options: .regularExpression) else { continue }
            if let b = best {
                if r.lowerBound > b.range.lowerBound { continue }
                if r.lowerBound == b.range.lowerBound, r.upperBound <= b.range.upperBound { continue }
            }
            best = (r, rule)
        }
        guard let b = best else { return nil }
        var rest = t
        rest.replaceSubrange(b.range, with: " ")
        rest = rest.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
        return Found(offset: b.rule.offset, label: b.rule.label, length: b.rule.length, rest: rest)
    }

    /// True when the text is only a day ("tomorrow", "on saturday", "this weekend").
    static func isOnlyDay(_ text: String) -> Bool {
        guard let f = find(in: text) else { return false }
        return f.rest.isEmpty || ["and", "then", "instead"].contains(f.rest)
    }
}
