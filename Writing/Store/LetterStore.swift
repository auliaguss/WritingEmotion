import SwiftUI
import Combine

@MainActor
final class LetterStore: ObservableObject {
    @Published var selectedEmotion: Emotion = .sad
    @Published var selectedMedia: MediaOption = .bowl
    @Published var myLetters: [Letter] = []

    func nextEmotion() {
        selectedEmotion = Self.cycle(selectedEmotion, by: 1)
    }

    func previousEmotion() {
        selectedEmotion = Self.cycle(selectedEmotion, by: -1)
    }

    func randomStrangerLetter() -> Letter {
        DummyLetters.random(for: selectedEmotion)
    }

    func send(body: String) {
        let letter = Letter(
            emotion: selectedEmotion,
            media: selectedMedia,
            body: body,
            signature: "You",
            dateLabel: Self.todayLabel
        )
        myLetters.insert(letter, at: 0)
    }

    func letters(for media: MediaOption) -> [Letter] {
        myLetters.filter { $0.media == media }
    }

    func count(for media: MediaOption) -> Int {
        letters(for: media).count
    }

    func letters(for media: MediaOption, emotion: Emotion) -> [Letter] {
        myLetters.filter { $0.media == media && $0.emotion == emotion }
    }

    func count(for media: MediaOption, emotion: Emotion) -> Int {
        letters(for: media, emotion: emotion).count
    }

    private static func cycle(_ emotion: Emotion, by offset: Int) -> Emotion {
        let all = Emotion.allCases
        guard let index = all.firstIndex(of: emotion) else { return emotion }
        let next = (index + offset + all.count) % all.count
        return all[next]
    }

    private static var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}
