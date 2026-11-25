import SwiftUI

/// The four ways Pick for me can choose.
enum DecideTab: String, CaseIterable, Identifiable {
    case wheel, coin, dice, teams

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wheel: return "Wheel"
        case .coin: return "Coin"
        case .dice: return "Dice"
        case .teams: return "Teams"
        }
    }

    var symbol: String {
        switch self {
        case .wheel: return "circle.circle.fill"
        case .coin: return "centsign.circle.fill"
        case .dice: return "die.face.5.fill"
        case .teams: return "person.3.fill"
        }
    }

    /// The two colors the screen glows in on this tab.
    var glow: (UInt32, UInt32) {
        switch self {
        case .wheel: return (0x8F7CFF, 0xFF5F8F)
        case .coin: return (0xF5B83D, 0xFF8A3D)
        case .dice: return (0x45D483, 0x1BC6FF)
        case .teams: return (0x5BB6FF, 0xB86BFF)
        }
    }
}

/// What the wheel editor is working on.
enum DecideEditTarget: Identifiable {
    case new
    case wheel(DecideWheel)

    var id: String {
        switch self {
        case .new: return "new"
        case .wheel(let wheel): return wheel.id.uuidString
        }
    }
}

/// A coin that shows heads or tails depending on how far it has turned, so the face changes
/// halfway through each flip while it spins.
struct DecideSpinningCoin: View, Animatable {
    var angle: Double
    var size: CGFloat = 170

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    /// The coin shows heads when its front faces you.
    static func showsHeads(_ angle: Double) -> Bool {
        let a = DecideMath.positive(angle)
        return a < 90 || a >= 270
    }

    var body: some View {
        let heads = Self.showsHeads(angle)
        DecideCoinFace(heads: heads, size: size)
            // The back face is drawn upside down so it reads the right way after the flip.
            .scaleEffect(x: 1, y: heads ? 1 : -1)
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), perspective: 0.45)
    }
}

