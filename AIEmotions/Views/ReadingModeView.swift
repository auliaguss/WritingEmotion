//
//  ReadingModeView.swift
//  AIEmotions
//
//  Reading page for either the user's local Post or a writing fetched
//  from the backend.
//

import SwiftUI
import SwiftData

enum ReadableItem: Identifiable {
    case post(Post)
    case remote(PublishedWritingResponse)

    var id: String {
        switch self {
        case .post(let post): "post-\(post.uniqueID)"
        case .remote(let writing): "remote-\(writing.id)"
        }
    }
}

struct ReadingModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.writingService) private var writingService
    @Bindable var user: User
    @State private var current: ReadableItem
    @State private var remoteWritings: [PublishedWritingPreview] = []
    @State private var isLoadingNext = false
    @State private var loadError: String?

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
        case .remote(let writing): writing.prompt.fullText
        }
    }

    private var bodyText: String {
        switch current {
        case .post(let post): post.textContent
        case .remote(let writing): writing.fullText
        }
    }

    private var emotions: [String] {
        switch current {
        case .post(let post): post.promptEmotions
        case .remote(let writing): writing.prompt.emotions
        }
    }

    private var date: Date {
        switch current {
        case .post(let post): post.publishedAt ?? post.createdAt
        case .remote(let writing): writing.publishedAt
        }
    }

    private var bylineName: String {
        switch current {
        case .post: "You"
        case .remote: "anonymous"
        }
    }

    private var currentRemoteID: String? {
        if case .remote(let writing) = current {
            return writing.id
        }
        return nil
    }

    private var isReadingRemote: Bool {
        if case .remote = current {
            return true
        }
        return false
    }

    private var isBookmarked: Bool {
        guard let currentRemoteID else { return false }
        return user.isWritingBookmarked(currentRemoteID)
    }

    private var unreadRemoteWritings: [PublishedWritingPreview] {
        remoteWritings.filter {
            $0.id != currentRemoteID && !user.isWritingRead($0.id)
        }
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

                if isReadingRemote {
                    readAnotherButton
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                }
            }
        }
        .task {
            markCurrentReadIfNeeded()
            guard isReadingRemote else { return }
            await loadRemoteWritings()
        }
    }

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
            if isReadingRemote {
                Button {
                    guard let currentRemoteID else { return }
                    user.toggleWritingBookmark(currentRemoteID)
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
                }
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark writing")
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
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
            }
            .stroke(Theme.ink.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 1)
    }

    private var readAnotherButton: some View {
        VStack(spacing: 8) {
            if let loadError {
                Text(loadError)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.error)
                    .multilineTextAlignment(.center)
            }

            Button(action: readAnother) {
                HStack(spacing: 8) {
                    if isLoadingNext {
                        ProgressView()
                            .tint(Theme.ink)
                    } else {
                        Image(systemName: "book")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(unreadRemoteWritings.isEmpty ? "All caught up!" : "Read another")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .hardCard(cornerRadius: 16, shadowOffset: 4)
            .disabled(unreadRemoteWritings.isEmpty || isLoadingNext)
            .opacity(unreadRemoteWritings.isEmpty ? 0.6 : 1)
        }
    }

    private var dotBackground: some View {
        Canvas { context, size in
            let spacing: CGFloat = 30
            let radius: CGFloat = 1.5
            let color = Theme.ink.opacity(0.12)
            for row in 0...Int(size.height / spacing) {
                for column in 0...Int(size.width / spacing) {
                    let origin = CGPoint(x: CGFloat(column) * spacing, y: CGFloat(row) * spacing)
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: origin.x - radius,
                            y: origin.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )),
                        with: .color(color)
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func loadRemoteWritings() async {
        do {
            remoteWritings = try await writingService.fetchWritings(deviceID: user.deviceID)
                .filter { $0.authorID != user.deviceID }
            loadError = nil
        } catch is CancellationError {
            // The view disappeared while its task was running.
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func markCurrentReadIfNeeded() {
        guard let currentRemoteID else { return }
        user.markWritingRead(currentRemoteID)
    }

    private func readAnother() {
        guard let next = unreadRemoteWritings.randomElement(), !isLoadingNext else { return }
        isLoadingNext = true
        loadError = nil
        Task {
            do {
                let writing = try await writingService.fetchWriting(id: next.id, deviceID: user.deviceID)
                user.markWritingRead(writing.id)
                withAnimation(.easeInOut(duration: 0.25)) {
                    current = .remote(writing)
                }
            } catch {
                loadError = error.localizedDescription
            }
            isLoadingNext = false
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: User.self, Post.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let user = User()
    container.mainContext.insert(user)
    let post = Post(
        deviceID: user.deviceID,
        textContent: "A locally published writing.",
        prompt: PromptData(
            fullText: "Chasing fireflies through fog",
            verb: "Chasing",
            emotionData: "nostalgia, wonder",
            coreEmotion: CoreEmotion.joy.rawValue
        ),
        isPublished: true
    )
    return ReadingModeView(user: user, item: .post(post))
        .modelContainer(container)
}
