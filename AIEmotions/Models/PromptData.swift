//
//  PromptData.swift
//  AIEmotions
//
//  A single writing prompt: a short "Verb-ing + Object" phrase, tagged
//  with the emotion(s) it's meant to evoke. PromptManager holds three of
//  these at a time (see class diagram, 1 PromptManager -> 3 PromptData).
//
//  This is kept as a lightweight Codable struct rather than a SwiftData
//  @Model, since prompts are ephemeral/generated each session. The parts
//  worth keeping long-term (what was actually written from) are copied
//  onto the Post itself when the user saves a draft or publishes.
//

import Foundation

struct PromptData: Identifiable, Codable, Hashable {
    let id: UUID
    var fullText: String
    var verb: String
    var emotionData: String

    /// Convenience: the emotion tags split out, lowercased & trimmed.
    var emotions: [String] {
        emotionData
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }

    init(id: UUID = UUID(), fullText: String, verb: String, emotionData: String) {
        self.id = id
        self.fullText = fullText
        self.verb = verb
        self.emotionData = emotionData
    }
}
