//
//  CoreEmotion.swift
//  AIEmotions
//
//  The strict, fixed set of backend emotion categories — the "data
//  tracking" half of the hybrid approach described in PROJECT.md.
//  Everything that touches the mathematical profile (`User.emotionProfile`,
//  the unlock threshold, prompt biasing) is keyed to exactly one of these
//  8 values. It's intentionally small and closed so aggregation actually
//  means something, unlike the free-text `displayEmotion`/`emotionData`
//  strings, which stay wide open for creative flavor.
//
//  Marked @Generable (not just Codable/CaseIterable) because it's used as
//  a property type inside GeneratedPrompt, a @Generable struct — without
//  this, FoundationModels has no schema to constrain the model's output
//  to a valid case, and structured generation for that property fails.
//

import Foundation
import FoundationModels

@Generable
enum CoreEmotion: String, Codable, CaseIterable {
    case joy, sadness, fear, anger, surprise, anticipation, trust, disgust
}
