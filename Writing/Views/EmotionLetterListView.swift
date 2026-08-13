import SwiftUI

struct EmotionLetterListView: View {
    let media: MediaOption
    let emotion: Emotion

    @EnvironmentObject var store: LetterStore
    @State private var selectedLetter: Letter?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if store.letters(for: media, emotion: emotion).isEmpty {
                    Text("You haven't written any letters here yet.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 40)
                } else {
                    ForEach(store.letters(for: media, emotion: emotion)) { letter in
                        Button {
                            selectedLetter = letter
                        } label: {
                            letterPreview(letter)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(emotion.label)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedLetter) { letter in
            ReadLetterView(letter: letter, allowReadAnother: false)
        }
    }

    private func letterPreview(_ letter: Letter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(letter.body)
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(letter.dateLabel)
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
    }
}
