//
//  PostListView.swift
//  AIEmotions
//
//  Shared list UI for both a user's drafts and their published posts.
//  Split into `PostListContent` (just the list — reused inline inside
//  ProfileView's segmented Publish/Drafts toggle and inside ReadView)
//  and `PostListView` (a standalone screen with its own NavigationStack,
//  for anywhere that needs it pushed/presented on its own).
//
//  Visual styling (Theme + hardCard) ported from the "Writing" branch.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

enum PostListMode {
    case drafts, published

    var title: String {
        switch self {
        case .drafts: "Drafts"
        case .published: "Published"
        }
    }

    var emptyMessage: String {
        switch self {
        case .drafts: "No drafts yet — save one from Write."
        case .published: "Nothing published yet."
        }
    }
}

struct PostListContent: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var user: User
    let mode: PostListMode

    private var posts: [Post] {
        mode == .drafts ? user.loadDrafts() : user.loadPublished()
    }

    var body: some View {
        Group {
            if posts.isEmpty {
                Text(mode.emptyMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkMuted)
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(posts) { post in
                        PostRow(post: post)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    }
                    .onDelete { offsets in
                        if mode == .drafts {
                            deleteDrafts(at: offsets)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func deleteDrafts(at offsets: IndexSet) {
        let drafts = posts
        for index in offsets {
            modelContext.delete(drafts[index])
        }
    }
}

struct PostListView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User
    let mode: PostListMode

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        RoundBackButton { dismiss() }
                        Spacer()
                        Text(mode.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Color.clear.frame(width: 34, height: 34)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    PostListContent(user: user, mode: mode)
                        .padding(.horizontal, 20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct PostRow: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(post.promptFullText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkMuted)
                Spacer()
                if post.isPublished, let date = post.publishedAt {
                    Text(date, style: .date)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkMuted)
                }
            }

            Text(post.textContent)
                .font(.system(size: 14))
                .foregroundStyle(Theme.ink)
                .lineLimit(4)

            if let data = post.attachedImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .clipped()
            }

            HStack(spacing: 6) {
                ForEach(post.promptEmotions, id: \.self) { emotion in
                    Text(emotion)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.card))
                        .overlay(Capsule().stroke(Theme.ink.opacity(0.4), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink.opacity(0.4), lineWidth: 1.5))
    }
}

#Preview {
    let container = try! ModelContainer(
        for: User.self, Post.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let user = User()
    container.mainContext.insert(user)
    Post.saveAsDraft(
        text: "The fog rolled in just as I started running.",
        prompt: PromptData(fullText: "Chasing fireflies through fog", verb: "Chasing", emotionData: "nostalgia, wonder", coreEmotion: CoreEmotion.joy.rawValue),
        photoData: nil,
        for: user,
        in: container.mainContext
    )
    return PostListView(user: user, mode: .drafts)
        .modelContainer(container)
}
