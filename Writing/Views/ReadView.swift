import SwiftUI

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

private struct NoteLayout {
    let position: CGPoint
    let rotation: Double
    let colorIndex: Int
}

private func layoutsForEntries(count: Int, columns: Int = 3) -> [NoteLayout] {
    let noteW: CGFloat = 180
    let noteH: CGFloat = 200
    let spacingX: CGFloat = 30
    let spacingY: CGFloat = 40
    let startX: CGFloat = 40
    let startY: CGFloat = 40

    return (0..<count).map { i in
        let col = i % columns
        let row = i / columns
        let baseX = startX + CGFloat(col) * (noteW + spacingX) + noteW / 2
        let baseY = startY + CGFloat(row) * (noteH + spacingY) + noteH / 2
        let jitterX = CGFloat((i * 37 + 13) % 31) - 15
        let jitterY = CGFloat((i * 23 + 7) % 25) - 12
        let rotation = Double((i * 47 + 3) % 21) - 10
        let colorIdx = i % noteColors.count
        return NoteLayout(
            position: CGPoint(x: baseX + jitterX, y: baseY + jitterY),
            rotation: rotation,
            colorIndex: colorIdx
        )
    }
}

struct ReadView: View {
    @EnvironmentObject var store: AppStore
    @Binding var route: Route

    @State private var selectedEntry: WritingEntry?
    @State private var showDetail = false

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0

    var body: some View {
        let entries = store.publishedEntries
        let layouts = layoutsForEntries(count: entries.count)

        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()

            boardCanvas(entries: entries, layouts: layouts)

            header

            if entries.isEmpty {
                emptyState
            }

            if showDetail, let entry = selectedEntry {
                NoteDetailView(
                    entry: entry,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetail = false
                            selectedEntry = nil
                        }
                    },
                    onReadAnother: {
                        readAnotherNote()
                    }
                )
                .environmentObject(store)
                .transition(.move(edge: .trailing))
                .zIndex(10)
            }
        }
        .onAppear {
            #if DEBUG
            if store.publishedEntries.isEmpty {
                let dummyData: [(body: String, prompt: String)] = [
                    ("The rain tapped against the window like tiny fingers asking to come in. I sat with my tea, watching the world blur into watercolour.", WritingPrompts.all[2]),
                    ("Sometimes I wonder if the stars remember us the way we remember them — distant, bright, full of stories we'll never fully understand.", WritingPrompts.all[1]),
                    ("She left the letter on the kitchen table, folded twice, smelling faintly of lavender. He didn't open it until spring.", "The apology you never got."),
                    ("The old bookshop on 5th street closed today. Twenty years of dog-eared pages and whispered recommendations, gone.", WritingPrompts.all[2]),
                    ("I learned to swim in words before I learned to swim in water. The page was always kinder than the ocean.", WritingPrompts.all[3]),
                    ("There's a kind of silence that only exists at 3 AM — not empty, but full, like a breath held too long.", WritingPrompts.all[4]),
                    ("My grandmother's hands told stories her mouth never did. Each wrinkle was a chapter, each scar a plot twist.", WritingPrompts.all[0]),
                    ("We built a fort out of cardboard boxes and called it a castle. For one afternoon, we were kings of something real.", WritingPrompts.all[5]),
                ]
                for (i, item) in dummyData.enumerated() {
                    store.entries.append(
                        WritingEntry(
                            body: item.body,
                            prompt: item.prompt,
                            status: .published,
                            createdAt: Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                        )
                    )
                }
            }
            #endif
        }
    }

    private func openNote(_ entry: WritingEntry) {
        store.markAsRead(entry)
        selectedEntry = entry
        withAnimation(.easeInOut(duration: 0.3)) {
            showDetail = true
        }
    }
    
    private func readAnotherNote() {
        let candidates = store.unreadPublishedEntries.filter { $0.id != selectedEntry?.id }
        guard let next = candidates.randomElement() else { return }
        store.markAsRead(next)
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedEntry = next
        }
    }

    private var header: some View {
        HStack {
            RoundBackButton { route = .home }
            Spacer()
            Text("Mading")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button {
                route = .bookmarks
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
            Text("No published notes yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("Write and publish something first!")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func boardCanvas(entries: [WritingEntry], layouts: [NoteLayout]) -> some View {
        let canvasW: CGFloat = max(600, layouts.map { $0.position.x }.max().map { $0 + 120 } ?? 600)
        let canvasH: CGFloat = max(800, layouts.map { $0.position.y }.max().map { $0 + 160 } ?? 800)

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                boardSurface(width: canvasW, height: canvasH)

                ForEach(Array(zip(entries, layouts)), id: \.0.id) { entry, layout in
                    StickyNoteView(
                        entry: entry,
                        color: noteColors[layout.colorIndex],
                        rotation: layout.rotation,
                        isBookmarked: store.isBookmarked(entry),
                        isRead: store.isRead(entry)
                    ) {
                        openNote(entry)
                    }
                    .position(layout.position)
                }
            }
            .frame(width: canvasW, height: canvasH)
            .scaleEffect(scale, anchor: .topLeading)
            .offset(offset)
            .gesture(dragGesture)
            .gesture(magnifyGesture)
            .clipped()
        }
        .padding(.top, 60)
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
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastScale * value.magnification
                scale = min(max(newScale, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale
            }
    }
}

private struct StickyNoteView: View {
    let entry: WritingEntry
    let color: Color
    let rotation: Double
    var isBookmarked: Bool = false
    var isRead: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                        .rotationEffect(.degrees(-45))

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
                }

                Spacer(minLength: 0)
                
                Text("\u{201C}\(entry.prompt)\u{201D}")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer(minLength: 0)

                Text(entry.dateLabel)
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
        }
        .buttonStyle(.plain)
        .rotationEffect(.degrees(rotation))
    }
}

