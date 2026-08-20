//
//  WrappedSummaryView.swift
//  AIEmotions
//
//  DEBUG-only. Presented as a sheet from the "Wrapped (test)" button next
//  to the Generate button on the live ProfileView (the button itself is
//  #if DEBUG-gated, so this never ships in Release). Paged, Spotify-
//  Wrapped-style cards built from WrappedSummaryGenerator.
//
//  Scope for this first pass, per the test spec: top emotional aspects,
//  what/how they've written, bookmarks (placeholder — not implemented
//  anywhere yet), and how much they've written per emotion.
//

#if DEBUG
import SwiftUI

struct WrappedSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let user: User

    @State private var generator = WrappedSummaryGenerator()

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()

            VStack(spacing: 16) {
                header

                if generator.isGenerating {
                    Spacer()
                    ProgressView()
                        .tint(Theme.card)
                    Text("Putting your recap together…")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.card.opacity(0.7))
                    Spacer()
                } else if let wrapped = generator.wrapped {
                    TabView {
                        topEmotionsCard(wrapped)
                        writingStyleCard(wrapped)
                        wordCountsCard(wrapped)
                        bookmarksCard
                        closingCard(wrapped)
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                } else {
                    Spacer()
                    Text("Nothing to recap yet — publish a few pieces first.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.card.opacity(0.8))
                    Spacer()
                }
            }
        }
        .task {
            await generator.generate(for: user)
        }
    }

    private var header: some View {
        HStack {
            Text("Your Wrapped (test)")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.card)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.card)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(Theme.card, lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func wrappedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 2))
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private func topEmotionsCard(_ wrapped: GeneratedWrappedSummary) -> some View {
        wrappedCard {
            Text("Top emotional aspects")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.inkMuted)
            Text(wrapped.topEmotionsLine)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.ink)
            if !wrapped.topEmotions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(wrapped.topEmotions.enumerated()), id: \.element) { index, emotion in
                        Text("\(index + 1). \(emotion.capitalized)")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
        }
    }

    private func writingStyleCard(_ wrapped: GeneratedWrappedSummary) -> some View {
        wrappedCard {
            Text("What & how you've written")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.inkMuted)
            Text(wrapped.writingStyleLine)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
    }

    private func wordCountsCard(_ wrapped: GeneratedWrappedSummary) -> some View {
        wrappedCard {
            Text("How much, per emotion")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.inkMuted)
            let sorted = wrapped.wordCountsPerEmotion.sorted { $0.value > $1.value }
            if sorted.isEmpty {
                Text("No words logged yet.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkMuted)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(sorted, id: \.key) { emotion, count in
                        HStack {
                            Text(emotion.capitalized)
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(count) words")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.inkMuted)
                        }
                    }
                }
            }
        }
    }

    private var bookmarksCard: some View {
        wrappedCard {
            Text("Bookmarks")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.inkMuted)
            Text("Coming soon.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("This card is a placeholder — bookmarking isn't implemented yet.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkMuted)
        }
    }

    private func closingCard(_ wrapped: GeneratedWrappedSummary) -> some View {
        wrappedCard {
            Spacer()
            Text(wrapped.closingLine)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}

#Preview {
    let user = User(profileText: "Testing.", emotionProfile: ["joy": 6, "trust": 2])
    return WrappedSummaryView(user: user)
}
#endif
