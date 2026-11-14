import Foundation

/// Things Ace can do, found by rules first and the neural classifier second.
enum Intent: Equatable {
    case greeting, thanks, goodbye
    case summon                   // just "Ace" or "hey Ace": are you there?
    case time, date
    case daysUntil(String)
    case math(String)
    case convert(String)
    case roman(String)
    case randomNumber(Int, Int)
    case spell(String)
    case timer(seconds: TimeInterval, label: String)
    case reminder(text: String)
    case alarm
    case calendarAdd(text: String)
    case calendarEdit(text: String)
    case calendarDelete(text: String)
    case calendarList(text: String)
    case openSite(String)
    case searchTab(query: String, site: String?)
    case recipe(String)
    case weather(place: String?)
    case check
    case battery, storage, memoryUsage, network
    case largeFiles
    case findFiles(String)
    case findScreenshots(String)
    case describePhoto
    case bedtime
    case remember(String)
    case setName(String)
    case recall(String)
    case recallAll
    case forget(String)
    case handsFree(Bool)
    case pcPower(String)          // shutdown or restart
    case pcApp(action: String, app: String, onPC: Bool)
    case pcStatus
    case syncNow
    case sounds(Bool)
    case tellMore
    case repeatLast
    case correction(String?)       // "no, it's X" / "that's wrong"
    case teach(question: String, answer: String)
    case ipadOnlyLimit(String)
}

extension Intent {
    /// A short name for the kind of thing to do ("timer", "weather"...). Used by tests and the think loop.
    var kind: String {
        switch self {
        case .greeting: return "greeting"
        case .summon: return "summon"
        case .thanks: return "thanks"
        case .goodbye: return "goodbye"
        case .time: return "time"
        case .date: return "date"
        case .daysUntil: return "daysUntil"
        case .math: return "math"
        case .convert: return "convert"
        case .roman: return "roman"
        case .randomNumber: return "randomNumber"
        case .spell: return "spell"
        case .timer: return "timer"
        case .reminder: return "reminder"
        case .alarm: return "alarm"
        case .calendarAdd: return "calendarAdd"
        case .calendarEdit: return "calendarEdit"
        case .calendarDelete: return "calendarDelete"
        case .calendarList: return "calendarList"
        case .openSite: return "openSite"
        case .searchTab: return "searchTab"
        case .recipe: return "recipe"
        case .weather: return "weather"
        case .check: return "check"
        case .battery: return "battery"
        case .storage: return "storage"
        case .memoryUsage: return "memoryUsage"
        case .network: return "network"
        case .largeFiles: return "largeFiles"
        case .findFiles: return "findFiles"
        case .findScreenshots: return "findScreenshots"
        case .describePhoto: return "describePhoto"
        case .bedtime: return "bedtime"
        case .remember: return "remember"
        case .setName: return "setName"
        case .recall: return "recall"
        case .recallAll: return "recallAll"
        case .forget: return "forget"
        case .handsFree: return "handsFree"
        case .pcPower: return "pcPower"
        case .pcApp: return "pcApp"
        case .pcStatus: return "pcStatus"
        case .syncNow: return "syncNow"
        case .sounds: return "sounds"
        case .tellMore: return "tellMore"
        case .repeatLast: return "repeatLast"
        case .correction: return "correction"
        case .teach: return "teach"
        case .ipadOnlyLimit: return "ipadOnlyLimit"
        }
    }
}

