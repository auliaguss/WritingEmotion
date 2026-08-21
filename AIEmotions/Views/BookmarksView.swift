//
//  BookmarksView.swift
//  AIEmotions
//
//  Standalone bookmarks screen, reached from the bookmark icon in
//  ReadView's header. Shows the same sticky-note grid as Profile's
//  Bookmark tab (StickyNoteCard) — this and Profile's tab are two
//  entry points to the same bookmarked sample notes.
//

import SwiftUI
import SwiftData

struct BookmarksView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User

    @State private var readingItem: ReadableItem?

    private var bookmarkedNotes: [SampleNote] {
        SampleNoteBank.all.filter { user.isSampleNoteBookmarked($0.id) }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    bookmarkGrid
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $readingItem) { item in
            ReadingModeView(user: user, item: item)
        }
    }

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
            Text("Bookmarks")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var bookmarkGrid: some View {
        Group {
            if bookmarkedNotes.isEmpty {
                Text("No bookmarks yet — tap the bookmark icon on any note to save it here.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkMuted)
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    ForEach(Array(bookmarkedNotes.enumerated()), id: \.element.id) { index, note in
                        Button {
                            readingItem = .sample(note)
                        } label: {
                            StickyNoteCard(
                                title: user.displayedWriting(note.prompt),
                                date: note.createdAt,
                                bodyPreview: user.displayedWriting(note.body),
                                emotions: note.emotions,
                                color: stickyNoteColors[index % stickyNoteColors.count],
                                rotation: stickyNoteRotation(for: index)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    let user = User()
    user.toggleSampleNoteBookmark(0)
    return NavigationStack {
        BookmarksView(user: user)
    }
    .modelContainer(for: [User.self, Post.self], inMemory: true)
}
