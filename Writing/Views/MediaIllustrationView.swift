import SwiftUI

struct MediaIllustrationView: View {
    let media: MediaOption

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Theme.accentSoft)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.line, lineWidth: 1))

            content
        }
        .frame(height: 260)
    }

    @ViewBuilder
    private var content: some View {
        switch media {
        case .bowl:
            ZStack {
                Image(systemName: "basket.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(Theme.ink)
                paperPeek(rotation: -18, xOffset: -34, yOffset: -78)
                paperPeek(rotation: 6, xOffset: 4, yOffset: -92)
                paperPeek(rotation: 20, xOffset: 38, yOffset: -76)
            }
        case .mailbox:
            ZStack {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 110))
                    .foregroundStyle(Theme.ink)
                paperPeek(rotation: -10, xOffset: -18, yOffset: -50)
                paperPeek(rotation: 12, xOffset: 22, yOffset: -46)
            }
        case .bird:
            ZStack {
                Image(systemName: "bird.fill")
                    .font(.system(size: 110))
                    .foregroundStyle(Theme.ink)
                Image(systemName: "envelope.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.muted)
                    .rotationEffect(.degrees(-16))
                    .offset(x: -58, y: 34)
            }
        }
    }

    private func paperPeek(rotation: Double, xOffset: CGFloat, yOffset: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.line, lineWidth: 1))
            .frame(width: 34, height: 44)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
    }
}
