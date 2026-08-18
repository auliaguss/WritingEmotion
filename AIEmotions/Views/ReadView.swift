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
//  Visual styling (Theme + hardCard) ported from the "Writing" branch.
//

import SwiftUI
import SwiftData

struct ReadView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Text("Reading other writers' pieces needs a backend to fetch from, which isn't built yet. For now, here's what you've published.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.tipText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.tipFill)

                PostListContent(user: user, mode: .published)
                    .scrollContentBackground(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
            Text("Read")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        ReadView(user: User())
    }
    .modelContainer(for: [User.self, Post.self], inMemory: true)
}
