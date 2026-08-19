//
//  SampleNoteBank.swift
//  AIEmotions
//
//  Fake "other writers'" notes for the Read screen's corkboard. There's
//  still no backend (see PROJECT.md / User.swift's readPublished note),
//  so this is a fixed pool of sample writing standing in for a real
//  community feed — ported from the "Writing" branch's read-another-logic
//  prototype, kept as explicitly-placeholder content rather than the
//  user's own posts.
//
//  Each note's `id` is its fixed index into `all`, not a freshly
//  generated UUID. That matters: the original prototype constructed a
//  brand-new random-UUID entry on every shake, which silently orphaned
//  any bookmark the moment the board reshuffled (the bookmarked ID no
//  longer matched anything). Keying by a stable pool index instead means
//  User's bookmark/read tracking survives reshuffling to a different
//  random batch.
//

import Foundation

struct SampleNote: Identifiable, Hashable {
    let id: Int
    let body: String
    let prompt: String
    let createdAt: Date
}

enum SampleNoteBank {
    /// Cycled across the pool below so each sample note carries a prompt
    /// in AIEmotions' own "Verb-ing + Object" voice (see PromptManager),
    /// rather than the old Writing branch's unrelated static prompt list.
    private static let prompts = [
        "Chasing fireflies through fog",
        "Unpacking a stranger's suitcase",
        "Whispering to an empty room",
        "Folding yesterday's letters",
        "Racing a closing door",
        "Planting a borrowed garden",
    ]

    private static let bodies: [String] = [
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

    /// The full fixed pool, in stable id order.
    static let all: [SampleNote] = bodies.enumerated().map { index, body in
        SampleNote(
            id: index,
            body: body,
            prompt: prompts[index % prompts.count],
            createdAt: Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
        )
    }

    /// A random subset for one board "batch" — reshuffled on shake. Always
    /// drawn from the same stable-id pool, so a note's identity (and any
    /// bookmark/read state keyed on it) survives moving between batches.
    static func randomBatch(minCount: Int = 12) -> [SampleNote] {
        let shuffled = all.shuffled()
        let count = Int.random(in: min(minCount, shuffled.count)...shuffled.count)
        return Array(shuffled.prefix(count))
    }
}
