//
//  HomeView.swift
//  AIEmotions
//
//  The app's root screen. Start of day: only "Write" is available. Once
//  the user completes today's single writing session (draft save OR
//  publish — see User.hasWrittenToday), "Write" gets scribbled out and
//  disabled, the tagline changes, and "Read" is revealed underneath.
//  Profile lives behind the top-right icon, classic-app style.
//
//  Visual styling (Theme + hardCard) ported from the "Writing" branch's
//  design; navigation/gating logic stays SwiftData-driven.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var user: User
    @State private var showWriting = false
    @State private var animateCaption = false
    @State private var showsCompletedDay = false

    private let motionStyle = MotionStyle.paperLift
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    ZStack(alignment: .leading) {
                        actionButton(
                            title: "Write",
                            icon: "pencil",
                            caption: showsCompletedDay
                                ? "Come back tomorrow to write something new!"
                                : "Start writing and see where it takes you!",
                            disabled: showsCompletedDay,
                            animateCaption: animateCaption // Pass the state here!
                        ) {
                            showWriting = true
                        }

                        if showsCompletedDay {
                            ScribbleOverlay()
                                .frame(height: 68)
                                .padding(.trailing, 6)
                                .padding(.bottom, 34)
                                .transition(motionStyle.revealTransition(reduceMotion: reduceMotion))

                            // The Invisible Tap Catcher!
                            Color.black.opacity(0.001)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    animateCaption.toggle() // Flips the state to trigger the spring
                                }
                        }
                    }

                    if showsCompletedDay {
                        actionButton(
                            title: "Read",
                            icon: "book.fill",
                            caption: "Discover a piece written by someone else!"
                        ) {
                            readDestinationTrigger = true
                        }
                        .transition(motionStyle.revealTransition(reduceMotion: reduceMotion))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 90)

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
            .onAppear {
                showsCompletedDay = user.hasWrittenToday
            }
            .onChange(of: showWriting) { _, isPresented in
                guard !isPresented else { return }
                withAnimation(motionStyle.animation(reduceMotion: reduceMotion)) {
                    showsCompletedDay = user.hasWrittenToday
                }
            }
            .onChange(of: user.hasWrittenToday) { _, hasWrittenToday in
                guard !showWriting else { return }
                withAnimation(motionStyle.animation(reduceMotion: reduceMotion)) {
                    showsCompletedDay = hasWrittenToday
                    if !hasWrittenToday {
                        animateCaption = false
                    }
                }
            }
        }
    }

    @State private var readDestinationTrigger = false

    private func actionButton(
        title: String,
        icon: String,
        caption: String,
        disabled: Bool = false,
        animateCaption: Bool = false, // 1. Add this parameter
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Button(action: action) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                    Text(title)
                        .fontWeight(.bold)
                }
                .font(.system(size: 20))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            }
            .hardCard()
            .padding(.trailing, 6)
            .padding(.bottom, 6)
            .disabled(disabled)

            Text(caption)
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                // 2. Add your custom animation modifiers right here!
                .scaleEffect(animateCaption && !reduceMotion ? 1.2 : 1)
                .shadow(color: .black.opacity(0.5), radius: animateCaption && !reduceMotion ? 10 : 0)
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.3), value: animateCaption)
        }
    }
}

#Preview("Fresh day") {
    HomeView(user: User())
        .modelContainer(for: [User.self, Post.self], inMemory: true)
}
