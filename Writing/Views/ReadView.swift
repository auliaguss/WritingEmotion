import SwiftUI

// MARK: - Sticky note colour palette
private let noteColors: [Color] = [
    Color(hex: 0xFFF9C4), // pale yellow
    Color(hex: 0xFFCCBC), // soft peach
    Color(hex: 0xC8E6C9), // mint green
    Color(hex: 0xBBDEFB), // baby blue
    Color(hex: 0xE1BEE7), // lavender
    Color(hex: 0xFFE0B2), // light orange
    Color(hex: 0xB2DFDB), // teal mist
    Color(hex: 0xF8BBD0), // blush pink
]

// MARK: - Layout helpers

/// Pre-computed position & rotation for each note on the board.
private struct NoteLayout {
    let position: CGPoint
    let rotation: Double  // degrees
    let colorIndex: Int
}

/// Deterministic scatter based on entry index.
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
        // Base grid position
        let baseX = startX + CGFloat(col) * (noteW + spacingX) + noteW / 2
        let baseY = startY + CGFloat(row) * (noteH + spacingY) + noteH / 2
        // Small deterministic jitter so it looks organic
        let jitterX = CGFloat((i * 37 + 13) % 31) - 15  // -15 to +15
        let jitterY = CGFloat((i * 23 + 7) % 25) - 12   // -12 to +12
        let rotation = Double((i * 47 + 3) % 21) - 10    // -10 to +10 degrees
        let colorIdx = i % noteColors.count
        return NoteLayout(
            position: CGPoint(x: baseX + jitterX, y: baseY + jitterY),
            rotation: rotation,
            colorIndex: colorIdx
        )
    }
}

// MARK: - ReadView

struct ReadView: View {
    @EnvironmentObject var store: AppStore
    @Binding var route: Route

    @State private var selectedEntry: WritingEntry?

    // Pan & zoom state
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
            // Cork board background
            Theme.background.ignoresSafeArea()

            // Pannable + zoomable canvas
            boardCanvas(entries: entries, layouts: layouts)

            // Fixed header overlay
            header

            // Empty state
            if entries.isEmpty {
                emptyState
            }
        }
        .sheet(item: $selectedEntry) { entry in
            FullNoteSheet(entry: entry)
                .environmentObject(store)
        }
        .onAppear {
            #if DEBUG
            if store.publishedEntries.isEmpty {
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
                            status: .published,
                            createdAt: Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                        )
                    )
                }
            }
            #endif
        }
    }

    // MARK: - Header

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

    // MARK: - Empty state

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

    // MARK: - Board canvas (pan + zoom)

    private func boardCanvas(entries: [WritingEntry], layouts: [NoteLayout]) -> some View {
        // Compute canvas size from layouts
        let canvasW: CGFloat = max(600, layouts.map { $0.position.x }.max().map { $0 + 120 } ?? 600)
        let canvasH: CGFloat = max(800, layouts.map { $0.position.y }.max().map { $0 + 160 } ?? 800)

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Board surface — subtle grid dots
                boardSurface(width: canvasW, height: canvasH)

                // Notes
                ForEach(Array(zip(entries, layouts)), id: \.0.id) { entry, layout in
                    StickyNoteView(
                        entry: entry,
                        color: noteColors[layout.colorIndex],
                        rotation: layout.rotation,
                        isBookmarked: store.isBookmarked(entry)
                    ) {
                        selectedEntry = entry
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
        .padding(.top, 60) // clear header
    }

    // MARK: - Board surface

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

    // MARK: - Gestures

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

// MARK: - Sticky note card

private struct StickyNoteView: View {
    let entry: WritingEntry
    let color: Color
    let rotation: Double
    var isBookmarked: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Pin icon + bookmark badge
                HStack {
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accent)
                    }
                    Spacer()
                    Image(systemName: "pin.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                        .rotationEffect(.degrees(-45))
                    Spacer()
                    if isBookmarked {
                        Color.clear.frame(width: 11) // balance
                    }
                }

                // Body snippet
                Text(entry.body)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(6)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                // Date
                Text(entry.dateLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.ink.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(14)
            .frame(width: 170, height: 190)
            .background(
                ZStack {
                    // Soft shadow behind
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.1))
                        .offset(x: 3, y: 4)
                    // Note card fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                    // Subtle border
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.ink.opacity(0.15), lineWidth: 0.5)
                }
            )
        }
        .buttonStyle(.plain)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Full note sheet

private struct FullNoteSheet: View {
    let entry: WritingEntry
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

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
                    Text(entry.body)
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
    let store = AppStore()
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
                status: .published,
                createdAt: Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            )
        )
    }
    return ReadView(route: .constant(.read))
        .environmentObject(store)
}
