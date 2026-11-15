import Foundation

/// Splits Lua or C++ code into colored pieces: keywords, strings, comments, numbers and well-known names.
/// No UI here, so the tests can check it.
enum CodeHighlighter {
    enum Kind: Equatable {
        case plain, keyword, string, comment, number, builtin, preprocessor
    }

    struct Piece: Equatable {
        var text: String
        var kind: Kind
    }

    static let luaKeywords: Set<String> = [
        "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not",
        "or", "repeat", "return", "then", "true", "until", "while", "continue", "export", "type",
    ]
    static let luaBuiltins: Set<String> = [
        "game", "workspace", "script", "task", "math", "string", "table", "print", "warn", "error", "pcall", "ipairs",
        "pairs", "tostring", "tonumber", "typeof", "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim2", "UDim",
        "Enum", "TweenInfo", "BrickColor", "Ray", "RaycastParams", "NumberSequence", "ColorSequence", "require", "os",
    ]
    static let cppKeywords: Set<String> = [
        "auto", "bool", "break", "case", "catch", "char", "class", "const", "constexpr", "continue", "default", "delete",
        "do", "double", "else", "enum", "explicit", "false", "float", "for", "if", "inline", "int", "long", "namespace",
        "new", "nullptr", "override", "private", "protected", "public", "return", "short", "signed", "size_t", "static",
        "struct", "switch", "template", "this", "throw", "true", "try", "typename", "unsigned", "using", "virtual",
        "void", "volatile", "while", "byte", "uint8_t", "uint16_t", "uint32_t", "int32_t", "boolean", "virtual",
    ]
    static let cppBuiltins: Set<String> = [
        "std", "cout", "cin", "endl", "string", "vector", "map", "setup", "loop", "pinMode", "digitalWrite",
        "digitalRead", "analogWrite", "analogRead", "delay", "millis", "Serial", "HIGH", "LOW", "INPUT", "OUTPUT",
        "INPUT_PULLUP", "tone", "noTone", "UCLASS", "UPROPERTY", "UFUNCTION", "GENERATED_BODY", "Super", "FVector",
        "FRotator", "AActor", "ACharacter", "UStaticMeshComponent", "UBoxComponent", "TEXT", "UE_LOG", "main",
    ]

    /// The colored pieces of the code. Joining every piece's text gives back the code exactly.
    static func pieces(_ code: String, language: String) -> [Piece] {
        let lua = language == "Lua"
        let keywords = lua ? luaKeywords : cppKeywords
        let builtins = lua ? luaBuiltins : cppBuiltins
        let chars = Array(code)
        var out: [Piece] = []
        var plain = ""
        var i = 0
        var lineStart = true

        func flush() {
            if !plain.isEmpty { out.append(Piece(text: plain, kind: .plain)); plain = "" }
        }
        func add(_ s: String, _ kind: Kind) {
            flush()
            if let last = out.last, last.kind == kind { out[out.count - 1].text += s } else { out.append(Piece(text: s, kind: kind)) }
        }
        func starts(_ s: String, at j: Int) -> Bool {
            let p = Array(s)
            guard j + p.count <= chars.count else { return false }
            return Array(chars[j..<(j + p.count)]) == p
        }
        func upTo(_ end: String, from j: Int) -> Int {
            // Index just past `end`, or the end of the code.
            var k = j
            while k < chars.count {
                if starts(end, at: k) { return k + end.count }
                k += 1
            }
            return chars.count
        }
        func lineEnd(from j: Int) -> Int {
            var k = j
            while k < chars.count, chars[k] != "\n" { k += 1 }
            return k
        }

        while i < chars.count {
            let c = chars[i]
            // Comments
            if lua, starts("--[[", at: i) {
                let e = upTo("]]", from: i + 4); add(String(chars[i..<e]), .comment); i = e; lineStart = false; continue
            }
            if lua, starts("--", at: i) {
                let e = lineEnd(from: i); add(String(chars[i..<e]), .comment); i = e; continue
            }
            if !lua, starts("//", at: i) {
                let e = lineEnd(from: i); add(String(chars[i..<e]), .comment); i = e; continue
            }
            if !lua, starts("/*", at: i) {
                let e = upTo("*/", from: i + 2); add(String(chars[i..<e]), .comment); i = e; lineStart = false; continue
            }
            // #include and friends
            if !lua, c == "#", lineStart {
                let e = lineEnd(from: i); add(String(chars[i..<e]), .preprocessor); i = e; continue
            }
            // Strings
            if lua, starts("[[", at: i) {
                let e = upTo("]]", from: i + 2); add(String(chars[i..<e]), .string); i = e; lineStart = false; continue
            }
            if c == "\"" || c == "'" || (lua && c == "`") {
                var k = i + 1
                while k < chars.count, chars[k] != c, chars[k] != "\n" {
                    k += chars[k] == "\\" ? 2 : 1
                }
                let e = min(k + 1, chars.count)
                add(String(chars[i..<e]), .string); i = e; lineStart = false; continue
            }
            // Numbers
            if c.isNumber, !(plain.last.map { $0.isLetter || $0 == "_" } ?? false) {
                var k = i
                while k < chars.count, chars[k].isNumber || chars[k] == "." || chars[k] == "x" || chars[k].isHexDigit || chars[k] == "_" {
                    if chars[k] == ".", k + 1 < chars.count, chars[k + 1] == "." { break }   // Lua's ".."
                    k += 1
                }
                add(String(chars[i..<k]), .number); i = k; lineStart = false; continue
            }
            // Words
            if c.isLetter || c == "_" {
                var k = i
                while k < chars.count, chars[k].isLetter || chars[k].isNumber || chars[k] == "_" { k += 1 }
                let word = String(chars[i..<k])
                if keywords.contains(word) { add(word, .keyword) }
                else if builtins.contains(word) { add(word, .builtin) }
                else { plain += word }
                i = k; lineStart = false; continue
            }
            plain.append(c)
            if c == "\n" { lineStart = true } else if c != " " && c != "\t" { lineStart = false }
            i += 1
        }
        flush()
        return out
    }
}
