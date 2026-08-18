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
    private(set) var summary: String?
    var generationError: String?

    private var session: LanguageModelSession

    init() {
        session = LanguageModelSession(instructions: Self.instructions)
    }
    
    /* Example 1 for Prompting
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
     ("you"), never about them in the third person.

     Be specific and genuine. Reference something concrete from what they \
     actually wrote when you can, rather than only naming emotions in the \
     abstract. Never produce a flat data-report sentence like "you've been \
     writing with emotions mixed in between X, Y, and Z" — that tone is \
     exactly what to avoid. Write flowing prose only: no lists, no headers, \
     no bullet points.
     """
     */
    
    private static let instructions = """
        You are an insightful, casual observer analyzing a writer's recent entries.
        Write a highly concise, natural reflection (maximum 3 sentences) directly to the writer using "you".
        
        Your goal is to describe their current writing voice and the underlying emotional current.
        
        CRITICAL RULES:
        1. NEVER use words like "piece", "post", "entry", "writing", or "prompt". 
        2. NEVER quote their text directly.
        3. NEVER directly address the emotions like "fear", "awe", or other emotionaldata provided.
        4. Instead, weave their recent emotions into your observation seamlessly (e.g., instead of saying "You felt nostalgic", say "There's a heavy sense of looking back in your words").
        5. Keep it conversational, relaxed, and highly concise. Do not sound like an AI data report.
        """

    /// Regenerates the summary from the user's most recent (up to 5)
    /// published posts. Clears the summary (rather than erroring) if
    /// nothing's published yet — the empty state is handled by the view.
    func refresh(for user: User) async {
        let recent = Array(user.loadPublished().prefix(5))
        guard !recent.isEmpty else {
            summary = nil
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        guard SystemLanguageModel.default.availability == .available else {
            generationError = "On-device model unavailable — showing a simple summary instead."
            summary = Self.fallbackSummary(profile: user.emotionProfile)
            return
        }

        do {
            let response = try await session.respond(
                to: Self.prompt(for: recent),
                generating: GeneratedStyleSummary.self
            )
            generationError = nil
            summary = response.content.summary
        } catch {
            generationError = error.localizedDescription
            summary = Self.fallbackSummary(profile: user.emotionProfile)
        }
    }

//    private static func prompt(for posts: [Post]) -> String {
//        var lines = ["Here are the writer's most recent published pieces, most recent first:"]
//        for (index, post) in posts.enumerated() {
//            let emotions = post.promptEmotions.joined(separator: ", ")
//            lines.append("""
//
//            Piece \(index + 1) — written for the emotion(s): \(emotions.isEmpty ? "unspecified" : emotions)
//            \"\"\"
//            \(post.textContent)
//            \"\"\"
//            """)
//        }
//        lines.append("\nWrite the reflection now.")
//        return lines.joined(separator: "\n")
//    }
    
    private static func prompt(for posts: [Post]) -> String {
            var lines = ["Here is what the user recently wrote and the emotions they were feeling:"]
            
            for post in posts {
                let emotions = post.promptEmotions.joined(separator: ", ")
                // Strip out the "Piece 1" labels so the AI doesn't parrot them back
                lines.append("""
                
                [Emotions: \(emotions.isEmpty ? "unspecified" : emotions)]
                \(post.textContent)
                """)
            }
            
            lines.append("\nProvide the 2-3 sentence reflection now without directly mentioning the emotions.")
            return lines.joined(separator: "\n")
        }

    /// Used only when the on-device model isn't available. Still
    /// deliberately phrased as a reflection rather than a data dump, even
    /// though it's built from the raw tally under the hood.
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
    @Guide(description: "A highly concise (max 3 sentences), natural reflection on the user's voice and emotions. Do not use words like 'piece' or 'post', and do not quote them. Do not use the emotion words provided in the published writings.")
    var summary: String
}
