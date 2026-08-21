//
//  ContentView.swift
//  AIEmotions
//
//  Ensures there's a single local User (created on first launch), then
//  hands off to HomeView — the actual root screen (Write / Read /
//  Profile). No TabView: Drafts and Published now live only inside
//  Profile. Shows a brief branded splash on launch.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showSplash = true

    var body: some View {
        Group {
            if let user = users.first {
                if user.age == nil {
                    AgeGateView { age in
                        user.confirmAge(age)
                    }
                } else {
                    HomeView(user: user)
                }
            } else {
                ProgressView()
                    .task { bootstrapUser() }
            }
        }
        .overlay {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeInOut(duration: 0.4)) {
                showSplash = false
            }
        }
    }

    private func bootstrapUser() {
        let user = User(deviceID: DeviceIdentity.current)
        modelContext.insert(user)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [User.self, Post.self], inMemory: true)
}
