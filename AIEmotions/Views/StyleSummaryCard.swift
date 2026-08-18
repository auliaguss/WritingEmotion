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

import SwiftUI

struct StyleSummaryCard: View {
    let user: User

    @State private var generator = StyleSummaryGenerator()

    private var publishedCount: Int {
        user.loadPublished().count
    }

    var body: some View {
        Group {
            if publishedCount == 0 {
                emptyState
            } else if let summary = generator.summary {
                summaryState(summary)
            } else {
                // This now catches the gap when publishedCount > 0
                // but the summary hasn't finished generating yet!
                loadingState
            }
        }
        .task(id: publishedCount) {
            await generator.refresh(for: user)
        }
    }

    private var emptyState: some View {
        card {
            Text("Publish your first piece and we'll start getting to know your voice.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkMuted)
        }
    }

    private var loadingState: some View {
        card {
            HStack(spacing: 8) {
                ProgressView()
                Text("Getting to know your voice…")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkMuted)
            }
        }
    }

    private func summaryState(_ text: String) -> some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("In your words")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
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
