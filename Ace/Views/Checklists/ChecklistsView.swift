import SwiftUI

/// Lists: packing lists, routines and to-dos. Each list is a colorful card with a progress bar.
/// Tap one to tick things off.
struct ChecklistsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = ChecklistStore.shared
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var opened: Checklist?
    @State private var editing: ChecklistEditTarget?
    @State private var deleting: Checklist?
    @State private var shown = false
    /// A list just made in the editor, opened once the editor has closed.
    @State private var openAfter: Checklist?

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        ZStack {
            AceTheme.background.ignoresSafeArea()
            glow
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topBar
                    if store.lists.isEmpty {
                        empty.bounceReveal(shown, order: 0)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
                            ForEach(Array(store.sorted.enumerated()), id: \.element.id) { index, list in
                                card(list)
                                    .bounceReveal(shown, order: index)
                            }
                        }
                    }
                    templates
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 40)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $opened) { list in
            ChecklistDetailView(store: store, listID: list.id)
        }
        .sheet(item: $editing, onDismiss: {
            // Open a brand-new list straight away so you can start adding things.
            if let list = openAfter {
                openAfter = nil
                opened = list
            }
        }) { target in
            ChecklistEditor(store: store, target: target) { made in openAfter = made }
        }
        .confirmationDialog("Delete this list?", isPresented: Binding(
            get: { deleting != nil },
            set: { if !$0 { deleting = nil } }
        ), titleVisibility: .visible, presenting: deleting) { list in
            Button("Delete \(list.title)", role: .destructive) {
                withAnimation(motion(.snappy)) { store.delete(list.id) }
                Haptics.shared.play(.tick)
            }
        }
        .onAppear { withAnimation(motion(.bouncy)) { shown = true } }
    }

    // MARK: Pieces

    private var glow: some View {
        let first = store.sorted.first?.tint ?? .purple
        return ZStack {
            Circle().fill(first.dark.opacity(0.3)).frame(width: 520, height: 520).blur(radius: 130).offset(x: -180, y: -280)
            Circle().fill(AceTheme.ace.opacity(0.18)).frame(width: 440, height: 440).blur(radius: 130).offset(x: 220, y: 300)
        }
        .animation(motion(.gentle), value: first)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close") { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Lists")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Text("Packing lists, routines and to-dos")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer()
            Button {
                Haptics.shared.play(.pop)
                editing = .new
            } label: {
                Label("New", systemImage: "plus")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AceTheme.accent))
            }
            .buttonStyle(.aceBouncy)
            .accessibilityLabel("New list")
        }
        .padding(.top, 14)
    }

    private func card(_ list: Checklist) -> some View {
        Button {
            Haptics.shared.play(.pop)
            opened = list
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Image(systemName: list.symbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(list.tint.gradient))
                        .rotationEffect(.degrees(-6))
                        .shadow(color: list.tint.dark.opacity(0.6), radius: 10, y: 5)
                    Spacer()
                    if list.isComplete {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(list.tint.light)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(list.title)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                    .lineLimit(1)
                Text(list.items.isEmpty ? "Nothing on it yet" : "\(list.doneCount) of \(list.items.count) done")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
                ChecklistBar(progress: list.progress, tint: list.tint, height: 10)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AceTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(list.isComplete ? list.tint.light.opacity(0.6) : AceTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.96))
        .contextMenu {
            Button { opened = list } label: { Label("Open", systemImage: "list.bullet") }
            Button { editing = .edit(list) } label: { Label("Edit", systemImage: "pencil") }
            Button {
                withAnimation(motion(.bouncy)) { _ = store.duplicate(list.id) }
            } label: { Label("Make a copy", systemImage: "plus.square.on.square") }
            Button {
                withAnimation(motion(.snappy)) { store.reset(list.id) }
            } label: { Label("Untick everything", systemImage: "arrow.counterclockwise") }
                .disabled(list.doneCount == 0)
            Button(role: .destructive) { deleting = list } label: { Label("Delete", systemImage: "trash") }
        }
        .accessibilityLabel("\(list.title), \(list.doneCount) of \(list.items.count) done")
    }

    private var empty: some View {
        VStack(spacing: 14) {
            Image(systemName: "checklist")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(ListTint.purple.gradient)
            Text("No lists yet")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            Text("Make a packing list, a morning routine or a to-do list, or start from one below.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .aceCard(padding: 0)
    }

    private var templates: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start from")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ChecklistTemplate.all) { template in
                        Button {
                            Haptics.shared.play(.success)
                            let made = store.create(from: template)
                            opened = made
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: template.symbol)
                                    .font(.system(size: 22, weight: .bold))
                                Text(template.title)
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                Text("\(template.items.count) things")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .opacity(0.85)
                            }
                            .foregroundStyle(.white)
                            .padding(14)
                            .frame(width: 150, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(template.tint.gradient))
                            .shadow(color: template.tint.dark.opacity(0.4), radius: 10, y: 6)
                        }
                        .buttonStyle(.aceBouncy)
                        .accessibilityLabel("New \(template.title) list")
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollClipDisabled()
        }
    }
}

/// What the list editor is for: a new list, or changing one.
enum ChecklistEditTarget: Identifiable {
    case new
    case edit(Checklist)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let list): return list.id.uuidString
        }
    }
}
