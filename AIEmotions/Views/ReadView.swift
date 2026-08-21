//
//  ReadView.swift
//  AIEmotions
//
//  A pannable corkboard backed entirely by published writings from the
//  live backend. Bookmark and read state remains local on User.
//

import SwiftUI
import UIKit
import SwiftData

private struct NoteLayout {
    let position: CGPoint
    let rotation: Double
    let colorIndex: Int
}

private let noteColors: [Color] = [
    Color(hex: 0xFFF9C4),
    Color(hex: 0xFFCCBC),
    Color(hex: 0xC8E6C9),
    Color(hex: 0xBBDEFB),
    Color(hex: 0xE1BEE7),
    Color(hex: 0xFFE0B2),
    Color(hex: 0xB2DFDB),
    Color(hex: 0xF8BBD0),
]

private func layoutsForEntries(count: Int, rows: Int = 3) -> [NoteLayout] {
    let noteW: CGFloat = 180
    let noteH: CGFloat = 200
    let spacingX: CGFloat = 80
    let spacingY: CGFloat = 70
    let startX: CGFloat = 40
    let startY: CGFloat = 40

    return (0..<count).map { index in
        let row = index % rows
        let column = index / rows
        let baseX = startX + CGFloat(column) * (noteW + spacingX) + noteW / 2
        let baseY = startY + CGFloat(row) * (noteH + spacingY) + noteH / 2
        let jitterX = CGFloat((index * 37 + 13) % 15) - 7
        let jitterY = CGFloat((index * 23 + 7) % 13) - 6
        return NoteLayout(
            position: CGPoint(x: baseX + jitterX, y: baseY + jitterY),
            rotation: Double((index * 47 + 3) % 11) - 5,
            colorIndex: index % noteColors.count
        )
    }
}

private struct BoardItem: Identifiable {
    var id: String { writing.id }
    var writing: PublishedWritingPreview
    var layout: NoteLayout
    var yOffset: CGFloat = 0
    var opacity: Double = 1
    var scale: CGFloat = 1
}

