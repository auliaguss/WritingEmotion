//
//  User.swift
//  AIEmotions
//
//  The local, on-device profile. There is exactly one of these per
//  install. `emotionProfile` is the running tally of which CORE emotions
//  the person has written from most (see CoreEmotion.swift) — PromptManager
//  reads it to bias what it generates next. Keys are always one of
//  CoreEmotion's 8 raw values, never the freeform creative display text
//  a prompt shows the user.
//
//  The profile, drafts, bookmarks, and read history stay local. Published
//  writing content from other devices is loaded through WritingService.
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

    // MARK: - Style summary (button-generated, persistent)
    // The last-generated "In your words" reflection text, persisted so it
    // survives app relaunches and simply stays put until the user taps
    // Generate again — see StyleSummaryGenerator / StyleSummaryCard.
    var styleSummaryText: String?
    // The published-post IDs (as strings) that were fed into the model
    // to produce `styleSummaryText`, most-recent-first — this is what
    // lets the Generate button know whether there's anything NEW to
    // regenerate from (see canRegenerateStyleSummary()).
    var styleSummarySourcePostIDs: [String] = []

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

    // Remote published writings are value types loaded by WritingService,
    // not SwiftData Posts attached to this local user.

    /// Bumps the weight for one CORE emotion. Called once per post, with
    /// the strict `CoreEmotion` category that post's prompt was tagged
    /// with — never the freeform display text. Silently ignores anything
    /// that isn't a real `CoreEmotion` raw value, since `emotionProfile`
    /// is meant to stay a closed, poolable set.
    func updateEmotionWeight(_ coreEmotion: String) {
        guard CoreEmotion(rawValue: coreEmotion) != nil else { return }
        emotionProfile[coreEmotion, default: 0] += 1
    }

    /// Top core emotions by weight, most-favored first.
    func topEmotions(_ limit: Int = 3) -> [String] {
        emotionProfile
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }

    // MARK: - Style summary (button-generated, persistent)

    /// Persists a freshly generated reflection along with the IDs of the
    /// published posts it was built from. Called by
    /// `StyleSummaryGenerator` after a successful (or fallback) generation.
    func setStyleSummary(_ text: String, sourcePostIDs: [UUID]) {
        styleSummaryText = text
        styleSummarySourcePostIDs = sourcePostIDs.map(\.uuidString)
    }

    /// Whether the Generate/Regenerate button should be enabled — i.e.
    /// whether the writer's latest 5 published posts differ from the set
    /// the current summary was actually generated from. Stays false
    /// (button disabled) if nothing's changed, so the same 5 pieces never
    /// produce a different summary just because the user tapped again.
    func canRegenerateStyleSummary() -> Bool {
        let currentIDs = loadPublished().prefix(5).map { $0.uniqueID.uuidString }
        return Array(currentIDs) != styleSummarySourcePostIDs
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

    // MARK: - Read board

    // Writing content comes from the backend. Bookmark and read state
    // remains local to this device and is keyed by the backend writing ID.
    var bookmarkedWritingIDs: [String] = []
    var readWritingIDs: [String] = []

    func isWritingBookmarked(_ id: String) -> Bool {
        bookmarkedWritingIDs.contains(id)
    }

    func toggleWritingBookmark(_ id: String) {
        if let index = bookmarkedWritingIDs.firstIndex(of: id) {
            bookmarkedWritingIDs.remove(at: index)
        } else {
            bookmarkedWritingIDs.append(id)
        }
    }

    func isWritingRead(_ id: String) -> Bool {
        readWritingIDs.contains(id)
    }

    func markWritingRead(_ id: String) {
        guard !readWritingIDs.contains(id) else { return }
        readWritingIDs.append(id)
    }
}
