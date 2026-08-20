//
//  ReadingModeView.swift
//  AIEmotions
//
//  The single reading page for any piece of writing — your own published
//  Post, or a placeholder SampleNote from the Read wall / Bookmark tab.
//  Opened from three places (ReadView's corkboard, ProfileView's
//  Published grid, ProfileView's Bookmark grid) so it lives here instead
//  of three separate detail views.
//
//  "Read another" always surfaces a different SAMPLE note, never one of
//  your own posts — even if you opened this page from your own Published
//  piece, tapping it jumps into someone else's (placeholder) writing.
//

import SwiftUI
import SwiftData

/// Either kind of thing this page can display.
enum ReadableItem: Identifiable {
    case post(Post)
    case sample(SampleNote)

    var id: String {
        switch self {
        case .post(let post): "post-\(post.uniqueID)"
        case .sample(let note): "sample-\(note.id)"
        }
    }
}

struct ReadingModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var user: User
    @State private var current: ReadableItem
    @State private var contentVisible = false

    private let motionStyle = MotionStyle.paperLift

    init(user: User, item: ReadableItem) {
        self.user = user
        _current = State(initialValue: item)
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private var title: String {
        switch current {
        case .post(let post): post.promptFullText
        case .sample(let note): note.prompt
        }
    }

    private var bodyText: String {
        switch current {
        case .post(let post): post.textContent
        case .sample(let note): note.body
        }
    }

    private var emotions: [String] {
        switch current {
        case .post(let post): post.promptEmotions
        case .sample(let note): note.emotions
        }
    }

    private var date: Date {
        switch current {
        case .post(let post): post.publishedAt ?? post.createdAt
        case .sample(let note): note.createdAt
        }
    }

    private var bylineName: String {
        switch current {
        case .post: "You"
        case .sample: "anonymous"
        }
    }

    /// Bookmarking only applies to sample notes — not your own posts.
    private var isBookmarked: Bool {
        guard case .sample(let note) = current else { return false }
        return user.isSampleNoteBookmarked(note.id)
    }

    private func toggleBookmark() {
        guard case .sample(let note) = current else { return }
        user.toggleSampleNoteBookmark(note.id)
    }

    /// The sample note's id if `current` is one — used to exclude it from
    /// "Read another" candidates, and is nil while reading your own post.
    private var currentSampleID: Int? {
        if case .sample(let note) = current { return note.id }
        return nil
    }

    /// "Read another" (and the bookmark icon) only make sense for sample
    /// notes — hidden entirely while reading one of your own posts.
    private var isReadingSample: Bool {
        if case .sample = current { return true }
        return false
    }

    private var hasUnreadSamples: Bool {
        SampleNoteBank.all.contains { !user.isSampleNoteRead($0.id) && $0.id != currentSampleID }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            dotBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    noteCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }

                if isReadingSample {
                    readAnotherButton
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                }
            }
            .opacity(contentVisible ? 1 : 0)
            .scaleEffect(contentVisible || reduceMotion ? 1 : 0.96)
            .offset(y: contentVisible || reduceMotion ? 0 : 28)
            .rotationEffect(.degrees(contentVisible || reduceMotion ? 0 : 0.7))
        }
        .onAppear {
            markCurrentReadIfNeeded()
            withAnimation(motionStyle.animation(reduceMotion: reduceMotion)) {
                contentVisible = true
            }
        }
    }

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
            if isReadingSample {
                Button {
                    toggleBookmark()
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var noteCard: some View {
        VStack(spacing: 0) {
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12, style: .continuous)
                    .fill(Theme.accent.opacity(0.55))
                    .frame(height: 26)
                Circle()
                    .fill(Theme.ink)
                    .frame(width: 11, height: 11)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.accent)

                Text("\(bylineName) · \(Self.relativeFormatter.localizedString(for: date, relativeTo: .now))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent.opacity(0.8))

                Text(bodyText)
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !emotions.isEmpty {
                    dashedDivider
                    HStack(spacing: 8) {
                        ForEach(emotions, id: \.self) { emotion in
                            Text(emotion)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .overlay(Capsule().stroke(Theme.accent, lineWidth: 1.3))
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.ink, lineWidth: 2))
        .padding(.top, 6)
    }

    private var dashedDivider: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0))
            }
            .stroke(Theme.ink.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 1)
    }

    private var readAnotherButton: some View {
        Button(action: readAnother) {
            HStack(spacing: 8) {
                Image(systemName: "book")
                    .font(.system(size: 15, weight: .semibold))
                Text(hasUnreadSamples ? "Read another" : "All caught up!")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .hardCard(cornerRadius: 16, shadowOffset: 4)
        .disabled(!hasUnreadSamples)
        .opacity(hasUnreadSamples ? 1 : 0.6)
    }

    private var dotBackground: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 30
            let radius: CGFloat = 1.5
            let color = Theme.ink.opacity(0.12)
            let cols = Int(size.width / spacing)
            let rows = Int(size.height / spacing)
            for row in 0...rows {
                for col in 0...cols {
                    let origin = CGPoint(x: CGFloat(col) * spacing, y: CGFloat(row) * spacing)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: origin.x - radius, y: origin.y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(color)
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func markCurrentReadIfNeeded() {
        if case .sample(let note) = current {
            user.markSampleNoteRead(note.id)
        }
    }

    /// Always jumps to another sample note — deliberately never cycles
    /// through the user's own posts, regardless of what `current` is.
    private func readAnother() {
        let candidates = SampleNoteBank.all.filter { !user.isSampleNoteRead($0.id) && $0.id != currentSampleID }
        guard let next = candidates.randomElement() else { return }
        user.markSampleNoteRead(next.id)
        current = .sample(next)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: User.self, Post.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let user = User()
    container.mainContext.insert(user)
    return ReadingModeView(user: user, item: .sample(SampleNoteBank.all[0]))
        .modelContainer(container)
}
