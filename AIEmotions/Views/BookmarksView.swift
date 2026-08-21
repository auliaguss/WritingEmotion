//
//  BookmarksView.swift
//  AIEmotions
//
//  Backend writings bookmarked locally on this device.
//

import SwiftUI
import SwiftData

struct BookmarksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.writingService) private var writingService
    @Bindable var user: User

    @State private var writings: [PublishedWritingPreview] = []
    @State private var readingItem: ReadableItem?
    @State private var isLoading = false
    @State private var isLoadingDetail = false
    @State private var loadError: String?

    private var bookmarkedWritings: [PublishedWritingPreview] {
        writings.filter { user.isWritingBookmarked($0.id) }
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

            if isLoadingDetail {
                Theme.overlay.ignoresSafeArea()
                ProgressView("Opening writing…")
                    .tint(Theme.ink)
                    .foregroundStyle(Theme.ink)
                    .padding(20)
                    .hardCard(cornerRadius: 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadWritings() }
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

    @ViewBuilder
    private var bookmarkGrid: some View {
        if isLoading {
            ProgressView("Loading bookmarks…")
                .tint(Theme.ink)
                .foregroundStyle(Theme.ink)
                .padding(.top, 40)
        } else if let loadError {
            VStack(spacing: 12) {
                Text(loadError)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.error)
                    .multilineTextAlignment(.center)
                Button("Try again") {
                    Task { await loadWritings() }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.ink)
            }
            .padding(.top, 40)
        } else if bookmarkedWritings.isEmpty {
            Text("No bookmarks yet — tap the bookmark icon on any writing to save it here.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkMuted)
                .padding(.top, 40)
                .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                ForEach(Array(bookmarkedWritings.enumerated()), id: \.element.id) { index, writing in
                    Button {
                        openWriting(writing)
                    } label: {
                        StickyNoteCard(
                            title: writing.prompt.fullText,
                            date: writing.publishedAt,
                            bodyPreview: writing.previewText,
                            emotions: writing.prompt.emotions,
                            color: stickyNoteColors[index % stickyNoteColors.count],
                            rotation: stickyNoteRotation(for: index)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func loadWritings() async {
        isLoading = true
        do {
            writings = try await writingService.fetchWritings(deviceID: user.deviceID)
            loadError = nil
        } catch is CancellationError {
            // The view disappeared while its task was running.
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func openWriting(_ preview: PublishedWritingPreview) {
        guard !isLoadingDetail else { return }
        isLoadingDetail = true
        Task {
            do {
                let writing = try await writingService.fetchWriting(id: preview.id, deviceID: user.deviceID)
                readingItem = .remote(writing)
                loadError = nil
            } catch {
                loadError = error.localizedDescription
            }
            isLoadingDetail = false
        }
    }
}

#Preview {
    NavigationStack {
        BookmarksView(user: User())
    }
    .modelContainer(for: [User.self, Post.self], inMemory: true)
}
