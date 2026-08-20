//
//  HomeView.swift
//  AIEmotions
//
//  The app's root screen. Start of day: only "Write" is available. Once
//  the user completes today's single writing session (draft save OR
//  publish — see User.hasWrittenToday), "Write" shows a gold lock and a
//  "come back in ..." countdown, and "Read" is revealed underneath.
//  Profile lives behind the top-right icon, classic-app style.
//
//  Visual styling (Theme + hardCard) ported from the "Writing" branch's
//  design; navigation/gating logic stays SwiftData-driven.
//
//  NOTE on the layout fix: the previous version placed an unconstrained
//  `Color` view ("invisible tap catcher") inside the ZStack to catch taps
//  on the disabled Write button. An unconstrained Color expands to fill
//  ALL remaining space given to its parent — that's what was stretching
//  the ZStack and shoving Read down to the bottom of the screen. Removed
//  entirely: the Button itself now stays enabled and branches on
//  `user.hasWrittenToday` inside its own action closure, so there's no
//  need for a second invisible tap target at all.
//

import SwiftUI
import SwiftData
internal import Combine

struct HomeView: View {
    @Bindable var user: User
    @State private var showWriting = false
    @State private var lockBounceTrigger = 0
    @State private var minuteTick = 0

    private static let minuteTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    actionButton(
                        title: "Write",
                        icon: "pencil",
                        caption: user.hasWrittenToday
                            ? "Come back in \(timeUntilNextDayString) to write something new!"
                            : "Start writing and see where it takes you!",
                        isLocked: user.hasWrittenToday,
                        bounceTrigger: lockBounceTrigger
                    ) {
                        if user.hasWrittenToday {
                            lockBounceTrigger += 1
                        } else {
                            showWriting = true
                        }
                    }

                    if user.hasWrittenToday {
                        actionButton(
                            title: "Read",
                            icon: "book.fill",
                            caption: "Discover a piece written by someone else!"
                        ) {
                            readDestinationTrigger = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 90)
                .animation(.easeInOut, value: user.hasWrittenToday)

                HStack {
                    #if DEBUG
                    NavigationLink {
                        TestingProfileView(user: user)
                    } label: {
                        Image(systemName: "ladybug.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Theme.card))
                            .overlay(Circle().stroke(Theme.ink, lineWidth: 2.5))
                    }
                    #endif

                    Spacer()
                    NavigationLink {
                        ProfileView(user: user)
                    } label: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Theme.card))
                            .overlay(Circle().stroke(Theme.ink, lineWidth: 2.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationDestination(isPresented: $readDestinationTrigger) {
                ReadView(user: user)
            }
            .fullScreenCover(isPresented: $showWriting) {
                WritingView(user: user)
            }
            .onReceive(Self.minuteTimer) { _ in
                // Forces the "come back in ..." caption to recompute and
                // stay accurate without the user needing to background/
                // foreground the app.
                minuteTick += 1
            }
        }
    }

    @State private var readDestinationTrigger = false

    /// Time remaining until the write-lock resets at the start of the
    /// next calendar day (matches User.hasWrittenToday's
    /// `Calendar.isDateInToday` check — this is a countdown to midnight,
    /// not a fixed duration after writing).
    private var timeUntilNextDayString: String {
        _ = minuteTick // read to establish a dependency for the periodic refresh
        let calendar = Calendar.current
        let now = Date()
        guard let startOfTomorrow = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else {
            return "tomorrow"
        }
        let totalMinutes = max(1, Int(startOfTomorrow.timeIntervalSince(now) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    private func actionButton(
        title: String,
        icon: String,
        caption: String,
        isLocked: Bool = false,
        bounceTrigger: Int = 0,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Button(action: action) {
                ZStack {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                        Text(title)
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.ink)
                    .opacity(isLocked ? 0.3 : 1)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color(red: 0.72, green: 0.56, blue: 0.14))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            }
            .hardCard()
            .padding(.trailing, 6)
            .padding(.bottom, 6)
            // Single-shot "big then small" pop, triggered once per tap —
            // replaces the old scale+shadow toggle, which needed two taps
            // (one to grow, one to shrink) since it flipped a plain Bool.
            // keyframeAnimator plays the whole grow→settle sequence every
            // time `bounceTrigger` changes, regardless of direction.
            .keyframeAnimator(initialValue: 1.0, trigger: bounceTrigger) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(1.12, duration: 0.12)
                    SpringKeyframe(1.0, duration: 0.28, spring: .bouncy)
                }
            }

            Text(caption)
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Fresh day") {
    HomeView(user: User())
        .modelContainer(for: [User.self, Post.self], inMemory: true)
}

#Preview("Already written") {
    let user = User()
    user.markWrittenToday()
    return HomeView(user: user)
        .modelContainer(for: [User.self, Post.self], inMemory: true)
}
