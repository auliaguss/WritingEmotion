import Foundation

enum MediaOption: String, CaseIterable, Identifiable, Codable {
    case bowl
    case mailbox
    case bird

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bowl: "Bowl"
        case .mailbox: "Mailbox"
        case .bird: "Bird"
        }
    }

    var chipIcon: String {
        switch self {
        case .bowl: "basket"
        case .mailbox: "envelope"
        case .bird: "bird"
        }
    }
}
