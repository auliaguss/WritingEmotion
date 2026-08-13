import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: LetterStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    foldersGrid
                }
                .padding(.vertical, 24)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationDestination(for: MediaOption.self) { media in
                FolderLettersView(media: media)
            }
            .navigationDestination(for: MediaEmotionSelection.self) { selection in
                EmotionLetterListView(media: selection.media, emotion: selection.emotion)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PROFILE")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.muted)
            Text("Your letters")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private var foldersGrid: some View {
        HStack(alignment: .top, spacing: 16) {
            ForEach(MediaOption.allCases) { media in
                NavigationLink(value: media) {
                    FolderStackView(label: media.label, count: store.count(for: media))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
    }
}
