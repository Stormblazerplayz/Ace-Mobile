import SwiftUI

/// What opens the solar system (see `AceCore.spaceScreen`).
struct SpaceScreen: Identifiable {
    let id = UUID()
    var start: SpaceStart
}

/// Ace Space: the Sun and planets where they really are today, on a map you can speed up to watch
/// them go round, with a card full of facts for each one and a lineup of their real sizes.
struct SpaceView: View {
    let start: SpaceStart

    enum Mode: String, CaseIterable, Identifiable {
        case map = "Map", sizes = "Sizes"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var clock = SpaceClock()
    @State private var selected: Planet?
    @State private var mode: Mode = .map
    @State private var shown = false
    @State private var started = false

    private var moves: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            ZStack {
                RadialGradient(colors: [Color(hex: 0x1A1440), Color(hex: 0x07061A), .black],
                               center: .center, startRadius: 0, endRadius: max(geo.size.width, geo.size.height) * 0.7)
                    .ignoresSafeArea()
                Starfield(moves: moves)

                Group {
                    switch mode {
                    case .map:
                        SpaceMapView(clock: clock, selected: selected, moves: moves, pick: pick)
                            .scaleEffect(selected != nil && !wide ? 0.66 : 1)
                            .offset(x: selected != nil && wide ? -PlanetPanel.width / 2 : 0,
                                    y: selected != nil && !wide ? -geo.size.height * 0.21 : 0)
                    case .sizes:
                        SizeLineup(selected: selected, moves: moves, pick: pick)
                            .padding(.bottom, selected != nil && !wide ? geo.size.height * 0.45 : 0)
                            .padding(.trailing, selected != nil && wide ? PlanetPanel.width : 0)
                    }
                }
                .transition(.opacity)

                VStack(spacing: 0) {
                    topBar
                        .bounceReveal(shown, order: 0)
                    Spacer(minLength: 0)
                    if selected == nil || wide {
                        VStack(spacing: 10) {
                            if mode == .map {
                                timeBar
                            }
                            planetChips
                        }
                        .padding(.trailing, selected != nil && wide ? PlanetPanel.width : 0)
                        .bounceReveal(shown, order: 1)
                        .transition(.opacity)
                    }
                }

                if let planet = selected {
                    panel(planet, wide: wide, size: geo.size)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
        .statusBarHidden()
        .onAppear(perform: begin)
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close the solar system") { dismiss() }
                .background(Circle().fill(.white.opacity(0.08)))
            VStack(alignment: .leading, spacing: 0) {
                Text("Solar system")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                Text(mode == .map ? "Where the planets really are. Tap one!" : "The planets at their real sizes")
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer(minLength: 8)
            Picker("View", selection: Binding(get: { mode }, set: { newMode in
                withAnimation(AceMotion.animation(.gentle, bouncy: bouncy, reduceMotion: reduceMotion)) { mode = newMode }
            })) {
                ForEach(Mode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 190)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    /// The date on the map, the speed buttons, and jumps back and forward.
    private var timeBar: some View {
        VStack(spacing: 8) {
            TimelineView(.periodic(from: .now, by: 0.1)) { timeline in
                let date = clock.date(at: timeline.date)
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(AceTheme.pebble)
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(AceTheme.fg)
                        .contentTransition(.numericText())
                    if !clock.isToday(at: timeline.date) {
                        Button {
                            setClock { $0.jump(to: Date()) }
                        } label: {
                            Label("Today", systemImage: "arrow.uturn.backward")
                                .font(.subheadline.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(AceTheme.ace.opacity(0.25)))
                        }
                        .buttonStyle(.aceBouncy)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .accessibilityElement(children: .combine)
            }
            HStack(spacing: 6) {
                stepButton(days: -30, symbol: "chevron.backward.2", label: "Back a month")
                ForEach(SpaceClock.Warp.allCases) { warp in
                    Button {
                        setClock { $0.set(warp) }
                        Haptics.shared.play(.tick)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: warp.symbol)
                                .font(.system(size: 15, weight: .bold))
                            Text(warp.short)
                                .font(.caption2.weight(.semibold))
                        }
                        .frame(width: 58, height: 46)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(clock.warp == warp ? AceTheme.ace.opacity(0.35) : .white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(clock.warp == warp ? AceTheme.ace : .clear, lineWidth: 1.5))
                        .foregroundStyle(clock.warp == warp ? AceTheme.fg : AceTheme.muted)
                    }
                    .buttonStyle(.aceBouncy)
                    .accessibilityLabel(warp.label)
                    .accessibilityAddTraits(clock.warp == warp ? .isSelected : [])
                }
                stepButton(days: 30, symbol: "chevron.forward.2", label: "Forward a month")
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AceTheme.cardBorder, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func stepButton(days: Double, symbol: String, label: String) -> some View {
        Button {
            setClock { $0.shift(days: days) }
            Haptics.shared.play(.tick)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 44, height: 46)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.06)))
        }
        .buttonStyle(.aceBouncy)
        .accessibilityLabel(label)
    }

    /// A button for the Sun and each planet, so you don't have to hit a tiny dot.
    private var planetChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SolarSystem.everything) { p in
                    Button { pick(selected?.id == p.id ? nil : p) } label: {
                        HStack(spacing: 6) {
                            PlanetBall(planet: p)
                                .frame(width: 24, height: 24)
                            Text(p.isSun ? "Sun" : p.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AceTheme.fg)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(selected?.id == p.id ? Color(hex: p.colors[1]).opacity(0.35) : .white.opacity(0.07)))
                        .overlay(Capsule().stroke(selected?.id == p.id ? Color(hex: p.colors[0]) : AceTheme.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.aceBouncy)
                    .accessibilityLabel(p.name)
                    .accessibilityAddTraits(selected?.id == p.id ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func panel(_ planet: Planet, wide: Bool, size: CGSize) -> some View {
        let card = PlanetPanel(planet: planet, clock: clock, moves: moves,
                               close: { pick(nil) },
                               step: { step($0) })
        if wide {
            HStack {
                Spacer()
                card
                    .frame(width: PlanetPanel.width)
                    .padding(.vertical, 12)
                    .padding(.trailing, 12)
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            VStack {
                Spacer()
                card
                    .frame(height: size.height * 0.5)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: Actions

    private func begin() {
        guard !started else { return }
        started = true
        // The planets drift along at a week a second, unless motion is turned down.
        clock = SpaceClock(date: Date(), warp: moves ? .week : .paused)
        if case .planet(let id) = start, let p = SolarSystem.planet(id) {
            selected = p
        }
        withAnimation(AceMotion.animation(.gentle, bouncy: bouncy, reduceMotion: reduceMotion)) { shown = true }
    }

    private func pick(_ planet: Planet?) {
        if planet != nil { Haptics.shared.play(.pop) }
        withAnimation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion)) { selected = planet }
    }

    /// Moves to the next planet out (1) or in (-1), wrapping round.
    private func step(_ by: Int) {
        let all = SolarSystem.everything
        let now = selected.flatMap { s in all.firstIndex { $0.id == s.id } } ?? 0
        pick(all[(now + by + all.count) % all.count])
    }

    private func setClock(_ change: (inout SpaceClock) -> Void) {
        withAnimation(AceMotion.animation(.snappy, bouncy: bouncy, reduceMotion: reduceMotion)) {
            change(&clock)
        }
    }
}

/// The map itself: orbits, the glowing Sun, each planet where it is on the map's date with a
/// fading trail behind it, the Moon going round Earth, and a line from Earth to the planet you picked.
struct SpaceMapView: View {
    let clock: SpaceClock
    let selected: Planet?
    let moves: Bool
    let pick: (Planet?) -> Void

    /// Where everything goes in a view of this size.
    struct Frame {
        let center: (x: Double, y: Double)
        let inner: Double
        let outer: Double
        let scale: Double

        init(_ size: CGSize) {
            let w = Double(size.width), h = Double(size.height)
            // Leave room for the bars above and below.
            outer = max(80, min(w - 40, h - 230) / 2)
            inner = outer * 0.16
            center = (w / 2, h / 2 + 8)
            scale = min(1.15, max(0.55, outer / 380))
        }
    }

    var body: some View {
        GeometryReader { geo in
            let frame = Frame(geo.size)
            TimelineView(.animation(minimumInterval: 1 / 30, paused: !clock.running && !moves)) { timeline in
                Canvas { ctx, size in
                    let real = timeline.date
                    let date = clock.date(at: real)
                    let t = moves ? real.timeIntervalSinceReferenceDate : 0
                    drawSunGlow(frame, t: t, in: ctx)
                    drawOrbits(frame, in: ctx)
                    drawTrails(frame, date: date, in: ctx)
                    drawEarthLine(frame, date: date, in: ctx)
                    for p in SolarSystem.everything {
                        drawPlanet(p, frame: frame, date: date, t: t, in: ctx)
                    }
                    drawMoon(frame, date: date, in: ctx)
                    drawSelection(frame, date: date, t: t, in: ctx)
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { tap in
                    let date = clock.date(at: Date())
                    let hit = SpaceMap.planet(near: (Double(tap.location.x), Double(tap.location.y)), at: date,
                                              center: frame.center, inner: frame.inner, outer: frame.outer, scale: frame.scale)
                    pick(hit)
                })
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Map of the solar system. Use the planet buttons below to pick one.")
    }

    private func cg(_ p: (x: Double, y: Double)) -> CGPoint { CGPoint(x: p.x, y: p.y) }

    private func drawSunGlow(_ f: Frame, t: Double, in ctx: GraphicsContext) {
        let pulse = 1 + 0.06 * sin(t * 1.3)
        let r = CGFloat(SpaceMap.dotRadius(SolarSystem.sun, scale: f.scale) * 3.2 * pulse)
        let c = cg(f.center)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                 with: .radialGradient(Gradient(colors: [Color(hex: 0xFFB43C).opacity(0.55), Color(hex: 0xFF7A1A).opacity(0.12), .clear]),
                                       center: c, startRadius: 0, endRadius: r))
    }

    private func drawOrbits(_ f: Frame, in ctx: GraphicsContext) {
        let c = cg(f.center)
        for p in SolarSystem.planets {
            let r = CGFloat(SpaceMap.radius(p.au, inner: f.inner, outer: f.outer))
            let picked = selected?.id == p.id
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                       with: .color(picked ? Color(hex: p.colors[0]).opacity(0.7) : .white.opacity(0.12)),
                       style: StrokeStyle(lineWidth: picked ? 2 : 1, dash: picked ? [] : [3, 5]))
        }
        // The asteroid belt, between Mars and Jupiter.
        let a = CGFloat(SpaceMap.radius(2.2, inner: f.inner, outer: f.outer))
        let b = CGFloat(SpaceMap.radius(3.2, inner: f.inner, outer: f.outer))
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - (a + b) / 2, y: c.y - (a + b) / 2, width: a + b, height: a + b)),
                   with: .color(Color(hex: 0xA89F91).opacity(0.1)), lineWidth: b - a)
    }

    /// A fading streak behind each planet: where it was over the last part of its trip.
    private func drawTrails(_ f: Frame, date: Date, in ctx: GraphicsContext) {
        let c = cg(f.center)
        for p in SolarSystem.planets {
            let r = CGFloat(SpaceMap.radius(p.au, inner: f.inner, outer: f.outer))
            let now = SolarSystem.longitude(p, at: date)
            let color = Color(hex: p.colors[0])
            let pieces = 14
            for i in 0..<pieces {
                let from = now - Double(i + 1) * 3, to = now - Double(i) * 3
                var path = Path()
                for k in 0...3 {
                    let a = (from + (to - from) * Double(k) / 3) * .pi / 180
                    let q = CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y - r * CGFloat(sin(a)))
                    if k == 0 { path.move(to: q) } else { path.addLine(to: q) }
                }
                ctx.stroke(path, with: .color(color.opacity(0.55 * (1 - Double(i) / Double(pieces)))),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
    }

    /// A dashed line from Earth to the planet you picked, with how long its light takes to get here.
    private func drawEarthLine(_ f: Frame, date: Date, in ctx: GraphicsContext) {
        guard let p = selected, p.id != "earth" else { return }
        let earth = cg(SpaceMap.point(SolarSystem.planets[2], at: date, center: f.center, inner: f.inner, outer: f.outer))
        let there = cg(SpaceMap.point(p, at: date, center: f.center, inner: f.inner, outer: f.outer))
        var line = Path()
        line.move(to: earth)
        line.addLine(to: there)
        ctx.stroke(line, with: .color(AceTheme.pebble.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
        let au = p.isSun ? 1.0 : SolarSystem.distanceFromEarth(p, at: date)
        let label = Text("Light: \(SolarSystem.lightTime(au))")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(AceTheme.pebble)
        let mid = CGPoint(x: (earth.x + there.x) / 2, y: (earth.y + there.y) / 2 - 12)
        var back = ctx
        back.addFilter(.shadow(color: .black, radius: 4))
        back.draw(label, at: mid)
    }

    private func drawPlanet(_ p: Planet, frame f: Frame, date: Date, t: Double, in ctx: GraphicsContext) {
        let at = cg(SpaceMap.point(p, at: date, center: f.center, inner: f.inner, outer: f.outer))
        let r = CGFloat(SpaceMap.dotRadius(p, scale: f.scale))
        let box = CGRect(x: at.x - r, y: at.y - r, width: r * 2, height: r * 2)
        // The Sun is in the middle, so each planet is lit from the side facing it.
        let toSun = SolarSystem.longitude(p, at: date) + 180
        PlanetBall.draw(p, in: box, sunAngle: p.isSun ? nil : toSun, spin: PlanetPanel.spin(p, t: t), ctx: ctx)
        guard !p.isSun else { return }
        let name = Text(p.name)
            .font(.system(size: 12, weight: selected?.id == p.id ? .heavy : .semibold, design: .rounded))
            .foregroundColor(selected?.id == p.id ? .white : AceTheme.muted)
        ctx.draw(name, at: CGPoint(x: at.x, y: at.y + r * (p.rings ? 0.75 : 1) + 10))
    }

    /// The Moon: a little dot circling Earth about once a month.
    private func drawMoon(_ f: Frame, date: Date, in ctx: GraphicsContext) {
        let earth = cg(SpaceMap.point(SolarSystem.planets[2], at: date, center: f.center, inner: f.inner, outer: f.outer))
        let a = SolarSystem.moonLongitude(at: date) * .pi / 180
        let reach = CGFloat(SpaceMap.dotRadius(SolarSystem.planets[2], scale: f.scale)) + 7
        let at = CGPoint(x: earth.x + reach * CGFloat(cos(a)), y: earth.y - reach * CGFloat(sin(a)))
        ctx.fill(Path(ellipseIn: CGRect(x: at.x - 2.5, y: at.y - 2.5, width: 5, height: 5)), with: .color(Color(hex: 0xE6E6EA)))
    }

    private func drawSelection(_ f: Frame, date: Date, t: Double, in ctx: GraphicsContext) {
        guard let p = selected else { return }
        let at = cg(SpaceMap.point(p, at: date, center: f.center, inner: f.inner, outer: f.outer))
        let base = CGFloat(SpaceMap.dotRadius(p, scale: f.scale)) + 8
        let grow = CGFloat(moves ? (sin(t * 3) + 1) * 3 : 0)
        let r = base + grow
        ctx.stroke(Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: r * 2, height: r * 2)),
                   with: .color(Color(hex: p.colors[0]).opacity(0.9)), lineWidth: 2)
    }
}
