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
                ContentUnavailableView(mode.emptyMessage, systemImage: mode == .drafts ? "doc.text" : "tray.full")
            } else {
                List {
                    ForEach(posts) { post in
                        PostRow(post: post)
                    }
                    .onDelete { offsets in
                        if mode == .drafts {
                            deleteDrafts(at: offsets)
                        }
                    }
                }
                .listStyle(.plain)
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
    @Bindable var user: User
    let mode: PostListMode

    var body: some View {
        NavigationStack {
            PostListContent(user: user, mode: mode)
                .navigationTitle(mode.title)
        }
    }
}

struct PostRow: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(post.promptFullText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if post.isPublished, let date = post.publishedAt {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(post.textContent)
                .font(.body)
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
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
        .padding(.vertical, 4)
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
        prompt: PromptData(fullText: "Chasing fireflies through fog", verb: "Chasing", emotionData: "nostalgia, wonder"),
        photoData: nil,
        for: user,
        in: container.mainContext
    )
    return PostListView(user: user, mode: .drafts)
        .modelContainer(container)
}
