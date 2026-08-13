import Foundation

enum Emotion: String, CaseIterable, Identifiable, Codable {
    case sad
    case angry
    case happy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sad: "Sad"
        case .angry: "Angry"
        case .happy: "Happy"
        }
    }

    var writePrompt: String {
        switch self {
        case .sad:
            "What's the sad thing you feel that has been bugging you for years that you can't get rid of?"
        case .angry:
            "What's something that still makes you furious every time you think about it?"
        case .happy:
            "What's a moment of pure happiness you don't want to forget?"
        }
    }
}
