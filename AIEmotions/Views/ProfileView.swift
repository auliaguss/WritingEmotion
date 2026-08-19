//
//  ProfileView.swift
//  AIEmotions
//
//  Profile now also hosts Drafts/Published/Bookmark — there's no separate
//  tab bar anymore, so this is the only place those live, switched via a
//  segmented "Publish (n) / Drafts (n) / Bookmark (n)" toggle. Published
//  and Bookmark render as a sticky-note grid (StickyNoteCard); Drafts
//  stays a plain editable list (PostListContent) since a draft is still
//  in progress rather than a finished piece.
//
//  Bookmarks used to have their own standalone screen reachable from
//  ReadView's header — consolidated in here instead, so there's one
//  place to see them, not two.
//
//  Visual styling (Theme + hardCard) ported from the "Writing" branch.
//

import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
import SwiftData
#endif

private enum ProfileTab {
    case published, drafts, bookmarks
}

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User

    @State private var photoItem: PhotosPickerItem?
    @State private var draftBio: String = ""
    @State private var isEditing = false
    @State private var selectedTab: ProfileTab = .published
    @State private var selectedDraft: Post?
    @State private var readingItem: ReadableItem?

    /// nil means "All". Otherwise the first-of-month date for the
    /// selected month, used both as the picker's identity and to group
    /// published posts by calendar month.
    @State private var selectedMonth: Date?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        avatar
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                user.updateProfile(newBio: user.profileText, newPictureData: data)
                            }
                        }
                    }

                    VStack(spacing: 10) {
                        if isEditing {
                            TextField("Say something about your writing…", text: $draftBio, axis: .vertical)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.ink)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 1.5))

                            Button {
                                user.updateProfile(newBio: draftBio, newPictureData: user.profilePictureData)
                                isEditing = false
                            } label: {
                                Text("Save")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            }
                            .hardCard(cornerRadius: 16, shadowOffset: 3)
                        } else {
                            Text(user.profileText.isEmpty ? "Lorem ipsum" : user.profileText)
                                .font(.system(size: 13))
                                .foregroundStyle(user.profileText.isEmpty ? Theme.inkMuted : Theme.ink)
                                .multilineTextAlignment(.center)

                            Button {
                                draftBio = user.profileText
                                isEditing = true
                            } label: {
                                Text("Edit bio")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            }
                            .hardCard(cornerRadius: 16, shadowOffset: 3)
                        }
                    }
                    .padding(.horizontal, 32)

                    EmotionPaletteView(emotionProfile: user.emotionProfile, mode: .topThree)

                    StyleSummaryCard(user: user)

                    modeToggle

                    if selectedTab == .published {
                        monthFilter
                    }

                    tabContent
                        .frame(minHeight: 200)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $selectedDraft) { draft in
            WritingView(user: user, draft: draft)
        }
        .fullScreenCover(item: $readingItem) { item in
            ReadingModeView(user: user, item: item)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .drafts:
            PostListContent(user: user, mode: .drafts) { draft in
                selectedDraft = draft
            }
        case .published:
            publishedGrid
        case .bookmarks:
            bookmarkGrid
        }
    }

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
            Text("My Profile")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
    }

    private var avatar: some View {
        Group {
            if let data = user.profilePictureData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Theme.card)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Theme.ink)
                    )
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.ink, lineWidth: 3.5))
    }

    private var modeToggle: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                toggleButton("Publish (\(user.loadPublished().count))", tab: .published)
                toggleButton("Drafts (\(user.loadDrafts().count))", tab: .drafts)
                toggleButton("Bookmark (\(bookmarkedNotes.count))", tab: .bookmarks)
            }
            .padding(.horizontal, 1) // keeps the hardCard-less pill strokes from clipping at the scroll edges
        }
    }

    private func toggleButton(_ title: String, tab: ProfileTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.card : Theme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.ink : Theme.card)
                        .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5))
                )
        }
    }

    // MARK: - Month filter (Published)

    private static let monthKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    /// The first-of-month date for each distinct month a post was
    /// published in, most recent first — used both as the dropdown's
    /// options and as the grouping key for `publishedGrid`.
    private var availableMonths: [Date] {
        let calendar = Calendar.current
        let starts = Set(user.loadPublished().map { post in
            let date = post.publishedAt ?? post.createdAt
            let comps = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: comps) ?? date
        })
        return starts.sorted(by: >)
    }

    private var monthFilter: some View {
        HStack(spacing: 10) {
            Text("Filter by:")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.inkMuted)

            Menu {
                Button("All") { selectedMonth = nil }
                ForEach(availableMonths, id: \.self) { month in
                    Button(Self.monthKeyFormatter.string(from: month)) {
                        selectedMonth = month
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedMonth.map(Self.monthKeyFormatter.string(from:)) ?? "All")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.card))
                .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5))
            }
            Spacer()
        }
    }

    // MARK: - Published grid

    private var filteredPublished: [Post] {
        let posts = user.loadPublished()
        guard let selectedMonth else { return posts }
        let calendar = Calendar.current
        return posts.filter { post in
            calendar.isDate(post.publishedAt ?? post.createdAt, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var publishedGrid: some View {
        Group {
            if filteredPublished.isEmpty {
                Text(user.loadPublished().isEmpty ? "Nothing published yet." : "Nothing published in this month.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkMuted)
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    ForEach(Array(filteredPublished.enumerated()), id: \.element.uniqueID) { index, post in
                        Button {
                            readingItem = .post(post)
                        } label: {
                            StickyNoteCard(
                                title: post.promptFullText,
                                date: post.publishedAt ?? post.createdAt,
                                bodyPreview: post.textContent,
                                emotions: post.promptEmotions,
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

    // MARK: - Bookmark grid

    private var bookmarkedNotes: [SampleNote] {
        SampleNoteBank.all.filter { user.isSampleNoteBookmarked($0.id) }
    }

    private var bookmarkGrid: some View {
        Group {
            if bookmarkedNotes.isEmpty {
                Text("No bookmarks yet — tap the bookmark icon on any note in Read to save it here.")
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
                                title: note.prompt,
                                date: note.createdAt,
                                bodyPreview: note.body,
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
    let user = User(profileText: "Writing my way through feelings.", emotionProfile: ["joy": 4, "trust": 2, "fear": 1])
    return NavigationStack {
        ProfileView(user: user)
    }
    .modelContainer(for: [User.self, Post.self], inMemory: true)
}
