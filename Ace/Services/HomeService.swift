import Foundation
import HomeKit

/// Ace's link to Apple Home (HomeKit): lights, plugs, switches, fans, thermostats, the robot vacuum and scenes.
/// Anything you've added to the Home app works here. Locks, garage doors and alarms are left to the Home app.
@MainActor
final class HomeService: NSObject, ObservableObject {
    static let shared = HomeService()

    struct Device: Identifiable, Equatable {
        enum Kind: String { case light, plug, fan, thermostat, vacuum, other }
        let id: UUID
        let name: String
        let room: String
        let kind: Kind
        var isOn: Bool?
        var level: Int?

        var icon: String {
            switch kind {
            case .light: return "lightbulb.fill"
            case .plug: return "poweroutlet.type.b.fill"
            case .fan: return "fan.fill"
            case .thermostat: return "thermometer.medium"
            case .vacuum: return "sparkles"
            case .other: return "switch.2"
            }
        }
    }

    enum Access: Equatable { case notConnected, waiting, allowed, denied, noHome }

    @Published private(set) var access: Access = .notConnected
    @Published private(set) var homeName = ""
    @Published private(set) var devices: [Device] = []
    @Published private(set) var scenes: [String] = []

    /// One controllable part of an accessory (a light bulb, an outlet...).
    private struct Entry {
        let service: HMService
        let accessory: HMAccessory
        let kind: Device.Kind
        let room: String
        var label: String { service.name.isEmpty ? accessory.name : (accessory.services.filter { HomeService.isControllable($0) }.count > 1 ? service.name : accessory.name) }
        var words: String { "\(room) \(accessory.name) \(service.name)".lowercased() }
    }

    private var manager: HMHomeManager?
    private var loaded = false
    private var entries: [Entry] = []

    private static let connectedKey = "homeConnected"

    /// True once you've connected Apple Home before (so Ace reconnects by itself).
    var wasConnected: Bool { UserDefaults.standard.bool(forKey: Self.connectedKey) }

    // MARK: Connecting

    /// Starts Apple Home. The first time, iOS asks for permission.
    func connect() {
        guard manager == nil else { return }
        UserDefaults.standard.set(true, forKey: Self.connectedKey)
        access = .waiting
        let m = HMHomeManager()
        m.delegate = self
        manager = m
    }

