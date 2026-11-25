import SwiftUI

/// One list: a colorful header with a glowing progress bar, rows whose ticks draw themselves in,
/// ticked things sinking to the bottom, and a box at the bottom to add more (paste a whole list at once).
struct ChecklistDetailView: View {
    @ObservedObject var store: ChecklistStore
    let listID: UUID

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var newText = ""
    @FocusState private var adding: Bool
    @State private var editMode: EditMode = .inactive
    @State private var renaming: ChecklistItem?
    @State private var renameText = ""
    @State private var cheers = 0
    @State private var showEditor = false
    @State private var confirmClear = false

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        ZStack {
            AceTheme.background.ignoresSafeArea()
            if let list = store.list(listID) {
                content(list)
            } else {
                Color.clear.onAppear { dismiss() }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func content(_ list: Checklist) -> some View {
        VStack(spacing: 0) {
            header(list)
            List {
                if list.items.isEmpty {
                    Text("Add the first thing below.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                ForEach(list.items) { item in
                    row(item, in: list)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 18))
                }
                .onDelete { offsets in
                    let ids = offsets.map { list.items[$0].id }
                    withAnimation(motion(.snappy)) {
                        for id in ids { store.remove(id, from: list.id) }
                    }
                }
                .onMove { source, destination in
                    store.move(in: list.id, from: source, to: destination)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $editMode)
            .animation(motion(.snappy), value: list.items)
            addBar(list)
        }
        .overlay(alignment: .top) {
            ChecklistCheer(trigger: cheers, tint: list.tint)
                .padding(.top, 120)
        }
        .sheet(isPresented: $showEditor) {
            ChecklistEditor(store: store, target: .edit(list)) { _ in }
        }
        .alert("Rename", isPresented: Binding(
            get: { renaming != nil },
            set: { if !$0 { renaming = nil } }
        )) {
            TextField("Thing to do", text: $renameText)
            Button("Save") {
                if let item = renaming { store.rename(item.id, in: list.id, to: renameText) }
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        } message: {
            Text("Leave it empty to delete it.")
        }
        .confirmationDialog("Delete every ticked thing?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Delete \(list.doneCount) ticked", role: .destructive) {
                withAnimation(motion(.snappy)) { store.clearDone(list.id) }
            }
        }
    }

    // MARK: Pieces

    private func header(_ list: Checklist) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                BouncyIconButton(symbol: "chevron.down", label: "Close") { dismiss() }
                Spacer()
                if !list.items.isEmpty {
                    Button(editMode == .active ? "Done" : "Reorder") {
                        withAnimation(motion(.snappy)) {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                }
                Menu {
                    Button { showEditor = true } label: { Label("Name, icon and color", systemImage: "pencil") }
                    Button {
                        withAnimation(motion(.snappy)) { store.reset(list.id) }
                    } label: { Label("Untick everything", systemImage: "arrow.counterclockwise") }
                        .disabled(list.doneCount == 0)
                    Button(role: .destructive) { confirmClear = true } label: { Label("Delete ticked things", systemImage: "trash") }
                        .disabled(list.doneCount == 0)
                    ShareLink(item: shareText(list)) { Label("Share list", systemImage: "square.and.arrow.up") }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .accessibilityLabel("More")
                }
            }
            HStack(spacing: 14) {
                Image(systemName: list.symbol)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.2)))
                    .symbolEffect(.bounce, value: list.isComplete)
                VStack(alignment: .leading, spacing: 3) {
                    Text(list.title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(list.isComplete ? "All done!" : "\(list.doneCount) of \(list.items.count) done")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .contentTransition(.numericText(value: list.progress))
                }
            }
            ChecklistBar(progress: list.progress, tint: list.tint)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(
            ZStack {
                list.tint.gradient
                Circle().fill(.white.opacity(0.18)).frame(width: 220).blur(radius: 50).offset(x: -140, y: -60)
                Image(systemName: list.symbol)
                    .font(.system(size: 150, weight: .bold))
                    .foregroundStyle(.white.opacity(0.1))
                    .rotationEffect(.degrees(-12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .offset(x: 30, y: 20)
            }
            .ignoresSafeArea(edges: .top)
        )
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30, style: .continuous))
        .shadow(color: list.tint.dark.opacity(0.4), radius: 20, y: 10)
    }

    private func row(_ item: ChecklistItem, in list: Checklist) -> some View {
        Button {
            toggle(item, in: list)
        } label: {
            HStack(spacing: 14) {
                ChecklistTick(done: item.done, tint: list.tint)
                Text(item.text)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .strikethrough(item.done, color: AceTheme.muted)
                    .foregroundStyle(item.done ? AceTheme.muted : AceTheme.fg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(item.done ? Color.white.opacity(0.03) : AceTheme.card)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.aceBouncy)
        .disabled(editMode == .active)
        .contextMenu {
            Button {
                renameText = item.text
                renaming = item
            } label: { Label("Rename", systemImage: "pencil") }
            Button(role: .destructive) {
                withAnimation(motion(.snappy)) { store.remove(item.id, from: list.id) }
            } label: { Label("Delete", systemImage: "trash") }
        }
        .accessibilityLabel(item.text)
        .accessibilityValue(item.done ? "Done" : "Not done")
        .accessibilityHint("Tap to \(item.done ? "untick" : "tick") it")
    }

    private func addBar(_ list: Checklist) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Add something (paste a whole list if you like)", text: $newText, axis: .vertical)
                .lineLimit(1...5)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .focused($adding)
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AceTheme.card))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(adding ? list.tint.light.opacity(0.7) : AceTheme.cardBorder, lineWidth: 1))
            Button {
                add(to: list)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(list.tint.gradient))
            }
            .buttonStyle(.aceBouncy)
            .disabled(ChecklistStore.cleanItems(newText.components(separatedBy: .newlines)).isEmpty)
            .accessibilityLabel("Add")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: Actions

    private func toggle(_ item: ChecklistItem, in list: Checklist) {
        let wasComplete = list.isComplete
        withAnimation(motion(.bouncy)) { store.toggle(item.id, in: list.id) }
        let nowComplete = store.list(list.id)?.isComplete ?? false
        if nowComplete && !wasComplete {
            cheers += 1
            Haptics.shared.play(.success)
            SoundFX.shared.play(.success)
        } else {
            Haptics.shared.play(.tick)
        }
    }

    private func add(to list: Checklist) {
        let added = withAnimation(motion(.bouncy)) { store.add(newText, to: list.id) }
        if added > 0 {
            newText = ""
            Haptics.shared.play(.pop)
        }
        adding = true
    }

    private func shareText(_ list: Checklist) -> String {
        ([list.title] + list.items.map { ($0.done ? "☑︎ " : "☐ ") + $0.text }).joined(separator: "\n")
    }
}
