//
//  PromptManager.swift
//  AIEmotions
//
//  Generates the "Verb-ing + Object" writing prompts using Apple's
//  on-device Foundation Models framework (iOS 26+), tagging each one
//  with the emotion(s) it's meant to evoke. Everything happens on-device
//  — no network calls, matching the project's "keep it strictly local"
//  goal.
//
//  Prompt lifecycle (per user, per calendar day):
//   - Exactly 3 prompts are generated once per day and persisted on
//     `User` (see User.todaysPrompts). Nothing regenerates until the
//     next calendar day.
//   - "Shuffling" a prompt DELETES it from the day's set — it does not
//     get replaced. 3 -> 2 -> 1, and the last one can't be removed.
//   - Below a "discovery" unlock threshold (any single emotion reaching
//     a weight of 5+), the day's 3 prompts are generated with a fully
//     random emotional spread so the user explores broadly before the
//     profile starts steering anything.
//   - Once unlocked, the day's 3 prompts are biased toward the user's
//     top emotions. A separate "discover" action (capped at once per
//     day, and only surfaced once the user has shuffled down to their
//     last mandatory prompt) generates one extra prompt. It strictly
//     prioritizes an emotion the user has NEVER scored at all, only
//     falling back to their single lowest-scored emotion if the model
//     truly can't land on something fresh — specifically so a profile
//     that's gotten heavy in 1-2 emotions doesn't feel like the whole
//     app is just showing the same feelings back.
//

import Foundation
import FoundationModels
import Observation

@Observable
@MainActor
final class PromptManager {

    private(set) var isGenerating: Bool = false
    var generationError: String?

    private var session: LanguageModelSession

    init() {
        session = LanguageModelSession(instructions: Self.instructions)
    }

    private static let instructions = """
    You are a prompt generator for a short-form creative writing app.

    Every prompt is a short, evocative "Verb-ing + Object" phrase, 3 to 6 \
    words, present participle (e.g. "Chasing fireflies through fog", \
    "Unpacking a stranger's suitcase", "Whispering to an empty room"). \
    Never write full sentences, only the phrase.

    For each prompt also name the 1-2 core emotions it's meant to evoke, \
    as lowercase, comma-separated words (e.g. "nostalgia, wonder").

    Keep prompts varied, concrete, and evocative rather than abstract. \
    Avoid repeating the same verb or object twice in one batch.
    """

    // MARK: - Daily batch

    /// Generates and persists today's 3 prompts, but only if the user
    /// doesn't already have a set for today. Safe to call every time the
    /// writing screen appears.
    func generateDailyPromptsIfNeeded(for user: User) async {
        guard !user.hasTodaysPrompts else { return }
        isGenerating = true
        defer { isGenerating = false }

        let prompts = await generateBatch(
            biased: user.isEmotionProfileUnlocked ? user.emotionProfile : [:]
        )
        user.setTodaysPrompts(prompts)
    }

    /// Force-regenerates today's set even if one already exists — only
    /// meant for a manual "start over" affordance, not the normal flow.
    func regenerateToday(for user: User) async {
        isGenerating = true
        defer { isGenerating = false }
        let prompts = await generateBatch(
            biased: user.isEmotionProfileUnlocked ? user.emotionProfile : [:]
        )
        user.setTodaysPrompts(prompts)
    }

    // MARK: - Shuffle (delete, no replacement)

    /// Removes `prompt` from today's set for good. Returns false (and
    /// does nothing) if it's the last remaining prompt — the user always
    /// has to be left with at least one to write from.
    @discardableResult
    func discardPrompt(_ prompt: PromptData, for user: User) -> Bool {
        user.removeTodaysPrompt(id: prompt.id)
    }

    // MARK: - Discovery prompt (once per day, post-unlock only)

    /// Generates one extra prompt strictly prioritizing an emotion the
    /// user has NEVER scored. Only falls back to their lowest-scored
    /// emotion if the model genuinely can't land on a fresh one. Only
    /// available once the profile is unlocked (5+ on some emotion) and
    /// only once per calendar day.
    @discardableResult
    func generateDiscoveryPrompt(for user: User) async -> PromptData? {
        guard user.isEmotionProfileUnlocked, !user.hasUsedDiscoveryToday else { return nil }
        isGenerating = true
        defer { isGenerating = false }

        let prompt = await generateSingle(
            scoredEmotions: Array(user.emotionProfile.keys),
            lowestScoredEmotion: user.emotionProfile.min { $0.value < $1.value }?.key
        )
        user.appendTodaysPrompt(prompt)
        user.markDiscoveryUsedToday()
        return prompt
    }

