import Foundation

/// One step of a breath: in, hold, or out.
enum BreathStep: String, Equatable {
    case breatheIn, hold, breatheOut, rest

    var words: String {
        switch self {
        case .breatheIn: return "Breathe in"
        case .hold: return "Hold"
        case .breatheOut: return "Breathe out"
        case .rest: return "Rest"
        }
    }
}

/// A breathing pattern: its steps and how many seconds each one lasts.
enum BreathPattern: String, CaseIterable, Identifiable {
    case balloon, calm, box, fourSevenEight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balloon: return "Balloon"
        case .calm: return "Calm"
        case .box: return "Box"
        case .fourSevenEight: return "4-7-8"
        }
    }

    var blurb: String {
        switch self {
        case .balloon: return "Fill up like a balloon, then let the air out slowly. Great to start with."
        case .calm: return "Breathe out longer than you breathe in. It helps your body slow down."
        case .box: return "In, hold, out, hold, 4 seconds each, like going round a box."
        case .fourSevenEight: return "In for 4, hold for 7, out for 8. A slow one for winding down."
        }
    }

    var symbol: String {
        switch self {
        case .balloon: return "balloon.fill"
        case .calm: return "leaf.fill"
        case .box: return "square"
        case .fourSevenEight: return "moon.stars.fill"
        }
    }

    var steps: [(step: BreathStep, seconds: Double)] {
        switch self {
        case .balloon: return [(.breatheIn, 3), (.breatheOut, 4)]
        case .calm: return [(.breatheIn, 4), (.breatheOut, 6)]
        case .box: return [(.breatheIn, 4), (.hold, 4), (.breatheOut, 4), (.rest, 4)]
        case .fourSevenEight: return [(.breatheIn, 4), (.hold, 7), (.breatheOut, 8)]
        }
    }

    /// Seconds for one whole breath.
    var cycle: Double { steps.reduce(0) { $0 + $1.seconds } }

    /// Breaths that fit in a session (at least one).
    func breaths(minutes: Int) -> Int { max(1, Int((Double(minutes) * 60 / cycle).rounded())) }
}

/// Where a session is at a moment: which breath, which step, how far into it, and how big the orb is.
struct BreathMoment: Equatable {
    let breath: Int
    let stepIndex: Int
    let step: BreathStep
    /// 0 to 1 through the step.
    let progress: Double
    /// Whole seconds left in the step, for the countdown (at least 1).
    let secondsLeft: Int
    /// 0 to 1 through the whole breath, for the dot going round the ring.
    let cycleProgress: Double
    /// How full the lungs are, 0 (empty) to 1 (full): grows breathing in, stays on hold, shrinks breathing out.
    let fullness: Double
    let finished: Bool
}

/// A breathing session: a pattern done for a number of breaths.
struct BreathSession: Equatable {
    let pattern: BreathPattern
    let breaths: Int

    init(pattern: BreathPattern, minutes: Int) {
        self.pattern = pattern
        breaths = pattern.breaths(minutes: minutes)
    }

    var length: Double { Double(breaths) * pattern.cycle }

    /// Gentle in and out, so the orb starts and stops softly.
    static func ease(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        return 0.5 - cos(x * .pi) / 2
    }

    func moment(at elapsed: Double) -> BreathMoment {
        let steps = pattern.steps
        guard elapsed < length else {
            let last = steps.count - 1
            return BreathMoment(breath: breaths - 1, stepIndex: last, step: steps[last].step, progress: 1, secondsLeft: 1,
                                cycleProgress: 1, fullness: 0, finished: true)
        }
        let t = max(0, elapsed)
        let breath = Int(t / pattern.cycle)
        var inBreath = t - Double(breath) * pattern.cycle
        let cycleProgress = inBreath / pattern.cycle
        var index = 0
        while index < steps.count - 1 && inBreath >= steps[index].seconds {
            inBreath -= steps[index].seconds
            index += 1
        }
        let (step, seconds) = steps[index]
        let progress = min(1, inBreath / seconds)
        let fullness: Double
        switch step {
        case .breatheIn: fullness = Self.ease(progress)
        case .hold: fullness = 1
        case .breatheOut: fullness = 1 - Self.ease(progress)
        case .rest: fullness = 0
        }
        return BreathMoment(breath: breath, stepIndex: index, step: step, progress: progress,
                            secondsLeft: max(1, Int((seconds - inBreath).rounded(.up))),
                            cycleProgress: cycleProgress, fullness: fullness, finished: false)
    }
}

/// Minutes of breathing done, and the run of days in a row, kept on the iPad.
struct BreathLog {
    static let shared = BreathLog(key: "ace.breathe.log")
    let key: String

    /// Seconds breathed on each day ("2026-11-25").
    private var days: [String: Double] {
        (UserDefaults.standard.dictionary(forKey: key) as? [String: Double]) ?? [:]
    }

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    func add(seconds: Double, on date: Date = Date()) {
        guard seconds > 0 else { return }
        var d = days
        d[Self.dayKey(date), default: 0] += seconds
        UserDefaults.standard.set(d, forKey: key)
    }

    var totalMinutes: Int { Int((days.values.reduce(0, +) / 60).rounded()) }

    func minutes(on date: Date = Date()) -> Int { Int(((days[Self.dayKey(date)] ?? 0) / 60).rounded()) }

    /// Days in a row with some breathing, counting back from today (or yesterday, if today has none yet).
    func streak(today: Date = Date(), calendar: Calendar = .current) -> Int {
        let d = days
        var day = calendar.startOfDay(for: today)
        if d[Self.dayKey(day, calendar: calendar)] == nil {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var count = 0
        while d[Self.dayKey(day, calendar: calendar)] != nil {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    func clearAll() { UserDefaults.standard.removeObject(forKey: key) }
}

/// Understands breathing asks: "breathe with me", "start a breathing exercise", "box breathing exercise".
/// Returns "open" or a pattern id. Questions about breathing ("how do fish breathe") are left for answers.
enum BreathAsk {
    private static let polite = #"^(?:(?:please|ok|okay|hey ace|ace|can you|could you|can we|let us|lets|i want to|i would like to|i need to|want to|time to)\s+)*"#

    static func parse(_ t: String) -> String? {
        if let g = Rx.groups(polite + #"(?:start|do|open|try|have|take)?\s*(?:a |an |some |the )?(box|calm|balloon|4 7 8|four seven eight) breathing(?: exercise| session)?(?: with me)?(?: please| now)?$"#, t),
           let first = g.first {
            // "do box breathing" is a request, but a bare "box breathing" may be a question, so it gets an answer.
            if t == first + " breathing" { return nil }
            switch first {
            case "box": return BreathPattern.box.rawValue
            case "calm": return BreathPattern.calm.rawValue
            case "balloon": return BreathPattern.balloon.rawValue
            default: return BreathPattern.fourSevenEight.rawValue
            }
        }
        if Rx.matches(polite + #"(?:breathe with me|do (?:some )?(?:deep |slow )?breathing(?: with me)?|(?:start|do|open|have|take|try) (?:a |an |some )?(?:deep |calm |slow )?breathing (?:exercise|exercises|session|break)(?: with me)?|(?:a )?breathing break|help me (?:calm down|relax) with (?:some )?breathing)(?: please| now)?$"#, t)
            || Rx.matches(#"^(?:ace )?breathe$"#, t) {
            return "open"
        }
        return nil
    }
}
