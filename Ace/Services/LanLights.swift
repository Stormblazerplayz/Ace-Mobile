import Foundation
import Network

/// Govee and Twinkly lights on your Wi-Fi, controlled directly (no account or cloud).
/// Govee: turn on "LAN Control" for each light in the Govee Home app. Twinkly works as it is.
/// Finding them asks for Local Network access the first time.
@MainActor
final class LanLights: ObservableObject {
    static let shared = LanLights()

    struct Light: Identifiable, Codable, Equatable {
        enum Brand: String, Codable { case govee, twinkly }
        var id: String
        var brand: Brand
        var name: String
        var ip: String
        var model: String
        var isOn: Bool?

        var label: String {
            if !name.isEmpty { return name }
            return brand == .govee ? "Govee \(model)" : "Twinkly lights"
        }
    }

    struct RGB: Equatable { var r: Int, g: Int, b: Int }

    @Published private(set) var lights: [Light] = []
    @Published private(set) var scanning = false
    /// Off until you turn it on in Settings, because finding lights asks for Local Network access.
    @Published var enabled: Bool = UserDefaults.standard.bool(forKey: "lanLights.enabled") {
        didSet { UserDefaults.standard.set(enabled, forKey: "lanLights.enabled") }
    }

    private let storeKey = "lanLights.saved"
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "ace.lanlights")
    private let inbox = Inbox()
    private var twinklyTokens: [String: (token: String, expires: Date)] = [:]

    private init() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let saved = try? JSONDecoder().decode([Light].self, from: data) {
            lights = saved
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(lights) { UserDefaults.standard.set(data, forKey: storeKey) }
        // So "turn on the bedroom strip" works for names you gave them.
        let names = Set(lights.map { $0.label.lowercased() })
        UserDefaults.standard.set(names.filter { $0.count >= 3 }.sorted(), forKey: "lanKnownNames")
    }

    /// Renames a light (Govee and Twinkly don't tell Ace the names you gave them).
    func rename(_ id: String, to name: String) {
        guard let i = lights.firstIndex(where: { $0.id == id }) else { return }
        lights[i].name = name.trimmingCharacters(in: .whitespaces)
        save()
    }

    func forget(_ id: String) {
        lights.removeAll { $0.id == id }
        save()
    }

    // MARK: Finding lights

    /// Looks for Govee and Twinkly lights on this Wi-Fi network. Takes a few seconds.
    @discardableResult
    func scan() async -> Int {
        guard !scanning else { return lights.count }
        scanning = true
        defer { scanning = false }
        guard let hosts = Self.hostsOnWiFi(), !hosts.isEmpty else { return lights.count }

        // Govee: ask every address, lights answer on port 4002.
        startListener()
        inbox.clear()
        let scan = Self.goveeMessage("scan", ["account_topic": "reserve"])
        for h in hosts { sendUDP(scan, to: h, port: 4001) }

        // Twinkly: every light answers a plain web request.
        async let twinkly = Self.findTwinkly(hosts)
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        let found = await twinkly

        var all = lights
        for reply in inbox.take() {
            guard let msg = reply["msg"] as? [String: Any], (msg["cmd"] as? String) == "scan",
                  let data = msg["data"] as? [String: Any], let ip = data["ip"] as? String else { continue }
            let id = (data["device"] as? String) ?? ip
            let sku = (data["sku"] as? String) ?? "light"
            if let i = all.firstIndex(where: { $0.id == id }) { all[i].ip = ip } else {
                all.append(Light(id: id, brand: .govee, name: "", ip: ip, model: sku, isOn: nil))
            }
        }
        for t in found {
            if let i = all.firstIndex(where: { $0.id == t.id }) { all[i].ip = t.ip } else { all.append(t) }
        }
        lights = all
        save()
        await refresh()
        return lights.count
    }

    /// Reads whether each light is on.
    func refresh() async {
        startListener()
        inbox.clear()
        for l in lights where l.brand == .govee { sendUDP(Self.goveeMessage("devStatus", [:]), to: l.ip, port: 4003) }
        for (i, l) in lights.enumerated() where l.brand == .twinkly {
            if let mode = await twinklyMode(l.ip), i < lights.count, lights[i].id == l.id { lights[i].isOn = mode != "off" }
        }
        try? await Task.sleep(nanoseconds: 800_000_000)
        for reply in inbox.take() {
            guard let msg = reply["msg"] as? [String: Any], (msg["cmd"] as? String) == "devStatus",
                  let data = msg["data"] as? [String: Any], let ip = reply["_from"] as? String,
                  let i = lights.firstIndex(where: { $0.ip == ip }) else { continue }
            if let on = (data["onOff"] as? NSNumber)?.intValue { lights[i].isOn = on != 0 }
        }
    }

    // MARK: Control

    func setPower(_ light: Light, _ on: Bool) async -> Bool {
        let ok: Bool
        switch light.brand {
        case .govee:
            sendUDP(Self.goveeMessage("turn", ["value": on ? 1 : 0]), to: light.ip, port: 4003)
            ok = true
        case .twinkly:
            ok = await twinklyPost(light.ip, "/xled/v1/led/mode", ["mode": on ? "movie" : "off"])
        }
        if ok, let i = lights.firstIndex(where: { $0.id == light.id }) { lights[i].isOn = on }
        return ok
    }

    func setBrightness(_ light: Light, _ level: Int) async -> Bool {
        let v = min(100, max(1, level))
        switch light.brand {
        case .govee:
            sendUDP(Self.goveeMessage("turn", ["value": 1]), to: light.ip, port: 4003)
            sendUDP(Self.goveeMessage("brightness", ["value": v]), to: light.ip, port: 4003)
            return true
        case .twinkly:
            return await twinklyPost(light.ip, "/xled/v1/led/out/brightness", ["mode": "enabled", "type": "A", "value": v])
        }
    }

    func setColor(_ light: Light, _ color: RGB, kelvin: Int? = nil) async -> Bool {
        switch light.brand {
        case .govee:
            sendUDP(Self.goveeMessage("turn", ["value": 1]), to: light.ip, port: 4003)
            var data: [String: Any] = ["color": ["r": color.r, "g": color.g, "b": color.b], "colorTemInKelvin": 0]
            if let kelvin { data = ["color": ["r": 0, "g": 0, "b": 0], "colorTemInKelvin": kelvin] }
            sendUDP(Self.goveeMessage("colorwc", data), to: light.ip, port: 4003)
            return true
        case .twinkly:
            guard await twinklyPost(light.ip, "/xled/v1/led/color", ["red": color.r, "green": color.g, "blue": color.b]) else { return false }
            return await twinklyPost(light.ip, "/xled/v1/led/mode", ["mode": "color"])
        }
    }

    /// Twinkly's built-in effects (for scenes like movie mode or party mode).
    func playEffects(_ light: Light) async -> Bool {
        guard light.brand == .twinkly else { return false }
        return await twinklyPost(light.ip, "/xled/v1/led/mode", ["mode": "movie"])
    }

    /// True when the words name Govee or Twinkly ("govee lights", "the twinkly").
    nonisolated static func namesBrand(_ target: String) -> Bool {
        Rx.matches(#"\b(govee|twinkly)\b"#, TextKit.normalize(target))
    }

    /// True when the words name a light by the name you gave it here.
    func namesOwn(_ target: String) -> Bool {
        let t = TextKit.normalize(target)
        return lights.contains { !$0.name.isEmpty && t.contains($0.name.lowercased()) }
    }

    /// The lights the words point to ("govee lights", "twinkly", "bedroom strip", "lights").
    func match(_ target: String) -> [Light] {
        let t = TextKit.normalize(target)
        if t.isEmpty { return [] }
        if t.contains("govee") { return lights.filter { $0.brand == .govee } }
        if t.contains("twinkly") || t.contains("christmas") || t.contains("fairy") { return lights.filter { $0.brand == .twinkly } }
        if let named = lights.first(where: { !$0.name.isEmpty && t.contains($0.name.lowercased()) }) { return [named] }
        // "the lights" / "all the lights" / "led strip" mean every light.
        let generic = Rx.matches(#"^(all |every |all the |the |my )?(lights?|lamps?|leds?|led strips?|light strips?|strip lights?|strips?)$"#, t)
        return generic ? lights : []
    }

    // MARK: Colors

    /// Color words Ace knows. Kelvin is for whites.
    nonisolated static func color(named name: String) -> (rgb: RGB, kelvin: Int?)? {
        switch name.lowercased() {
        case "red": return (RGB(r: 255, g: 0, b: 0), nil)
        case "orange": return (RGB(r: 255, g: 110, b: 0), nil)
        case "yellow": return (RGB(r: 255, g: 210, b: 0), nil)
        case "gold", "amber": return (RGB(r: 255, g: 170, b: 30), nil)
        case "green": return (RGB(r: 0, g: 220, b: 60), nil)
        case "lime": return (RGB(r: 140, g: 255, b: 0), nil)
        case "cyan", "teal": return (RGB(r: 0, g: 210, b: 210), nil)
        case "blue": return (RGB(r: 0, g: 70, b: 255), nil)
        case "purple", "violet": return (RGB(r: 140, g: 40, b: 255), nil)
        case "pink": return (RGB(r: 255, g: 70, b: 170), nil)
        case "magenta": return (RGB(r: 255, g: 0, b: 200), nil)
        case "white", "cool white": return (RGB(r: 255, g: 255, b: 255), 6000)
        case "warm white", "warm": return (RGB(r: 255, g: 180, b: 110), 2700)
        default: return nil
        }
    }

    // MARK: Govee (UDP)

    private static func goveeMessage(_ cmd: String, _ data: [String: Any]) -> Data {
        (try? JSONSerialization.data(withJSONObject: ["msg": ["cmd": cmd, "data": data]])) ?? Data()
    }

    private func sendUDP(_ data: Data, to host: String, port: UInt16) {
        Self.sendUDP(data, to: host, port: port, queue: queue)
    }

    nonisolated private static func sendUDP(_ data: Data, to host: String, port: UInt16, queue: DispatchQueue) {
        guard let p = NWEndpoint.Port(rawValue: port) else { return }
        let c = NWConnection(host: NWEndpoint.Host(host), port: p, using: .udp)
        c.stateUpdateHandler = { state in
            if case .failed = state { c.cancel() }
        }
        c.start(queue: queue)
        c.send(content: data, completion: .contentProcessed { _ in c.cancel() })
    }

    /// Listens on port 4002, where Govee lights answer.
    private func startListener() {
        guard listener == nil, let l = Self.makeListener(inbox: inbox, queue: queue) else { return }
        listener = l
    }

    fileprivate func listenerFailed() { listener = nil }

    nonisolated private static func makeListener(inbox: Inbox, queue: DispatchQueue) -> NWListener? {
        guard let port = NWEndpoint.Port(rawValue: 4002), let l = try? NWListener(using: .udp, on: port) else { return nil }
        l.newConnectionHandler = { conn in
            var from = ""
            if case .hostPort(let host, _) = conn.endpoint {
                from = "\(host)".components(separatedBy: "%").first ?? ""
            }
            conn.start(queue: queue)
            Self.receive(conn, from: from, into: inbox)
        }
        l.stateUpdateHandler = { state in
            if case .failed = state {
                l.cancel()
                Task { @MainActor in LanLights.shared.listenerFailed() }
            }
        }
        l.start(queue: queue)
        return l
    }

    nonisolated private static func receive(_ conn: NWConnection, from: String, into inbox: Inbox) {
        conn.receiveMessage { data, _, _, error in
            if let data, var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                json["_from"] = from
                inbox.add(json)
            }
            if error == nil { receive(conn, from: from, into: inbox) } else { conn.cancel() }
        }
    }

    // MARK: Twinkly (HTTP)

    nonisolated private static func findTwinkly(_ hosts: [String]) async -> [Light] {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 1.5
        config.timeoutIntervalForResource = 2
        let session = URLSession(configuration: config)
        return await withTaskGroup(of: Light?.self) { group in
            for h in hosts {
                group.addTask {
                    guard let url = URL(string: "http://\(h)/xled/v1/gestalt"),
                          let (data, _) = try? await session.data(from: url),
                          let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                          let product = json["product_name"] as? String, product.lowercased().contains("twinkly") else { return nil }
                    let id = (json["mac"] as? String) ?? h
                    let name = (json["device_name"] as? String) ?? ""
                    let model = (json["product_code"] as? String) ?? "Twinkly"
                    return Light(id: id, brand: .twinkly, name: name.hasPrefix("Twinkly_") ? "" : name, ip: h, model: model, isOn: nil)
                }
            }
            var out: [Light] = []
            for await l in group { if let l { out.append(l) } }
            return out
        }
    }

    private func twinklyToken(_ ip: String) async -> String? {
        if let t = twinklyTokens[ip], t.expires > Date() { return t.token }
        var bytes = [UInt8](repeating: 0, count: 32)
        for i in bytes.indices { bytes[i] = UInt8.random(in: 0...255) }
        let challenge = Data(bytes).base64EncodedString()
        guard let login = await Self.request(ip, "/xled/v1/login", body: ["challenge": challenge], token: nil),
              let token = login["authentication_token"] as? String else { return nil }
        let response = (login["challenge-response"] as? String) ?? ""
        guard let verify = await Self.request(ip, "/xled/v1/verify", body: ["challenge-response": response], token: token),
              (verify["code"] as? NSNumber)?.intValue == 1000 else { return nil }
        let life = (login["authentication_token_expires_in"] as? NSNumber)?.doubleValue ?? 14_400
        twinklyTokens[ip] = (token, Date().addingTimeInterval(life - 60))
        return token
    }

    private func twinklyPost(_ ip: String, _ path: String, _ body: [String: Any]) async -> Bool {
        for attempt in 0..<2 {
            guard let token = await twinklyToken(ip) else { return false }
            let r = await Self.request(ip, path, body: body, token: token)
            let code = (r?["code"] as? NSNumber)?.intValue
            if code == 1000 { return true }
            twinklyTokens[ip] = nil
            if attempt == 1 { return false }
        }
        return false
    }

    private func twinklyMode(_ ip: String) async -> String? {
        guard let token = await twinklyToken(ip) else { return nil }
        return await Self.request(ip, "/xled/v1/led/mode", body: nil, token: token)?["mode"] as? String
    }

    nonisolated private static func request(_ ip: String, _ path: String, body: [String: Any]?, token: String?) async -> [String: Any]? {
        guard let url = URL(string: "http://\(ip)\(path)") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 4)
        if let body {
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        if let token { req.setValue(token, forHTTPHeaderField: "X-Auth-Token") }
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    // MARK: The Wi-Fi network

    /// Every other address on this iPad's Wi-Fi network (up to 254).
    nonisolated static func hostsOnWiFi() -> [String]? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let ifa = ptr.pointee
            guard let addr = ifa.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET), let maskPtr = ifa.ifa_netmask,
                  String(cString: ifa.ifa_name) == "en0" else { continue }
            let ip = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { UInt32(bigEndian: $0.pointee.sin_addr.s_addr) }
            var mask = maskPtr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { UInt32(bigEndian: $0.pointee.sin_addr.s_addr) }
            if mask < 0xFFFF_FF00 { mask = 0xFFFF_FF00 }   // only look at the nearest 254 addresses
            let net = ip & mask
            let count = ~mask
            guard count >= 2 else { return [] }
            var out: [String] = []
            for n in 1..<count where net | n != ip {
                let a = net | n
                out.append("\(a >> 24 & 255).\(a >> 16 & 255).\(a >> 8 & 255).\(a & 255)")
            }
            return out
        }
        return nil
    }
}

/// Govee answers, collected from the network queue.
final class Inbox: @unchecked Sendable {
    private var items: [[String: Any]] = []
    private let lock = NSLock()

    func add(_ item: [String: Any]) { lock.lock(); items.append(item); lock.unlock() }
    func clear() { lock.lock(); items.removeAll(); lock.unlock() }
    func take() -> [[String: Any]] { lock.lock(); defer { lock.unlock() }; let out = items; items.removeAll(); return out }
}