    // MARK: - Generation internals

    private func generateBatch(biased profile: [String: Int]) async -> [PromptData] {
        guard SystemLanguageModel.default.availability == .available else {
            generationError = "On-device model unavailable — showing starter prompts instead."
            return Array(Self.fallbackBatch().shuffled().prefix(3))
        }

        let bias = Self.biasLine(from: profile)
        do {
            let response = try await session.respond(
                to: "Generate 3 new writing prompts. \(bias)",
                generating: GeneratedPromptBatch.self
            )
            generationError = nil
            return response.content.prompts.map {
                PromptData(fullText: $0.fullText, verb: $0.verb, emotionData: $0.emotionData)
            }
        } catch {
            generationError = error.localizedDescription
            return Array(Self.fallbackBatch().shuffled().prefix(3))
        }
    }

    private func generateSingle(scoredEmotions: [String], lowestScoredEmotion: String?) async -> PromptData {
        guard SystemLanguageModel.default.availability == .available else {
            return Self.fallbackBatch().randomElement()!
        }

        // Strict priority order given to the model: (1) an emotion never
        // scored by this writer at all, (2) only if that's genuinely not
        // possible, their single lowest-scored emotion.
        let scoredList = scoredEmotions.isEmpty ? "(none yet)" : scoredEmotions.joined(separator: ", ")
        var instruction = """
        Generate 1 new writing prompt. Follow this priority strictly:
        Priority 1 — evoke an emotion that is NOT in this list of emotions the \
        writer has already scored at least once: \(scoredList). This is the \
        preferred outcome; almost any distinct emotion word not on that list \
        qualifies, so use this priority unless truly no such word exists.
        """
        if let lowestScoredEmotion {
            instruction += """

            Priority 2 (fallback ONLY if priority 1 is genuinely impossible) \
            — use the writer's lowest-scored emotion so far: '\(lowestScoredEmotion)'.
            """
        }

        do {
            let response = try await session.respond(to: instruction, generating: GeneratedPrompt.self)
            let p = response.content
            generationError = nil
            return PromptData(fullText: p.fullText, verb: p.verb, emotionData: p.emotionData)
        } catch {
            generationError = error.localizedDescription
            return Self.fallbackBatch().randomElement()!
        }
    }

    private static func biasLine(from userProfile: [String: Int]) -> String {
        let top = userProfile.sorted { $0.value > $1.value }.prefix(3).map(\.key)
        guard !top.isEmpty else {
            return "The writer has no established emotional profile yet — deliberately spread the 3 prompts across distinctly different emotions so they can explore broadly."
        }
        return "This writer has recently leaned toward these emotions: \(top.joined(separator: ", ")). " +
               "Lean into 1-2 of them, but keep the third prompt a wildcard for variety."
    }

    private static func fallbackBatch() -> [PromptData] {
        [
            PromptData(fullText: "Chasing fireflies through fog", verb: "Chasing", emotionData: "nostalgia, wonder"),
            PromptData(fullText: "Unpacking a stranger's suitcase", verb: "Unpacking", emotionData: "curiosity, unease"),
            PromptData(fullText: "Whispering to an empty room", verb: "Whispering", emotionData: "loneliness, comfort"),
            PromptData(fullText: "Folding yesterday's letters", verb: "Folding", emotionData: "grief, tenderness"),
            PromptData(fullText: "Racing a closing door", verb: "Racing", emotionData: "urgency, hope"),
            PromptData(fullText: "Planting a borrowed garden", verb: "Planting", emotionData: "patience, optimism")
        ]
    }
}

// MARK: - Generable schema

@Generable
struct GeneratedPromptBatch {
    @Guide(.count(3))
    var prompts: [GeneratedPrompt]
}

@Generable
struct GeneratedPrompt {
    @Guide(description: "A present-participle verb, e.g. 'Chasing', 'Unpacking', 'Whispering'")
    var verb: String
    @Guide(description: "A 3-6 word evocative 'verb-ing + object' phrase built from the verb, e.g. 'Chasing fireflies through fog'")
    var fullText: String
    @Guide(description: "1-2 lowercase emotion words this phrase evokes, comma separated, e.g. 'nostalgia, wonder'")
    var emotionData: String
}
