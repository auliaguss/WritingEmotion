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

struct ReadView: View {
    @EnvironmentObject var store: AppStore
    @Binding var route: Route

    @State private var selectedEntry: WritingEntry?
    @State private var showDetail = false

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDragging = false

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
                    ("She left the letter on the kitchen table, folded twice, smelling faintly of lavender. He didn't open it until spring.", WritingPrompts.all[2]),
                    ("The old bookshop on 5th street closed today. Twenty years of dog-eared pages and whispered recommendations, gone.", WritingPrompts.all[3]),
                    ("I learned to swim in words before I learned to swim in water. The page was always kinder than the ocean.", WritingPrompts.all[4]),
                    ("There's a kind of silence that only exists at 3 AM — not empty, but full, like a breath held too long.", WritingPrompts.all[5]),
                    ("My grandmother's hands told stories her mouth never did. Each wrinkle was a chapter, each scar a plot twist.", WritingPrompts.all[0]),
                    ("We built a fort out of cardboard boxes and called it a castle. For one afternoon, we were kings of something real.", WritingPrompts.all[1]),
                    ("The coffee shop where we first met turned into a parking lot. Progress, they called it. I called it erasure.", WritingPrompts.all[2]),
                    ("I keep a jar of sea glass on my desk. Each piece was sharp once, before the ocean taught it patience.", WritingPrompts.all[3]),
                    ("He played the same song every morning. Not because he loved it, but because she used to hum it in her sleep.", WritingPrompts.all[0]),
                    ("The dictionary defines home as a place of residence. It says nothing about the ache of returning to one that no longer fits.", WritingPrompts.all[0]),
                    ("I found a photograph of us laughing, and I couldn't remember what was so funny. That terrified me more than forgetting your face.", WritingPrompts.all[4]),
                    ("The taxi driver told me his whole life story in twelve blocks. Somewhere between 3rd and 7th Avenue, I forgot my own sadness.", WritingPrompts.all[5]),
                    ("She painted sunsets the way other people breathe — effortlessly, endlessly, as if the sky owed her its palette.", WritingPrompts.all[1]),
                    ("There's a tree in my old backyard that still has my initials carved into it. I wonder if it remembers the boy who held the knife.", WritingPrompts.all[0]),
                    ("The last voicemail she left me is still on my phone. I can't listen to it, but I'll never delete it.", WritingPrompts.all[3]),
                    ("We used to measure summer by the height of the sunflowers. This year, nobody planted any.", WritingPrompts.all[4]),
                    ("I wrote your name in the sand and watched the tide take it. The ocean doesn't care about permanence either.", WritingPrompts.all[1]),
                    ("The library smelled of dust and possibility. Every shelf was a door, every book a key to somewhere I'd never been.", WritingPrompts.all[5]),
                    ("My father's watch stopped the day he did. I wear it anyway — a reminder that some things outlast the hands that wound them.", WritingPrompts.all[0]),
                    ("The streetlights came on one by one like tired eyes opening. The city never truly sleeps, it just pretends.", WritingPrompts.all[2]),
                    ("I pressed a wildflower between the pages of your favourite book. You'll find it someday, and maybe you'll think of me.", WritingPrompts.all[1]),
                    ("The train pulled away and I didn't wave. Sometimes goodbye is just standing still while everything else moves.", WritingPrompts.all[3]),
                    ("She collected words the way magpies collect shiny things — greedily, lovingly, with no regard for what's practical.", WritingPrompts.all[5]),
                    ("The kitchen smelled of cinnamon and regret. I was baking her recipe, but it would never taste the same.", WritingPrompts.all[0]),
                    ("I counted the cracks in the ceiling and imagined they were rivers on a map leading somewhere I'd never go.", WritingPrompts.all[4]),
                    ("The old piano in the corner hadn't been tuned in years, but it still knew how to hold a melody hostage.", WritingPrompts.all[2]),
                    ("We promised to write letters, real ones, with stamps and everything. The first one arrived three months late. The second one never came.", WritingPrompts.all[1]),
                    ("The fog rolled in like a secret, hiding the harbour and muffling the horns. For one hour, the world was only as big as my front porch.", WritingPrompts.all[5]),
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
                        isRead: store.isRead(entry),
                        isDragging: $isDragging
                    ) {
                        openNote(entry)
                    }
                    .position(layout.position)
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
    let entry: WritingEntry
    let color: Color
    let rotation: Double
    var isBookmarked: Bool = false
    var isRead: Bool = false
    @Binding var isDragging: Bool
    let onTap: () -> Void

    var body: some View {
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
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isDragging else { return }
            onTap()
        }
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
        "The coffee shop where we first met turned into a parking lot. Progress, they called it. I called it erasure.",
        "I keep a jar of sea glass on my desk. Each piece was sharp once, before the ocean taught it patience.",
        "He played the same song every morning. Not because he loved it, but because she used to hum it in her sleep.",
        "The dictionary defines home as a place of residence. It says nothing about the ache of returning to one that no longer fits.",
        "I found a photograph of us laughing, and I couldn't remember what was so funny. That terrified me more than forgetting your face.",
        "The taxi driver told me his whole life story in twelve blocks. Somewhere between 3rd and 7th Avenue, I forgot my own sadness.",
        "She painted sunsets the way other people breathe — effortlessly, endlessly, as if the sky owed her its palette.",
        "There's a tree in my old backyard that still has my initials carved into it. I wonder if it remembers the boy who held the knife.",
        "The last voicemail she left me is still on my phone. I can't listen to it, but I'll never delete it.",
        "We used to measure summer by the height of the sunflowers. This year, nobody planted any.",
        "I wrote your name in the sand and watched the tide take it. The ocean doesn't care about permanence either.",
        "The library smelled of dust and possibility. Every shelf was a door, every book a key to somewhere I'd never been.",
        "My father's watch stopped the day he did. I wear it anyway — a reminder that some things outlast the hands that wound them.",
        "The streetlights came on one by one like tired eyes opening. The city never truly sleeps, it just pretends.",
        "I pressed a wildflower between the pages of your favourite book. You'll find it someday, and maybe you'll think of me.",
        "The train pulled away and I didn't wave. Sometimes goodbye is just standing still while everything else moves.",
        "She collected words the way magpies collect shiny things — greedily, lovingly, with no regard for what's practical.",
        "The kitchen smelled of cinnamon and regret. I was baking her recipe, but it would never taste the same.",
        "I counted the cracks in the ceiling and imagined they were rivers on a map leading somewhere I'd never go.",
        "The old piano in the corner hadn't been tuned in years, but it still knew how to hold a melody hostage.",
        "We promised to write letters, real ones, with stamps and everything. The first one arrived three months late. The second one never came.",
        "The fog rolled in like a secret, hiding the harbour and muffling the horns. For one hour, the world was only as big as my front porch.",
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
