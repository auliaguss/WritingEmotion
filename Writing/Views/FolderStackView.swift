import SwiftUI

struct FolderStackView: View {
    let label: String
    let count: Int

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .top) {
                folder(tabAlignment: .trailing, rotation: -6, yOffset: -2, isFront: false)
                folder(tabAlignment: .center, rotation: 0, yOffset: 2, isFront: false)
                folder(tabAlignment: .leading, rotation: 6, yOffset: 8, isFront: true)

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(Theme.accentInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Theme.accent)
                    .clipShape(Capsule())
                    .offset(y: -12)
            }
            .frame(height: 96)

            Text("\(count) letters")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
        }
    }

    private func folder(tabAlignment: HorizontalAlignment, rotation: Double, yOffset: CGFloat, isFront: Bool) -> some View {
        VStack(alignment: tabAlignment, spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .frame(width: 44, height: 12)
                .padding(.horizontal, 10)

            RoundedRectangle(cornerRadius: 6)
                .frame(width: 120, height: 76)
        }
        .foregroundStyle(isFront ? Theme.surface : Theme.accentSoft)
        .overlay(
            VStack(alignment: tabAlignment, spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.line, lineWidth: 1)
                    .frame(width: 44, height: 12)
                    .padding(.horizontal, 10)
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.line, lineWidth: 1)
                    .frame(width: 120, height: 76)
            }
        )
        .rotationEffect(.degrees(rotation))
        .offset(y: yOffset)
        .shadow(color: .black.opacity(isFront ? 0.1 : 0), radius: 6, y: 4)
    }
}
