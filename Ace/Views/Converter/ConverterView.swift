import SwiftUI
import UIKit

/// Ace's unit converter: pick a kind, type an amount and see it in another unit, in every unit
/// at once, and next to real things (or on a thermometer for temperatures).
struct ConverterView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("converter.kind") private var savedKind = MeasureKind.length.rawValue
    @AppStorage("converter.pairs") private var savedPairs = ""

    @Namespace private var glow
    @State private var kind: MeasureKind = .length
    @State private var pairs: [MeasureKind: (from: String, to: String)] = [:]
    @State private var input = "1"
    @State private var shown = false
    @State private var swaps = 0
    @State private var copied = false
    @FocusState private var typing: Bool

    private var moves: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    // MARK: The numbers

    private var units: [MeasureUnit] { Converter.units(kind) }

    private var pair: (from: String, to: String) { pairs[kind] ?? kind.defaultPair }

    private var fromUnit: MeasureUnit {
        Converter.unit(pair.from, in: kind) ?? units[0]
    }

    private var toUnit: MeasureUnit {
        Converter.unit(pair.to, in: kind) ?? units[min(1, units.count - 1)]
    }

    private var amount: Double? { Converter.parse(input) }

    private var answer: Double? {
        amount.map { Converter.convert($0, from: fromUnit, to: toUnit, kind: kind) }
    }

    private var answerText: String {
        answer.map(Converter.format) ?? "—"
    }

    private var baseAmount: Double? {
        amount.map { Converter.toBase($0, from: fromUnit, kind: kind) }
    }

    /// True when the temperature is below absolute zero, which can't happen.
    private var belowAbsoluteZero: Bool {
        kind == .temperature && (baseAmount ?? 0) < -273.15
    }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 760
            ZStack {
                AceTheme.background.ignoresSafeArea()
                backdrop
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        topBar
                            .bounceReveal(shown, order: 0, rise: 24)
                        kindGrid(columns: wide ? 8 : 4)
                            .bounceReveal(shown, order: 1)
                        converterCard
                            .bounceReveal(shown, order: 2)
                        if wide {
                            HStack(alignment: .top, spacing: 18) {
                                everyUnitCard
                                    .frame(maxWidth: .infinity)
                                    .bounceReveal(shown, order: 3)
                                pictureCard
                                    .frame(maxWidth: .infinity)
                                    .bounceReveal(shown, order: 4)
                            }
                        } else {
                            pictureCard.bounceReveal(shown, order: 3)
                            everyUnitCard.bounceReveal(shown, order: 4)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            kind = MeasureKind(rawValue: savedKind) ?? .length
            pairs = Converter.decodePairs(savedPairs)
            withAnimation(motion(.bouncy)) { shown = true }
        }
        .onChange(of: kind) { _, new in
            savedKind = new.rawValue
            copied = false
            // Only temperatures can go below zero.
            if new != .temperature, input.hasPrefix("-") { input.removeFirst() }
        }
        .onChange(of: input) { _, _ in copied = false }
    }

    // MARK: Pieces

    /// Two soft glows in the kind's colors that drift slowly.
    private var backdrop: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !moves)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(Color(hex: kind.hexes.0).opacity(0.26))
                    .frame(width: 520, height: 520)
                    .blur(radius: 120)
                    .offset(x: -220 + 50 * sin(t / 5), y: -260 + 40 * cos(t / 6))
                Circle()
                    .fill(Color(hex: kind.hexes.1).opacity(0.2))
                    .frame(width: 480, height: 480)
                    .blur(radius: 120)
                    .offset(x: 240 + 50 * cos(t / 7), y: 280 + 40 * sin(t / 4))
            }
            .animation(.easeInOut(duration: 0.8), value: kind)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close") { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Converter")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Text("Change any measurement into another")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer(minLength: 0)
            if typing {
                Button("Done") { typing = false }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AceTheme.ace)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.top, 14)
        .animation(motion(.snappy), value: typing)
    }

    private func kindGrid(columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
            ForEach(MeasureKind.allCases) { item in
                MeasureKindTile(kind: item, picked: item == kind, glow: glow) {
                    guard item != kind else { return }
                    Haptics.shared.play(.tick)
                    withAnimation(motion(.snappy)) { kind = item }
                }
            }
        }
    }

    private var converterCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // From.
            VStack(alignment: .leading, spacing: 8) {
                sideLabel("From", unit: fromUnit) { id in setPair(from: id, to: pair.to) }
                HStack(spacing: 10) {
                    TextField("Type an amount", text: Binding(
                        get: { input },
                        set: { input = Converter.cleanTyping($0, allowNegative: kind == .temperature) }
                    ))
                    .keyboardType(.decimalPad)
                    .focused($typing)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AceTheme.fg)
                    .minimumScaleFactor(0.4)
                    .accessibilityLabel("Amount in \(fromUnit.name)")
                    if kind == .temperature {
                        Button {
                            Haptics.shared.play(.tick)
                            if input.hasPrefix("-") { input.removeFirst() } else { input = "-" + input }
                        } label: {
                            Text("±")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(AceTheme.soft))
                                .foregroundStyle(AceTheme.fg)
                        }
                        .buttonStyle(.aceBouncy)
                        .accessibilityLabel("Plus or minus")
                    }
                    if !input.isEmpty {
                        Button {
                            Haptics.shared.play(.tick)
                            input = ""
                            typing = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(AceTheme.muted)
                        }
                        .buttonStyle(.aceBouncy)
                        .accessibilityLabel("Clear")
                    }
                }
            }

            swapRow

            // To.
            VStack(alignment: .leading, spacing: 8) {
                sideLabel("To", unit: toUnit) { id in setPair(from: pair.from, to: id) }
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    RollingNumber(
                        text: answerText,
                        value: answer ?? 0,
                        size: 52,
                        color: Color(hex: kind.hexes.0),
                        moves: moves
                    )
                    .accessibilityLabel(answer == nil ? "Type an amount" : "\(answerText) \(toUnit.name)")
                    Text(toUnit.short)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                        .accessibilityHidden(true)
                    Spacer(minLength: 0)
                    if answer != nil {
                        Button {
                            UIPasteboard.general.string = answerText
                            Haptics.shared.play(.success)
                            withAnimation(motion(.pop)) { copied = true }
                        } label: {
                            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Capsule().fill(AceTheme.soft))
                                .foregroundStyle(copied ? AceTheme.good : AceTheme.fg)
                        }
                        .buttonStyle(.aceBouncy)
                    }
                }
                if let amount, answer != nil {
                    Text("\(Converter.format(amount)) \(fromUnit.short) = \(answerText) \(toUnit.short)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                        .textSelection(.enabled)
                }
                if belowAbsoluteZero {
                    Label("That's below absolute zero, the coldest anything can be.", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AceTheme.warn)
                }
            }
        }
        .aceCard(padding: 20)
    }

    /// The "From" or "To" label with a menu to pick the unit.
    private func sideLabel(_ title: String, unit: MeasureUnit, pick: @escaping (String) -> Void) -> some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AceTheme.muted)
            Menu {
                ForEach(units) { item in
                    Button {
                        Haptics.shared.play(.tick)
                        withAnimation(motion(.snappy)) { pick(item.id) }
                    } label: {
                        if item.id == unit.id {
                            Label(item.name, systemImage: "checkmark")
                        } else {
                            Text(item.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(unit.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color(hex: kind.hexes.0)))
            }
            .accessibilityLabel("\(title) unit, \(unit.name)")
            Spacer(minLength: 0)
        }
    }

    /// A line across the card with a round button that spins and swaps the two units.
    private var swapRow: some View {
        HStack(spacing: 12) {
            Rectangle().fill(AceTheme.cardBorder).frame(height: 1)
            Button {
                Haptics.shared.play(.pop)
                withAnimation(motion(.bouncy)) {
                    swaps += 1
                    swapUnits()
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Color.black)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle().fill(LinearGradient(
                            colors: [Color(hex: kind.hexes.0), Color(hex: kind.hexes.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    )
                    .rotationEffect(.degrees(moves ? Double(swaps) * 180 : 0))
            }
            .buttonStyle(.aceBouncy)
            .accessibilityLabel("Swap units")
            Rectangle().fill(AceTheme.cardBorder).frame(height: 1)
        }
    }

    /// The amount in every unit of the kind. Tap one to convert to it.
    private var everyUnitCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("In every unit", systemImage: "list.bullet.rectangle.fill")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            if let amount {
                ForEach(Array(Converter.everyUnit(amount, from: fromUnit, kind: kind).enumerated()), id: \.element.id) { index, row in
                    let isTarget = row.unit.id == toUnit.id
                    let isSource = row.unit.id == fromUnit.id
                    Button {
                        guard !isSource, !isTarget else { return }
                        Haptics.shared.play(.tick)
                        withAnimation(motion(.snappy)) { setPair(from: pair.from, to: row.unit.id) }
                    } label: {
                        HStack {
                            Text(row.unit.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(isSource ? AceTheme.muted : AceTheme.fg)
                            Spacer(minLength: 8)
                            Text("\(Converter.format(row.value)) \(row.unit.short)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(isTarget ? Color(hex: kind.hexes.0) : AceTheme.fg)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isTarget ? Color(hex: kind.hexes.0).opacity(0.16) : AceTheme.soft)
                        )
                    }
                    .buttonStyle(.aceBouncyRow)
                    .disabled(isSource)
                    .accessibilityHint(isTarget || isSource ? "" : "Converts to \(row.unit.name)")
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(motion(.gentle)?.delay(Double(index) * 0.02), value: kind)
                }
            } else {
                Text("Type an amount to see it in every unit.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            }
        }
        .aceCard(padding: 18)
    }

    /// For temperatures, a thermometer. For everything else, comparisons with real things.
    private var pictureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if kind == .temperature {
                HStack {
                    Label("On a thermometer", systemImage: "thermometer.sun.fill")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(AceTheme.fg)
                    Spacer(minLength: 8)
                    if let celsius = baseAmount, !belowAbsoluteZero {
                        Text(Converter.feel(celsius: celsius))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color(hex: kind.hexes.1)))
                            .contentTransition(.opacity)
                    }
                }
                ConverterThermometer(
                    celsius: baseAmount ?? 0,
                    label: { celsius in
                        "\(Converter.format(Converter.fromBase(celsius, to: toUnit, kind: .temperature))) \(toUnit.short)"
                    },
                    moves: moves
                )
            } else {
                Label("How big is that?", systemImage: "sparkle.magnifyingglass")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                let comparisons = Converter.compare(base: baseAmount ?? 0, kind: kind)
                if let top = Converter.headline(comparisons) {
                    HStack(spacing: 12) {
                        Image(systemName: top.reference.symbol)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.black)
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(hex: kind.hexes.1))
                            )
                            .id(top.reference.id)
                            .transition(.scale.combined(with: .opacity))
                        Text(Converter.sentence(top))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(AceTheme.fg)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .animation(motion(.pop), value: top.reference.id)
                    CompareBars(comparisons: comparisons, hexes: kind.hexes, shown: shown, moves: moves)
                } else {
                    Text("Type an amount bigger than zero to compare it with real things.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                }
            }
        }
        .aceCard(padding: 18)
    }

    // MARK: Changing units

    private func setPair(from: String, to: String) {
        // Picking the same unit on both sides swaps them instead.
        if from == to {
            pairs[kind] = (pair.to, pair.from)
        } else {
            pairs[kind] = (from, to)
        }
        savedPairs = Converter.encodePairs(pairs)
    }

    private func swapUnits() {
        let old = pair
        // Keep the amount: the answer becomes what you typed.
        if let answer {
            let rounded = Converter.format(answer)
            if !rounded.contains("×"), !rounded.contains("—") {
                input = Converter.cleanTyping(rounded.replacingOccurrences(of: ",", with: ""), allowNegative: kind == .temperature)
            }
        }
        pairs[kind] = (old.to, old.from)
        savedPairs = Converter.encodePairs(pairs)
    }
}