/// Pick for me: spin a wheel of choices, flip a coin, roll dice or split friends into teams.
struct DecideView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = DecideStore.shared
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @AppStorage("decide.teamNames") private var teamNames = ""
    @AppStorage("decide.teamCount") private var teamCount = 2
    @AppStorage("decide.diceCount") private var diceCount = 2
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var tabSpace

    @State private var tab: DecideTab = .wheel
    @State private var shown = false
    @State private var drift = false

    // Wheel
    @State private var wheelID: UUID?
    @State private var rotation: Double = 0
    @State private var spinning = false
    @State private var wheelResult: String?
    @State private var pointerTilt: Double = 0
    @State private var editing: DecideEditTarget?

    // Coin
    @State private var coinAngle: Double = 0
    @State private var coinUp = false
    @State private var flipping = false
    @State private var coinResult: String?
    @State private var headsCount = 0
    @State private var tailsCount = 0

    // Dice
    @State private var dice: [Int] = [3, 5]
    @State private var rolling = false
    @State private var tumble: Double = 0
    @State private var diceRolled = false

    // Teams
    @State private var teams: [[String]] = []
    @State private var teamsRound = 0

    private var moving: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    private var currentWheel: DecideWheel? {
        if let wheelID, let wheel = store.wheel(wheelID) { return wheel }
        return store.wheels.first
    }

    private var options: [String] { currentWheel?.options ?? [] }

    var body: some View {
        ZStack {
            backdrop
            ScrollView {
                VStack(spacing: 22) {
                    topBar
                    tabBar
                        .bounceReveal(shown, order: 0)
                    Group {
                        switch tab {
                        case .wheel: wheelPage
                        case .coin: coinPage
                        case .dice: dicePage
                        case .teams: teamsPage
                        }
                    }
                    .bounceReveal(shown, order: 1, rise: 26)
                    historyCard
                        .bounceReveal(shown, order: 2)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 40)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .preferredColorScheme(.dark)
        .sheet(item: $editing) { target in
            DecideWheelEditor(store: store, target: target) { saved in
                if let saved {
                    wheelID = saved.id
                    wheelResult = nil
                } else if let wheelID, store.wheel(wheelID) == nil {
                    self.wheelID = nil
                    wheelResult = nil
                }
            }
        }
        .onAppear {
            if dice.count != clampedDice { dice = Array(repeating: 1, count: clampedDice) }
            withAnimation(motion(.bouncy)) { shown = true }
            if moving {
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) { drift = true }
            }
        }
    }

    // MARK: Frame

    /// The screen glows in the current tab's colors, with two blobs that slowly drift.
    private var backdrop: some View {
        let colors = tab.glow
        return ZStack {
            AceTheme.background
            Circle()
                .fill(Color(hex: colors.0).opacity(0.45))
                .frame(width: 520, height: 520)
                .blur(radius: 120)
                .offset(x: drift ? -140 : -60, y: drift ? -260 : -180)
            Circle()
                .fill(Color(hex: colors.1).opacity(0.35))
                .frame(width: 460, height: 460)
                .blur(radius: 120)
                .offset(x: drift ? 160 : 80, y: drift ? 300 : 220)
        }
        .animation(.easeInOut(duration: 0.6), value: tab)
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close") { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Pick for me")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Text("Can't decide? Let the wheel, a coin or the dice choose.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer()
        }
        .padding(.top, 14)
    }

    /// The four tabs. The colored pill slides across to the one you tap.
    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(DecideTab.allCases) { item in
                Button {
                    guard item != tab else { return }
                    Haptics.shared.play(.tick)
                    withAnimation(motion(.bouncy)) { tab = item }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.symbol)
                        Text(item.title)
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(tab == item ? Color.white : AceTheme.muted)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity)
                    .background {
                        if tab == item {
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: item.glow.0), Color(hex: item.glow.1)],
                                                     startPoint: .leading, endPoint: .trailing))
                                .matchedGeometryEffect(id: "pill", in: tabSpace)
                                .shadow(color: Color(hex: item.glow.0).opacity(0.5), radius: 10, y: 4)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.aceBouncy)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(tab == item ? .isSelected : [])
            }
        }
        .padding(5)
        .background(Capsule().fill(AceTheme.card))
        .overlay(Capsule().stroke(AceTheme.cardBorder, lineWidth: 1))
    }

    private func bigButton(_ title: String, symbol: String, colors: (UInt32, UInt32), disabled: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 34)
                .padding(.vertical, 16)
                .background(
                    Capsule().fill(LinearGradient(colors: [Color(hex: colors.0), Color(hex: colors.1)],
                                                  startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: Color(hex: colors.0).opacity(0.45), radius: 14, y: 6)
                .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.aceBouncy)
        .disabled(disabled)
    }

    /// The big answer under each tab. It pops in each time it changes.
    private func resultBanner(_ text: String?, placeholder: String) -> some View {
        Text(text ?? placeholder)
            .font(.system(size: text == nil ? 17 : 30, weight: .heavy, design: .rounded))
            .foregroundStyle(text == nil ? AceTheme.muted : AceTheme.fg)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AceTheme.card))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AceTheme.cardBorder, lineWidth: 1))
            .id(text ?? "none")
            .transition(.scale(scale: 0.6).combined(with: .opacity))
            .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: Wheel

    private var wheelPage: some View {
        VStack(spacing: 18) {
            wheelChips
            ZStack(alignment: .top) {
                DecideWheelView(options: options, rotation: rotation)
                    .frame(maxWidth: 460)
                    .padding(.top, 18)
                    .onTapGesture { spin() }
                DecidePointer()
                    .rotationEffect(.degrees(pointerTilt), anchor: .top)
            }
            .frame(maxWidth: .infinity)
            resultBanner(wheelResult, placeholder: spinning ? "Spinning..." : "Tap Spin, or tap the wheel")
                .animation(motion(.pop), value: wheelResult)
            HStack(spacing: 12) {
                bigButton(spinning ? "Spinning" : "Spin", symbol: "arrow.clockwise", colors: DecideTab.wheel.glow,
                          disabled: spinning || options.count < 2) { spin() }
                if let wheel = currentWheel {
                    Button {
                        Haptics.shared.play(.pop)
                        editing = .wheel(wheel)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(AceTheme.fg)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(AceTheme.card))
                    }
                    .buttonStyle(.aceBouncy)
                    .disabled(spinning)
                    .accessibilityLabel("Edit \(wheel.title)")
                }
            }
        }
    }

    /// Saved wheels as chips you can tap to switch, plus one to make a new wheel.
    private var wheelChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.wheels) { wheel in
                    let selected = wheel.id == currentWheel?.id
                    Button {
                        guard !spinning else { return }
                        Haptics.shared.play(.tick)
                        withAnimation(motion(.snappy)) {
                            wheelID = wheel.id
                            wheelResult = nil
                        }
                    } label: {
                        Text(wheel.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(selected ? Color.white : AceTheme.fg)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(selected ? AceTheme.accent : AceTheme.card))
                    }
                    .buttonStyle(.aceBouncy)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .contextMenu {
                        Button { editing = .wheel(wheel) } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) {
                            withAnimation(motion(.snappy)) {
                                store.delete(wheel.id)
                                if wheelID == wheel.id { wheelID = nil; wheelResult = nil }
                            }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
                Button {
                    Haptics.shared.play(.pop)
                    editing = .new
                } label: {
                    Label("New wheel", systemImage: "plus")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AceTheme.ace)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().stroke(AceTheme.ace.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                }
                .buttonStyle(.aceBouncy)
                .disabled(spinning)
            }
            .padding(.vertical, 4)
        }
    }

    private func spin() {
        let choices = options
        guard !spinning, choices.count >= 2 else { return }
        var rng = SystemRandomNumberGenerator()
        let result = DecideMath.spin(from: rotation, count: choices.count, turns: moving ? 5 : 1, using: &rng)
        Haptics.shared.play(.pop)
        withAnimation(motion(.snappy)) { wheelResult = nil }
        let picked = choices[result.winner]
        guard moving else {
            rotation = result.rotation
            finishSpin(picked)
            return
        }
        spinning = true
        let seconds = 4.2
        withAnimation(.timingCurve(0.12, 0.75, 0.2, 1, duration: seconds)) {
            rotation = result.rotation
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            spinning = false
            finishSpin(picked)
        }
    }

    private func finishSpin(_ picked: String) {
        // The pointer flicks to the side and springs back, like it just caught the winner.
        if moving {
            withAnimation(.easeOut(duration: 0.12)) { pointerTilt = 16 }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 120_000_000)
                withAnimation(motion(.pop)) { pointerTilt = 0 }
            }
        }
        Haptics.shared.play(.success)
        SoundFX.shared.play(.success)
        withAnimation(motion(.pop)) { wheelResult = picked }
        store.remember("\(currentWheel?.title ?? "Wheel"): \(picked)")
    }

    // MARK: Coin

    private var coinPage: some View {
        VStack(spacing: 22) {
            DecideSpinningCoin(angle: coinAngle)
                .offset(y: coinUp ? -120 : 0)
                .scaleEffect(coinUp ? 1.15 : 1)
                .padding(.top, 140)
                .padding(.bottom, 10)
                .onTapGesture { flip() }
                .accessibilityElement()
                .accessibilityLabel(coinResult ?? "A coin")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { flip() }
            resultBanner(coinResult, placeholder: flipping ? "Flipping..." : "Heads or tails?")
                .animation(motion(.pop), value: coinResult)
            bigButton(flipping ? "Flipping" : "Flip", symbol: "arrow.up.circle.fill", colors: DecideTab.coin.glow,
                      disabled: flipping) { flip() }
            HStack(spacing: 14) {
                tally("Heads", count: headsCount, symbol: "crown.fill")
                tally("Tails", count: tailsCount, symbol: "bolt.fill")
            }
        }
    }

    private func tally(_ title: String, count: Int, symbol: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AceTheme.amber)
            Text("\(count)")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
                .contentTransition(.numericText())
                .animation(motion(.pop), value: count)
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AceTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .aceCard()
        .accessibilityElement(children: .combine)
    }

    private func flip() {
        guard !flipping else { return }
        let heads = Bool.random()
        let nowHeads = DecideSpinningCoin.showsHeads(coinAngle)
        // Several full turns, plus half a turn more when the coin has to land on its other side.
        let target = coinAngle + (moving ? 1440 : 0) + (heads == nowHeads ? 0 : 180)
        Haptics.shared.play(.pop)
        withAnimation(motion(.snappy)) { coinResult = nil }
        guard moving else {
            coinAngle = target
            finishFlip(heads)
            return
        }
        flipping = true
        let seconds = 1.3
        withAnimation(.easeInOut(duration: seconds)) { coinAngle = target }
        withAnimation(.easeOut(duration: seconds / 2)) { coinUp = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds / 2 * 1_000_000_000))
            withAnimation(.easeIn(duration: seconds / 2)) { coinUp = false }
            try? await Task.sleep(nanoseconds: UInt64(seconds / 2 * 1_000_000_000))
            flipping = false
            finishFlip(heads)
        }
    }

    private func finishFlip(_ heads: Bool) {
        if heads { headsCount += 1 } else { tailsCount += 1 }
        Haptics.shared.play(.success)
        withAnimation(motion(.pop)) { coinResult = heads ? "Heads!" : "Tails!" }
        store.remember("Coin: \(heads ? "Heads" : "Tails")")
    }

    // MARK: Dice

    private var clampedDice: Int { min(4, max(1, diceCount)) }

    private let dieTints: [UInt32] = [0xFFFFFF, 0xFFE38A, 0xB8F5D2, 0xC9DEFF]

    private var dicePage: some View {
        VStack(spacing: 22) {
            HStack(spacing: 18) {
                ForEach(Array(dice.enumerated()), id: \.offset) { index, value in
                    DecideDie(value: value, size: dice.count > 2 ? 92 : 120, tint: Color(hex: dieTints[index % dieTints.count]))
                        .rotationEffect(.degrees(tumble * (index % 2 == 0 ? 1 : -1)))
                        .offset(y: rolling ? -18 : 0)
                }
            }
            .frame(minHeight: 170)
            .contentShape(Rectangle())
            .onTapGesture { roll() }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Dice showing \(dice.map(String.init).joined(separator: ", "))")
            resultBanner(diceRolled && !rolling ? diceLine : nil, placeholder: rolling ? "Rolling..." : "Roll the dice")
                .animation(motion(.pop), value: diceRolled && !rolling ? diceLine : nil)
            bigButton(rolling ? "Rolling" : "Roll", symbol: "dice.fill", colors: DecideTab.dice.glow,
                      disabled: rolling) { roll() }
            HStack(spacing: 12) {
                Text("How many dice")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
                Spacer()
                ForEach(1...4, id: \.self) { n in
                    Button {
                        guard !rolling else { return }
                        Haptics.shared.play(.tick)
                        diceCount = n
                        withAnimation(motion(.bouncy)) {
                            dice = Array(repeating: 1, count: n)
                            diceRolled = false
                        }
                    } label: {
                        Text("\(n)")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(clampedDice == n ? Color.black : AceTheme.fg)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(clampedDice == n ? AceTheme.good : AceTheme.card))
                    }
                    .buttonStyle(.aceBouncy)
                    .accessibilityLabel("\(n) \(n == 1 ? "die" : "dice")")
                    .accessibilityAddTraits(clampedDice == n ? .isSelected : [])
                }
            }
            .aceCard()
        }
    }

    private var diceLine: String {
        dice.count == 1 ? "You rolled \(dice[0])" : "\(dice.map(String.init).joined(separator: " + ")) = \(dice.reduce(0, +))"
    }

    private func roll() {
        guard !rolling else { return }
        var rng = SystemRandomNumberGenerator()
        let final = DecideMath.roll(clampedDice, using: &rng)
        Haptics.shared.play(.pop)
        guard moving else {
            dice = final
            finishRoll()
            return
        }
        rolling = true
        withAnimation(.easeInOut(duration: 0.9)) { tumble += 720 }
        Task { @MainActor in
            // The faces flicker while the dice tumble, then land on the real roll.
            for _ in 0..<9 {
                var flicker = SystemRandomNumberGenerator()
                dice = DecideMath.roll(final.count, using: &flicker)
                Haptics.shared.play(.tick)
                try? await Task.sleep(nanoseconds: 90_000_000)
            }
            dice = final
            withAnimation(motion(.pop)) { rolling = false }
            finishRoll()
        }
    }

    private func finishRoll() {
        diceRolled = true
        Haptics.shared.play(.success)
        store.remember("Dice: \(diceLine)")
    }

    // MARK: Teams

    private let teamColors: [UInt32] = [0xFF5F8F, 0x5BB6FF, 0x45D483, 0xFFB020, 0x8F7CFF, 0x1BC6FF]

    private var people: [String] {
        DecideMath.cleanNames(teamNames.components(separatedBy: .newlines))
    }

    private var teamsPage: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Who's playing? One name per line.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
                TextEditor(text: $teamNames)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                    .frame(minHeight: 130, maxHeight: 220)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AceTheme.soft))
                    .accessibilityLabel("Names, one per line")
                HStack {
                    Text("\(people.count) \(people.count == 1 ? "person" : "people")")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                    Spacer()
                    Stepper("\(teamCount) teams", value: $teamCount, in: 2...6)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AceTheme.fg)
                        .fixedSize()
                }
            }
            .aceCard()
            bigButton("Make teams", symbol: "shuffle", colors: DecideTab.teams.glow,
                      disabled: people.count < 2) { makeTeams() }
            if !teams.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 14)], spacing: 14) {
                    ForEach(Array(teams.enumerated()), id: \.offset) { index, team in
                        teamCard(index, team)
                            .bounceReveal(true, order: index)
                            .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }
                }
                .id(teamsRound)
            }
        }
    }

    private func teamCard(_ index: Int, _ team: [String]) -> some View {
        let color = Color(hex: teamColors[index % teamColors.count])
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(color).frame(width: 14, height: 14)
                Text("Team \(index + 1)")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Spacer()
                Text("\(team.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            ForEach(team, id: \.self) { name in
                Text(name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [color.opacity(0.32), color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(color.opacity(0.5), lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }

    private func makeTeams() {
        var rng = SystemRandomNumberGenerator()
        let made = DecideMath.teams(people, into: teamCount, using: &rng)
        guard !made.isEmpty else { return }
        Haptics.shared.play(.success)
        withAnimation(motion(.bouncy)) {
            teams = made
            teamsRound += 1
        }
        store.remember("Teams: \(made.count) teams of \(people.count)")
    }

    // MARK: History

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Last picks")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Spacer()
                if !store.history.isEmpty {
                    Button("Clear") {
                        Haptics.shared.play(.tick)
                        withAnimation(motion(.snappy)) { store.clearHistory() }
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AceTheme.ace)
                }
            }
            if store.history.isEmpty {
                Text("Your picks show up here.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            } else {
                ForEach(Array(store.history.enumerated()), id: \.offset) { index, line in
                    HStack(spacing: 10) {
                        Image(systemName: index == 0 ? "sparkle" : "clock.arrow.circlepath")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(index == 0 ? AceTheme.pebble : AceTheme.muted)
                        Text(line)
                            .font(.system(size: 15, weight: index == 0 ? .bold : .medium, design: .rounded))
                            .foregroundStyle(index == 0 ? AceTheme.fg : AceTheme.muted)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aceCard()
    }
}
