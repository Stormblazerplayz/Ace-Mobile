import Foundation

/// Known websites and apps Ace can open by name ("open YouTube"),
/// plus search links for "search for cats on YouTube".
enum Sites {
    struct Site {
        var name: String
        var url: URL
        /// Search link with {q} where the words go.
        var search: String?
    }

    private static let table: [String: (String, String, String?)] = [
        "youtube": ("YouTube", "https://www.youtube.com", "https://www.youtube.com/results?search_query={q}"),
        "google": ("Google", "https://www.google.com", "https://www.google.com/search?q={q}"),
        "gmail": ("Gmail", "https://mail.google.com", nil),
        "google drive": ("Google Drive", "https://drive.google.com", nil),
        "drive": ("Google Drive", "https://drive.google.com", nil),
        "google docs": ("Google Docs", "https://docs.google.com", nil),
        "google maps": ("Google Maps", "https://maps.google.com", "https://www.google.com/maps/search/{q}"),
        "maps": ("Apple Maps", "https://maps.apple.com", "https://maps.apple.com/?q={q}"),
        "wikipedia": ("Wikipedia", "https://en.wikipedia.org", "https://en.wikipedia.org/w/index.php?search={q}"),
        "amazon": ("Amazon", "https://www.amazon.com", "https://www.amazon.com/s?k={q}"),
        "reddit": ("Reddit", "https://www.reddit.com", "https://www.reddit.com/search/?q={q}"),
        "github": ("GitHub", "https://github.com", "https://github.com/search?q={q}"),
        "bing": ("Bing", "https://www.bing.com", "https://www.bing.com/search?q={q}"),
        "duckduckgo": ("DuckDuckGo", "https://duckduckgo.com", "https://duckduckgo.com/?q={q}"),
        "spotify": ("Spotify", "https://open.spotify.com", "https://open.spotify.com/search/{q}"),
        "twitch": ("Twitch", "https://www.twitch.tv", "https://www.twitch.tv/search?term={q}"),
        "tiktok": ("TikTok", "https://www.tiktok.com", "https://www.tiktok.com/search?q={q}"),
        "pinterest": ("Pinterest", "https://www.pinterest.com", "https://www.pinterest.com/search/pins/?q={q}"),
        "ebay": ("eBay", "https://www.ebay.com", "https://www.ebay.com/sch/i.html?_nkw={q}"),
        "netflix": ("Netflix", "https://www.netflix.com", nil),
        "apple music": ("Apple Music", "https://music.apple.com", "https://music.apple.com/search?term={q}"),
        "roblox": ("Roblox", "https://www.roblox.com", "https://www.roblox.com/discover/?Keyword={q}"),
        "minecraft": ("Minecraft", "https://www.minecraft.net", nil),
        "minecraft wiki": ("Minecraft Wiki", "https://minecraft.wiki", "https://minecraft.wiki/?search={q}"),
        "thingiverse": ("Thingiverse", "https://www.thingiverse.com", "https://www.thingiverse.com/search?q={q}"),
        "printables": ("Printables", "https://www.printables.com", "https://www.printables.com/search/models?q={q}"),
        "makerworld": ("MakerWorld", "https://makerworld.com", "https://makerworld.com/en/search/models?keyword={q}"),
        "bambu": ("Bambu Lab", "https://bambulab.com", nil),
        "etsy": ("Etsy", "https://www.etsy.com", "https://www.etsy.com/search?q={q}"),
        "imdb": ("IMDb", "https://www.imdb.com", "https://www.imdb.com/find/?q={q}"),
        "walmart": ("Walmart", "https://www.walmart.com", "https://www.walmart.com/search?q={q}"),
        "target": ("Target", "https://www.target.com", "https://www.target.com/s?searchTerm={q}"),
        "chatgpt": ("ChatGPT", "https://chatgpt.com", nil),
        "claude": ("Claude", "https://claude.ai", nil),
        "hugging face": ("Hugging Face", "https://huggingface.co", "https://huggingface.co/search/full-text?q={q}"),
        "huggingface": ("Hugging Face", "https://huggingface.co", "https://huggingface.co/search/full-text?q={q}"),
        "khan academy": ("Khan Academy", "https://www.khanacademy.org", "https://www.khanacademy.org/search?page_search_query={q}"),
        "scratch": ("Scratch", "https://scratch.mit.edu", "https://scratch.mit.edu/search/projects?q={q}"),
        "nasa": ("NASA", "https://www.nasa.gov", nil),
        "weather": ("Weather.gov", "https://www.weather.gov", nil),
        "news": ("Apple News", "https://www.apple.com/apple-news/", nil),
        "apple": ("Apple", "https://www.apple.com", nil),
        "icloud": ("iCloud", "https://www.icloud.com", nil),
        "discord": ("Discord", "https://discord.com/app", nil),
        "x": ("X", "https://x.com", "https://x.com/search?q={q}"),
        "twitter": ("X", "https://x.com", "https://x.com/search?q={q}"),
        "instagram": ("Instagram", "https://www.instagram.com", nil),
        "figma": ("Figma", "https://www.figma.com", nil),
        "canva": ("Canva", "https://www.canva.com", nil),
        "settings": ("Settings", "app-settings:", nil),
        "ace settings": ("Settings", "app-settings:", nil),
    ]

    static func lookup(_ name: String) -> Site? {
        var key = name.lowercased().trimmingCharacters(in: .whitespaces)
        for suffix in [".com", " app", " website", " site"] where key.hasSuffix(suffix) {
            key = String(key.dropLast(suffix.count))
        }
        if let e = table[key], let url = URL(string: e.1) {
            return Site(name: e.0, url: url, search: e.2)
        }
        return nil
    }

    /// A link to open for "open X": a known site, a typed web address, or a web search for it.
    static func link(for target: String, engine: String) -> (title: String, url: URL)? {
        if let s = lookup(target) { return (s.name, s.url) }
        let t = target.lowercased().replacingOccurrences(of: " dot ", with: ".").replacingOccurrences(of: " ", with: "")
        if Regex.matches(#"^[a-z0-9\-]+(\.[a-z0-9\-]+)+(/.*)?$"#, t), let url = URL(string: "https://" + t) {
            return (t, url)
        }
        return searchLink(target, site: nil, engine: engine)
    }

    static func searchLink(_ query: String, site: String?, engine: String) -> (title: String, url: URL)? {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? query
        if let site, let s = lookup(site), let pattern = s.search,
           let url = URL(string: pattern.replacingOccurrences(of: "{q}", with: q)) {
            return ("\(s.name): \(query)", url)
        }
        let pattern: String
        switch engine {
        case "duckduckgo": pattern = "https://duckduckgo.com/?q={q}"
        case "bing": pattern = "https://www.bing.com/search?q={q}"
        default: pattern = "https://www.google.com/search?q={q}"
        }
        guard let url = URL(string: pattern.replacingOccurrences(of: "{q}", with: q)) else { return nil }
        return ("Search: \(query)", url)
    }
}

extension CharacterSet {
    /// Characters that are safe inside a query value (no & = + ?).
    static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=+?#")
        return set
    }()
}
