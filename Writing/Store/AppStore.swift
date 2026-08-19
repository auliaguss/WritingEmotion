import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var entries: [WritingEntry] = [] {
        didSet { persistEntries() }
    }
    @Published var bookmarkedIDs: Set<UUID> = [] {
        didSet { persistBookmarks() }
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
        static let bookmarks = "writing.bookmarks"
        static let name = "writing.profile.name"
        static let bio = "writing.profile.bio"
        static let image = "writing.profile.image"
    }

    init() {
        if let data = defaults.data(forKey: Keys.entries),
           let decoded = try? JSONDecoder().decode([WritingEntry].self, from: data) {
            entries = decoded
        }
        if let data = defaults.data(forKey: Keys.bookmarks),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            bookmarkedIDs = decoded
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
    var bookmarkedEntries: [WritingEntry] { entries.filter { bookmarkedIDs.contains($0.id) } }

    func isBookmarked(_ entry: WritingEntry) -> Bool {
        bookmarkedIDs.contains(entry.id)
    }

    func toggleBookmark(_ entry: WritingEntry) {
        if bookmarkedIDs.contains(entry.id) {
            bookmarkedIDs.remove(entry.id)
        } else {
            bookmarkedIDs.insert(entry.id)
        }
    }

    func save(body: String, status: EntryStatus) {
        entries.insert(WritingEntry(body: body, status: status, createdAt: Date()), at: 0)
    }

    private func persistEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: Keys.entries)
    }

    private func persistBookmarks() {
        guard let data = try? JSONEncoder().encode(bookmarkedIDs) else { return }
        defaults.set(data, forKey: Keys.bookmarks)
    }
}