struct ReadView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.writingService) private var writingService
    @Bindable var user: User

    @State private var readingItem: ReadableItem?
    @State private var boardItems: [BoardItem] = []
    @State private var isRefreshing = false
    @State private var isLoadingDetail = false
    @State private var loadError: String?

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDragging = false

    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()
            boardCanvas
            header

            if boardItems.isEmpty {
                emptyState
            }

            if isLoadingDetail {
                Theme.overlay.ignoresSafeArea()
                ProgressView("Opening writing…")
                    .tint(Theme.ink)
                    .foregroundStyle(Theme.ink)
                    .padding(20)
                    .hardCard(cornerRadius: 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard boardItems.isEmpty else { return }
            await loadBoard()
        }
        .onShake {
            refreshBoard()
        }
        .fullScreenCover(item: $readingItem) { item in
            ReadingModeView(user: user, item: item)
        }
    }

    // MARK: - Backend loading

    private func loadBoard() async {
        isRefreshing = true
        do {
            let writings = try await writingService.fetchWritings(deviceID: user.deviceID)
                .filter { $0.authorID != user.deviceID }
            loadError = nil
            apply(writings.shuffled(), animated: false)
        } catch is CancellationError {
            // The view disappeared while its task was running.
        } catch {
            loadError = error.localizedDescription
            boardItems = []
        }
        isRefreshing = false
    }

    private func openWriting(_ preview: PublishedWritingPreview) {
        guard !isLoadingDetail else { return }
        isLoadingDetail = true
        Task {
            do {
                let writing = try await writingService.fetchWriting(id: preview.id, deviceID: user.deviceID)
                loadError = nil
                readingItem = .remote(writing)
            } catch {
                loadError = error.localizedDescription
            }
            isLoadingDetail = false
        }
    }

    // MARK: - Refresh flow

    private func refreshBoard() {
        guard !isRefreshing, readingItem == nil else { return }
        isRefreshing = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let fallOrder = boardItems.indices.shuffled()
        let fallDuration = 0.45
        let staggerStep = 0.035
        let maxStaggerNotes = 18

        for (order, index) in fallOrder.enumerated() {
            let delay = staggerStep * Double(min(order, maxStaggerNotes))
            withAnimation(.easeIn(duration: fallDuration).delay(delay)) {
                boardItems[index].yOffset = 900
                boardItems[index].opacity = 0
                boardItems[index].scale = 0.9
            }
        }

        let totalFallTime = fallDuration + staggerStep * Double(min(fallOrder.count, maxStaggerNotes)) + 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + totalFallTime) {
            Task { await reloadBoard() }
        }
    }

    private func reloadBoard() async {
        do {
            let writings = try await writingService.fetchWritings(deviceID: user.deviceID)
                .filter { $0.authorID != user.deviceID }
            loadError = nil
            apply(writings.shuffled(), animated: true)
        } catch is CancellationError {
            isRefreshing = false
        } catch {
            loadError = error.localizedDescription
            boardItems = []
            isRefreshing = false
        }
    }

    private func apply(_ writings: [PublishedWritingPreview], animated: Bool) {
        let layouts = layoutsForEntries(count: writings.count)
        boardItems = zip(writings, layouts).map { writing, layout in
            BoardItem(
                writing: writing,
                layout: layout,
                yOffset: animated ? -500 : 0,
                opacity: animated ? 0 : 1,
                scale: animated ? 0.85 : 1
            )
        }

        offset = .zero
        lastOffset = .zero
        guard animated else { return }

        let entranceOrder = boardItems.indices.shuffled()
        let staggerStep = 0.05
        let maxStaggerNotes = 18
        for (order, index) in entranceOrder.enumerated() {
            let delay = staggerStep * Double(min(order, maxStaggerNotes))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72).delay(delay)) {
                boardItems[index].yOffset = 0
                boardItems[index].opacity = 1
                boardItems[index].scale = 1
            }
        }

        let totalEntranceTime = 0.5 + staggerStep * Double(min(entranceOrder.count, maxStaggerNotes))
        DispatchQueue.main.asyncAfter(deadline: .now() + totalEntranceTime) {
            isRefreshing = false
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
            Text("Read")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            NavigationLink {
                BookmarksView(user: user)
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            if isRefreshing {
                ProgressView()
                    .tint(Theme.ink)
            } else {
                Image(systemName: loadError == nil ? "pin.slash" : "wifi.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.inkMuted)
            }
            Text(loadError == nil ? "No writings available" : "Couldn't load writings")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text(loadError ?? "Check back after another writer publishes.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkMuted)
                .multilineTextAlignment(.center)
            if loadError != nil {
                Button("Try again") {
                    Task { await loadBoard() }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .hardCard(cornerRadius: 16, shadowOffset: 3)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var boardCanvas: some View {
        let canvasWidth: CGFloat = max(600, boardItems.map { $0.layout.position.x }.max().map { $0 + 120 } ?? 600)
        let canvasHeight: CGFloat = max(800, boardItems.map { $0.layout.position.y }.max().map { $0 + 160 } ?? 800)

        return GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                boardSurface(width: canvasWidth, height: canvasHeight)

                ForEach(boardItems) { item in
                    StickyNoteView(
                        writing: item.writing,
                        color: noteColors[item.layout.colorIndex],
                        rotation: item.layout.rotation,
                        isBookmarked: user.isWritingBookmarked(item.writing.id),
                        isRead: user.isWritingRead(item.writing.id),
                        isDragging: $isDragging
                    ) {
                        openWriting(item.writing)
                    }
                    .scaleEffect(item.scale)
                    .opacity(item.opacity)
                    .position(x: item.layout.position.x, y: item.layout.position.y + item.yOffset)
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)
            .scaleEffect(scale, anchor: .topLeading)
            .offset(offset)
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(magnifyGesture)
            .clipped()
        }
        .padding(.top, 60)
        .allowsHitTesting(!isRefreshing && !isLoadingDetail)
    }

    private func boardSurface(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, size in
            let dotSpacing: CGFloat = 30
            let dotRadius: CGFloat = 1.5
            let dotColor = Theme.ink.opacity(0.12)
            for row in 0...Int(size.height / dotSpacing) {
                for column in 0...Int(size.width / dotSpacing) {
                    let origin = CGPoint(x: CGFloat(column) * dotSpacing, y: CGFloat(row) * dotSpacing)
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: origin.x - dotRadius,
                            y: origin.y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2
                        )),
                        with: .color(dotColor)
                    )
                }
            }
        }
        .frame(width: width, height: height)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                isDragging = true
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isDragging = false
                }
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                isDragging = true
                let newScale = lastScale * value.magnification
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
                    scale = min(max(newScale, minScale), maxScale)
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    lastScale = scale
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isDragging = false
                }
            }
    }
}

private struct StickyNoteView: View {
    let writing: PublishedWritingPreview
    let color: Color
    let rotation: Double
    var isBookmarked = false
    var isRead = false
    @Binding var isDragging: Bool
    let onTap: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                if isRead {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.ink.opacity(0.45))
                }
                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.accent)
                }
                Spacer()
            }

            Spacer(minLength: 0)

            Text("\u{201C}\(writing.prompt.fullText)\u{201D}")
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineLimit(4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)

            Text(Self.dateFormatter.string(from: writing.publishedAt))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.ink.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
        .frame(width: 170, height: 190)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.1))
                    .offset(x: 3, y: 4)
                RoundedRectangle(cornerRadius: 4)
                    .fill(isRead ? color.opacity(0.55) : color)
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.ink.opacity(0.15), lineWidth: 0.5)
            }
        )
        .overlay(alignment: .top) {
            Image(systemName: "pin.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .rotationEffect(.degrees(-45))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 2)
                .offset(y: -14)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isDragging else { return }
            onTap()
        }
        .rotationEffect(.degrees(rotation))
        .zIndex(1)
    }
}

#Preview {
    NavigationStack {
        ReadView(user: User())
    }
    .modelContainer(for: [User.self, Post.self], inMemory: true)
}
