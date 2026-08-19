//
//  TestingProfileView.swift
//  AIEmotions
//
//  Developer-only screen, entirely excluded from Release builds. Two
//  jobs:
//    1. "Refresh the day" — rewinds the once-per-day write lock, today's
//       generated prompt set, and discovery usage, so a new batch of
//       prompts can be generated and the whole daily loop re-tested
//       without waiting for midnight.
//    2. Shows the raw emotional-palette bars (EmotionPaletteView) that
//       the LIVE Profile screen no longer shows to users — this is what
//       PromptManager is actually biasing off of under the hood, useful
//       to see while testing even though it's intentionally hidden from
//       the real product experience (see StyleSummaryCard).
//
//  Reached via a debug-only icon on HomeView (also #if DEBUG-gated).
//

#if DEBUG
import SwiftUI
import SwiftData

struct TestingProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User

    @State private var didRefresh = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    refreshDayButton

                    dailyStateSummary

                    // Always shows all 8 CoreEmotion categories, with a
                    // "—" placeholder for any that don't have a weight
                    // yet — unlike the live top-3 view, this never hides
                    // rows, so it always reflects the full backend state.
                    EmotionPaletteView(emotionProfile: user.emotionProfile, mode: .allEmotions)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
            Text("Testing")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
    }

    private var refreshDayButton: some View {
        VStack(spacing: 6) {
            Button {
                user.debugRefreshDay()
                didRefresh = true
            } label: {
                Text("Refresh the day")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .hardCard(cornerRadius: 16, shadowOffset: 3)

            if didRefresh {
                Text("Day refreshed — go back and tap Write to generate a fresh set of prompts.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var dailyStateSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            row("Written today", user.hasWrittenToday ? "Yes (Write is locked)" : "No")
            row("Today's prompts", user.hasTodaysPrompts ? "\(user.todaysPrompts.count) generated" : "None generated yet")
            row("Discovery used today", user.hasUsedDiscoveryToday ? "Yes" : "No")
            row("Profile unlocked", user.isEmotionProfileUnlocked ? "Yes" : "No")
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 2))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkMuted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
    }
}

#Preview {
    let user = User(profileText: "Testing.", emotionProfile: ["joy": 6, "trust": 2])
    return NavigationStack {
        TestingProfileView(user: user)
    }
    .modelContainer(for: [User.self, Post.self], inMemory: true)
}
#endif
