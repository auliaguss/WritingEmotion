//
//  Post.swift
//  AIEmotions
//
//  A single piece of writing, produced from a prompt. Lives as a draft
//  until the user publishes it. `promptUsed` from the class diagram is
//  flattened into stored properties (verb/fullText/emotionData/coreEmotion)
//  rather than a nested relationship, since PromptData is ephemeral —
//  this keeps a durable snapshot of the exact prompt this post came from.
//
//  `promptEmotionData` is the free-text creative flavor (unchanged).
//  `promptCoreEmotion` is new: a snapshot of the strict CoreEmotion
//  category that prompt was tagged with, for the same hybrid reasons
//  described on CoreEmotion.swift and in PROJECT.md.
//

import Foundation
import SwiftData

@Model
final class Post {
    @Attribute(.unique) var uniqueID: UUID
    var deviceID: String
    var textContent: String

    // Snapshot of the PromptData this post was written from.
    var promptVerb: String
    var promptFullText: String
    var promptEmotionData: String
    // Defaulted (unlike the three above) so SwiftData's automatic
    // lightweight migration can add this column to existing local stores
    // — a required @Model property with no default crashes ModelContainer
    // creation against pre-existing data instead of migrating.
    var promptCoreEmotion: String = ""

    @Attribute(.externalStorage) var attachedImageData: Data?
    var isPublished: Bool
    var createdAt: Date
    var publishedAt: Date?
    var remoteID: String?

    var author: User?

    init(
        deviceID: String,
        textContent: String,
        prompt: PromptData,
        attachedImageData: Data? = nil,
        isPublished: Bool = false
    ) {
        self.uniqueID = UUID()
        self.deviceID = deviceID
        self.textContent = textContent
        self.promptVerb = prompt.verb
        self.promptFullText = prompt.fullText
        self.promptEmotionData = prompt.emotionData
        self.promptCoreEmotion = prompt.coreEmotion
        self.attachedImageData = attachedImageData
        self.isPublished = isPublished
        self.createdAt = .now
        self.publishedAt = isPublished ? .now : nil
        self.remoteID = nil
    }

    /// The creative, freeform emotion tags carried by the prompt this
    /// post was written from — display-only, never fed into the
    /// mathematical profile. See `coreEmotion` for the strict category.
    var promptEmotions: [String] {
        promptEmotionData
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }

    /// Typed access to the strict backend category, when the raw string
    /// happens to still be a known case (it always should be, barring
    /// old data from before this field existed — see PROJECT.md).
    var coreEmotion: CoreEmotion? {
        CoreEmotion(rawValue: promptCoreEmotion)
    }

    // MARK: - Diagram methods

    /// Creates and inserts a new draft `Post` for the given user.
    /// (Diagram: `saveAsDraft(text:prompt:photo:) -> Void` — implemented as
    /// a factory since a brand-new Post has to be created and inserted
    /// into the model context, not mutated on an existing empty instance.)
    @discardableResult
    static func saveAsDraft(
        text: String,
        prompt: PromptData,
        photoData: Data?,
        for user: User,
        in context: ModelContext
    ) -> Post {
        let post = Post(
            deviceID: user.deviceID,
            textContent: text,
            prompt: prompt,
            attachedImageData: photoData,
            isPublished: false
        )
        post.author = user
        context.insert(post)
        user.postsWrittenCount += 1
        user.markWrittenToday()
        // Backend math uses ONE strict core-emotion bump per post — not
        // the freeform display tags, which can carry 1-2 creative words
        // that don't map cleanly onto a single countable category. See
        // CoreEmotion.swift for the reasoning.
        user.updateEmotionWeight(prompt.coreEmotion)
        return post
    }

    /// Marks this draft as published. (Diagram: `publish(id:text:photo:) ->
    /// Void`. Since the post already carries its id/text/photo once saved
    /// as a draft, publishing here just flips its state rather than
    /// re-accepting the same values — call `update(text:photoData:)` first
    /// if the content changed.)
    func publish() {
        isPublished = true
        publishedAt = .now
    }

    /// Edits the text/photo of a still-unpublished draft.
    func update(text: String, photoData: Data?) {
        textContent = text
        attachedImageData = photoData
    }
}
