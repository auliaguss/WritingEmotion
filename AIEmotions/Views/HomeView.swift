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

import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var user: User
    @State private var showWriting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Spacer()

                ZStack {
                    Button {
                        showWriting = true
                    } label: {
                        Label("Write", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(user.hasWrittenToday)

                    if user.hasWrittenToday {
                        ScribbleOverlay()
                    }
                }
                .padding(.horizontal, 40)

                Text(user.hasWrittenToday
                     ? "Come back tomorrow to write something new!"
                     : "Start writing and see where it takes you!")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if user.hasWrittenToday {
                    NavigationLink {
                        ReadView(user: user)
                    } label: {
                        Label("Read", systemImage: "book")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                    Text("Discover a piece written by someone else!")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Spacer()
            }
            .animation(.easeInOut, value: user.hasWrittenToday)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ProfileView(user: user)
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                    }
                }
            }
            .fullScreenCover(isPresented: $showWriting) {
                WritingView(user: user)
            }
        }
    }
}

#Preview("Fresh day") {
    HomeView(user: User())
        .modelContainer(for: [User.self, Post.self], inMemory: true)
}
