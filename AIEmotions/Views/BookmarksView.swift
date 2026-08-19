//
//  BookmarksView.swift
//  AIEmotions
//
//  Ported from the "Writing" branch's read-another-logic prototype,
//  adapted from AppStore/WritingEntry to User/SampleNoteBank. Lists the
//  sample notes (see SampleNoteBank, ReadView) the user has bookmarked
//  from the Read corkboard — looked up by their stable pool id, so a
//  bookmark stays visible here even if that note isn't in the board's
//  current random batch.
//

import SwiftUI
import SwiftData

struct BookmarksView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User

    @State private var selectedNote: SampleNote?

    private var bookmarkedNotes: [SampleNote] {
        SampleNoteBank.all.filter { user.isSampleNoteBookmarked($0.id) }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if bookmarkedNotes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(bookmarkedNotes) { note in
                                bookmarkRow(note)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedNote) { note in
            BookmarkDetailSheet(note: note, user: user)
        }
    }

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
            Text("Bookmarks")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 40))
                .foregroundStyle(Theme.inkMuted)
            Text("No bookmarks yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("Tap the bookmark icon on any note to save it here.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func bookmarkRow(_ note: SampleNote) -> some View {
        Button {
            selectedNote = note
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\u{201C}\(note.prompt)\u{201D}")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Text(note.createdAt, style: .date)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        user.toggleSampleNoteBookmark(note.id)
                    }
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ink.opacity(0.4), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

private struct BookmarkDetailSheet: View {
    let note: SampleNote
    @Bindable var user: User
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(note.createdAt, style: .date)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.inkMuted)
                    Spacer()
                    Button {
                        user.toggleSampleNoteBookmark(note.id)
                    } label: {
                        Image(systemName: user.isSampleNoteBookmarked(note.id) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.card))
                            .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
                    }
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.card))
                            .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
                    }
                }

                ScrollView {
                    Text(note.body)
                        .font(.system(size: 18, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
