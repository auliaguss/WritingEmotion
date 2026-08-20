//
//  EmotionPaletteView.swift
//  AIEmotions
//
//  The per-CORE-emotion weight breakdown, as a bar chart. Keys are always
//  one of CoreEmotion's 8 strict categories (see CoreEmotion.swift) —
//  never the freeform creative text a prompt shows the user.
//
//  Two display modes now:
//    - `.topThree` — what the LIVE ProfileView shows, above the
//      AI-generated reflection. Only emotions actually written from
//      (count > 0) appear, capped at the top 3. If nothing's been
//      written yet, this renders as an empty state — never 3 empty
//      placeholder bars. If only 1 emotion has been written, exactly 1
//      bar shows, not padded out with 2 blank ones.
//    - `.allEmotions` — DEBUG-only, used by TestingProfileView. Always
//      shows all 8 CoreEmotion categories regardless of whether they've
//      been written from, with a nil/blank count for the ones that
//      haven't — this is what PromptManager is actually biasing off of,
//      worth seeing in full during development even though users only
//      ever see the curated top-3 version.
//

import SwiftUI

struct EmotionPaletteView: View {
    enum DisplayMode {
        case topThree
        case allEmotions
    }

    let emotionProfile: [String: Int]
    var mode: DisplayMode = .topThree

    private struct Entry {
        let label: String
        let count: Int?
    }

    private var entries: [Entry] {
        switch mode {
        case .topThree:
            return emotionProfile
                .filter { $0.value > 0 }
                .sorted { $0.value > $1.value }
                .prefix(3)
                .map { Entry(label: $0.key, count: $0.value) }
        case .allEmotions:
            return CoreEmotion.allCases.map { emotion in
                Entry(label: emotion.rawValue, count: emotionProfile[emotion.rawValue])
            }
        }
    }

    private var title: String {
        switch mode {
        case .topThree: "Your emotional palette"
        case .allEmotions: "Core emotion palette (internal only)"
        }
    }

    var body: some View {
        let maxCount = max(entries.compactMap(\.count).max() ?? 0, 1)

        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)

            if entries.isEmpty {
                Text("Nothing here yet — write something to start filling this in.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkMuted)
            } else {
                ForEach(entries, id: \.label) { entry in
                    row(entry, maxCount: maxCount)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 2))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ entry: Entry, maxCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.label.capitalized)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(entry.count.map(String.init) ?? "—")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkMuted)
            }
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.accent.opacity(0.25))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * CGFloat(entry.count ?? 0) / CGFloat(maxCount))
                    }
            }
            .frame(height: 8)
        }
    }
}

#Preview("Top 3 — live") {
    EmotionPaletteView(emotionProfile: ["joy": 6, "trust": 2, "fear": 1, "sadness": 4], mode: .topThree)
        .padding()
}

#Preview("Top 3 — one emotion only") {
    EmotionPaletteView(emotionProfile: ["joy": 3], mode: .topThree)
        .padding()
}

#Preview("Top 3 — empty") {
    EmotionPaletteView(emotionProfile: [:], mode: .topThree)
        .padding()
}

#Preview("All emotions — debug") {
    EmotionPaletteView(emotionProfile: ["joy": 6, "trust": 2], mode: .allEmotions)
        .padding()
}
