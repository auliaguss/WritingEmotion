import Foundation

struct Letter: Identifiable, Codable, Equatable {
    let id: UUID
    let emotion: Emotion
    let media: MediaOption
    let body: String
    let signature: String
    let dateLabel: String

    init(id: UUID = UUID(), emotion: Emotion, media: MediaOption, body: String, signature: String, dateLabel: String) {
        self.id = id
        self.emotion = emotion
        self.media = media
        self.body = body
        self.signature = signature
        self.dateLabel = dateLabel
    }

    var wordCount: Int {
        body.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}
