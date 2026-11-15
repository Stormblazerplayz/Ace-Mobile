import Foundation

/// Chat and banter ("roast me", "lol", "bet you can't", "I'm bored") and goodbyes ("I'm gonna leave",
/// "gtg"). These are conversation, so Ace answers them itself and never sends them to a web search.
/// Only clear information questions ever go to the web.
enum Chat {
    enum Kind: String, CaseIterable, Equatable {
        /// "roast me", "it's not like you can roast me"
        case roast
        /// "you're dumb", "you suck" (Ace never insults back)
        case insult
        /// "bet you can't", "prove it"
        case dare
        /// "I'm bored", "this is boring"
        case bored
        /// "lol", "haha"
        case laugh
        /// "whatever", "meh", "bruh", "ok cool"
        case whatever
    }

    private static let tail = #"(\s+(ace|bro|dude|man|lol|lmao|haha|then|anyway|anyways|now|ok|okay|though|tho))*"#

    /// What kind of banter a message is, or nil when it's a real question or command.
    static func kind(_ raw: String) -> Kind? {
        let t = TextKit.normalize(raw)
        guard !t.isEmpty else { return nil }
        // Roasting a person (not "roast a chicken", which is a recipe).
        if Rx.matches(#"\broast (me|you|yourself|him|her|us|them|my (friend|brother|sister|mom|dad|cousin|teacher|dog|cat))\b"#, t)
            || Rx.matches(#"\b(can not|can't|could not|cannot) roast\b"#, t)
            || Rx.matches(#"^(give me a |do a |say a |try a )?roast$"#, t) {
            return .roast
        }
        if Rx.matches(#"^(ace )?(you are|your|you re|ace is|you|u)( so| really| very| such| super| kinda| kind of| the| a| an)* (dumb|stupid|useless|bad|annoying|trash|garbage|boring|lame|cringe|slow|weird|idiot|noob|worst|terrible|mean|bad at this|not smart|not funny|not that smart|a bot|just a bot|broken)"# + tail + "$", t)
            || Rx.matches(#"^(you suck|you stink|i hate you|i do not like you|shut up|be quiet|nobody asked|no one asked|you are no help|you are not helping|you are not even smart)"# + tail + "$", t) {
            return .insult
        }
        if Rx.matches(#"^(i )?bet you (can not|could not|do not|will not|cannot|wont|cant)\b"#, t)
            || Rx.matches(#"^(prove it|i dare you|i double dare you|make me|you wish|yeah right|sure you can|as if)"# + tail + "$", t)
            || Rx.matches(#"^(whatever |well |ok |okay )?it is not like you (can|could|know|are)\b"#, t)
            || Rx.matches(#"^you can not (even )?(do|beat|answer|win|say|make|roast|stop)\b"#, t) {
            return .dare
        }
        if Rx.matches(#"\b(i am|i) (so |really |very |super |kinda |kind of )*bored\b"#, t)
            || Rx.matches(#"^(this is|that is|that was|this|it is|today is) (so |really |very |super )*boring"# + tail + "$", t)
            || Rx.matches(#"^i (have|got) nothing to do"# + tail + "$", t) {
            return .bored
        }
        if Rx.matches(#"^(lol+|lmao+|lmfao|rofl|haha+|hahaha+|hehe+|ha|hah|ha ha( ha)*|xd|that is (so )?funny|so funny|funny)"# + tail + "$", t) {
            return .laugh
        }
        if Rx.matches(#"^(whatever|meh|bruh|bro|k|kk|cool|cool cool|nice|nice one|wow|ugh|hmm+|oof|nah|sure|fine|ok cool|okay cool|ok then|okay then|same|idk|i do not know|dunno|nothing|nothing much|who cares|so what|bruh moment|yikes|oh well|ok whatever|okay whatever)"# + tail + "$", t)
            || Rx.matches(#"^whatever\b"#, t) {
            return .whatever
        }
        return nil
    }

    /// "I'm gonna leave", "gtg", "goodnight", "I'm going", "see ya": time to say bye.
    static func isGoodbye(_ raw: String) -> Bool {
        let t = TextKit.normalize(raw)
        guard !t.isEmpty else { return false }
        let lead = #"^((ok|okay|alright|well|anyway|anyways|so|um|uh|welp|right|ace),? )*"#
        let end = #"(\s+(now|soon|bye|ace|bro|dude|for now|for the night|for today|tonight|later|everyone|lol|okay|ok|then))*$"#
        let leave = #"(leave|go|head out|head off|get going|bounce|sleep|go to bed|go to sleep|log off|sign off|get off|go now|leave now|be going|take off|dip)"#
        return Rx.matches(lead + #"(i am |i |i will |i'll )?(going to|got to|gotta|have to|need to|should|must|will|am about to|about to|want to) "# + leave + end, t)
            || Rx.matches(lead + #"(i am|i|i'm) (leaving|going|off|out|outta here|heading out|logging off|signing off|done|done for (today|now|the night)|going to bed|going to sleep|heading to bed|off to bed|off to sleep)"# + end, t)
            || Rx.matches(lead + #"(gtg|g2g|got to go|gotta go|ttyl|brb|bye|bye bye|byee+|goodbye|good bye|good night|goodnight|gn|night|nighty night|night night|see you|see ya|see you later|see you tomorrow|see ya later|later|laters|cya|peace|peace out|catch you later|talk later|talk to you later|adios|farewell|sleep well|sweet dreams|until next time|that is all|that is it for now|i am done for today)"# + end, t)
    }

    /// Words that point at the last thing you asked ("search it", "look that up").
    static let pointers: Set<String> = ["it", "that", "this", "them", "those", "these", "that one", "this one",
                                       "the answer", "the question", "that up", "it up", "this up", "the last one"]

    static func isPointer(_ query: String) -> Bool {
        pointers.contains(TextKit.normalize(query))
    }

    /// What "search it" should search: the last real question, or nil (then Ace asks "Search what?").
    static func resolve(_ query: String, lastQuestion: String?) -> String? {
        guard isPointer(query) else { return query }
        guard let q = lastQuestion?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty, !isPointer(q) else { return nil }
        return q
    }

    private static let questionStart = #"^(what|what is|what are|who|whom|whose|where|when|why|how|which|is|are|was|were|can|could|does|do|did|will|would|should|has|have|had|tell me|explain|define|describe|meaning of|definition of|show me|list|name|give me|facts about|info on|information on|history of|i want to know|i wonder|search for|look up|find out)\b"#
    private static let statementStart = #"^(i|i am|i'm|my|me|you|you are|your|we|it|it is|that|that is|this|this is|they|he|she|lol|ok|okay|yes|yeah|yep|no|nah|whatever|bruh|so|well|anyway|anyways|wow|oh|ugh|hmm|haha|thanks|thank you|bye|hi|hello|hey)\b"#

    /// A clear information question that can go to the web. Never banter, a goodbye, one word,
    /// or a message that's only little words like "it" and "the".
    static func isInfoQuestion(_ raw: String) -> Bool {
        let t = TextKit.normalize(raw)
        let words = TextKit.words(raw)
        guard words.count >= 2, !TextKit.keywords(raw).isEmpty else { return false }
        guard kind(raw) == nil, !isGoodbye(raw) else { return false }
        if Rx.matches(questionStart, t) { return true }
        if Rx.matches(statementStart, t) { return false }
        if raw.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?") { return true }
        // A short topic like "black hole facts" or "capital of peru".
        return words.count <= 6
    }

    /// Ace's friendly answers in Normal mode.
    static func lines(_ kind: Kind) -> [String] {
        switch kind {
        case .roast:
            return ["I'd rather cheer you on than roast you. Want a joke instead?",
                    "No roasting from me. I'm a hype orb. You've got this!",
                    "Roasting isn't my thing, but I can tell you a joke. Just say \"tell me a joke\".",
                    "How about a compliment instead? You ask great questions."]
        case .insult:
            return ["Ouch. I'm still here to help, though. What do you need?",
                    "Sorry I let you down. Tell me what went wrong and I'll try again.",
                    "I'll try to do better. What can I help with?",
                    "Fair enough. Want to try asking me another way?"]
        case .dare:
            return ["Challenge accepted. What should I try?",
                    "Oh yeah? Try me. Ask me anything.",
                    "Let's find out. Give me your hardest question.",
                    "Watch me. What's the challenge?"]
        case .bored:
            return ["Want to play trivia? Just say \"trivia\".",
                    "Let's fix that. I can play trivia or 20 questions, or tell you a joke.",
                    "Boredom? Not on my watch. Say \"trivia\", \"20 questions\" or \"tell me a joke\".",
                    "How about a fun fact? Ask me \"tell me a fun fact\"."]
        case .laugh:
            return ["Ha! Glad that landed.",
                    "I'm here all day.",
                    "Haha. Want another one?",
                    "That made my orb glow."]
        case .whatever:
            return ["Got it. Let me know if you need anything.",
                    "Okay! I'm here when you want me.",
                    "No problem. Ask me anything whenever.",
                    "Alright. Want to play a game or ask me something?"]
        }
    }
}
