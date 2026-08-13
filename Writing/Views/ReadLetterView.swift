import SwiftUI

struct ReadLetterView: View {
    @EnvironmentObject var store: LetterStore
    @Environment(\.dismiss) private var dismiss

    var allowReadAnother: Bool = true

    @State private var letter: Letter

    init(letter: Letter, allowReadAnother: Bool = true) {
        _letter = State(initialValue: letter)
        self.allowReadAnother = allowReadAnother
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            Text(letter.signature == "You" ? "Your \(letter.emotion.label.lowercased()) letter" : "Someone else's \(letter.emotion.label.lowercased()) letter")
                .font(.system(size: 15))
                .foregroundStyle(Theme.muted)

            Text(letter.emotion.writePrompt)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)

            LetterPaperCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text(letter.body)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("— \(letter.signature)")
                        Text(letter.dateLabel)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 8)

            if allowReadAnother {
                Button {
                    letter = store.randomStrangerLetter()
                } label: {
                    Text("Read Another")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.accentInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(Theme.background.ignoresSafeArea())
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
            Text(letter.emotion.label)
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
