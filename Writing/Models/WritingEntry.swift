import Foundation

enum EntryStatus: String, Codable {
    case draft
    case published
}

struct WritingEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var body: String
    var status: EntryStatus
    var createdAt: Date

    init(id: UUID = UUID(), body: String, status: EntryStatus, createdAt: Date) {
        self.id = id
        self.body = body
        self.status = status
        self.createdAt = createdAt
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var dateLabel: String { Self.dateFormatter.string(from: createdAt) }
}
