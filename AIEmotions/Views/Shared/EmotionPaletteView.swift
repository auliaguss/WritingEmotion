//
//  EmotionPaletteView.swift
//  AIEmotions
//
//  The raw per-emotion weight breakdown, as a bar chart. This used to be
//  what the live Profile screen showed directly. As of the AI-summary
//  pass, it's intentionally NOT part of the live user-facing screen
//  anymore — a numeric tally of someone's emotions reads like internal
//  analytics, not something to hand back to a writer who's here
//  specifically because they don't want to feel judged or measured.
//
//  It's kept here, extracted into its own reusable view, purely for
//  TestingProfileView (see Views/Testing) — this is what PromptManager
//  is actually biasing off of, and it's worth being able to see raw
//  during development even though users never will.
//

import SwiftUI

struct EmotionPaletteView: View {
    let emotionProfile: [String: Int]

    var body: some View {
        let total = max(emotionProfile.values.reduce(0, +), 1)
        let sorted = emotionProfile.sorted { $0.value > $1.value }

        VStack(alignment: .leading, spacing: 10) {
            Text("Emotional palette (internal only)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)

            ForEach(sorted, id: \.key) { emotion, count in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(emotion.capitalized)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(count)")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkMuted)
                    }
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.accent.opacity(0.25))
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.accent)
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat(total))
                            }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 2))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    EmotionPaletteView(emotionProfile: ["nostalgia": 6, "hope": 2, "unease": 1])
        .padding()
}
