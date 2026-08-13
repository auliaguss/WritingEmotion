import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: LetterStore
    @State private var showWrite = false
    @State private var strangerLetter: Letter?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header
                mediaSelector
                readWriteButtons
                MediaIllustrationView(media: store.selectedMedia)
                    .padding(.horizontal, 24)
                emotionPicker
            }
            .padding(.vertical, 24)
        }
        .background(Theme.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $showWrite) {
            WriteLetterView().environmentObject(store)
        }
        .fullScreenCover(item: $strangerLetter) { letter in
            ReadLetterView(letter: letter).environmentObject(store)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THE JAR")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.muted)
            Text("Let it go, one letter at a time")
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private var mediaSelector: some View {
        HStack(spacing: 12) {
            ForEach(MediaOption.allCases) { option in
                Button {
                    store.selectedMedia = option
                } label: {
                    Image(systemName: option.chipIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(store.selectedMedia == option ? Theme.accentInk : Theme.ink)
                        .frame(width: 44, height: 44)
                        .background(store.selectedMedia == option ? Theme.accent : Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                }
            }
        }
    }

    private var readWriteButtons: some View {
        HStack(spacing: 12) {
            actionButton(title: "Read", systemImage: "envelope.open.fill") {
                strangerLetter = store.randomStrangerLetter()
            }
            actionButton(title: "Write", systemImage: "pencil") {
                showWrite = true
            }
        }
        .padding(.horizontal, 24)
    }

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
        }
    }

    private var emotionPicker: some View {
        HStack(spacing: 20) {
            Button {
                store.previousEmotion()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Theme.ink)
            }

            Text(store.selectedEmotion.label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(minWidth: 110)
                .padding(.vertical, 10)
                .background(Theme.accentSoft)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.line, lineWidth: 1))

            Button {
                store.nextEmotion()
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.ink)
            }
        }
    }
}
