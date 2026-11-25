import SwiftUI

/// Every song, as cards with a little rainbow picture of the tune, your best stars,
/// and buttons to learn it or hear Ace play it.
struct PianoSongsSheet: View {
    let progress: PianoProgress
    let learn: (PianoSong) -> Void
    let listen: (PianoSong) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var shown = false

    private let columns = [GridItem(.adaptive(minimum: 230), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    summary
                        .bounceReveal(shown, order: 0)
                    ForEach(Array(PianoSong.Level.allCases.enumerated()), id: \.element) { group, level in
                        let songs = PianoSongs.all.filter { $0.level == level }
                        if !songs.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(level.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(AceTheme.fg)
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(Array(songs.enumerated()), id: \.element.id) { i, song in
                                        PianoSongCard(song: song, stars: progress.best(song.id), index: i,
                                                      learn: { learn(song) }, listen: { listen(song) })
                                            .bounceReveal(shown, order: group * 3 + i + 1)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle("Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { shown = true }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
    }

    private var summary: some View {
        let total = PianoSongs.all.count * 3
        return HStack(spacing: 14) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(AceTheme.pebble)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(progress.totalStars) of \(total) stars")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                Text(progress.songsLearned == 0
                     ? "Pick a song. Learn it one note at a time, or let Ace play it first."
                     : "\(progress.songsLearned) of \(PianoSongs.all.count) songs played. Get 3 stars on every one!")
                    .font(.subheadline)
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .aceCard()
    }
}

struct PianoSongCard: View {
    let song: PianoSong
    let stars: Int
    let index: Int
    let learn: () -> Void
    let listen: () -> Void
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tilt: Double {
        AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) ? [-1.6, 1.2, -0.8, 1.7][index % 4] : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MelodyStrip(song: song)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            HStack(alignment: .firstTextBaseline) {
                Text(song.title)
                    .font(.headline)
                    .foregroundStyle(AceTheme.fg)
                    .lineLimit(2)
                Spacer(minLength: 4)
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(i < stars ? AceTheme.pebble : .white.opacity(0.3))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(stars == 0 ? "Not played yet" : "Best: \(stars) of 3 stars")
            }
            Text("\(song.notes.count) notes · about \(Int(song.seconds.rounded())) seconds")
                .font(.caption)
                .foregroundStyle(AceTheme.muted)
            HStack(spacing: 8) {
                Button(action: learn) {
                    Label("Learn", systemImage: "graduationcap.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(AceTheme.ace))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.aceBouncy)
                .accessibilityLabel("Learn \(song.title)")
                Button(action: listen) {
                    Label("Listen", systemImage: "play.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.1)))
                        .foregroundStyle(AceTheme.fg)
                }
                .buttonStyle(.aceBouncy)
                .accessibilityLabel("Listen to \(song.title)")
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AceTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AceTheme.cardBorder, lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
        .rotationEffect(.degrees(tilt))
    }
}

/// The whole tune as a little picture: each note a colored bar, higher notes higher up.
struct MelodyStrip: View {
    let song: PianoSong

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.35)))
            let low = Double(song.lowest), span = Double(max(1, song.highest - song.lowest))
            let perBeat = size.width / CGFloat(max(1, song.beats))
            for note in song.notes {
                let x = CGFloat(note.beat) * perBeat
                let w = max(2, CGFloat(note.length) * perBeat - 1.5)
                let y = (1 - CGFloat((Double(note.midi) - low) / span)) * (size.height - 12) + 3
                let r = CGRect(x: x, y: y, width: w, height: 6)
                ctx.fill(Path(roundedRect: r, cornerRadius: 3), with: .color(PianoTheory.color(note.midi)))
            }
        }
        .accessibilityHidden(true)
    }
}
