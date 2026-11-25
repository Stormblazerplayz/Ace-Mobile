import Foundation

/// Real words for each typing lesson. Each row's words only use keys learned so far.
enum TypingWords {
    /// Only A S D F G H J K L.
    static let homeRow = [
        "a", "as", "ask", "asks", "add", "adds", "all", "dad", "dads", "sad", "fall", "falls",
        "hall", "halls", "glad", "flag", "flags", "gas", "has", "had", "lad", "lads", "shall",
        "flask", "half", "salad", "salads", "gala", "saga", "slash", "flash", "dash", "lash",
        "sash", "lag", "fad", "alas", "glass", "lass", "salsa", "gall", "jags", "ha",
    ].filter { $0.allSatisfy { "asdfghjkl".contains($0) } }

    /// Home row plus Q W E R T Y U I O P.
    static let topRow = [
        "water", "quiet", "quote", "tower", "power", "write", "after", "offer", "other", "their",
        "there", "three", "start", "stair", "house", "horse", "sugar", "fruit", "ready", "story",
        "tired", "quest", "pilot", "purple", "guitar", "yellow", "forest", "desert", "field",
        "light", "right", "sight", "great", "today", "toast", "otter", "puppy", "kitty", "salt",
        "roof", "food", "good", "idea", "ship", "sheep", "wheat", "poet", "giraffe", "keep",
        "deep", "hope", "rope", "tree", "free", "quilt", "judge", "jelly", "happy", "party",
        "pretty", "little", "apple", "tiger", "your", "while", "people", "kite",
    ].filter { $0.allSatisfy { "asdfghjklqwertyuiop".contains($0) } }

    /// Words that each use at least one of Z X C V B N M.
    static let bottomRow = [
        "zebra", "box", "fox", "cave", "van", "moon", "name", "number", "bench", "camp", "cabin",
        "magic", "music", "zoom", "buzz", "jazz", "maze", "vine", "voice", "brave", "cloud",
        "climb", "snack", "black", "back", "cab", "mix", "six", "next", "exam", "banana", "comic",
        "bacon", "nuts", "vacuum", "cozy", "lazy", "crab", "bamboo", "dozen", "frozen", "oxygen",
        "nickname", "cucumber", "bubble", "mobile", "cabbage", "beach", "seven", "movie", "camera",
    ].filter { $0.contains { "zxcvbnm".contains($0) } }

    /// Words with letters from all over the keyboard.
    static let allLetters = [
        "keyboard", "jumping", "quickly", "wizard", "zigzag", "puzzle", "jacket", "oxygen",
        "sphinx", "quartz", "voyage", "galaxy", "jigsaw", "fjord", "kayak", "juice", "crayon",
        "dolphin", "hockey", "volcano", "whisper", "joyful", "banjo", "pumpkin", "octopus",
        "rhythm", "blizzard", "waltz", "xylophone", "squeak", "jungle", "marshmallow",
        "flamingo", "tornado", "mystery", "adventure", "chocolate", "treasure", "lizard", "wax",
    ]

    /// The 100 words people write most.
    static let common = [
        "the", "of", "and", "a", "to", "in", "is", "you", "that", "it", "he", "was", "for", "on",
        "are", "as", "with", "his", "they", "over", "at", "be", "this", "have", "from", "or", "one",
        "had", "by", "word", "but", "not", "what", "all", "were", "we", "when", "your", "can",
        "said", "there", "use", "an", "each", "which", "she", "do", "how", "their", "if", "will",
        "up", "other", "about", "out", "many", "then", "them", "these", "so", "some", "her",
        "would", "make", "like", "him", "into", "time", "has", "look", "two", "more", "write",
        "go", "see", "number", "no", "way", "could", "people", "my", "than", "first", "water",
        "been", "call", "who", "oil", "its", "now", "find", "long", "down", "day", "did", "get",
        "come", "made", "may", "part",
    ]

    /// Short sentences with capitals and punctuation.
    static let sentences = [
        "The quick brown fox jumps over the lazy dog.",
        "Practice a little every day and your fingers will learn the way.",
        "Keep your eyes on the screen, not on your hands.",
        "Rest your fingers on the home row before you start.",
        "Jupiter is the biggest planet in our solar system.",
        "A good typist is fast, but a great typist is careful too.",
        "My dog likes to chase the ball across the park.",
        "Six zebras jumped over a box of quiet, sleeping foxes!",
        "Can you type this whole sentence without one mistake?",
        "The moon goes around the Earth about once a month.",
        "Pizza, tacos and pancakes are all great for dinner.",
        "We packed our bags, grabbed snacks and drove to the beach.",
    ]
}
