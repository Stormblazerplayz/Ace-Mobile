import Foundation

/// Free web lookups with no account or key: DuckDuckGo instant answers,
/// Wikipedia, TheMealDB recipes and Open-Meteo weather.
enum WebService {
    struct Research {
        var title: String
        var summary: String
        var bullets: [String]
        var imageURL: URL?
        var sources: [WebSource]
        /// 0...1, how sure Ace is that this answers the question.
        var confidence: Double
    }

    private static let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 12
        c.httpAdditionalHeaders = ["User-Agent": "AceForiPad/4.0 (personal assistant app)"]
        return URLSession(configuration: c)
    }()

    private static func json(_ url: URL) async -> Any? {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            return nil
        }
    }

    private static func url(_ base: String, _ items: [String: String]) -> URL? {
        var c = URLComponents(string: base)
        c?.queryItems = items.map { URLQueryItem(name: $0.key, value: $0.value) }
        return c?.url
    }

    // MARK: General research

    /// Looks something up and writes a short summary from the best sentences.
    static func research(_ query: String) async -> Research? {
        async let ddg = duckDuckGo(query)
        async let wiki = wikipedia(query)
        var (d, w) = await (ddg, wiki)
        // Throw out anything about a different place or topic than the question.
        // Saying "I'm not sure" is better than showing a page about something else.
        if let r = d, !fits(r, query: query) { d = nil }
        if let r = w, !fits(r, query: query) { w = nil }
        // An exact instant answer ("Answer" field) wins.
        if let d, d.confidence >= 0.9 { return d }
        switch (d, w) {
        case let (d?, w?):
            if w.confidence > d.confidence + 0.1 {
                var merged = w
                merged.sources += d.sources.filter { s in !w.sources.contains(where: { $0.url == s.url }) }
                return merged
            }
            var merged = d
            merged.sources += w.sources.filter { s in !d.sources.contains(where: { $0.url == s.url }) }
            if merged.bullets.isEmpty { merged.bullets = w.bullets }
            return merged
        case let (d?, nil): return d
        case let (nil, w?): return w
        default: return nil
        }
    }

    private static func duckDuckGo(_ query: String) async -> Research? {
        guard let u = url("https://api.duckduckgo.com/", ["q": query, "format": "json", "no_html": "1", "skip_disambig": "1", "no_redirect": "1"]),
              let obj = await json(u) as? [String: Any] else { return nil }
        let heading = obj["Heading"] as? String ?? ""
        let answer = (obj["Answer"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let abstract = (obj["AbstractText"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let definition = (obj["Definition"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var sources: [WebSource] = []
        if let s = obj["AbstractURL"] as? String, let su = URL(string: s), !s.isEmpty {
            sources.append(WebSource(title: obj["AbstractSource"] as? String ?? "Source", url: su))
        }
        var image: URL?
        if let img = obj["Image"] as? String, !img.isEmpty {
            image = img.hasPrefix("http") ? URL(string: img) : URL(string: "https://duckduckgo.com" + img)
        }
        var bullets: [String] = []
        if let related = obj["RelatedTopics"] as? [[String: Any]] {
            for r in related.prefix(4) {
                if let t = r["Text"] as? String, !t.isEmpty { bullets.append(t) }
            }
        }
        if !answer.isEmpty, !answer.contains("<") {
            return Research(title: heading.isEmpty ? query : heading, summary: answer, bullets: [], imageURL: image, sources: sources, confidence: 0.92)
        }
        let body = abstract.isEmpty ? definition : abstract
        guard !body.isEmpty else { return nil }
        let summary = Summarizer.summarize(body, query: query, maxSentences: 3)
        return Research(title: heading.isEmpty ? query : heading, summary: summary, bullets: Array(bullets.prefix(3)),
                        imageURL: image, sources: sources, confidence: 0.75)
    }

    private static func wikipedia(_ query: String) async -> Research? {
        let cleaned = Summarizer.topic(of: query)
        guard let su = url("https://en.wikipedia.org/w/api.php",
                           ["action": "query", "list": "search", "srsearch": cleaned, "format": "json", "srlimit": "3"]),
              let obj = await json(su) as? [String: Any],
              let q = obj["query"] as? [String: Any],
              let hits = q["search"] as? [[String: Any]]
        else { return nil }
        // The top hit isn't always about the question ("president uk" can find a German page),
        // so try the first three and keep the first one that fits.
        for hit in hits.prefix(3) {
            guard let title = hit["title"] as? String,
                  let r = await wikipediaPage(title, query: query, cleaned: cleaned) else { continue }
            if fits(r, query: query) { return r }
        }
        return nil
    }

    private static func wikipediaPage(_ title: String, query: String, cleaned: String) async -> Research? {
        guard let eu = url("https://en.wikipedia.org/w/api.php",
                           ["action": "query", "prop": "extracts|pageimages", "exintro": "1", "explaintext": "1",
                            "redirects": "1", "titles": title, "format": "json", "pithumbsize": "480"]),
              let eobj = await json(eu) as? [String: Any],
              let eq = eobj["query"] as? [String: Any],
              let pages = eq["pages"] as? [String: Any],
              let page = pages.values.first as? [String: Any],
              let extract = page["extract"] as? String, !extract.isEmpty
        else { return nil }
        var image: URL?
        if let thumb = page["thumbnail"] as? [String: Any], let src = thumb["source"] as? String {
            image = URL(string: src)
        }
        let summary = Summarizer.summarize(extract, query: query, maxSentences: 3)
        let bullets = Summarizer.keyFacts(extract, excluding: summary, count: 3)
        let pageTitle = page["title"] as? String ?? title
        let link = URL(string: "https://en.wikipedia.org/wiki/" + (pageTitle.replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""))
        let overlap = Summarizer.overlap(query: cleaned, text: pageTitle + " " + summary)
        return Research(title: pageTitle, summary: summary, bullets: bullets, imageURL: image,
                        sources: link.map { [WebSource(title: "Wikipedia: \(pageTitle)", url: $0)] } ?? [],
                        confidence: min(0.85, 0.45 + overlap * 0.5))
    }

    // MARK: Does a result fit the question?

    static func fits(_ r: Research, query: String) -> Bool {
        fits(title: r.title, text: r.summary + " " + r.bullets.joined(separator: " "), query: query)
    }

    /// True when a web result is about what was asked: it names the place in the question (if there is one)
    /// and has enough of the question's main words. "capital of the UK" doesn't fit a page about Sanrio,
    /// and "president of the UK" doesn't fit a page about Germany.
    static func fits(title: String, text: String, query: String) -> Bool {
        let hay = title + " " + text
        let asked = Leaders.countries(in: query)
        if !asked.isEmpty, !asked.contains(where: { Leaders.mentions($0, in: hay) }) { return false }
        let main = mainWords(query)
        guard !main.isEmpty else { return true }
        let have = Set(TextKit.keywords(hay))
        let hits = main.filter { m in
            have.contains(m) || have.contains { $0.count >= 4 && m.count >= 4 && ($0.hasPrefix(m) || m.hasPrefix($0)) }
        }.count
        let need = main.count <= 2 ? 1 : main.count / 2
        return hits >= need
    }

    /// The words a question is really about, without greetings, filler or place names.
    static func mainWords(_ query: String) -> [String] {
        let placeWords = Set(Leaders.countries(in: query).flatMap { c in (c.names + c.people).flatMap { TextKit.keywords($0) } })
        let skip: Set<String> = [
            "hello", "hi", "hiya", "yo", "ace", "current", "currently", "now", "today", "latest", "right", "please",
            "thank", "thanks", "tell", "explain", "mean", "meaning", "fact", "facts", "info", "information", "search",
            "look", "lookup", "google", "web", "internet", "online",
        ]
        var out: [String] = []
        for w in TextKit.keywords(query) where !skip.contains(w) && !placeWords.contains(w) && !TextKit.commonWords.contains(w) && !out.contains(w) {
            out.append(w)
        }
        return out
    }

    // MARK: Leaders

    /// Who has a country's top jobs right now, from Wikidata
    /// (head of state is P35, head of government is P6). nil when it can't be reached.
    static func leaders(_ wikidataID: String) async -> (state: String?, government: String?)? {
        guard let u = url("https://www.wikidata.org/w/api.php",
                          ["action": "wbgetentities", "ids": wikidataID, "props": "claims", "format": "json"]),
              let obj = await json(u) as? [String: Any],
              let entities = obj["entities"] as? [String: Any],
              let entity = entities[wikidataID] as? [String: Any],
              let claims = entity["claims"] as? [String: Any]
        else { return nil }
        let stateID = currentHolder(claims["P35"] as? [[String: Any]] ?? [])
        let governmentID = currentHolder(claims["P6"] as? [[String: Any]] ?? [])
        var ids: [String] = []
        for id in [stateID, governmentID].compactMap({ $0 }) where !ids.contains(id) { ids.append(id) }
        guard !ids.isEmpty,
              let lu = url("https://www.wikidata.org/w/api.php",
                           ["action": "wbgetentities", "ids": ids.joined(separator: "|"), "props": "labels",
                            "languages": "en", "format": "json"]),
              let lobj = await json(lu) as? [String: Any],
              let labels = lobj["entities"] as? [String: Any]
        else { return nil }
        func name(_ id: String?) -> String? {
            guard let id, let e = labels[id] as? [String: Any], let all = e["labels"] as? [String: Any],
                  let en = all["en"] as? [String: Any], let value = en["value"] as? String, !value.isEmpty else { return nil }
            return value
        }
        let found = (state: name(stateID), government: name(governmentID))
        return found.state == nil && found.government == nil ? nil : found
    }

    /// Picks who has the job now from Wikidata statements: no end date, "preferred" first, then the newest start.
    static func currentHolder(_ statements: [[String: Any]]) -> String? {
        var best: (id: String, preferred: Bool, start: String)?
        for s in statements {
            let rank = s["rank"] as? String ?? "normal"
            guard rank != "deprecated" else { continue }
            let qualifiers = s["qualifiers"] as? [String: Any] ?? [:]
            // An end date (P582) means that person doesn't have the job any more.
            if qualifiers["P582"] != nil { continue }
            guard let snak = s["mainsnak"] as? [String: Any],
                  let dv = snak["datavalue"] as? [String: Any],
                  let value = dv["value"] as? [String: Any],
                  let id = value["id"] as? String else { continue }
            var start = ""
            if let starts = qualifiers["P580"] as? [[String: Any]],
               let sdv = starts.first?["datavalue"] as? [String: Any],
               let sv = sdv["value"] as? [String: Any],
               let time = sv["time"] as? String {
                start = time
            }
            let preferred = rank == "preferred"
            if let b = best {
                if (preferred && !b.preferred) || (preferred == b.preferred && start > b.start) {
                    best = (id, preferred, start)
                }
            } else {
                best = (id, preferred, start)
            }
        }
        return best?.id
    }

    // MARK: Recipes

    static func recipe(_ dish: String) async -> RecipeCard? {
        let tries = [dish, Summarizer.topic(of: dish), dish.split(separator: " ").last.map(String.init) ?? dish]
        for term in tries where !term.isEmpty {
            if let u = url("https://www.themealdb.com/api/json/v1/1/search.php", ["s": term]),
               let obj = await json(u) as? [String: Any],
               let meals = obj["meals"] as? [[String: Any]], let meal = meals.first {
                return parseMeal(meal)
            }
        }
        // Try it as a main ingredient ("something with chicken").
        let ingredient = dish.split(separator: " ").last.map(String.init) ?? dish
        if let u = url("https://www.themealdb.com/api/json/v1/1/filter.php", ["i": ingredient]),
           let obj = await json(u) as? [String: Any],
           let meals = obj["meals"] as? [[String: Any]], let first = meals.randomElement(),
           let id = first["idMeal"] as? String,
           let lu = url("https://www.themealdb.com/api/json/v1/1/lookup.php", ["i": id]),
           let lobj = await json(lu) as? [String: Any],
           let lmeals = lobj["meals"] as? [[String: Any]], let meal = lmeals.first {
            return parseMeal(meal)
        }
        return nil
    }

    private static func parseMeal(_ m: [String: Any]) -> RecipeCard {
        func s(_ k: String) -> String? {
            guard let v = m[k] as? String else { return nil }
            let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        var ingredients: [String] = []
        for i in 1...20 {
            guard let ing = s("strIngredient\(i)") else { continue }
            if let measure = s("strMeasure\(i)") {
                ingredients.append("\(measure) \(ing)")
            } else {
                ingredients.append(ing)
            }
        }
        let instructions = s("strInstructions") ?? ""
        return RecipeCard(
            name: s("strMeal") ?? "Recipe",
            category: s("strCategory"),
            area: s("strArea"),
            imageURL: s("strMealThumb").flatMap { URL(string: $0) },
            ingredients: ingredients,
            steps: splitSteps(instructions),
            sourceURL: s("strSource").flatMap { URL(string: $0) } ?? s("strYoutube").flatMap { URL(string: $0) }
        )
    }

    static func splitSteps(_ text: String) -> [String] {
        var lines = text
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        // Drop "STEP 1" style labels and lone numbers.
        lines = lines.filter { line in
            let l = line.lowercased()
            if l.hasPrefix("step") && l.count <= 8 { return false }
            if Int(l.trimmingCharacters(in: CharacterSet(charactersIn: ".)"))) != nil { return false }
            return true
        }
        if lines.count <= 1 {
            lines = Summarizer.sentences(text)
        }
        return lines.map { line in
            var l = line
            if let r = l.range(of: #"^(step\s*)?\d+[\.\):\-]\s*"#, options: [.regularExpression, .caseInsensitive]) {
                l.removeSubrange(r)
            }
            return l
        }.filter { !$0.isEmpty }
    }

    // MARK: Weather

    static func weather(place: String, fahrenheit: Bool) async -> WeatherCard? {
        guard let gu = url("https://geocoding-api.open-meteo.com/v1/search", ["name": place, "count": "1", "language": "en", "format": "json"]),
              let gobj = await json(gu) as? [String: Any],
              let results = gobj["results"] as? [[String: Any]], let r = results.first,
              let lat = r["latitude"] as? Double, let lon = r["longitude"] as? Double
        else { return nil }
        var placeName = r["name"] as? String ?? place
        if let admin = r["admin1"] as? String, admin != placeName { placeName += ", \(admin)" }
        else if let country = r["country"] as? String { placeName += ", \(country)" }
        var items: [String: String] = [
            "latitude": String(lat), "longitude": String(lon),
            "current": "temperature_2m,apparent_temperature,weather_code,wind_speed_10m",
            "daily": "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max",
            "timezone": "auto", "forecast_days": "7",
        ]
        if fahrenheit {
            items["temperature_unit"] = "fahrenheit"
            items["wind_speed_unit"] = "mph"
        }
        guard let fu = url("https://api.open-meteo.com/v1/forecast", items),
              let fobj = await json(fu) as? [String: Any],
              let cur = fobj["current"] as? [String: Any],
              let temp = (cur["temperature_2m"] as? NSNumber)?.doubleValue
        else { return nil }
        var days: [WeatherCard.Day] = []
        if let daily = fobj["daily"] as? [String: Any],
           let times = daily["time"] as? [String],
           let highs = daily["temperature_2m_max"] as? [Any],
           let lows = daily["temperature_2m_min"] as? [Any],
           let codes = daily["weather_code"] as? [Any] {
            let rain = daily["precipitation_probability_max"] as? [Any] ?? []
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            for i in 0..<min(times.count, highs.count, lows.count, codes.count) {
                guard let date = f.date(from: times[i]),
                      let hi = (highs[i] as? NSNumber)?.doubleValue,
                      let lo = (lows[i] as? NSNumber)?.doubleValue,
                      let code = (codes[i] as? NSNumber)?.intValue else { continue }
                let chance = i < rain.count ? (rain[i] as? NSNumber)?.intValue : nil
                days.append(.init(date: date, high: hi, low: lo, code: code, rainChance: chance))
            }
        }
        return WeatherCard(
            place: placeName,
            temperature: temp,
            feelsLike: (cur["apparent_temperature"] as? NSNumber)?.doubleValue,
            code: (cur["weather_code"] as? NSNumber)?.intValue ?? 0,
            wind: (cur["wind_speed_10m"] as? NSNumber)?.doubleValue,
            unit: fahrenheit ? "°F" : "°C",
            days: days
        )
    }

    /// Words and an SF Symbol for an Open-Meteo weather code.
    static func describe(code: Int) -> (text: String, symbol: String) {
        switch code {
        case 0: return ("clear", "sun.max.fill")
        case 1: return ("mostly clear", "sun.min.fill")
        case 2: return ("partly cloudy", "cloud.sun.fill")
        case 3: return ("cloudy", "cloud.fill")
        case 45, 48: return ("foggy", "cloud.fog.fill")
        case 51, 53, 55, 56, 57: return ("drizzly", "cloud.drizzle.fill")
        case 61, 63, 65, 66, 67: return ("rainy", "cloud.rain.fill")
        case 71, 73, 75, 77: return ("snowy", "cloud.snow.fill")
        case 80, 81, 82: return ("showery", "cloud.heavyrain.fill")
        case 85, 86: return ("snow showers", "cloud.snow.fill")
        case 95, 96, 99: return ("stormy", "cloud.bolt.rain.fill")
        default: return ("mixed", "cloud.sun.fill")
        }
    }
}
