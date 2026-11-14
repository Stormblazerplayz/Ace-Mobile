import Foundation

/// Finds dates, times and lengths of time in what the user says.
enum DateParser {
    struct Found {
        var date: Date
        var duration: TimeInterval?
        var allDay: Bool
        /// The words that described the time, so they can be cut out of a title.
        var phrase: String
        var hint: String = ""

        var phrases: [String] { [phrase, hint].filter { !$0.isEmpty } }
    }

    /// "in 10 minutes", "for an hour and a half", "5 min" -> seconds.
    static func duration(in text: String) -> (seconds: TimeInterval, phrase: String)? {
        let t = MathEval.numberWordsToDigits(TextKit.normalize(text))
            .replacingOccurrences(of: "an hour and a half", with: "90 minutes")
            .replacingOccurrences(of: "a hour", with: "1 hour")
            .replacingOccurrences(of: "an hour", with: "1 hour")
            .replacingOccurrences(of: "a minute", with: "1 minute")
            .replacingOccurrences(of: "half an hour", with: "30 minutes")
            .replacingOccurrences(of: "half a minute", with: "30 seconds")
            .replacingOccurrences(of: "a day", with: "1 day")
            .replacingOccurrences(of: "a second", with: "1 second")
        let pattern = #"(\d+(?:\.\d+)?)\s*(seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h|days?|d|weeks?)\b"#
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = re.matches(in: t, range: NSRange(t.startIndex..., in: t))
        guard !matches.isEmpty else { return nil }
        var total: TimeInterval = 0
        var phrases: [String] = []
        for m in matches {
            guard let nr = Range(m.range(at: 1), in: t), let ur = Range(m.range(at: 2), in: t),
                  let whole = Range(m.range, in: t), let n = Double(t[nr]) else { continue }
            let unit = String(t[ur])
            let mult: Double
            switch unit.first {
            case "s": mult = 1
            case "m": mult = 60
            case "h": mult = 3600
            case "d": mult = 86400
            case "w": mult = 604800
            default: mult = 60
            }
            total += n * mult
            phrases.append(String(t[whole]))
        }
        guard total > 0 else { return nil }
        return (total, phrases.joined(separator: " "))
    }

    /// Finds a date/time like "tomorrow at 4", "next friday", "dec 3 at 5pm", "in 20 minutes", "tonight".
    static func find(in text: String, now: Date = Date()) -> Found? {
        let lower = text.lowercased()
        // "in 20 minutes" style.
        if Rx.matches(#"\bin\s+(\d+|a|an|one|two|three|four|five|ten|fifteen|twenty|thirty|half)\b"#, lower),
           let d = duration(in: lower) {
            return Found(date: now.addingTimeInterval(d.seconds), duration: nil, allDay: false, phrase: "in " + d.phrase)
        }
        var prepared = text
        let swaps: [(String, String)] = [
            ("tonight", "today at 8pm"), ("this evening", "today at 6pm"), ("this afternoon", "today at 3pm"),
            ("this morning", "today at 9am"), ("tomorrow morning", "tomorrow at 9am"),
            ("tomorrow night", "tomorrow at 8pm"), ("tomorrow afternoon", "tomorrow at 3pm"),
            ("tomorrow evening", "tomorrow at 6pm"), (" noon", " 12pm"), (" midnight", " 11:59pm"),
        ]
        var phraseHint = ""
        for (a, b) in swaps where prepared.lowercased().contains(a) {
            if let r = prepared.range(of: a, options: .caseInsensitive) {
                prepared.replaceSubrange(r, with: b)
                phraseHint = a.trimmingCharacters(in: .whitespaces)
            }
        }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let range = NSRange(prepared.startIndex..., in: prepared)
        guard let m = detector.firstMatch(in: prepared, range: range), let date = m.date,
              let r = Range(m.range, in: prepared) else { return nil }
        let phrase = String(prepared[r])
        let p = phrase.lowercased()
        let hasTime = Rx.matches(#"\d\s*(am|pm|a\.m\.|p\.m\.)|\d:\d\d|\bat\s+\d|noon|midnight|o'?clock"#, p)
            || !phraseHint.isEmpty && phraseHint != "today"
        var result = date
        // A bare time that already passed today means tomorrow ("at 7" said at 9pm).
        if hasTime, !p.contains("today"), !p.contains("tomorrow"), result < now,
           Calendar.current.isDate(result, inSameDayAs: now) {
            result = Calendar.current.date(byAdding: .day, value: 1, to: result) ?? result
        }
        if !hasTime {
            result = Calendar.current.startOfDay(for: result)
        }
        var d: TimeInterval?
        if m.duration > 0 { d = m.duration }
        return Found(date: result, duration: d, allDay: !hasTime, phrase: phrase, hint: phraseHint)
    }

    /// Removes the date words and filler from a sentence so what's left is a good title.
    static func title(from text: String, removing phrases: [String], fillers: [String]) -> String {
        var s = " " + text + " "
        for phrase in phrases where !phrase.isEmpty {
            s = s.replacingOccurrences(of: phrase, with: " ", options: .caseInsensitive)
        }
        for f in fillers.sorted(by: { $0.count > $1.count }) {
            s = s.replacingOccurrences(of: " \(f) ", with: " ", options: .caseInsensitive)
        }
        let cutWords = ["today", "tomorrow", "tonight", "on", "at", "for", "from", "to", "this", "next", "every"]
        var words = s.split(separator: " ").map(String.init)
        while let last = words.last, cutWords.contains(last.lowercased()) { words.removeLast() }
        while let first = words.first, ["to", "a", "an", "the", "that", "about"].contains(first.lowercased()), words.count > 1 {
            words.removeFirst()
        }
        let t = words.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " .,!?"))
        return TextKit.capitalizeFirst(t)
    }

    static func say(_ date: Date, allDay: Bool = false, now: Date = Date()) -> String {
        let cal = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        let dayWord: String
        if cal.isDateInToday(date) { dayWord = "today" }
        else if cal.isDateInTomorrow(date) { dayWord = "tomorrow" }
        else if cal.isDateInYesterday(date) { dayWord = "yesterday" }
        else if let days = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: date)).day, days > 0, days < 7 {
            dayWord = date.formatted(.dateTime.weekday(.wide))
        } else {
            dayWord = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        }
        return allDay ? dayWord : "\(dayWord) at \(time)"
    }

    static func sayDuration(_ seconds: TimeInterval) -> String {
        let f = DateComponentsFormatter()
        f.allowedUnits = seconds >= 86400 ? [.day, .hour] : seconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        f.unitsStyle = .full
        f.maximumUnitCount = 2
        return f.string(from: seconds) ?? "\(Int(seconds)) seconds"
    }
}