    /// Connects and waits (up to about 5 seconds) for Apple Home to load.
    func ready() async -> Bool {
        connect()
        for _ in 0..<50 where !loaded {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        updateAccess()
        return access == .allowed
    }

    private var home: HMHome? { manager?.homes.first }

    private func updateAccess() {
        guard let manager else { access = .notConnected; return }
        let status = manager.authorizationStatus
        if status.contains(.determined) && !status.contains(.authorized) {
            access = .denied
        } else if !loaded {
            access = .waiting
        } else if manager.homes.isEmpty {
            access = .noHome
        } else {
            access = .allowed
        }
    }

    fileprivate func homesChanged() {
        loaded = true
        rebuild()
        updateAccess()
        Task { await refresh() }
    }

    fileprivate func statusChanged() {
        updateAccess()
    }

    nonisolated static func isControllable(_ s: HMService) -> Bool {
        s.characteristics.contains {
            $0.characteristicType == HMCharacteristicTypePowerState
                || $0.characteristicType == HMCharacteristicTypeActive
                || $0.characteristicType == HMCharacteristicTypeTargetTemperature
        }
    }

    private static let blocked: Set<String> = [HMServiceTypeLockMechanism, HMServiceTypeGarageDoorOpener, HMServiceTypeSecuritySystem]

    private func kind(of s: HMService, in a: HMAccessory) -> Device.Kind? {
        if Self.blocked.contains(s.serviceType) { return nil }
        guard Self.isControllable(s) else { return nil }
        let about = [a.name, s.name, a.manufacturer ?? "", a.model ?? "", a.category.localizedDescription, s.localizedDescription]
            .joined(separator: " ").lowercased()
        if Rx.matches(#"vacuum|\bmova\b|roborock|roomba|dreame|robot|cleaner"#, about) { return .vacuum }
        switch s.serviceType {
        case HMServiceTypeLightbulb: return .light
        case HMServiceTypeOutlet, HMServiceTypeSwitch: return .plug
        case HMServiceTypeFan: return .fan
        case HMServiceTypeThermostat: return .thermostat
        default: return .other
        }
    }

    private func rebuild() {
        guard let home else { entries = []; devices = []; scenes = []; homeName = ""; return }
        homeName = home.name
        var list: [Entry] = []
        for a in home.accessories {
            let room = a.room?.name ?? ""
            for s in a.services {
                if let k = kind(of: s, in: a) { list.append(Entry(service: s, accessory: a, kind: k, room: room)) }
            }
        }
        entries = list.sorted { ($0.room, $0.label) < ($1.room, $1.label) }
        let old = Dictionary(devices.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        devices = entries.map { e in
            Device(id: e.service.uniqueIdentifier, name: e.label, room: e.room, kind: e.kind,
                   isOn: old[e.service.uniqueIdentifier]?.isOn, level: old[e.service.uniqueIdentifier]?.level)
        }
        scenes = home.actionSets.map(\.name).sorted()
        // So "turn on the desk thing" works for any name you used in the Home app.
        var names = Set<String>()
        for e in entries { names.insert(e.accessory.name.lowercased()); names.insert(e.service.name.lowercased()) }
        for r in home.rooms { names.insert(r.name.lowercased()) }
        UserDefaults.standard.set(names.filter { $0.count >= 3 }.sorted(), forKey: "homeKnownNames")
    }

    /// Reads every device's on/off state and brightness.
    func refresh() async {
        guard loaded else { return }
        rebuild()
        var on: [UUID: Bool] = [:]
        var level: [UUID: Int] = [:]
        for e in entries.prefix(60) {
            let id = e.service.uniqueIdentifier
            if let c = power(e.service), let v = await readNumber(c) { on[id] = v != 0 }
            if let c = e.service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }),
               let v = await readNumber(c) { level[id] = Int(v) }
        }
        for i in devices.indices {
            if let v = on[devices[i].id] { devices[i].isOn = v }
            if let v = level[devices[i].id] { devices[i].level = v }
        }
    }

    /// Turns a device on or off from the Settings list.
    func setPower(_ id: UUID, _ on: Bool) async {
        guard let i = entries.firstIndex(where: { $0.service.uniqueIdentifier == id }), let c = power(entries[i].service) else { return }
        if await write(c, on) { devices[i].isOn = on }
    }

    // MARK: Commands

    func run(_ cmd: HomeCommand, confirmed: Bool, fahrenheit: Bool) async -> (reply: BrainReply, confirm: HomeCommand?) {
        if case .safety = cmd.action { return (say(.homeSafety, mood: .idle), nil) }
        let lan = LanLights.shared
        let lanHits = lan.enabled ? lan.match(cmd.target) : []
        let lightish = Self.isLightAction(cmd.action)

        // Govee or Twinkly lights named on purpose don't need Apple Home.
        if lightish, !lanHits.isEmpty, LanLights.namesBrand(cmd.target) || lan.namesOwn(cmd.target) {
            return (await runLan(cmd.action, lanHits), nil)
        }

        guard await ready() else {
            if lightish, !lanHits.isEmpty { return (await runLan(cmd.action, lanHits), nil) }
            if case .scene(let name) = cmd.action, let reply = await builtInScene(name, homeLights: []) { return (reply, nil) }
            if LanLights.namesBrand(cmd.target) { return (say(.lanNone, mood: .idle), nil) }
            switch access {
            case .denied: return (say(.homeNoAccess, mood: .idle), nil)
            case .noHome: return (say(.homeNoHome, mood: .idle), nil)
            default: return (say(.homeNoAccess, mood: .idle), nil)
            }
        }
        guard let home else { return (say(.homeNoHome, mood: .idle), nil) }
        return await runAppleHome(cmd, home: home, confirmed: confirmed, fahrenheit: fahrenheit, lanHits: lanHits)
    }

    private func runAppleHome(_ cmd: HomeCommand, home: HMHome, confirmed: Bool, fahrenheit: Bool,
                              lanHits: [LanLights.Light]) async -> (reply: BrainReply, confirm: HomeCommand?) {
        switch cmd.action {
        case .safety:
            return (say(.homeSafety, mood: .idle), nil)

        case .list:
            await refresh()
            let lan = LanLights.shared
            if lan.enabled && !lan.lights.isEmpty { await lan.refresh() }
            let lanLights = lan.enabled ? lan.lights : []
            guard !devices.isEmpty || !lanLights.isEmpty else { return (say(.homeNotFound, ["device": "any devices"], mood: .idle), nil) }
            var lines: [String] = []
            let byRoom = Dictionary(grouping: devices, by: { $0.room.isEmpty ? "No room" : $0.room })
            for room in byRoom.keys.sorted() {
                let items = byRoom[room]!.map { d -> String in
                    guard let on = d.isOn else { return d.name }
                    return "\(d.name) (\(on ? "on" : "off"))"
                }
                lines.append("- \(room): \(items.joined(separator: ", "))")
            }
            if !lanLights.isEmpty {
                let items = lanLights.map { l -> String in
                    guard let on = l.isOn else { return l.label }
                    return "\(l.label) (\(on ? "on" : "off"))"
                }
                lines.append("- On your Wi-Fi: \(items.joined(separator: ", "))")
            }
            if !scenes.isEmpty { lines.append("- Scenes: \(scenes.joined(separator: ", "))") }
            let total = devices.count + lanLights.count
            let count = "\(total) device\(total == 1 ? "" : "s")"
            var text = Say.line(.homeList, ["count": count, "home": home.name]) + "\n" + lines.joined(separator: "\n")
            if !devices.contains(where: { $0.kind == .vacuum }) { text += "\n\n" + Say.line(.vacuumMissing) }
            return (BrainReply(text: text, source: "Apple Home"), nil)

        case .scene(let name):
            guard let set = findScene(name, in: home) else {
                if let reply = await builtInScene(name, homeLights: entries.filter { $0.kind == .light }) { return (reply, nil) }
                return (say(.homeNotFound, ["device": "a \"\(TextKit.capitalizeFirst(name))\" scene"], mood: .idle), nil)
            }
            let ok = await runScene(set, in: home)
            return (ok ? say(.homeScene, ["scene": set.name]) : say(.homeFailed, ["device": set.name], mood: .alert), nil)

        case .vacuumStart, .vacuumRoom, .vacuumPause, .vacuumDock, .vacuumStatus:
            return (await vacuum(cmd.action), nil)

        case .on, .off, .level, .color, .temp, .status:
            break
        }

        // Lights, plugs, fans, thermostats...
        let wantsThermostat: Bool = {
            switch cmd.action {
            case .temp: return true
            default: return false
            }
        }()
        var found = match(wantsThermostat && cmd.target.isEmpty ? "thermostat" : cmd.target, preferThermostat: wantsThermostat)
        if case .color = cmd.action { found.entries = found.entries.filter { $0.kind == .light } }
        if found.entries.isEmpty {
            if Self.isLightAction(cmd.action), !lanHits.isEmpty { return (await runLan(cmd.action, lanHits), nil) }
            if let brand = Self.appOnlyBrand(cmd.target) { return (say(.homeAddTip, ["device": brand], mood: .idle), nil) }
            if LanLights.namesBrand(cmd.target) { return (say(.lanNone, mood: .idle), nil) }
            return (say(.homeNotFound, ["device": quoted(cmd.target)], mood: .idle), nil)
        }
        // "The lights" means the Apple Home lights and the Govee/Twinkly ones too.
        let alsoLan: Bool = {
            if case .status = cmd.action { return false }
            return Self.isLightAction(cmd.action) && !lanHits.isEmpty
        }()
        let name = alsoLan ? "every light" : displayName(found.entries, target: cmd.target)
        if !confirmed && (found.fuzzy || found.unsure) {
            return (say(.homeConfirm, ["action": verb(cmd.action), "device": name], mood: .idle), cmd)
        }

        switch cmd.action {
        case .on, .off:
            let on: Bool = {
                if case .on = cmd.action { return true }
                return false
            }()
            var okAll = await apply(cmd.action, to: found.entries)
            if alsoLan { okAll = await applyLan(cmd.action, lanHits) && okAll }
            if !okAll { return (say(.homeFailed, ["device": name], mood: .alert), nil) }
            return (say(on ? .homeOn : .homeOff, ["device": name]), nil)

        case .level(let level):
            var okAll = await apply(cmd.action, to: found.entries)
            if alsoLan { okAll = await applyLan(cmd.action, lanHits) && okAll }
            if !okAll { return (say(.homeCantDo, ["device": name, "action": "dim"], mood: .idle), nil) }
            return (say(.homeLevel, ["device": name, "level": "\(level)"]), nil)

        case .color(let color):
            var okAll = await apply(cmd.action, to: found.entries)
            if alsoLan { okAll = await applyLan(cmd.action, lanHits) && okAll }
            if !okAll { return (say(.homeCantDo, ["device": name, "action": "change color"], mood: .idle), nil) }
            return (say(.homeColor, ["device": name, "color": color]), nil)

        case .temp(let value, let unit):
            let useF = unit.map { $0 == "f" } ?? fahrenheit
            let celsius = useF ? (value - 32) * 5 / 9 : value
            let clamped = min(38, max(10, celsius))
            var okAll = true
            var any = false
            for e in found.entries {
                guard let c = e.service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetTemperature }) else { continue }
                any = true
                let ok = await write(c, (clamped * 2).rounded() / 2)
                okAll = okAll && ok
            }
            if !any { return (say(.homeCantDo, ["device": name, "action": "change the temperature"], mood: .idle), nil) }
            if !okAll { return (say(.homeFailed, ["device": name], mood: .alert), nil) }
            return (say(.homeTemp, ["device": name, "temp": Self.degrees(clamped, fahrenheit: useF)]), nil)

        case .status:
            let e = found.entries[0]
            var parts: [String] = []
            if let c = power(e.service), let v = await readNumber(c) {
                parts.append(v != 0 ? "on" : "off")
            }
            if let c = e.service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }), let v = await readNumber(c), parts.first == "on" {
                parts[0] = "on at \(Int(v))%"
            }
            if let c = e.service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetTemperature }), let v = await readNumber(c) {
                parts.append("set to \(Self.degrees(v, fahrenheit: fahrenheit))")
            }
            if let c = e.service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }), let v = await readNumber(c) {
                parts.append("reading \(Self.degrees(v, fahrenheit: fahrenheit)) right now")
            }
            let state = parts.isEmpty ? "not reporting anything right now" : parts.joined(separator: ", and ")
            let label = found.entries.count > 1 ? e.label : name
            return (say(.homeStatus, ["device": label, "state": state]), nil)

        default:
            return (say(.homeNotFound, ["device": quoted(cmd.target)], mood: .idle), nil)
        }
    }

    // MARK: Lights (Apple Home and Govee/Twinkly)

    nonisolated static func isLightAction(_ a: HomeCommand.Action) -> Bool {
        switch a {
        case .on, .off, .level, .color, .status: return true
        default: return false
        }
    }

    /// Brands that only work through Apple Home (no way to reach them on your Wi-Fi).
    nonisolated static func appOnlyBrand(_ target: String) -> String? {
        let t = TextKit.normalize(target)
        if t.contains("blueair") { return "Blueair" }
        if Rx.matches(#"\b(smarthq|smart hq|dishwasher|washing machine|dryer|oven)\b"#, t) { return "your SmartHQ appliance" }
        if Rx.matches(#"\b(mova|vacuum|robot)\b"#, t) { return "MOVA" }
        return nil
    }

    /// Turns Apple Home lights on, off, brighter or a color. True when every one worked.
    private func apply(_ action: HomeCommand.Action, to list: [Entry]) async -> Bool {
        var okAll = true
        for e in list {
            let s = e.service
            let ok: Bool
            switch action {
            case .on, .off:
                let on: Bool = { if case .on = action { return true }; return false }()
                guard let c = power(s) else { okAll = false; continue }
                ok = await write(c, on)
                if ok, let i = devices.firstIndex(where: { $0.id == s.uniqueIdentifier }) { devices[i].isOn = on }
            case .level(let level):
                guard let c = characteristic(s, HMCharacteristicTypeBrightness) else { okAll = false; continue }
                if level > 0, let p = power(s) { _ = await write(p, true) }
                ok = await write(c, level)
                if ok, let i = devices.firstIndex(where: { $0.id == s.uniqueIdentifier }) { devices[i].level = level; devices[i].isOn = level > 0 }
            case .color(let name):
                guard let color = LanLights.color(named: name) else { okAll = false; continue }
                if let p = power(s) { _ = await write(p, true) }
                if let k = color.kelvin, let c = characteristic(s, HMCharacteristicTypeColorTemperature) {
                    ok = await write(c, NSNumber(value: min(500, max(140, 1_000_000 / k))))
                } else if let h = characteristic(s, HMCharacteristicTypeHue), let sat = characteristic(s, HMCharacteristicTypeSaturation) {
                    let hs = Self.hueSaturation(color.rgb)
                    let a = await write(h, NSNumber(value: hs.hue))
                    let b = await write(sat, NSNumber(value: hs.saturation))
                    ok = a && b
                } else {
                    ok = false
                }
            default:
                ok = false
            }
            okAll = okAll && ok
        }
        return okAll
    }

    /// The same for Govee and Twinkly lights.
    private func applyLan(_ action: HomeCommand.Action, _ lights: [LanLights.Light]) async -> Bool {
        let lan = LanLights.shared
        var okAll = true
        for l in lights {
            let ok: Bool
            switch action {
            case .on: ok = await lan.setPower(l, true)
            case .off: ok = await lan.setPower(l, false)
            case .level(let level): ok = await (level == 0 ? lan.setPower(l, false) : lan.setBrightness(l, level))
            case .color(let name):
                guard let c = LanLights.color(named: name) else { okAll = false; continue }
                ok = await lan.setColor(l, c.rgb, kelvin: c.kelvin)
            default: ok = false
            }
            okAll = okAll && ok
        }
        return okAll
    }

    private func runLan(_ action: HomeCommand.Action, _ lights: [LanLights.Light]) async -> BrainReply {
        let name = lights.count == 1 ? lights[0].label : (Set(lights.map(\.brand)).count == 1 ? "your \(lights[0].brand == .govee ? "Govee" : "Twinkly") lights" : "every light")
        if case .status = action {
            await LanLights.shared.refresh()
            let fresh = LanLights.shared.lights.first { $0.id == lights[0].id } ?? lights[0]
            let state = fresh.isOn.map { $0 ? "on" : "off" } ?? "not answering right now"
            return lanSay(.homeStatus, ["device": fresh.label, "state": state])
        }
        guard await applyLan(action, lights) else { return lanSay(.homeFailed, ["device": name], mood: .alert) }
        switch action {
        case .on: return lanSay(.homeOn, ["device": name])
        case .off: return lanSay(.homeOff, ["device": name])
        case .level(let l): return lanSay(.homeLevel, ["device": name, "level": "\(l)"])
        case .color(let c): return lanSay(.homeColor, ["device": name, "color": c])
        default: return lanSay(.homeCantDo, ["device": name, "action": "do that"], mood: .idle)
        }
    }

    /// Ace's own scenes for when Apple Home doesn't have one with that name.
    private func builtInScene(_ name: String, homeLights: [Entry]) async -> BrainReply? {
        let n = TextKit.normalize(name)
        let lan = LanLights.shared.enabled ? LanLights.shared.lights : []
        guard !homeLights.isEmpty || !lan.isEmpty else { return nil }
        let steps: [HomeCommand.Action]
        let title: String
        if Rx.matches(#"good ?night|bed|sleep|leaving|away|lights out"#, n) {
            steps = [.off]; title = "Goodnight"
        } else if Rx.matches(#"movie|film|cinema|tv"#, n) {
            steps = [.color("warm white"), .level(15)]; title = "Movie mode"
        } else if Rx.matches(#"good ?morning|wake|morning"#, n) {
            steps = [.color("warm white"), .level(100)]; title = "Good morning"
        } else if Rx.matches(#"focus|study|homework|work|reading|read"#, n) {
            steps = [.color("cool white"), .level(100)]; title = "Focus"
        } else if Rx.matches(#"party|disco|rainbow|fun"#, n) {
            steps = []; title = "Party mode"
        } else if Rx.matches(#"home|back|arrive|relax|chill|cozy"#, n) {
            steps = [.color("warm white"), .level(60)]; title = "Welcome home"
        } else {
            return nil
        }
        if title == "Party mode" {
            let colors = ["purple", "blue", "pink", "cyan", "green", "orange"]
            for (i, e) in homeLights.enumerated() { _ = await apply(.color(colors[i % colors.count]), to: [e]) }
            for (i, l) in lan.enumerated() {
                if l.brand == .twinkly { _ = await LanLights.shared.playEffects(l) } else { _ = await applyLan(.color(colors[(i + 3) % colors.count]), [l]) }
            }
        } else {
            for step in steps {
                _ = await apply(step, to: homeLights)
                _ = await applyLan(step, lan)
            }
            if title == "Movie mode" {
                for l in lan where l.brand == .twinkly { _ = await LanLights.shared.playEffects(l) }
            }
        }
        return say(.homeScene, ["scene": title])
    }

    private func characteristic(_ s: HMService, _ type: String) -> HMCharacteristic? {
        s.characteristics.first { $0.characteristicType == type }
    }

    /// Hue (0...360) and saturation (0...100) for Apple Home lights.
    nonisolated static func hueSaturation(_ c: LanLights.RGB) -> (hue: Double, saturation: Double) {
        let r = Double(c.r) / 255, g = Double(c.g) / 255, b = Double(c.b) / 255
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
        var h = 0.0
        if d > 0 {
            if mx == r { h = 60 * ((g - b) / d).truncatingRemainder(dividingBy: 6) }
            else if mx == g { h = 60 * ((b - r) / d + 2) }
            else { h = 60 * ((r - g) / d + 4) }
        }
        if h < 0 { h += 360 }
        let sat = mx == 0 ? 0 : d / mx * 100
        return ((h * 10).rounded() / 10, (sat * 10).rounded() / 10)
    }

    private func lanSay(_ key: ReplyKey, _ slots: [String: String] = [:], mood: OrbMood = .happy) -> BrainReply {
        BrainReply(text: TextKit.capitalizeFirst(Say.line(key, slots)), source: "Your Wi-Fi lights", mood: mood)
    }

    // MARK: Robot vacuum

    private func vacuum(_ action: HomeCommand.Action) async -> BrainReply {
        guard let e = entries.first(where: { $0.kind == .vacuum }) else { return say(.vacuumMissing, mood: .idle) }
        let name = e.accessory.name
        guard let c = power(e.service) else { return say(.homeCantDo, ["device": name, "action": "do that"], mood: .idle) }
        switch action {
        case .vacuumStatus:
            guard let v = await readNumber(c) else { return say(.homeFailed, ["device": name], mood: .alert) }
            return say(.homeStatus, ["device": name, "state": v != 0 ? "cleaning" : "not cleaning"])
        case .vacuumStart:
            return await write(c, true) ? say(.vacuumStart, ["device": name]) : say(.homeFailed, ["device": name], mood: .alert)
        case .vacuumRoom(let room):
            return await write(c, true) ? say(.vacuumRoom, ["device": name, "room": room]) : say(.homeFailed, ["device": name], mood: .alert)
        case .vacuumPause:
            return await write(c, false) ? say(.vacuumPause, ["device": name]) : say(.homeFailed, ["device": name], mood: .alert)
        case .vacuumDock:
            // In Apple Home, turning a robot vacuum off sends it back to its dock.
            return await write(c, false) ? say(.vacuumDock, ["device": name]) : say(.homeFailed, ["device": name], mood: .alert)
        default:
            return say(.homeCantDo, ["device": name, "action": "do that"], mood: .idle)
        }
    }

    // MARK: Scenes

    private func findScene(_ name: String, in home: HMHome) -> HMActionSet? {
        let n = TextKit.normalize(name)
        let sets = home.actionSets
        if let s = sets.first(where: { TextKit.normalize($0.name) == n }) { return s }
        if let s = sets.first(where: { TextKit.normalize($0.name).contains(n) || n.contains(TextKit.normalize($0.name)) }) { return s }
        let type: String?
        if Rx.matches(#"good ?night|bed|sleep"#, n) { type = HMActionSetTypeSleep }
        else if Rx.matches(#"good ?morning|wake"#, n) { type = HMActionSetTypeWakeUp }
        else if Rx.matches(#"leaving|away"#, n) { type = HMActionSetTypeHomeDeparture }
        else if Rx.matches(#"home|back|arrive"#, n) { type = HMActionSetTypeHomeArrival }
        else { type = nil }
        if let type { return sets.first { $0.actionSetType == type } }
        return nil
    }

    private func runScene(_ set: HMActionSet, in home: HMHome) async -> Bool {
        await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            home.executeActionSet(set) { error in cont.resume(returning: error == nil) }
        }
    }

    // MARK: Finding devices

    private static let stopWords: Set<String> = ["the", "my", "all", "of", "in", "on", "please", "a", "an", "every", "both", "now", "for", "me", "our", "room"]

    nonisolated private static func kindWord(_ w: String) -> Device.Kind? {
        switch w {
        case "light", "lights", "lamp", "lamps", "bulb", "bulbs", "strip", "strips", "leds", "led": return .light
        case "plug", "plugs", "outlet", "outlets", "switch", "switches": return .plug
        case "fan", "fans": return .fan
        case "thermostat", "heat", "heating", "ac", "aircon", "temperature", "temp": return .thermostat
        case "vacuum", "robot", "mova", "roomba": return .vacuum
        default: return nil
        }
    }

    /// Finds the devices the words point to. `fuzzy` means it only matched by a near spelling,
    /// `unsure` means several matched when you named one, so Ace asks first.
    private func match(_ target: String, preferThermostat: Bool) -> (entries: [Entry], fuzzy: Bool, unsure: Bool) {
        let t = TextKit.normalize(target)
        let words = t.split(separator: " ").map(String.init)
        let plural = words.contains("all") || words.contains("every") || words.contains("everything")
            || words.contains { ["lights", "lamps", "plugs", "fans", "bulbs", "outlets", "switches", "strips", "leds"].contains($0) }
        let kinds = Set(words.compactMap(Self.kindWord))
        let nameWords = words.filter { !Self.stopWords.contains($0) && Self.kindWord($0) == nil }
        var pool = entries
        if preferThermostat { pool = pool.filter { $0.kind == .thermostat } }

        // Exact name first ("Desk Lamp").
        let exact = pool.filter { $0.accessory.name.lowercased() == t || $0.service.name.lowercased() == t }
        if !exact.isEmpty { return (exact, false, false) }

        let hits = pool.filter { e in
            let hay = e.words
            let kindOK = kinds.isEmpty || kinds.contains(e.kind) || kinds.contains { k in
                words.contains { Self.kindWord($0) == k && hay.contains(Self.singular($0)) }
            }
            guard kindOK else { return false }
            if nameWords.isEmpty { return !kinds.isEmpty }
            return nameWords.allSatisfy { hay.contains(Self.singular($0)) }
        }
        if !hits.isEmpty {
            return (hits, false, hits.count > 1 && !plural && nameWords.isEmpty)
        }

        // A near spelling ("kitchn light")
        let wanted = nameWords.joined(separator: " ")
        guard wanted.count >= 3 else { return ([], false, false) }
        var best: (Entry, Int)?
        for e in pool {
            for candidate in [e.accessory.name.lowercased(), e.room.lowercased(), e.service.name.lowercased()] where !candidate.isEmpty {
                let d = Self.distance(wanted, candidate)
                if d <= max(1, candidate.count / 4), best == nil || d < best!.1 { best = (e, d) }
            }
        }
        if let best { return ([best.0], true, false) }
        return ([], false, false)
    }

    private func displayName(_ list: [Entry], target: String) -> String {
        if list.count == 1 { return list[0].label }
        let rooms = Set(list.map(\.room))
        let kinds = Set(list.map(\.kind))
        let noun: String
        if kinds.count == 1 {
            switch kinds.first! {
            case .light: noun = "light"
            case .plug: noun = "plug"
            case .fan: noun = "fan"
            case .thermostat: noun = "thermostat"
            case .vacuum: noun = "vacuum"
            case .other: noun = "device"
            }
        } else {
            noun = "device"
        }
        if rooms.count == 1, let r = rooms.first, !r.isEmpty { return "every \(noun) in the \(r)" }
        return "every \(noun)"
    }

    private func verb(_ a: HomeCommand.Action) -> String {
        switch a {
        case .on: return "turn on"
        case .off: return "turn off"
        case .level(let l): return "set the brightness to \(l)% on"
        case .temp: return "change the temperature on"
        case .color(let c): return "make it \(c) on"
        default: return "check"
        }
    }

    private func quoted(_ target: String) -> String {
        target.isEmpty ? "that" : "\"\(target)\""
    }

    private func power(_ s: HMService) -> HMCharacteristic? {
        s.characteristics.first { $0.characteristicType == HMCharacteristicTypePowerState }
            ?? s.characteristics.first { $0.characteristicType == HMCharacteristicTypeActive }
    }

    // MARK: Reading and writing

    private func readNumber(_ c: HMCharacteristic) async -> Double? {
        await withCheckedContinuation { (cont: CheckedContinuation<Double?, Never>) in
            c.readValue { error in
                if error != nil { cont.resume(returning: nil); return }
                cont.resume(returning: (c.value as? NSNumber)?.doubleValue)
            }
        }
    }

    private func write(_ c: HMCharacteristic, _ on: Bool) async -> Bool {
        // "Active" takes 1 or 0, "Power State" takes true or false.
        let value: NSNumber = c.characteristicType == HMCharacteristicTypeActive ? NSNumber(value: on ? 1 : 0) : NSNumber(value: on)
        return await write(c, value)
    }

    private func write(_ c: HMCharacteristic, _ level: Int) async -> Bool {
        await write(c, NSNumber(value: level))
    }

    private func write(_ c: HMCharacteristic, _ celsius: Double) async -> Bool {
        await write(c, NSNumber(value: celsius))
    }

    private func write(_ c: HMCharacteristic, _ value: NSNumber) async -> Bool {
        await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            c.writeValue(value) { error in cont.resume(returning: error == nil) }
        }
    }

    // MARK: Helpers

    private func say(_ key: ReplyKey, _ slots: [String: String] = [:], mood: OrbMood = .happy) -> BrainReply {
        BrainReply(text: TextKit.capitalizeFirst(Say.line(key, slots)), source: "Apple Home", mood: mood)
    }

    nonisolated static func degrees(_ celsius: Double, fahrenheit: Bool) -> String {
        fahrenheit ? "\(Int((celsius * 9 / 5 + 32).rounded()))°F" : String(format: "%.1f°C", celsius).replacingOccurrences(of: ".0°", with: "°")
    }

    nonisolated static func singular(_ w: String) -> String {
        if w.hasSuffix("ches") || w.hasSuffix("shes") { return String(w.dropLast(2)) }
        if w.hasSuffix("s"), w.count > 3, !w.hasSuffix("ss") { return String(w.dropLast()) }
        return w
    }

    /// How many letters you'd change to turn one word into the other.
    nonisolated static func distance(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        if x.isEmpty { return y.count }
        if y.isEmpty { return x.count }
        var row = Array(0...y.count)
        for i in 1...x.count {
            var prev = row[0]
            row[0] = i
            for j in 1...y.count {
                let cur = row[j]
                row[j] = min(row[j] + 1, row[j - 1] + 1, prev + (x[i - 1] == y[j - 1] ? 0 : 1))
                prev = cur
            }
        }
        return row[y.count]
    }
}

extension HomeService: HMHomeManagerDelegate {
    nonisolated func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        Task { @MainActor in HomeService.shared.homesChanged() }
    }

    nonisolated func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        Task { @MainActor in HomeService.shared.statusChanged() }
    }
}
