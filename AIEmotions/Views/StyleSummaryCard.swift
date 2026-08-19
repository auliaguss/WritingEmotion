//
//  StyleSummaryCard.swift
//  AIEmotions
//
//  Live-facing replacement for the raw emotional-palette bars on
//  ProfileView: a short, personalized reflection generated on-device
//  from the writer's own recent published text (see
//  StyleSummaryGenerator). The underlying emotion tally still exists and
//  still drives prompt bias — it's just not shown to the user anymore.
//
//  Button-driven, not automatic: the writer taps Generate/Regenerate
//  themselves. The result is persisted on `User.styleSummaryText`, so it
//  stays exactly as-is — surviving relaunches — until they tap again.
//  The button is disabled whenever the latest 5 published posts are the
//  same ones the current summary was already generated from, so the
//  same 5 pieces can never quietly produce a different summary.
//
//  Also hosts a DEBUG-only "Wrapped (test)" button next to Generate —
//  see WrappedSummaryGenerator/WrappedSummaryView for that experiment.
//

import SwiftUI

struct StyleSummaryCard: View {
    @Bindable var user: User

    @State private var generator = StyleSummaryGenerator()
    #if DEBUG
    @State private var showWrapped = false
    #endif

    private var publishedCount: Int {
        user.loadPublished().count
    }

    private var canRegenerate: Bool {
        user.canRegenerateStyleSummary()
    }

    var body: some View {
        content
            #if DEBUG
            .sheet(isPresented: $showWrapped) {
                WrappedSummaryView(user: user)
            }
            #endif
    }

    @ViewBuilder
    private var content: some View {
        if publishedCount == 0 {
            emptyState
        } else {
            card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("In your words")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)

                    if generator.isGenerating {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Getting to know your voice…")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.inkMuted)
                        }
                    } else if let summary = user.styleSummaryText {
                        Text(summary)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Tap Generate and we'll put together a short reflection on your recent writing.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkMuted)
                    }

                    buttonRow
                }
            }
        }
    }

    private var buttonRow: some View {
        HStack(spacing: 10) {
            Button {
                Task { await generator.generate(for: user) }
            } label: {
                Text(user.styleSummaryText == nil ? "Generate" : "Regenerate")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
            }
            .hardCard(cornerRadius: 16, shadowOffset: 3)
            .disabled(generator.isGenerating || !canRegenerate)
            .opacity((generator.isGenerating || !canRegenerate) ? 0.5 : 1)

            #if DEBUG
            Button {
                showWrapped = true
            } label: {
                Text("Wrapped (test)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.card)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
            }
            .hardCard(fill: Theme.accent, cornerRadius: 16, shadowOffset: 3)
            #endif
        }
        .padding(.top, 4)
    }

    private var emptyState: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("In your words")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Publish your first piece and we'll start getting to know your voice.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkMuted)
            }
        }
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 5).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 2))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
