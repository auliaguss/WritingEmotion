import SwiftUI
import UIKit

private let minimumCharacterCount = 50
private let maxShuffles = 3

struct WritingView: View {
    @EnvironmentObject var store: AppStore
    @Binding var route: Route

    @State private var draft: String = ""
    @State private var currentPrompt: String = WritingPrompts.all[0]
    @State private var shufflesRemaining = maxShuffles

    @State private var showScanner = false
    @State private var isRecognizingText = false

    @State private var showError = false
    @State private var showSavePopup = false

    private var characterCount: Int {
        draft.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var hasReachedMinimum: Bool { characterCount >= minimumCharacterCount }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                header

                promptSection

                paperBox

                tipBox

                Spacer(minLength: 12)

                if showError && !hasReachedMinimum {
                    Text("Keep writing! You haven't reached the minimum yet.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.error)
                }

                doneButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if showSavePopup {
                savePopup
            }
        }
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
    }

    private var header: some View {
        HStack {
            RoundBackButton { route = .home }
            Spacer()
        }
    }

    private var promptSection: some View {
        VStack(spacing: 10) {
            Text("Here's something to get you started.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text("\u{201C}\(currentPrompt)\u{201D}")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Theme.accent)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                shuffle()
            } label: {
                Text("Shuffle your prompt \u{21C4} (\(shufflesRemaining)/\(maxShuffles))")
                    .font(.system(size: 13, weight: .semibold))
                    .underline()
                    .foregroundStyle(shufflesRemaining > 0 ? Theme.accent : Theme.inkMuted)
            }
            .disabled(shufflesRemaining == 0)
        }
        .padding(.horizontal, 16)
    }

    private var paperBox: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.ink, lineWidth: 2))
            .frame(height: 300)
            .overlay(
                TextEditor(text: $draft)
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
        .disabled(isRecognizingText)
    }

    private var tipBox: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{1F4A1}")
            Text("Tip: ").fontWeight(.bold) +
            Text("Be creative. Be yourself. Write in any form you'd like, and reach a minimum of \(minimumCharacterCount) characters.")
        }
        .font(.system(size: 13))
        .foregroundStyle(Theme.tipText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.tipFill))
    }

    private var doneButton: some View {
        Button {
            if hasReachedMinimum {
                showSavePopup = true
            } else {
                showError = true
            }
        } label: {
            Text("Done")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .hardCard()
    }

    private var savePopup: some View {
        ZStack {
            Theme.overlay.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Save for later or publish now?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text("Save it as a draft to continue later, or publish it to share it with other readers.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button {
                        finish(status: .draft)
                    } label: {
                        Text("Save draft")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .hardCard(cornerRadius: 24, shadowOffset: 3)

                    Button {
                        finish(status: .published)
                    } label: {
                        Text("Publish")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.card)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .hardCard(fill: Theme.ink, cornerRadius: 24, shadowOffset: 3)
                }
            }
            .padding(22)
            .frame(maxWidth: 320)
            .hardCard(cornerRadius: 22)
        }
    }

    private func shuffle() {
        guard shufflesRemaining > 0 else { return }
        currentPrompt = WritingPrompts.random(excluding: currentPrompt)
        shufflesRemaining -= 1
    }

    private func finish(status: EntryStatus) {
        store.save(body: draft, prompt: currentPrompt, status: status)
        showSavePopup = false
        route = .animation
    }

    private func recognizeText(from images: [UIImage]) {
        guard !images.isEmpty else { return }
        isRecognizingText = true
        Task {
            let recognized = await TextRecognizer.recognizeText(in: images)
            isRecognizingText = false
            guard !recognized.isEmpty else { return }
            draft = draft.isEmpty ? recognized : draft + "\n\n" + recognized
        }
    }
}

#Preview {
    WritingView(route: .constant(.writing))
        .environmentObject(AppStore())
}
