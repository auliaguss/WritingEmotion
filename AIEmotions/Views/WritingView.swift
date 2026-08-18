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

import SwiftUI
import PhotosUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct WritingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User
    @State private var promptManager = PromptManager()

    @State private var draftText: String = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showConfirm = false

    /// Minimum characters required before "Done" unlocks — keeps people
    /// from spamming empty/junk entries.
    private static let minimumCharacterCount = 10

    private var trimmedText: String {
        draftText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var meetsMinimumLength: Bool {
        trimmedText.count >= Self.minimumCharacterCount
    }

    private var todaysPrompts: [PromptData] { user.todaysPrompts }
    private var currentPrompt: PromptData? { todaysPrompts.first }

    private var showDiscoverOption: Bool {
        user.isEmotionProfileUnlocked && user.hasExhaustedTodaysShuffles && !user.hasUsedDiscoveryToday
    }
    
    @FocusState private var isInputActive: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .task {
                await promptManager.generateDailyPromptsIfNeeded(for: user)
            }
        }
    }

    // MARK: - Sections

    private func promptHeader(_ prompt: PromptData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Here's something to get you started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
//            Text(prompt.emotionData)

            Text("\u{201C}\(prompt.fullText).\u{201D}")
                .font(.title2.weight(.bold))
                .foregroundStyle(.brown)

            HStack(spacing: 10) {
                Button {
                    promptManager.discardPrompt(prompt, for: user)
                } label: {
                    HStack(spacing: 4) {
                        Text("Shuffle your prompt")
                            .underline()
                        Image(systemName: "xmark")
                    }
                    .font(.footnote.weight(.medium))
                }
                .disabled(todaysPrompts.count <= 1 || promptManager.isGenerating)

                Text("(\(todaysPrompts.count)/3)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if showDiscoverOption {
                Button {
                    Task { await promptManager.generateDiscoveryPrompt(for: user) }
                } label: {
                    Label("Discover a new emotion", systemImage: "sparkles")
                        .font(.footnote.weight(.medium))
                }
                .buttonStyle(.bordered)
                .disabled(promptManager.isGenerating)
            }

            if let error = promptManager.generationError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var textBox: some View {
        ZStack(alignment: .bottom) {
            TextEditor(text: $draftText)
                .focused($isInputActive)
                .frame(minHeight: 240)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(photoData == nil ? "Camera" : "Photo added", systemImage: "camera")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
            }
            .padding(.bottom, 12)
            .onChange(of: photoItem) { _, newItem in
                Task {
                    photoData = try? await newItem?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    private var tipBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tip: Be creative. Be yourself. Write in any form you'd like, and reach a minimum of \(Self.minimumCharacterCount) characters.")
                .font(.caption)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.brown.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)

            if !meetsMinimumLength {
                Text("Keep writing! You haven't reached the minimum yet.")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    private var doneButton: some View {
        Button {
            showConfirm = true
        } label: {
            Text("Done")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!meetsMinimumLength)
    }

    private func confirmOverlay(prompt: PromptData) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { showConfirm = false }

            VStack(spacing: 14) {
                Text("Save for later or publish now?")
                    .font(.headline)

                Text("Save it as a draft to continue later, or publish it to share it with other readers.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button {
                        saveDraft(prompt: prompt)
                    } label: {
                        Text("Save draft")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        publish(prompt: prompt)
                    } label: {
                        Text("Publish")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(36)
        }
    }

    // MARK: - Actions

    private func saveDraft(prompt: PromptData) {
        Post.saveAsDraft(text: draftText, prompt: prompt, photoData: photoData, for: user, in: modelContext)
        dismiss()
    }

    private func publish(prompt: PromptData) {
        let post = Post.saveAsDraft(text: draftText, prompt: prompt, photoData: photoData, for: user, in: modelContext)
        post.publish()
        dismiss()
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
