import SwiftUI
import UIKit

/// One chat bubble, plus any cards and Ace's "How I got this" steps.
struct MessageRow: View {
    let message: ChatMessage
    @EnvironmentObject var core: AceCore
    @State private var showThoughts = false

    private var isUser: Bool { message.speaker == .user }
    /// Ace's words without any model thinking tags (older saved chats could still have them).
    private var shownText: String { isUser ? message.text : TextKit.stripModelTags(message.text) }
    private var hasContent: Bool { !shownText.isEmpty || !message.cards.isEmpty || message.imageFile != nil }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isUser { Spacer(minLength: 60) }
            if !isUser {
                OrbStill(mood: .idle, look: .zero)
                    .frame(width: 26, height: 26)
                    .padding(.top, 4)
            }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                if let file = message.imageFile, let image = UIImage(contentsOfFile: Persistence.imageURL(file).path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 260, maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                if !shownText.isEmpty {
                    Text(shownText)
                        .textSelection(.enabled)
                        .foregroundStyle(isUser ? Color.black : AceTheme.fg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubble)
                        .contextMenu {
                            Button { UIPasteboard.general.string = shownText } label: { Label("Copy", systemImage: "doc.on.doc") }
                            if !isUser {
                                Button { core.speak(shownText, cards: message.cards) } label: { Label("Read aloud", systemImage: "speaker.wave.2") }
                            }
                        }
                }
                ForEach(Array(message.cards.enumerated()), id: \.offset) { _, card in
                    CardView(card: card, messageID: message.id)
                        .frame(maxWidth: 560, alignment: .leading)
                }
                // "How I got this" only ever sits under its own message.
                if !message.thoughts.isEmpty, hasContent {
                    thoughtsView
                }
            }
            if !isUser { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private var bubble: some View {
        if isUser {
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AceTheme.ace)
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AceTheme.card)
        }
    }

    private var thoughtsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showThoughts.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "brain")
                    Text("How I got this")
                    if let s = message.source { Text("· \(s)").foregroundStyle(AceTheme.muted.opacity(0.7)) }
                    Image(systemName: showThoughts ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundStyle(AceTheme.muted)
            }
            .buttonStyle(.plain)
            if showThoughts {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(message.thoughts.enumerated()), id: \.offset) { i, t in
                        Text("\(i + 1). \(t)")
                            .font(.caption)
                            .foregroundStyle(AceTheme.muted)
                    }
                }
                .padding(.leading, 4)
            }
        }
    }
}
