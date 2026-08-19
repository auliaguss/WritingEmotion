//
//  StyleSummaryGenerator.swift
//  AIEmotions
//
//  Generates a short, warm, personalized reflection on how someone's
//  been writing — built from the actual TEXT of their most recent
//  published pieces (up to 5), not just their raw emotion tally. This is
//  what the live Profile screen shows in place of the emotional-palette
//  bars (see EmotionPaletteView, now testing-only).
//
//  Deliberately reads `post.promptEmotions` (the free-text CREATIVE
//  display tags, e.g. "wistful yearning") rather than `post.coreEmotion`
//  (the strict 8-category backend enum) when building the model prompt
//  below. The whole point of the hybrid split in CoreEmotion.swift is
//  that the creative side stays expressive language a human reflection
//  should sound like, while the strict side stays math-only — feeding
//  the FM raw enum cases like "joy"/"trust" repeatedly would push this
//  right back toward the flat, data-report tone we're trying to avoid.
//
//  Button-triggered, not automatic. The result is written straight onto
//  `User.styleSummaryText` (see User.setStyleSummary), so it's durable
//  across relaunches and stays exactly as-is until the writer taps
//  Generate again — see StyleSummaryCard for the button/disabled-state
//  logic that goes with this.
//
//  Everything runs on-device via FoundationModels, same as PromptManager
//  — no network calls, matching the project's "keep it strictly local"
//  goal. Falls back to a softer (still non-clinical) templated summary
//  if the model is unavailable.
//

import Foundation
import FoundationModels
import Observation

@Observable
@MainActor
final class StyleSummaryGenerator {

    private(set) var isGenerating = false
    var generationError: String?

    private var session: LanguageModelSession

    init() {
        session = LanguageModelSession(instructions: Self.instructions)
    }

    private static let instructions = """
    You write a short, warm reflection (2-4 sentences) on someone's recent \
    creative writing, as if a thoughtful friend had actually sat down and \
    read it.

    You'll be given the full text of up to 5 of their most recent \
    published pieces, most recent first, each labeled with the emotion(s) \
    its prompt was meant to evoke.

    Read for their actual voice: word choice, imagery, rhythm, recurring \
    themes or images, how they tend to open or land a piece — not just \
    which emotion words are attached to it. Speak directly TO the writer \
    using "you" ("you are...", "you have...", "your..."). Never use the \
    word "I" anywhere in the reflection, and never refer to yourself or \
    to the act of reading/judging their work — this should read like a \
    personalized result, the way a well-written personality quiz talks \
    about you, never like someone is personally observing or grading \
    them.

    Be specific and genuine. Reference something concrete from what they \
    actually wrote when you can, rather than only naming emotions in the \
    abstract. Never produce a flat data-report sentence like "you've been \
    writing with emotions mixed in between X, Y, and Z" — that tone is \
    exactly what to avoid. Write flowing prose only: no lists, no headers, \
    no bullet points.
    """

    /// Generates a fresh reflection from the user's most recent (up to 5)
    /// published posts and persists it onto `user.styleSummaryText`.
    /// Does nothing if nothing's published yet — the empty state is
    /// handled by the view. Called only when the writer taps
    /// Generate/Regenerate (see StyleSummaryCard) — never automatically.
    func generate(for user: User) async {
        let recent = Array(user.loadPublished().prefix(5))
        guard !recent.isEmpty else { return }

        let sourceIDs = recent.map(\.uniqueID)

        isGenerating = true
        defer { isGenerating = false }

        guard SystemLanguageModel.default.availability == .available else {
            generationError = "On-device model unavailable — showing a simple summary instead."
            user.setStyleSummary(Self.fallbackSummary(profile: user.emotionProfile), sourcePostIDs: sourceIDs)
            return
        }

        do {
            let response = try await session.respond(
                to: Self.prompt(for: recent),
                generating: GeneratedStyleSummary.self
            )
            generationError = nil
            user.setStyleSummary(response.content.summary, sourcePostIDs: sourceIDs)
        } catch {
            generationError = error.localizedDescription
            user.setStyleSummary(Self.fallbackSummary(profile: user.emotionProfile), sourcePostIDs: sourceIDs)
        }
    }

    private static func prompt(for posts: [Post]) -> String {
        var lines = ["Here are the writer's most recent published pieces, most recent first:"]
        for (index, post) in posts.enumerated() {
            let emotions = post.promptEmotions.joined(separator: ", ")
            lines.append("""

            Piece \(index + 1) — written for the emotion(s): \(emotions.isEmpty ? "unspecified" : emotions)
            \"\"\"
            \(post.textContent)
            \"\"\"
            """)
        }
        lines.append("\nWrite the reflection now.")
        return lines.joined(separator: "\n")
    }

    /// Used only when the on-device model isn't available. Still
    /// deliberately phrased as a reflection rather than a data dump, even
    /// though it's built from the raw tally under the hood. Never uses
    /// "I", same rule as the model-generated version.
    private static func fallbackSummary(profile: [String: Int]) -> String {
        let top = profile.sorted { $0.value > $1.value }.prefix(2).map(\.key)
        switch top.count {
        case 0:
            return "You're just getting started — keep writing and we'll get to know your voice."
        case 1:
            return "Lately your writing keeps circling back to \(top[0]) — there's a real thread running through your last few pieces."
        default:
            return "Your recent writing has been moving between \(top[0]) and \(top[1]) — two feelings that seem to be shaping a lot of what you're putting down right now."
        }
    }
}

// MARK: - Generable schema

@Generable
struct GeneratedStyleSummary {
    @Guide(description: "A warm, specific, 2-4 sentence reflection on the writer's recent pieces, written directly to them using 'you' ('you are...', 'you have...'), never the word 'I', in flowing prose with no lists or headers.")
    var summary: String
}
