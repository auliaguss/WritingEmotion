import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var entries: [WritingEntry] = [] {
        didSet { persistEntries() }
    }
    @Published var profileName: String = "Lorem ipsum" {
        didSet { defaults.set(profileName, forKey: Keys.name) }
    }
    @Published var profileBio: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit." {
        didSet { defaults.set(profileBio, forKey: Keys.bio) }
    }
    @Published var profileImageData: Data? {
        didSet { defaults.set(profileImageData, forKey: Keys.image) }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let entries = "writing.entries"
        static let name = "writing.profile.name"
        static let bio = "writing.profile.bio"
        static let image = "writing.profile.image"
    }

    init() {
        if let data = defaults.data(forKey: Keys.entries),
           let decoded = try? JSONDecoder().decode([WritingEntry].self, from: data) {
            entries = decoded
        }
        if let name = defaults.string(forKey: Keys.name) {
            profileName = name
        }
        if let bio = defaults.string(forKey: Keys.bio) {
            profileBio = bio
        }
        profileImageData = defaults.data(forKey: Keys.image)
    }

    var hasEntries: Bool { !entries.isEmpty }
    var publishedEntries: [WritingEntry] { entries.filter { $0.status == .published } }
    var draftEntries: [WritingEntry] { entries.filter { $0.status == .draft } }

    func save(body: String, status: EntryStatus) {
        entries.insert(WritingEntry(body: body, status: status, createdAt: Date()), at: 0)
    }

    private func persistEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: Keys.entries)
    }
}
