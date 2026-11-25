import Foundation

/// Things Ace can do, found by rules first and the neural classifier second.
enum Intent: Equatable {
    case greeting, thanks, goodbye
    case chat(Chat.Kind)              // banter: "roast me", "lol", "bet you can't", "I'm bored"
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
    case recipeTweak(String)        // "make it spicier", "for 8 people"
    case script(String)             // "give me a kill brick script", "C++ servo code"
    case translate(phrase: String, code: String)   // "how do you say thank you in spanish"
    case translateList              // "what languages can you speak"
    case game(String)               // "trivia", "trivia:Space", "twenty", "tictactoe", "hangman", "number", "rps", "arcade"
    case homework(String)           // "solve 2x + 3 = 11" (or "" for "help me with my homework")
    case note(action: String, text: String)   // "take a note: buy milk", "read my notes"
    case voiceSpeed(String)         // "talk slower": "slower", "faster" or "normal"
    case shopping(String)           // "recipe", "read" or "add:milk and eggs"
    case weather(place: String?, day: String? = nil)
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
    case call(Bool)               // "call Ace" starts a voice call (true), "hang up" ends it (false)
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
    case home(HomeCommand)
    case focus(String)            // "start 1500", "stop" or "left"
    case personality(Bool)        // "turn on sassy mode" (true), "go back to normal mode" (false)
    case leader(Leaders.Ask)      // "who is the prime minister of the UK", "who is the president of the UK" (it has none)
    case flashcards(FlashcardAsk) // "study my flashcards", "make spanish flashcards", "add a flashcard: hola = hello"
}

extension Intent {
    /// Things Ace does itself (timers, checks, calendar, memory, math, PC...), so they never go to LFM3 Omni.
    /// Only small talk goes to the model when it's picked as the brain.
    var isAction: Bool {
        switch self {
        case .greeting, .thanks, .goodbye, .chat: return false
        default: return true
        }
    }

    /// A short name for the kind of thing to do ("timer", "weather"...). Used by tests and the think loop.
    var kind: String {
        switch self {
        case .greeting: return "greeting"
        case .summon: return "summon"
        case .thanks: return "thanks"
        case .goodbye: return "goodbye"
        case .chat: return "chat"
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
        case .recipeTweak: return "recipeTweak"
        case .script: return "script"
        case .translate, .translateList: return "translate"
        case .game: return "game"
        case .homework: return "homework"
        case .note: return "note"
        case .voiceSpeed: return "voiceSpeed"
        case .shopping: return "shopping"
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
        case .call: return "call"
        case .pcPower: return "pcPower"
        case .pcApp: return "pcApp"
        case .pcStatus: return "pcStatus"
        case .syncNow: return "syncNow"
        case .personality: return "personality"
        case .sounds: return "sounds"
        case .tellMore: return "tellMore"
        case .repeatLast: return "repeatLast"
        case .correction: return "correction"
        case .teach: return "teach"
        case .ipadOnlyLimit: return "ipadOnlyLimit"
        case .home: return "home"
        case .focus: return "focus"
        case .leader: return "leader"
        case .flashcards: return "flashcards"
        }
    }
}