private struct NoteDetailView: View {
    let entry: WritingEntry
    @EnvironmentObject var store: AppStore
    let onClose: () -> Void
    let onReadAnother: () -> Void

    private var hasUnread: Bool {
        store.unreadPublishedEntries.contains { $0.id != entry.id }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(entry.dateLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.inkMuted)
                    Spacer()
                    Button {
                        store.toggleBookmark(entry)
                    } label: {
                        Image(systemName: store.isBookmarked(entry) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.card))
                            .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
                    }
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.card))
                            .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
                    }
                }

                readAnotherButton

                ScrollView {
                    Text(entry.body)
                        .font(.system(size: 18, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                readAnotherButton
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private var readAnotherButton: some View {
        Button(action: onReadAnother) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(hasUnread ? "Read Another Note" : "All Caught Up!")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(hasUnread ? Theme.tipText : Theme.inkMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .hardCard(
                fill: hasUnread ? Theme.accent : Theme.card,
                cornerRadius: 10,
                borderWidth: 1.5,
                shadowOffset: 3
            )
        }
        .buttonStyle(.plain)
        .disabled(!hasUnread)
        .opacity(hasUnread ? 1 : 0.6)
    }
}

#Preview {
    let store = AppStore()
    let prompts = WritingPrompts.all
    let dummyTexts = [
        "The rain tapped against the window like tiny fingers asking to come in. I sat with my tea, watching the world blur into watercolour.",
        "Sometimes I wonder if the stars remember us the way we remember them — distant, bright, full of stories we'll never fully understand.",
        "She left the letter on the kitchen table, folded twice, smelling faintly of lavender. He didn't open it until spring.",
        "The old bookshop on 5th street closed today. Twenty years of dog-eared pages and whispered recommendations, gone.",
        "I learned to swim in words before I learned to swim in water. The page was always kinder than the ocean.",
        "There's a kind of silence that only exists at 3 AM — not empty, but full, like a breath held too long.",
        "My grandmother's hands told stories her mouth never did. Each wrinkle was a chapter, each scar a plot twist.",
        "We built a fort out of cardboard boxes and called it a castle. For one afternoon, we were kings of something real.",
    ]
    for (i, text) in dummyTexts.enumerated() {
        store.entries.append(
            WritingEntry(
                body: text,
                prompt: prompts[i % prompts.count],
                status: .published,
                createdAt: Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            )
        )
    }
    return ReadView(route: .constant(.read))
        .environmentObject(store)
}
