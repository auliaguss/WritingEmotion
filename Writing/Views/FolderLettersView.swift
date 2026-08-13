import SwiftUI

struct FolderLettersView: View {
    let media: MediaOption

    @EnvironmentObject var store: LetterStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                emotionFoldersGrid
            }
            .padding(.vertical, 24)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(media.label)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        Text("Sorted by emotion")
            .font(.system(size: 13))
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
    }

    private var emotionFoldersGrid: some View {
        HStack(alignment: .top, spacing: 16) {
            ForEach(Emotion.allCases) { emotion in
                NavigationLink(value: MediaEmotionSelection(media: media, emotion: emotion)) {
                    FolderStackView(label: emotion.label, count: store.count(for: media, emotion: emotion))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
    }
}
