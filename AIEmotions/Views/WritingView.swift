//
//  WritingView.swift
//  AIEmotions
//
//  Today's prompts are generated once per day and persisted on `User`.
//  Only the current (first) prompt is shown — "shuffling" it permanently
//  removes it from today's set (no replacement), down to a floor of 1
//  that can't be discarded. Once all of today's shuffleable prompts are
//  gone (User.hasExhaustedTodaysShuffles) AND the profile is unlocked, a
//  once-a-day "Discover" option surfaces.
//
//  The user gets exactly one writing session per calendar day: tapping
//  "Done" (only enabled once the minimum length is met) surfaces a
//  save-or-publish choice, and either choice locks Write on the Home
//  screen until tomorrow — so this view dismisses itself right after.
//
//  Visual styling (Theme + hardCard "paper box") ported from the
//  "Writing" branch. The Camera button is also ported from there: it's
//  the VisionKit document scanner + Vision OCR pipeline (scan a written
//  page, transcribe it into the draft) rather than the previous
//  PhotosPicker photo-attach — a deliberate replacement, not an addition.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct WritingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.writingService) private var writingService
    @Bindable var user: User
    private let draft: Post?
    @State private var promptManager = PromptManager()

    @State private var draftText: String
    @State private var showConfirm = false
    @State private var showMinimumLengthError = false
    @State private var pendingPost: Post?
    @State private var pendingRequest: PublishWritingRequest?
    @State private var isPublishing = false
    @State private var publishingError: String?
    @State private var canRetryPublishing = true

    @State private var showScanner = false
    @State private var isRecognizingText = false

    /// Minimum characters required before "Done" unlocks — keeps people
    /// from spamming empty/junk entries.
    private static let minimumCharacterCount = 10

    init(user: User, draft: Post? = nil) {
        self.user = user
        self.draft = draft
        _draftText = State(initialValue: draft?.textContent ?? "")
    }

    private var trimmedText: String {
        draftText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var meetsMinimumLength: Bool {
        trimmedText.count >= Self.minimumCharacterCount
    }

    private var todaysPrompts: [PromptData] { user.todaysPrompts }
    private var currentPrompt: PromptData? {
        if let draft {
            return PromptData(
                id: draft.uniqueID,
                fullText: draft.promptFullText,
                verb: draft.promptVerb,
                emotionData: draft.promptEmotionData,
                coreEmotion: draft.promptCoreEmotion
            )
        }
        return todaysPrompts.first
    }

    private var showDiscoverOption: Bool {
        user.isEmotionProfileUnlocked && user.hasExhaustedTodaysShuffles && !user.hasUsedDiscoveryToday
    }

    @FocusState private var isInputActive: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        if let currentPrompt {
                            promptHeader(currentPrompt)
                            textBox
                            tipBanner
                            Spacer(minLength: 30)
                            doneButton
                        } else if promptManager.isGenerating {
                            ProgressView("Generating today's prompts…")
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                        }
                    }
                    .padding()
                }
                .onTapGesture {
                    isInputActive = false
                }

                if showConfirm, let currentPrompt {
                    confirmOverlay(prompt: currentPrompt)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showScanner) {
                DocumentScannerView(
                    onFinish: { images in
                        showScanner = false
                        recognizeText(from: images)
                    },
                    onCancel: {
                        showScanner = false
                    }
                )
                .ignoresSafeArea()
            }
            .task {
                guard draft == nil else { return }
                await promptManager.generateDailyPromptsIfNeeded(for: user)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            RoundBackButton { dismiss() }
            Spacer()
        }
    }

    private func promptHeader(_ prompt: PromptData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(draft == nil ? "Here's something to get you started." : "Continue your draft.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)

            Text("\u{201C}\(prompt.fullText).\u{201D}")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Theme.accent)

            if draft == nil {
                HStack(spacing: 10) {
                    Button {
                        promptManager.discardPrompt(prompt, for: user)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Shuffle your prompt")
                                .underline()
                            Image(systemName: "xmark")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(todaysPrompts.count > 1 && !promptManager.isGenerating ? Theme.accent : Theme.inkMuted)
                    }
                    .disabled(todaysPrompts.count <= 1 || promptManager.isGenerating)

                    Text("(\(todaysPrompts.count)/3)")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkMuted)
                }

                if showDiscoverOption {
                    Button {
                        Task { await promptManager.generateDiscoveryPrompt(for: user) }
                    } label: {
                        Label("Discover a new emotion", systemImage: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .hardCard(cornerRadius: 16, shadowOffset: 3)
                    .disabled(promptManager.isGenerating)
                }

                if let error = promptManager.generationError {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var textBox: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 2))
            .frame(height: 260)
            .overlay(
                TextEditor(text: $draftText)
                    .focused($isInputActive)
                    .disabled(isPublishing)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .padding(16)
            )
            .overlay {
                if isRecognizingText {
                    ZStack {
                        Theme.card.opacity(0.9)
                        ProgressView("Reading your handwriting...")
                            .tint(Theme.ink)
                            .foregroundStyle(Theme.ink)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .overlay(alignment: .bottom) {
                cameraButton
                    .offset(y: 22)
            }
            .padding(.bottom, 22)
    }

    private var cameraButton: some View {
        Button {
            showScanner = true
        } label: {
            Label("Camera", systemImage: "camera.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
        }
        .hardCard(cornerRadius: 5, shadowOffset: 3)
        .disabled(isRecognizingText || isPublishing)
    }

    private var tipBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text("\u{1F4A1}")
                Text("Tip: ").fontWeight(.bold) +
                Text("Be creative. Be yourself. Write in any form you'd like, and reach a minimum of \(Self.minimumCharacterCount) characters.")
            }
            .font(.system(size: 13))
            .foregroundStyle(Theme.tipText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 5).fill(Theme.tipFill))

            if showMinimumLengthError && !meetsMinimumLength {
                Text("Keep writing! You haven't reached the minimum yet.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.error)
            }
        }
    }

    private var doneButton: some View {
        Button {
            if meetsMinimumLength {
                showConfirm = true
            } else {
                showMinimumLengthError = true
            }
        } label: {
            Text("Done")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .hardCard()
        .disabled(isPublishing)
    }

    private func confirmOverlay(prompt: PromptData) -> some View {
        ZStack {
            Theme.overlay.ignoresSafeArea()
                .onTapGesture {
                    guard !isPublishing, pendingRequest == nil else { return }
                    showConfirm = false
                }

            VStack(spacing: 16) {
                Text(draft == nil ? "Save for later or publish now?" : "Keep editing later or publish now?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text("Save it as a draft to continue later, or publish it to share it with other readers.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)

                if isPublishing {
                    ProgressView("Publishing…")
                        .tint(Theme.ink)
                        .foregroundStyle(Theme.ink)
                }

                if let publishingError {
                    Text(publishingError)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.error)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Publishing failed. \(publishingError)")
                }

                HStack(spacing: 12) {
                    Button {
                        saveDraft(prompt: prompt)
                    } label: {
                        Text(pendingPost == nil ? "Save draft" : "Keep draft")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .hardCard(cornerRadius: 24, shadowOffset: 3)
                    .disabled(isPublishing)

                    Button {
                        publish(prompt: prompt)
                    } label: {
                        Text(pendingRequest == nil ? "Publish" : "Retry publish")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.card)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .hardCard(fill: Theme.ink, cornerRadius: 24, shadowOffset: 3)
                    .disabled(isPublishing || !canRetryPublishing)
                }
            }
            .padding(22)
            .frame(maxWidth: 320)
            .hardCard(cornerRadius: 22)
        }
    }

    // MARK: - Actions

    private func saveDraft(prompt: PromptData) {
        if let pendingPost {
            pendingPost.update(text: draftText, photoData: pendingPost.attachedImageData)
        } else if let draft {
            draft.update(text: draftText, photoData: draft.attachedImageData)
        } else {
            Post.saveAsDraft(text: draftText, prompt: prompt, photoData: nil, for: user, in: modelContext)
        }
        dismiss()
    }

    private func publish(prompt: PromptData) {
        guard !isPublishing else { return }

        let post: Post
        let request: PublishWritingRequest

        if let pendingPost, let pendingRequest {
            post = pendingPost
            request = pendingRequest
        } else {
            if let draft {
                draft.update(text: draftText, photoData: draft.attachedImageData)
                post = draft
            } else {
                post = Post.saveAsDraft(
                    text: draftText,
                    prompt: prompt,
                    photoData: nil,
                    for: user,
                    in: modelContext
                )
            }

            request = PublishWritingRequest(
                clientWritingID: post.uniqueID,
                title: nil,
                fullText: post.textContent,
                prompt: .init(
                    verb: post.promptVerb,
                    fullText: post.promptFullText,
                    emotions: post.promptEmotions
                )
            )
            pendingPost = post
            pendingRequest = request
        }

        isPublishing = true
        publishingError = nil
        canRetryPublishing = true

        Task {
            do {
                let response = try await writingService.publish(request, deviceID: post.deviceID)
                guard response.clientWritingID == post.uniqueID else {
                    throw WritingServiceError.invalidResponse
                }
                post.remoteID = response.id
                post.publish()
                dismiss()
            } catch let error as WritingServiceError {
                publishingError = error.localizedDescription
                canRetryPublishing = error.canRetry
                isPublishing = false
            } catch {
                publishingError = "Your writing couldn't be published. Please try again."
                canRetryPublishing = true
                isPublishing = false
            }
        }
    }

    private func recognizeText(from images: [UIImage]) {
        guard !images.isEmpty else { return }
        isRecognizingText = true
        Task {
            let recognized = await TextRecognizer.recognizeText(in: images)
            isRecognizingText = false
            guard !recognized.isEmpty else { return }
            draftText = draftText.isEmpty ? recognized : draftText + "\n\n" + recognized
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: User.self, Post.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let user = User()
    container.mainContext.insert(user)
    return WritingView(user: user)
        .modelContainer(container)
}