enum IntentRouter {
    /// Reads the sentence with rules. Returns nil when no rule fits.
    static func parse(_ raw: String) -> Intent? {
        let t = TextKit.normalize(raw)
        guard !t.isEmpty else { return nil }

        // Calling Ace by name ("Ace", "hey Ace", "Ace, are you there?") is never a web search.
        if Rx.matches(#"^((hey|hi|hello|yo|ok|okay|oi|psst|um|uh|so|yes|yeah)\s+)*ace(\s+(are you there|you there|are you here|are you awake|are you listening|you awake|wake up))?$"#, t)
            || Rx.matches(#"^(are )?you (there|here|awake|listening)( ace)?$"#, t) {
            return .summon
        }

        // Small talk
        if Rx.matches(#"^(hi|hello|hey|yo|sup|hiya|howdy|good (morning|afternoon|evening|day))( there)?( to you)?( ace)?( to you)?$"#, t) { return .greeting }
        if Rx.matches(#"^(thanks|thank you|ty|thx|cheers|thank u)( ace)?( so much| very much| a lot| a bunch| a ton| heaps)?( ace| buddy| man| dude)?$"#, t) { return .thanks }
        if Rx.matches(#"^(ok |okay |alright |well )?(bye|goodbye|bye bye|good night|goodnight|see you|see ya|later|cya|talk to you later|catch you later)( for now)?( ace)?( for now)?$"#, t) { return .goodbye }

        // Teaching and corrections
        if let g = Rx.groups(#"^(?:if i ask|when i ask|if i say|when i say)\s+(.+?)\s*,?\s*(?:you should say|you say|say|answer|reply)\s+(.+)$"#, t) {
            return .teach(question: g[0], answer: g[1])
        }
        if let g = Rx.groups(#"^the answer to\s+(.+?)\s+is\s+(.+)$"#, t) { return .teach(question: g[0], answer: g[1]) }
        if Rx.matches(#"^(no|nope|wrong|that is wrong|that is not right|that is incorrect|incorrect|not right)$"#, t) { return .correction(nil) }
        if let g = Rx.groups(#"^(?:no|nope|wrong|actually|that is wrong|incorrect)\s*,?\s*(?:it is|the answer is|it should be|it was)\s+(.+)$"#, t) {
            return .correction(g[0])
        }

        // Follow-ups
        if Rx.matches(#"^(tell me more|more|more info|go on|keep going|what else|more about that|tell me more about (it|that))$"#, t) { return .tellMore }
        if Rx.matches(#"^(say that again|repeat that|what did you say|repeat|come again)$"#, t) { return .repeatLast }

        // Name and memory
        if let g = Rx.groups(#"^(?:my name is|call me|i am called)\s+([a-z][a-z' \-]{0,30})$"#, t) { return .setName(g[0]) }
        if Rx.matches(#"^(what do you (know|remember) about me|what do you remember|what have you remembered|list (my )?memories)$"#, t) { return .recallAll }
        if let g = Rx.groups(#"^(?:please )?remember (?:that )?(.+)$"#, t) { return .remember(g[0]) }
        if let g = Rx.groups(#"^forget (?:about )?(.+)$"#, t) { return .forget(g[0]) }
        if let g = Rx.groups(#"^(?:what is|do you know|what are|whats|tell me) my\s+(.+)$"#, t) { return .recall(g[0]) }
        if let g = Rx.groups(#"^(my .+? (?:is|are) .+)$"#, t), !t.contains("?") { return .remember(g[0]) }

        // Time
        if Rx.matches(#"^(what time is it|what is the time|time|current time|whats the time|tell me the time|time now|what time is it now)$"#, t) { return .time }
        if Rx.matches(#"^(what day is it|what is the date|what is today|todays date|what is todays date|date|what day is today|what is the date today)$"#, t)
            || Rx.matches(#"^(what is |whats |tell me )?(today'?s|the) date( today)?( please)?$|^what is the date today$|^what (day|date) is it( today)?$"#, t) { return .date }
        if let g = Rx.groups(#"^how (?:many|long) (?:days|sleeps|weeks) (?:until|till|til|to|before)\s+(.+)$"#, t) { return .daysUntil(g[0]) }

        // Hands-free and sounds
        if Rx.matches(#"(turn on|start|enable) hands ?free|hands ?free (on|mode)|start listening"#, t) { return .handsFree(true) }
        if Rx.matches(#"(turn off|stop|disable|end) hands ?free|hands ?free off|stop listening"#, t) { return .handsFree(false) }
        if Rx.matches(#"^(mute|turn off|disable) (your |the )?(sounds|sound effects|noises)$"#, t) { return .sounds(false) }
        if Rx.matches(#"^(unmute|turn on|enable) (your |the )?(sounds|sound effects|noises)$"#, t) { return .sounds(true) }

        // PC power (Nimbus does it; Ace tells, doesn't ask)
        let pcWords = #"(pc|computer|desktop|laptop|nimbus|windows)"#
        if Rx.matches(#"(shut ?down|turn off|power off|power down)\s+(my |the )?"# + pcWords, t) { return .pcPower("shutdown") }
        if Rx.matches(#"(restart|reboot)\s+(my |the )?"# + pcWords, t) { return .pcPower("restart") }
        if Rx.matches(#"^(shut ?down|restart|reboot|turn off|power off)( now)?$"#, t) { return .pcPower(t.contains("re") ? "restart" : "shutdown") }
        if Rx.matches(#"(shut ?down|turn off|restart|reboot|power off) (my |this |the )?ipad"#, t) {
            return .ipadOnlyLimit("Apps can't turn off or restart an iPad. Hold the top button and a volume button, then slide to power off.")
        }
        if Rx.matches(#"^(is my (pc|computer) (on|awake|online)|pc status|computer status|how is my (pc|computer))"#, t) { return .pcStatus }
        if Rx.matches(#"^(sync|sync now|sync with (my )?(pc|computer|nimbus)|sync up)$"#, t) { return .syncNow }

        // App window control (PC only)
        if let g = Rx.groups(#"^(close|quit|minimize|minimise|maximize|maximise|resize|kill|force quit|exit)\s+(?:the\s+)?(.+?)(\s+(?:on|in) (?:my |the )?(?:pc|computer|desktop|laptop))?$"#, t) {
            let action = g[0].replacingOccurrences(of: "minimise", with: "minimize").replacingOccurrences(of: "maximise", with: "maximize")
            let app = g[1].replacingOccurrences(of: " app", with: "").replacingOccurrences(of: " window", with: "")
            if !["this", "that", "it", "chat"].contains(app) {
                return .pcApp(action: action, app: app, onPC: !g[2].isEmpty)
            }
        }

        // Checks
        if Rx.matches(#"^(run|do) a (quick |full )?check( on (everything|things|my ipad|the ipad|stuff))?$"#, t) { return .check }
        if Rx.matches(#"^(check|check (everything|things|stuff|my ipad|the ipad|on things|up|around|status|in)|run a check|do a check|status( report)?|look around|how is my ipad|ipad status|how is everything|anything i should know|what needs my attention|scan)$"#, t) { return .check }
        if Rx.matches(#"\bbattery\b|\bcharge left\b|\bhow charged\b"#, t) { return .battery }
        if Rx.matches(#"\b(large|big|huge|biggest|largest) files?\b|taking up (space|storage)"#, t) { return .largeFiles }
        if Rx.matches(#"\b(storage|space left|free space|disk space|how much space|running out of space)\b"#, t) { return .storage }
        // "what does ram stand for" is a question about the word, not about this iPad's memory.
        if Rx.matches(#"\b(ram|memory usage|how much memory|memory use)\b"#, t),
           !Rx.matches(#"\b(stand for|stands for|short for|mean|meaning)\b|^(what is|whats) (a |the )?ram$"#, t) { return .memoryUsage }
        if Rx.matches(#"^(am i online|is (the )?(wifi|internet) (on|working)|network status|internet status)"#, t) { return .network }

        // Sleep
        if Rx.matches(#"(when should i (go to )?(bed|sleep)|bedtime|what time should i (go to )?(bed|sleep)|sleep schedule|am i sleeping enough|go to sleep)"#, t) { return .bedtime }

        // Math, conversions, numbers
        if let g = Rx.groups(#"^(?:what is |convert |change )?(-?\d+(?:\.\d+)?\s*[a-z°/ ]+?\s+(?:to|in|into)\s+[a-z°/ ]+)$"#, t), UnitConvert.convert(g[0]) != nil {
            return .convert(g[0])
        }
        if Rx.matches(#"^how many [a-z ]+ (are )?(in|is) \d"#, t), UnitConvert.convert(t) != nil { return .convert(t) }
        if let g = Rx.groups(#"(?:what is|whats)?\s*(\d+|[ivxlcdm]+) (?:in|to|as) roman numerals?"#, t) { return .roman(g[0]) }
        if let g = Rx.groups(#"^(?:what is|whats|convert)?\s*(?:the )?roman numerals? (?:for )?(\d+|[ivxlcdm]+)$"#, t) { return .roman(g[0]) }
        if let g = Rx.groups(#"random number (?:between|from) (-?\d+) (?:and|to) (-?\d+)"#, t), let a = Int(g[0]), let b = Int(g[1]) {
            return .randomNumber(min(a, b), max(a, b))
        }
        if let g = Rx.groups(#"^how (?:do you|do i|to) spell\s+([a-z\-']+)$"#, t) { return .spell(g[0]) }
        if let expr = MathEval.expression(from: t) { return .math(expr) }

        // Timers, reminders, alarms
        if Rx.matches(#"\b(set|start|make|create)?\s*(a |an )?timer\b"#, t) || Rx.matches(#"^\d+\s*(minute|min|second|sec|hour)s?\s+timer"#, t) {
            if let d = DateParser.duration(in: t) {
                var label = "Timer"
                if let g = Rx.groups(#"(?:called|named|labeled|for the|for my)\s+([a-z][a-z ]{1,30})$"#, t) {
                    label = TextKit.capitalizeFirst(g[0]) + " timer"
                } else if let g = Rx.groups(#"^(?:set |start |make )?(?:a |an |the )?([a-z]{3,20}) timer"#, t),
                          !["set", "start", "make", "new", "quick", "minute", "second", "hour"].contains(g[0]),
                          MathEval.numberWordsToDigits(g[0]) == g[0] {
                    label = TextKit.capitalizeFirst(g[0]) + " timer"
                }
                return .timer(seconds: d.seconds, label: label)
            }
        }
        if Rx.matches(#"^(can you |could you |please )?(time|count down) (\d|one|two|three|four|five|ten|fifteen|twenty|thirty|forty|fifty|sixty|ninety|a )"#, t),
           let d = DateParser.duration(in: t) {
            return .timer(seconds: d.seconds, label: "Timer")
        }
        if Rx.matches(#"^(set|make|create) (an |a )?alarm|wake me up"#, t) { return .alarm }
        if Rx.matches(#"^remind me\b|^(set|make|create|add) (a )?reminder|^reminder to|^(do not|dont) let me forget\b|^make sure i (remember|do not forget)\b"#, t) { return .reminder(text: raw) }

        // Calendar
        if Rx.matches(#"\b(what is|whats|what do i have|anything|show me|show|list|check|what s|open)\b.*\b(calendar|schedule|agenda|my events|my plans|any events|any plans)\b"#, t)
            || Rx.matches(#"^(what do i have|am i (free|busy)|whats? (next|coming up)|what is (next|coming up|on today|happening))"#, t)
            || Rx.matches(#"^(my )?(schedule|agenda|calendar)( today| tomorrow| this week)?$"#, t) {
            return .calendarList(text: t)
        }
        if Rx.matches(#"^(delete|remove|cancel|clear)\b.*"#, t) && Rx.matches(#"\b(event|meeting|appointment|calendar|practice|class|party|lesson|game|session)\b"#, t) {
            return .calendarDelete(text: raw)
        }
        if Rx.matches(#"^(move|reschedule|change|push|rename|edit|update)\b.*\b(to|from)\b"#, t)
            && !Rx.matches(#"\b(volume|brightness|wallpaper|setting|settings|password|name|voice|unit|units)\b"#, t) {
            return .calendarEdit(text: raw)
        }
        if Rx.matches(#"\b(add|put|schedule|create|make|book|plan|set up)\b.*\b(calendar|event|meeting|appointment)\b"#, t)
            || Rx.matches(#"^(schedule|new event|add event|create event|calendar add)\b"#, t) {
            return .calendarAdd(text: raw)
        }

        // Recipes and weather
        if let g = Rx.groups(#"(?:recipe|recipes) (?:for|of|with)\s+(.+)$"#, t) { return .recipe(g[0]) }
        if let g = Rx.groups(#"^(?:give me |show me |find |get )?(?:a |an )?(.+?) recipes?$"#, t) { return .recipe(g[0]) }
        if let g = Rx.groups(#"^how (?:do i|do you|to|can i) (?:cook|bake|grill|roast|fry)\s+(?:a |an |some )?(.+)$"#, t) { return .recipe(g[0]) }
        if let g = Rx.groups(#"^what (?:can|should) i (?:cook|make for (?:dinner|lunch|breakfast)|eat)(?: with (.+))?$"#, t) {
            return .recipe(g[0].isEmpty ? "chicken" : g[0])
        }
        if Rx.matches(#"\b(weather|forecast|temperature outside|how (hot|cold) is it|will it (rain|snow)|is it (raining|snowing)|umbrella)\b"#, t) {
            if let g = Rx.groups(#"\b(?:in|for|at)\s+([a-z][a-z .'\-]+?)(?:\s+(?:today|tomorrow|this week|right now|now))?$"#, t),
               !["today", "tomorrow", "this week", "now", "right now", "here", "my area", "outside", "the week", "the weekend"].contains(g[0]) {
                return .weather(place: g[0])
            }
            return .weather(place: nil)
        }

        // Files, screenshots, photos
        if let g = Rx.groups(#"(?:find|search for|look for|where is|search)\s+(?:a |an |my |the )?screenshots?\s*(?:of|with|about|that says|showing|for)?\s*(.*)$"#, t) {
            return .findScreenshots(g[0])
        }
        if let g = Rx.groups(#"^(?:search|look through) (?:my )?screenshots (?:for )?(.+)$"#, t) { return .findScreenshots(g[0]) }
        if let g = Rx.groups(#"(?:find|search for|look for|where is|open|search)\s+(?:a |an |my |the )?(?:file|document|doc|pdf|folder|files)\s*(?:called|named|about|with|for)?\s*(.*)$"#, t) {
            return .findFiles(g[0])
        }
        if let g = Rx.groups(#"^search (?:my )?(?:files|documents|docs) (?:for )?(.+)$"#, t) { return .findFiles(g[0]) }
        if Rx.matches(#"(what is|whats|what s) in (this|the|that|my) (picture|photo|image|pic|screenshot)|describe (this|the|that) (picture|photo|image)|read (this|the) (picture|photo|image)"#, t) {
            return .describePhoto
        }

        // Browser (hands-free friendly)
        if let g = Rx.groups(#"^(?:search|look up|find)\s+(.+?)\s+on\s+(youtube|google|wikipedia|amazon|reddit|github|bing|duckduckgo|spotify|twitch|tiktok|pinterest|ebay|maps|google maps|apple music|netflix|roblox|thingiverse|printables|makerworld|etsy|imdb|walmart|target)$"#, t) {
            return .searchTab(query: g[0], site: g[1])
        }
        if let g = Rx.groups(#"^(?:play|watch)\s+(.+?)\s+on\s+youtube$"#, t) { return .searchTab(query: g[0], site: "youtube") }
        if let g = Rx.groups(#"^(youtube|google|wikipedia|amazon|reddit)\s+(.+)$"#, t) { return .searchTab(query: g[1], site: g[0]) }
        if let g = Rx.groups(#"^(?:search for|search the web for|search the internet for|google|search up|search)\s+(.+)$"#, t) {
            return .searchTab(query: g[0], site: nil)
        }
        if let g = Rx.groups(#"^(?:open|go to|launch|pull up|take me to|bring up|visit|open up)\s+(?:the\s+)?(.+?)(?:\s+(?:website|site|page|tab|app|in safari|in a new tab|for me|please))*$"#, t) {
            let target = g[0]
            if !["my calendar", "calendar", "settings", "ace settings", "checks"].contains(target) || Sites.lookup(target) != nil {
                return .openSite(target)
            }
        }
        return nil
    }
}
