//
//  Post.swift
//  AIEmotions
//
//  A single piece of writing, produced from a prompt. Lives as a draft
//  until the user publishes it. `promptUsed` from the class diagram is
//  flattened into three stored properties (verb/fullText/emotionData)
//  rather than a nested relationship, since PromptData is ephemeral —
//  this keeps a durable snapshot of the exact prompt this post came from.
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

    @Attribute(.externalStorage) var attachedImageData: Data?
    var isPublished: Bool
    var createdAt: Date
    var publishedAt: Date?

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
        self.attachedImageData = attachedImageData
        self.isPublished = isPublished
        self.createdAt = .now
        self.publishedAt = isPublished ? .now : nil
    }

    /// The emotion tags carried by the prompt this post was written from.
    var promptEmotions: [String] {
        promptEmotionData
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
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
        for emotion in prompt.emotions {
            user.updateEmotionWeight(emotion)
        }
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
