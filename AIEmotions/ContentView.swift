//
//  ContentView.swift
//  AIEmotions
//
//  Ensures there's a single local User (created on first launch), then
//  hands off to HomeView — the actual root screen (Write / Read /
//  Profile). No TabView: Drafts and Published now live only inside
//  Profile.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    var body: some View {
        Group {
            if let user = users.first {
                HomeView(user: user)
            } else {
                ProgressView()
                    .task { bootstrapUser() }
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
