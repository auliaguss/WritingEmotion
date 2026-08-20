//
//  WrappedSummaryGenerator.swift
//  AIEmotions
//
//  DEBUG-only experiment (#if DEBUG-gated end to end, same as the rest
//  of Views/Testing) — exploring a Spotify-Wrapped-style personalized
//  recap as a possible future evolution of StyleSummaryCard's "In your
//  words" reflection. Not wired into the live/Release experience.
//
//  For now this covers, per the current test scope:
//    - the writer's top emotional aspects
//    - what and how they've been writing about (voice/themes)
//    - bookmarks — placeholder only, not yet implemented anywhere
//    - how much they've written for each emotion (word counts)
//
//  Same house rule as StyleSummaryGenerator: every line is written
//  directly to the writer in second person, never first person — no "I"
//  anywhere, so it reads like a personalized result, not commentary.
//

#if DEBUG
import Foundation
import FoundationModels
import Observation

@Observable
@MainActor
final class WrappedSummaryGenerator {

    private(set) var isGenerating = false
    private(set) var wrapped: GeneratedWrappedSummary?
    var generationError: String?

    private var session: LanguageModelSession

    init() {
        session = LanguageModelSession(instructions: Self.instructions)
    }

    private static let instructions = """
    You write the copy for a short, personalized "wrapped"-style recap of \
    someone's recent creative writing — think Spotify Wrapped, but for a \
    private journal instead of a music library. Playful, warm, and \
    specific, never clinical.

    You'll be given: their top emotional categories by how much they've \
    written from each one, and the actual text of their most recent \
    pieces labeled with the creative emotion tags their prompts carried.

    Write directly TO the writer, second person only ("you are...", \
    "you've been...", "your..."). Never use the word "I" anywhere, and \
    never write as though you are personally watching, judging, or \
    grading them — this is a personalized result screen, not an \
    observation.

    Keep every line short and punchy, like a stat card caption — this is \
    not flowing essay prose, it's a series of short, quotable lines.
    """

    /// Computes the local (non-generated) stats and, if the model is
    /// available, asks it to write the wrapped-style captions around
    /// them. Word counts and top emotions are always computed locally —
    /// only the phrasing is generated.
    func generate(for user: User) async {
        let published = user.loadPublished()
        let wordCounts = Self.wordCountsPerEmotion(posts: published)
        let topEmotions = user.topEmotions(3)

        isGenerating = true
        defer { isGenerating = false }

        guard SystemLanguageModel.default.availability == .available, !published.isEmpty else {
            wrapped = Self.fallbackSummary(topEmotions: topEmotions, wordCounts: wordCounts)
            return
        }

        do {
            let response = try await session.respond(
                to: Self.prompt(topEmotions: topEmotions, recentPosts: Array(published.prefix(5))),
                generating: GeneratedWrappedCopy.self
            )
            generationError = nil
            wrapped = GeneratedWrappedSummary(
                topEmotionsLine: response.content.topEmotionsLine,
                writingStyleLine: response.content.writingStyleLine,
                closingLine: response.content.closingLine,
                topEmotions: topEmotions,
                wordCountsPerEmotion: wordCounts
            )
        } catch {
            generationError = error.localizedDescription
            wrapped = Self.fallbackSummary(topEmotions: topEmotions, wordCounts: wordCounts)
        }
    }

    private static func prompt(topEmotions: [String], recentPosts: [Post]) -> String {
        var lines = ["Top emotional categories by how much they've written from each, most-written first: \(topEmotions.joined(separator: ", "))."]
        lines.append("\nRecent pieces, most recent first:")
        for (index, post) in recentPosts.enumerated() {
            let emotions = post.promptEmotions.joined(separator: ", ")
            lines.append("Piece \(index + 1) (\(emotions.isEmpty ? "unspecified" : emotions)): \(post.textContent.prefix(300))")
        }
        lines.append("\nWrite the three wrapped-style lines now.")
        return lines.joined(separator: "\n")
    }

    /// Total words written per core emotion, across ALL posts (drafts +
    /// published) tagged with that emotion — "how much they've written
    /// for each emotion," per the test scope.
    private static func wordCountsPerEmotion(posts: [Post]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for post in posts {
            guard let emotion = post.coreEmotion?.rawValue else { continue }
            let words = post.textContent.split { $0.isWhitespace || $0.isNewline }.count
            counts[emotion, default: 0] += words
        }
        return counts
    }

    private static func fallbackSummary(topEmotions: [String], wordCounts: [String: Int]) -> GeneratedWrappedSummary {
        let top = topEmotions.first ?? "your writing"
        return GeneratedWrappedSummary(
            topEmotionsLine: topEmotions.isEmpty
                ? "You're just getting started — write a bit more and your top feelings will show up here."
                : "\(top.capitalized) has been showing up the most in your writing lately.",
            writingStyleLine: "Your recent pieces are still building a shape — keep going and your voice will come through even more.",
            closingLine: "That's your recap so far — more to come the more you write.",
            topEmotions: topEmotions,
            wordCountsPerEmotion: wordCounts
        )
    }
}

// MARK: - Generated copy schema (model-facing, phrasing only)

@Generable
struct GeneratedWrappedCopy {
    @Guide(description: "One punchy sentence, second person, naming the writer's top emotional aspect(s). Never use 'I'.")
    var topEmotionsLine: String

    @Guide(description: "One or two short sentences, second person, about what and how they've been writing — themes, imagery, voice. Never use 'I'.")
    var writingStyleLine: String

    @Guide(description: "One playful, second person closing line tying the recap together. Never use 'I'.")
    var closingLine: String
}

// MARK: - Full wrapped result (copy + locally-computed stats)

struct GeneratedWrappedSummary {
    var topEmotionsLine: String
    var writingStyleLine: String
    var closingLine: String

    /// Locally computed — not generated.
    var topEmotions: [String]
    /// Locally computed — not generated. Words written per core emotion.
    var wordCountsPerEmotion: [String: Int]
}
#endif
