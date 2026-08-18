//
//  ReadView.swift
//  AIEmotions
//
//  "Discover a piece written by someone else." — reading OTHER users'
//  published posts needs a backend to fetch from, which this build
//  intentionally doesn't have (see User.swift's readPublished note /
//  PROJECT.md). Until that exists, this shows the user's own published
//  posts as a stand-in, with an honest note about why.
//

import SwiftUI
import SwiftData

struct ReadView: View {
    @Bindable var user: User

    var body: some View {
        VStack(spacing: 0) {
            Text("Reading other writers' pieces needs a backend to fetch from, which isn't built yet. For now, here's what you've published.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))

            PostListContent(user: user, mode: .published)
        }
        .navigationTitle("Read")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ReadView(user: User())
    }
    .modelContainer(for: [User.self, Post.self], inMemory: true)
}
