import Foundation

/// Splits Lua, C++, Python or Swift code into colored pieces: keywords, strings, comments, numbers and well-known names.
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

    static let pythonKeywords: Set<String> = [
        "False", "None", "True", "and", "as", "assert", "async", "await", "break", "class", "continue", "def", "del",
        "elif", "else", "except", "finally", "for", "from", "global", "if", "import", "in", "is", "lambda", "nonlocal",
        "not", "or", "pass", "raise", "return", "try", "while", "with", "yield",
    ]
    static let pythonBuiltins: Set<String> = [
        "print", "input", "len", "range", "int", "str", "float", "bool", "list", "dict", "set", "tuple", "open", "sorted",
        "sum", "min", "max", "abs", "round", "enumerate", "zip", "type", "isinstance", "random", "time", "math", "os",
        "json", "turtle", "self", "__name__", "__init__", "append", "split", "join", "format", "GPIO",
    ]
    static let swiftKeywords: Set<String> = [
        "actor", "as", "async", "await", "break", "case", "catch", "class", "continue", "default", "defer", "do", "else",
        "enum", "extension", "false", "fileprivate", "for", "func", "guard", "if", "import", "in", "init", "inout",
        "internal", "is", "lazy", "let", "mutating", "nil", "open", "private", "protocol", "public", "repeat", "return",
        "self", "Self", "some", "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try",
        "var", "weak", "where", "while", "any",
    ]
    static let swiftBuiltins: Set<String> = [
        "print", "String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set", "Character", "View", "Text",
        "Button", "VStack", "HStack", "ZStack", "Image", "List", "ForEach", "NavigationStack", "State", "Binding",
        "Color", "Spacer", "TextField", "Toggle", "Slider", "App", "Scene", "WindowGroup", "ContentView", "Date",
        "Timer", "withAnimation", "Identifiable", "Codable", "UUID", "Task", "Preview", "body",
    ]

    /// The colored pieces of the code. Joining every piece's text gives back the code exactly.
    static func pieces(_ code: String, language: String) -> [Piece] {
        let lua = language == "Lua"
        let python = language == "Python"
        let swift = language == "Swift"
        // C++ and Swift share // and /* */ comments.
        let cStyle = !lua && !python
        let keywords: Set<String>
        let builtins: Set<String>
        switch language {
        case "Lua": keywords = luaKeywords; builtins = luaBuiltins
        case "Python": keywords = pythonKeywords; builtins = pythonBuiltins
        case "Swift": keywords = swiftKeywords; builtins = swiftBuiltins
        default: keywords = cppKeywords; builtins = cppBuiltins
        }
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
            if python, c == "#" {
                let e = lineEnd(from: i); add(String(chars[i..<e]), .comment); i = e; continue
            }
            if cStyle, starts("//", at: i) {
                let e = lineEnd(from: i); add(String(chars[i..<e]), .comment); i = e; continue
            }
            if cStyle, starts("/*", at: i) {
                let e = upTo("*/", from: i + 2); add(String(chars[i..<e]), .comment); i = e; lineStart = false; continue
            }
            // #include and friends
            if cStyle, !swift, c == "#", lineStart {
                let e = lineEnd(from: i); add(String(chars[i..<e]), .preprocessor); i = e; continue
            }
            // Strings
            if lua, starts("[[", at: i) {
                let e = upTo("]]", from: i + 2); add(String(chars[i..<e]), .string); i = e; lineStart = false; continue
            }
            if python || swift, starts("\"\"\"", at: i) || (python && starts("'''", at: i)) {
                let quote = String(chars[i..<(i + 3)])
                let e = upTo(quote, from: i + 3); add(String(chars[i..<e]), .string); i = e; lineStart = false; continue
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