enum IntentRouter {
    /// Takes "Hello Ace," or "Hey Ace" off the front of a question, so "Hello Ace what is the capital of the UK"
    /// is just "what is the capital of the UK". A plain "hello" or "hey Ace" on its own is left alone (it's a greeting),
    /// and so is "hello world in python", where "hello" is part of the question.
    static func withoutGreeting(_ raw: String) -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^(?:((?:hey|hi|hello|hiya|yo|howdy|ok|okay|good morning|good afternoon|good evening|morning)(?:\s+there)?)\b\s*([,!.;:]*)\s*)?(?:(ace)\b\s*([,!.;:]*)\s*)?(.*)$"#
        guard let g = Rx.groups(pattern, text), g.count == 5 else { return text }
        let greeting = g[0], greetingMark = g[1], name = g[2], nameMark = g[3]
        let rest = g[4].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !greeting.isEmpty || !name.isEmpty, !rest.isEmpty else { return text }
        // A real question or command has to follow, not just more chat ("hey ace!!").
        guard rest.rangeOfCharacter(from: .alphanumerics) != nil else { return text }
        // "Hello Ace ..." or "Ace, ..." is clearly talking to Ace. "Ace of spades" isn't, so the name alone needs a comma.
        let marked = (!greeting.isEmpty && !name.isEmpty) || !greetingMark.isEmpty || !nameMark.isEmpty
        let starts = #"^(what|what's|whats|who|who's|whos|where|where's|when|why|how|how's|which|is|are|was|were|can|could|do|does|did|will|would|should|tell|show|give|make|set|play|start|stop|open|turn|find|search|remind|add|let's|lets|please|define|translate|calculate|explain|convert|spell|i|i'm|im|my|whats|help)\b"#
        guard marked || Rx.matches(starts, rest) else { return text }
        return rest
    }

    /// "call Ace" or "start a voice call" is true, "hang up" or "end the call" is false, anything else nil.
    /// "call me Sam" and "call mom" aren't calls to Ace, so they're nil.
    static func call(_ t: String) -> Bool? {
        let polite = #"^(?:(?:please|can you|could you|would you|can we|could we|ok|okay|alright|yo|hey|hi|ace)\s+)*"#
        let end = #"(?:\s+(?:please|now|right now|ace|with me|again))*$"#
        let what = #"(?:the |this |our |my |a )?(?:voice |phone |audio )?call"#
        if Rx.matches(polite + #"(?:hang up|end|stop|leave|finish|quit|exit) "# + what + #"(?: with (?:you|ace|me))?"# + end, t)
            || Rx.matches(polite + #"hang up(?: the phone| on me| now)?"# + end, t)
            || Rx.matches(#"^(?:ok |okay |alright )?(?:bye|goodbye|bye bye) (?:and |now )?hang up$"#, t) {
            return false
        }
        if Rx.matches(polite + #"(?:call|ring|phone|facetime|video call|voice call) (?:ace|ase|you)"# + end, t)
            || Rx.matches(polite + #"(?:start|begin|make|have|do|open|start up|set up) (?:a |an |the )?(?:voice |phone |audio )?call(?: with (?:you|ace|me))?(?: screen| mode)?"# + end, t)
            || Rx.matches(polite + #"(?:let us|lets|i want to|want to|i would like to) (?:have |do |start |make )?(?:a )?(?:voice |phone )?call(?: with (?:you|ace))?"# + end, t)
            || Rx.matches(polite + #"(?:let us|lets|can we|i want to) talk on (?:the |a )?(?:phone|call)"# + end, t)
            || Rx.matches(polite + #"(?:voice|phone|audio) call(?: mode| screen)?"# + end, t)
            || Rx.matches(polite + #"call (?:mode|screen)"# + end, t)
            || t == "call" {
            return true
        }
        return nil
    }

    /// "turn on sassy mode" is true, "turn off sassy mode" or "normal mode" is false, anything else nil.
    static func personality(_ t: String) -> Bool? {
        let polite = #"^(?:please |can you |could you |would you |ace |hey ace |ok ace |yo ace )*"#
        let sass = #"(?:sassy|sass|sassy mode|sass mode|sassy personality|attitude mode)"#
        if Rx.matches(polite + #"(?:turn off|switch off|stop|disable|end|no more|exit|quit|leave) (?:the |your )?"# + sass + #"(?: mode)?(?: please| now)?$"#, t)
            || Rx.matches(polite + #"(?:go |switch |change |turn )?(?:back )?(?:to )?(?:normal|nice|regular|default) (?:mode|personality|ace)(?: please| now)?$"#, t)
            || Rx.matches(polite + #"(?:be|act) (?:normal|nice)(?: again| now)?$"#, t)
            || Rx.matches(#"^"# + sass + #"(?: mode)? off$"#, t) {
            return false
        }
        if Rx.matches(polite + #"(?:turn on|switch on|start|enable|activate|go|switch|change|put)(?: to| into| on)? (?:the |your )?"# + sass + #"(?: mode)?(?: please| now)?$"#, t)
            || Rx.matches(polite + #"(?:get|act) (?:more |extra |super )?sassy(?: please| now| again)?$"#, t)
            || Rx.matches(#"^"# + sass + #"(?: mode)? on$"#, t) {
            return true
        }
        return nil
    }

    /// Reads the sentence with rules. Returns nil when no rule fits.
    static func parse(_ raw: String) -> Intent? {
        let t = TextKit.normalize(raw)
        guard !t.isEmpty else { return nil }

        // Calling Ace by name ("Ace", "hey Ace", "Ace, are you there?") is never a web search.
        if Rx.matches(#"^((hey|hi|hello|yo|ok|okay|oi|psst|um|uh|so|yes|yeah)\s+)*ace(\s+(are you there|you there|are you here|are you awake|are you listening|you awake|wake up))?$"#, t)
            || Rx.matches(#"^(are )?you (there|here|awake|listening)( ace)?$"#, t) {
            return .summon
        }

        // A voice call ("call Ace", "hang up"), before small talk so "bye and hang up" ends the call.
        if let on = call(t) { return .call(on) }

        // Small talk
        if Rx.matches(#"^(hi|hello|hey|yo|sup|hiya|howdy|good (morning|afternoon|evening|day))( there)?( to you)?( ace)?( to you)?$"#, t) { return .greeting }
        if Rx.matches(#"^(ok |okay |oh |well )?(thanks|thank you|ty|thx|cheers|thank u|tysm|tyvm|thanks a lot|many thanks|much appreciated|appreciate it|i appreciate it|i appreciate you)( ace)?( so much| very much| a lot| a bunch| a ton| heaps| for (the help|helping|that|everything))?( ace| buddy| man| dude| bro| bud| friend)?$"#, t) { return .thanks }
        if Rx.matches(#"^(ok |okay |alright |well )?(bye|goodbye|bye bye|good night|goodnight|see you|see ya|later|cya|talk to you later|catch you later)( for now)?( ace)?( for now)?$"#, t) { return .goodbye }
        // "I'm gonna leave", "gtg", "goodnight": a goodbye, never a web search.
        if Chat.isGoodbye(raw) { return .goodbye }

        // Teaching and corrections
        if let g = Rx.groups(#"^(?:if i ask|when i ask|if i say|when i say)\s+(.+?)\s*,?\s*(?:you should say|you say|say|answer|reply)\s+(.+)$"#, t) {
            return .teach(question: g[0], answer: g[1])
        }
        if let g = Rx.groups(#"^the answer to\s+(.+?)\s+is\s+(.+)$"#, t) { return .teach(question: g[0], answer: g[1]) }
        if Rx.matches(#"^(no|nope|wrong|that is wrong|that is not right|that is incorrect|incorrect|not right)$"#, t) { return .correction(nil) }
        if let g = Rx.groups(#"^(?:no|nope|wrong|actually|that is wrong|incorrect)\s*,?\s*(?:it is|the answer is|it should be|it was)\s+(.+)$"#, t) {
            return .correction(g[0])
        }

        // Banter ("roast me", "lol", "whatever", "bet you can't"): conversation, never a web search.
        if let banter = Chat.kind(raw) { return .chat(banter) }

        // Follow-ups
        if Rx.matches(#"^(tell me more|more|more info|go on|keep going|what else|more about that|tell me more about (it|that))$"#, t) { return .tellMore }
        if Rx.matches(#"^(say that again|repeat that|what did you say|repeat|come again)$"#, t) { return .repeatLast }

        // Flashcards ("study my flashcards", "make spanish flashcards", "add a flashcard: hola = hello").
        // Read from the words as typed, because normalizing drops "=" and ":", and before homework so "x = y" is a card.
        if let ask = FlashcardText.parse(raw) { return .flashcards(ask) }

        // Who leads a country, and fixing a wrong title ("president of the UK").
        if let ask = Leaders.parse(raw) { return .leader(ask) }

        // Homework, step by step ("solve 2x + 3 = 11", "3/4 + 1/8", "help me with my math homework").
        // Read from the words as typed, because normalizing drops "=", "(" and ")".
        if let hw = Homework.intent(raw) { return .homework(hw) }

        // Notes, the voice speed and the shopping list
        if let n = HelperParser.note(raw) { return .note(action: n.action, text: n.text) }
        if let v = HelperParser.voiceSpeed(raw) { return .voiceSpeed(v) }
        if let s = HelperParser.shopping(raw) { return .shopping(s) }

        // Ace's built-in scripts: Roblox Lua and C++ ("give me a kill brick script", "C++ servo code")
        if ScriptLibrary.wantsScript(t) || ScriptLibrary.listAsk(t) != nil || ScriptLibrary.needsOne(t) != nil { return .script(t) }

        // Translating ("how do you say thank you in spanish", "translate good night to japanese")
        if let tr = Phrasebook.parse(t) { return .translate(phrase: tr.phrase, code: tr.code) }
        if Rx.matches(#"^(what|which) languages (can you|do you) (speak|translate|know|translate to|say things in)$"#, t)
            || Rx.matches(#"^(can you|do you) (speak|translate)( other| different)? languages$"#, t) { return .translateList }

        // Games: trivia and 20 questions
        if Rx.matches(#"^(?:(?:can we|can you|let us|lets|i want to|want to|wanna|please|ok|okay)\s+)*(?:play|start|do)\s+(?:a\s+|some\s+)?(?:game of\s+)?(?:20|twenty) questions(?: with me)?$"#, t)
            || Rx.matches(#"^(?:can you\s+)?guess what i am thinking(?: of| about)?$"#, t)
            || Rx.matches(#"^(?:20|twenty) questions$"#, t) {
            return .game("twenty")
        }
        if Rx.matches(#"^(?:(?:what (?:is|are)|show(?: me)?|tell me|read(?: me)?|check) )?(?:my |the )?(?:best |high |top )?(?:trivia|quiz) (?:scores?|records?|bests?|high scores?|top scores?|streaks?|scoreboard|stats)(?: please)?$"#, t)
            || Rx.matches(#"^(?:what (?:is|are) )?my (?:best |high |top )?(?:scores?|records?|streaks?) (?:in|at|for) (?:trivia|the quiz)(?: please)?$"#, t)
            || Rx.matches(#"^how (?:am i doing|have i done|good am i) (?:at|in) trivia$"#, t) {
            return .game("trivia:records")
        }
        if Rx.matches(#"^(?:(?:can we|can you|let us|lets|i want to|want to|wanna|please|ok|okay)\s+)*(?:(?:play|start|do|give me|have)\s+(?:a\s+|some\s+)?(?:trivia|quiz)(?:\s+game|\s+round|\s+questions?)?|quiz me|test me|ask me (?:a\s+|some\s+)?(?:trivia|quiz)(?:\s+questions?)?|trivia(?: time)?)(?:\s+(?:about|on|with|for)\s+.+)?(?: please)?$"#, t) {
            if let cat = Trivia.category(in: t) { return .game("trivia:" + cat) }
            return .game("trivia")
        }

        // Ace Games: tic-tac-toe, hangman, guess the number, rock paper scissors and the games screen
        if let g = ArcadeAsk.parse(t) { return .game(g) }

        // Sassy mode by voice ("turn on sassy mode", "get sassy", "normal mode"), before Home so it's never a scene.
        if let on = personality(t) { return .personality(on) }

        // Home (Apple Home): lights, plugs, fans, thermostats, the robot vacuum, scenes
        if let h = HomeParser.parse(t) { return .home(h) }

        // Changing the last recipe ("make it vegetarian", "for 8 people", "double it")
        if RecipeTweaks.parse(t) != nil { return .recipeTweak(t) }

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
        if Rx.matches(#"^how many [a-z0-9 ]+ (are )?(in|is) (\d|a |an |one )"#, t), UnitConvert.convert(t) != nil { return .convert(t) }
        if let g = Rx.groups(#"^(?:what is |convert |change )?((?:a|an|one) [a-z°/ ]+?\s+(?:to|in|into)\s+[a-z°/ 0-9]+)$"#, t), UnitConvert.convert(g[0]) != nil {
            return .convert(g[0])
        }
        if let g = Rx.groups(#"(?:what is|whats)?\s*(\d+|[ivxlcdm]+) (?:in|to|as) roman numerals?"#, t) { return .roman(g[0]) }
        if let g = Rx.groups(#"^(?:what is|whats|convert)?\s*(?:the )?roman numerals? (?:for )?(\d+|[ivxlcdm]+)$"#, t) { return .roman(g[0]) }
        if let g = Rx.groups(#"random number (?:between|from) (-?\d+) (?:and|to) (-?\d+)"#, t), let a = Int(g[0]), let b = Int(g[1]) {
            return .randomNumber(min(a, b), max(a, b))
        }
        if let g = Rx.groups(#"^how (?:do you|do i|to) spell\s+([a-z\-']+)$"#, t) { return .spell(g[0]) }
        if let expr = MathEval.expression(from: t) { return .math(expr) }

        // Focus sessions ("focus for 25 minutes", "start a pomodoro", "how much focus time is left")
        if Rx.matches(#"\b(focus|pomodoro|study session|homework session)\b"#, t), !Rx.matches(#"\b(scene|mode|lights?)\b"#, t) {
            if Rx.matches(#"^(please )?(stop|end|cancel|quit|finish|turn off)( the| my)? (focus|pomodoro|study|homework)( session| timer| time)?( please)?$"#, t) {
                return .focus("stop")
            }
            if Rx.matches(#"\b(left|remaining)\b"#, t), Rx.matches(#"^(how (much|long)|what is|time)"#, t) { return .focus("left") }
            if Rx.matches(#"^(please |can you |could you |ace )?(start|begin|set|do|make|give me|time to|i want to|i need to|let us|lets|help me)?\s*(a |an |my |the )?(focus|pomodoro|study|homework)( session| timer| time| block)?(\s+(for|of)\s+.+|\s+\d+.*)?( please)?$"#, t) {
                let seconds = DateParser.duration(in: t).map { Int($0.seconds) } ?? 25 * 60
                return .focus("start \(min(max(seconds, 60), 4 * 3600))")
            }
        }

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

        // Recipes ("with eggs and cheese" asks for ideas, "idea dinner" asks for any idea)
        if let g = Rx.groups(#"^(?:so |ok |okay )?what (?:can|could|should) (?:i|we) (?:make|cook|bake|eat|have)(?: for (?:dinner|lunch|breakfast|dessert|a snack|snack))? (?:with|using|out of|from)\s+(.+)$"#, t)
            ?? Rx.groups(#"^(?:give me |show me |find |suggest |any |got any )?(?:a |some )?(?:recipes?|meals?|dishes|food|ideas?) (?:i can make |to make |i can cook |to cook )?(?:with|using)\s+(.+)$"#, t)
            ?? Rx.groups(#"^i (?:have|got|only have)\s+(.+?) what (?:can|should|could) i (?:make|cook|bake)$"#, t) {
            return .recipe("with " + g[0])
        }
        if let g = Rx.groups(#"^what (?:can|should|could) (?:i|we) (?:cook|make|bake|eat|have)(?: for (dinner|lunch|breakfast|dessert|a snack|snack|tonight|today))?$"#, t) {
            return .recipe("idea " + g[0])
        }
        if let g = Rx.groups(#"^(?:give me |tell me |show me |suggest |i want |i need |find me )?(?:a |some |any )?(?:random |good |easy |new |yummy )?(dinner |lunch |breakfast |dessert |snack )?(?:recipe|recipes|recipe ideas?|meal ideas?)$"#, t) {
            return .recipe("idea " + g[0].trimmingCharacters(in: .whitespaces))
        }
        if let g = Rx.groups(#"^(?:any |some |got any |give me |i need )?(dinner|lunch|breakfast|dessert|snack|meal|food|cooking|baking) ideas?$"#, t) {
            return .recipe("idea " + g[0])
        }
        if let g = Rx.groups(#"(?:recipe|recipes) (?:for|of)\s+(?:a |an |some |the )?(.+)$"#, t) { return .recipe(g[0]) }
        if let g = Rx.groups(#"^(?:give me |show me |find |get |find me )?(?:a |an |the )?(.+?) recipes?$"#, t),
           !Rx.matches(#"^(what|who|why|how|is|are|do|does|did|can|where|when|which)\b"#, g[0]) { return .recipe(g[0]) }
        if let g = Rx.groups(#"^(?:how (?:do i|do you|to|can i|would i|should i)|i want to|lets|let us|teach me (?:how )?to|can you teach me (?:how )?to|help me|show me how to) (?:cook|bake|grill|roast|fry)\s+(?:a |an |some |the )?(.+?)(?: please| at home| from scratch)?$"#, t) {
            return .recipe(g[0])
        }
        // "make" is used for lots of things ("make a crafting table"), so only known dishes count.
        if let g = Rx.groups(#"^(?:how (?:do i|do you|to|can i|would i|should i) make|i want to make|lets make|let us make|teach me (?:how )?to make|can you teach me (?:how )?to make|help me make|show me how to make)\s+(?:a |an |some |the |homemade )?(.+?)(?: please| at home| from scratch)?$"#, t),
           RecipeBook.knows(g[0]) {
            return .recipe(g[0])
        }
        if Rx.matches(#"\b(weather|forecast|temperature outside|how (hot|cold) is it|will it (rain|snow)|is it (raining|snowing)|umbrella)\b"#, t) {
            let day = DayWords.find(in: t)
            let rest = day?.rest ?? t
            let when = day.flatMap { $0.offset == 0 && $0.label == "today" ? nil : $0.label.lowercased() }
            if let g = Rx.groups(#"\b(?:in|for|at)\s+([a-z][a-z .'\-]+?)(?:\s+(?:this week|right now|now|like))?$"#, rest),
               !["this week", "now", "right now", "here", "my area", "outside", "the week", "like"].contains(g[0]) {
                return .weather(place: g[0], day: when)
            }
            return .weather(place: nil, day: when)
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
        // "look it up", "google that": search the last thing you asked.
        if let g = Rx.groups(#"^(?:search|look|google|find|search up|look up)\s+(it|that|this|that one|this one)(?:\s+up)?(?:\s+(?:on|in)\s+(?:google|the web|the internet|safari))?(?:\s+(?:for me|please|now))*$"#, t) {
            return .searchTab(query: g[0], site: nil)
        }
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
