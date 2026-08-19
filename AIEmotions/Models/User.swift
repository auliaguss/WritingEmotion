//
//  User.swift
//  AIEmotions
//
//  The local, on-device profile. There is exactly one of these per
//  install. `emotionProfile` is the running tally of which emotions the
//  person has written from most — PromptManager reads it to bias what
//  it generates next.
//
//  Per the project scope, this stays fully local: `readPublished(id:)`
//  from the class diagram (reading another device's published posts)
//  is intentionally NOT implemented — there's no backend to fetch from.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var deviceID: String
    @Attribute(.externalStorage) var profilePictureData: Data?
    var profileText: String
    var emotionProfile: [String: Int]
    var postsWrittenCount: Int

    // MARK: - Daily prompt state
    // The day's 3 prompts, persisted so they're stable across app
    // launches for the same calendar day. Stored as encoded JSON rather
    // than a relationship since PromptData is a plain value type, not a
    // SwiftData model. Shuffling a prompt *removes* it from this array
    // (see PromptManager.discardPrompt) rather than replacing it.
    @Attribute(.externalStorage) private var dailyPromptsData: Data?
    private var dailyPromptsDate: Date?

    // The "discovery" prompt button (targets an unexplored/low-scored
    // emotion) is capped at once per calendar day.
    private var lastDiscoveryUseDate: Date?

    // The user can complete one writing session (save-draft OR publish)
    // per calendar day. Set the moment either action happens — see
    // Post.saveAsDraft.
    private var lastWriteDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \Post.author)
    var posts: [Post] = []

    init(
        deviceID: String = DeviceIdentity.current,
        profileText: String = "",
        emotionProfile: [String: Int] = [:],
        postsWrittenCount: Int = 0
    ) {
        self.deviceID = deviceID
        self.profileText = profileText
        self.emotionProfile = emotionProfile
        self.postsWrittenCount = postsWrittenCount
    }

    // MARK: - Diagram methods

    func updateProfile(newBio: String, newPictureData: Data?) {
        profileText = newBio
        profilePictureData = newPictureData
    }

    /// (Diagram: `loadDrafts() -> [Post]`) — the `posts` relationship is
    /// already live/observable via SwiftData, so this is just a filtered
    /// view of it rather than a separate fetch.
    func loadDrafts() -> [Post] {
        posts.filter { !$0.isPublished }.sorted { $0.createdAt > $1.createdAt }
    }

    /// (Diagram: `loadPublished() -> [Post]`)
    func loadPublished() -> [Post] {
        posts.filter(\.isPublished).sorted { ($0.publishedAt ?? $0.createdAt) > ($1.publishedAt ?? $1.createdAt) }
    }

    // readPublished(id: !deviceID) -> [Post] is intentionally skipped —
    // see file header. Re-add here once there's a backend to read from.

    /// Bumps the weight for one emotion. Called whenever a post is
    /// drafted/published from a prompt carrying that emotion tag, so the
    /// profile drifts toward what the person actually writes about.
    func updateEmotionWeight(_ emotion: String) {
        let key = emotion.trimmingCharacters(in: .whitespaces).lowercased()
        guard !key.isEmpty else { return }
        emotionProfile[key, default: 0] += 1
    }

    /// Top emotions by weight, most-favored first.
    func topEmotions(_ limit: Int = 3) -> [String] {
        emotionProfile
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }

    /// Weighted (bias-driven) prompt generation only kicks in once at
    /// least one emotion has been written from 5+ times. Before that,
    /// prompts stay fully random/varied so the user explores broadly
    /// instead of the profile prematurely narrowing what they see.
    var isEmotionProfileUnlocked: Bool {
        emotionProfile.values.contains { $0 >= 5 }
    }

    // MARK: - Daily prompts

    private static let calendar = Calendar.current

    /// Whether `dailyPromptsData` was generated today (vs. stale from a
    /// previous day, in which case it should be regenerated).
    var hasTodaysPrompts: Bool {
        guard let date = dailyPromptsDate else { return false }
        return Self.calendar.isDateInToday(date)
    }

    /// The remaining prompts for today, most-recently-added last.
    /// Empty if nothing's been generated yet today.
    var todaysPrompts: [PromptData] {
        guard hasTodaysPrompts, let data = dailyPromptsData else { return [] }
        return (try? JSONDecoder().decode([PromptData].self, from: data)) ?? []
    }

    /// Called once per day by PromptManager to seed the day's 3 prompts.
    func setTodaysPrompts(_ prompts: [PromptData]) {
        dailyPromptsData = try? JSONEncoder().encode(prompts)
        dailyPromptsDate = .now
    }

    /// Removes a prompt from today's set — this is what "shuffling"
    /// actually does now: it deletes, it does not replace. Refuses to
    /// remove the last remaining prompt.
    @discardableResult
    func removeTodaysPrompt(id: UUID) -> Bool {
        var prompts = todaysPrompts
        guard prompts.count > 1, let index = prompts.firstIndex(where: { $0.id == id }) else {
            return false
        }
        prompts.remove(at: index)
        dailyPromptsData = try? JSONEncoder().encode(prompts)
        return true
    }

    /// Adds a prompt to today's set without touching the rest — used by
    /// the once-a-day "discover an unexplored emotion" prompt.
    func appendTodaysPrompt(_ prompt: PromptData) {
        var prompts = todaysPrompts
        prompts.append(prompt)
        dailyPromptsData = try? JSONEncoder().encode(prompts)
    }

    /// Whether the once-per-day "discover a new emotion" prompt has
    /// already been used today.
    var hasUsedDiscoveryToday: Bool {
        guard let date = lastDiscoveryUseDate else { return false }
        return Self.calendar.isDateInToday(date)
    }

    func markDiscoveryUsedToday() {
        lastDiscoveryUseDate = .now
    }

    // MARK: - Once-per-day writing

    /// Whether the user has already completed a writing session (saved a
    /// draft or published) today. The Home screen disables "Write" and
    /// reveals "Read" once this is true; resets automatically the next
    /// calendar day.
    var hasWrittenToday: Bool {
        guard let date = lastWriteDate else { return false }
        return Self.calendar.isDateInToday(date)
    }

    /// Called by `Post.saveAsDraft` — both saving a draft and publishing
    /// go through it, so either one counts as "today's writing" and
    /// locks further writing until tomorrow.
    func markWrittenToday() {
        lastWriteDate = .now
    }

    /// Whether every *shuffleable* prompt for today has been discarded,
    /// leaving only the mandatory last one. This is the gate for showing
    /// the "Discover" button — it stays hidden while the user still has
    /// real choices among today's original 3.
    var hasExhaustedTodaysShuffles: Bool {
        todaysPrompts.count <= 1
    }

    #if DEBUG
    /// TESTING ONLY — compiled out of Release builds entirely. Rewinds
    /// all of today's daily-cycle state (the write lock, today's prompt
    /// set, discovery usage) so the app behaves as if a new calendar day
    /// had started, without waiting for midnight. Lets `TestingProfileView`
    /// cycle through fresh prompt generations repeatedly while testing.
    func debugRefreshDay() {
        lastWriteDate = nil
        dailyPromptsData = nil
        dailyPromptsDate = nil
        lastDiscoveryUseDate = nil
    }
    #endif

    // MARK: - Read board (sample notes)

    // Bookmark/read state for the Read screen's corkboard of sample
    // "other writers'" notes (see SampleNoteBank — there's still no
    // backend, so these are fixed placeholder content, not real other
    // users). Keyed by SampleNote.id, which is a stable index into the
    // fixed pool rather than a freshly-generated identifier, so a
    // bookmark keeps pointing at the same note even after the board
    // reshuffles to a different random batch.
    var bookmarkedSampleNoteIDs: [Int] = []
    var readSampleNoteIDs: [Int] = []

    func isSampleNoteBookmarked(_ id: Int) -> Bool {
        bookmarkedSampleNoteIDs.contains(id)
    }

    func toggleSampleNoteBookmark(_ id: Int) {
        if let index = bookmarkedSampleNoteIDs.firstIndex(of: id) {
            bookmarkedSampleNoteIDs.remove(at: index)
        } else {
            bookmarkedSampleNoteIDs.append(id)
        }
    }

    func isSampleNoteRead(_ id: Int) -> Bool {
        readSampleNoteIDs.contains(id)
    }

    func markSampleNoteRead(_ id: Int) {
        guard !readSampleNoteIDs.contains(id) else { return }
        readSampleNoteIDs.append(id)
    }
}
