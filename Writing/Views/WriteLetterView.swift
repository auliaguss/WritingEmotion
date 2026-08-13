import SwiftUI

struct WriteLetterView: View {
    @EnvironmentObject var store: LetterStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: String = ""
    @State private var showConfirm = false

    private var wordCount: Int {
        draft.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private var canSend: Bool { wordCount >= 10 }

    var body: some View {
        VStack(spacing: 20) {
            header

            Text(store.selectedEmotion.writePrompt)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)

            LetterPaperCard {
                TextEditor(text: $draft)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
            }
            .padding(.horizontal, 8)

            Text("\(min(wordCount, 10))/10 words minimum")
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)

            Button {
                showConfirm = true
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accentInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSend ? Theme.accent : Theme.line)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canSend)
            .padding(.horizontal, 24)
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(Theme.background.ignoresSafeArea())
        .alert("Are you sure you wanna send?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Send") {
                store.send(body: draft)
                dismiss()
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            Text(store.selectedEmotion.label)
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Theme.muted)
            Spacer()
            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 20)
    }
}
