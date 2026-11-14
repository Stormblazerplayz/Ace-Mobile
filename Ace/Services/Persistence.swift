import Foundation

/// Saves and loads JSON files in Ace's Application Support folder.
enum Persistence {
    static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("Ace", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static func url(_ name: String) -> URL {
        folder.appendingPathComponent(name)
    }

    static func subfolder(_ name: String) -> URL {
        let url = folder.appendingPathComponent(name, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        guard let data = try? Data(contentsOf: url(name)) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, to name: String) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url(name), options: [.atomic])
    }

    /// Saves a picture the user sent and returns its file name.
    static func saveImage(_ data: Data) -> String? {
        let name = UUID().uuidString + ".jpg"
        let dest = subfolder("Images").appendingPathComponent(name)
        do {
            try data.write(to: dest, options: [.atomic])
            return name
        } catch {
            return nil
        }
    }

    static func imageURL(_ name: String) -> URL {
        subfolder("Images").appendingPathComponent(name)
    }

    static func dayKey(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
