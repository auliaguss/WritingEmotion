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
    @Bindable var user: User
    @State private var showWriting = false
    @State private var animateCaption = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    ZStack(alignment: .leading) {
                        actionButton(
                            title: "Write",
                            icon: "pencil",
                            caption: user.hasWrittenToday
                                ? "Come back tomorrow to write something new!"
                                : "Start writing and see where it takes you!",
                            disabled: user.hasWrittenToday,
                            animateCaption: animateCaption // Pass the state here!
                        ) {
                            showWriting = true
                        }

                        if user.hasWrittenToday {
                            ScribbleOverlay()
                                .frame(height: 68)
                                .padding(.trailing, 6)
                                .padding(.bottom, 34)
                                
                            // The Invisible Tap Catcher!
                            Color.black.opacity(0.001)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    animateCaption.toggle() // Flips the state to trigger the spring
                                }
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
                .scaleEffect(animateCaption ? 1.2 : 1)
                .shadow(color: .black.opacity(0.5), radius: animateCaption ? 10 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.3), value: animateCaption)
        }
    }
}

#Preview("Fresh day") {
    HomeView(user: User())
        .modelContainer(for: [User.self, Post.self], inMemory: true)
}
