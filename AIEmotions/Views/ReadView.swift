//
//  ReadView.swift
//  AIEmotions
//
//  "Discover a piece written by someone else." Reading OTHER users'
//  published posts needs a backend to fetch from, which this build
//  intentionally doesn't have (see User.swift's readPublished note /
//  PROJECT.md) — so this corkboard is populated from SampleNoteBank, a
//  fixed pool of placeholder "other writer" notes, not real people.
//
//  Ported from the "Writing" branch's read-another-logic prototype:
//  a pannable/zoomable board of sticky notes, shake-to-reshuffle, tap a
//  note to read it full-size with a bookmark toggle and a "Read Another
//  Note" shortcut. The original prototype kept swapping the user's real
//  published posts out for fake ones on every shake — SampleNoteBank
//  fixes that by construction: this view never reads or writes `Post`
//  or `user.posts` at all, only the fixed sample pool and the
//  bookmark/read tracking on `User` (see SampleNoteBank.swift).

import SwiftUI
import UIKit
import SwiftData

private struct NoteLayout {
    let position: CGPoint
    let rotation: Double
    let colorIndex: Int
}

private let noteColors: [Color] = [
    Color(hex: 0x9BF6FF),
    Color(hex: 0xA0C4FF),
    Color(hex: 0xBDB2FF),
    Color(hex: 0xCAFFBF),
    Color(hex: 0xFDFFB6),
    Color(hex: 0xFFADAD),
    Color(hex: 0xFFC6FF),
    Color(hex: 0xFFD6A5),
]

private func layoutsForEntries(count: Int, rows: Int = 3) -> [NoteLayout] {
    let noteW: CGFloat = 180
    let noteH: CGFloat = 200
    let spacingX: CGFloat = 80
    let spacingY: CGFloat = 70
    let startX: CGFloat = 40
    let startY: CGFloat = 40

    return (0..<count).map { i in
        let row = i % rows
        let col = i / rows
        let baseX = startX + CGFloat(col) * (noteW + spacingX) + noteW / 2
        let baseY = startY + CGFloat(row) * (noteH + spacingY) + noteH / 2
        let jitterX = CGFloat((i * 37 + 13) % 15) - 7
        let jitterY = CGFloat((i * 23 + 7) % 13) - 6
        let rotation = Double((i * 47 + 3) % 11) - 5
        let colorIdx = i % noteColors.count
        return NoteLayout(
            position: CGPoint(x: baseX + jitterX, y: baseY + jitterY),
            rotation: rotation,
            colorIndex: colorIdx
        )
    }
}

private struct BoardItem: Identifiable {
    var id: Int { note.id }
    var note: SampleNote
    var layout: NoteLayout
    var yOffset: CGFloat = 0
    var opacity: Double = 1
    var scale: CGFloat = 1
}

struct ReadView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User

    @State private var readingItem: ReadableItem?

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDragging = false

    @State private var boardItems: [BoardItem] = []
    @State private var isRefreshing = false

    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()

            boardCanvas

            header

            if boardItems.isEmpty && !isRefreshing {
                emptyState
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if boardItems.isEmpty {
                syncBoardItems()
            }
        }
        .onShake {
            refreshBoard()
        }
        .fullScreenCover(item: $readingItem) { item in
            ReadingModeView(user: user, item: item)
        }
    }

    // MARK: - Refresh (shake) flow

    /// Reshuffles which sample notes are on the board — never touches the
    /// user's real posts. Every visible note falls + fades out first
    /// (staggered), then a new random batch animates back in.
    private func refreshBoard() {
        guard !isRefreshing, readingItem == nil else { return }
        isRefreshing = true

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        guard !boardItems.isEmpty else {
            swapInNewNotes()
            return
        }

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
            swapInNewNotes()
        }
    }

    private func swapInNewNotes() {
        let newBatch = SampleNoteBank.randomBatch()
        let layouts = layoutsForEntries(count: newBatch.count)
        boardItems = zip(newBatch, layouts).map { note, layout in
            BoardItem(note: note, layout: layout, yOffset: -500, opacity: 0, scale: 0.85)
        }

        withAnimation(.easeOut(duration: 0.3)) {
            offset = .zero
            lastOffset = .zero
        }

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

    private func syncBoardItems() {
        let notes = SampleNoteBank.randomBatch()
        let layouts = layoutsForEntries(count: notes.count)
        boardItems = zip(notes, layouts).map { note, layout in
            BoardItem(note: note, layout: layout)
        }
    }

    private func openNote(_ note: SampleNote) {
        readingItem = .sample(note)
    }

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
            Image(systemName: "pin.slash")
                .font(.system(size: 40))
                .foregroundStyle(Theme.inkMuted)
            Text("The board is empty")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("Shake to bring up some notes!")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var boardCanvas: some View {
        let canvasW: CGFloat = max(600, boardItems.map { $0.layout.position.x }.max().map { $0 + 120 } ?? 600)
        let canvasH: CGFloat = max(800, boardItems.map { $0.layout.position.y }.max().map { $0 + 160 } ?? 800)

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                boardSurface(width: canvasW, height: canvasH)

                ForEach(boardItems) { item in
                    StickyNoteView(
                        note: item.note,
                        color: noteColors[item.layout.colorIndex],
                        rotation: item.layout.rotation,
                        isBookmarked: user.isSampleNoteBookmarked(item.note.id),
                        isRead: user.isSampleNoteRead(item.note.id),
                        isDragging: $isDragging
                    ) {
                        openNote(item.note)
                    }
                    .scaleEffect(item.scale)
                    .opacity(item.opacity)
                    .position(x: item.layout.position.x, y: item.layout.position.y + item.yOffset)
                }
            }
            .frame(width: canvasW, height: canvasH)
            .scaleEffect(scale, anchor: .topLeading)
            .offset(offset)
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(magnifyGesture)
            .clipped()
        }
        .padding(.top, 60)
        .allowsHitTesting(!isRefreshing)
    }

    private func boardSurface(width: CGFloat, height: CGFloat) -> some View {
        Canvas { ctx, size in
            let dotSpacing: CGFloat = 30
            let dotRadius: CGFloat = 1.5
            let dotColor = Theme.ink.opacity(0.12)
            let cols = Int(size.width / dotSpacing)
            let rows = Int(size.height / dotSpacing)
            for row in 0...rows {
                for col in 0...cols {
                    let origin = CGPoint(
                        x: CGFloat(col) * dotSpacing,
                        y: CGFloat(row) * dotSpacing
                    )
                    ctx.fill(
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
    let note: SampleNote
    let color: Color
    let rotation: Double
    var isBookmarked: Bool = false
    var isRead: Bool = false
    @Binding var isDragging: Bool
    let onTap: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("pin")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(Theme.accent)
                .rotationEffect(.degrees(-45))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 2)
                .frame(maxWidth: .infinity, alignment: .center)
            
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

            Text("\u{201C}\(note.prompt)\u{201D}")
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineLimit(4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)

            Text(Self.dateFormatter.string(from: note.createdAt))
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
