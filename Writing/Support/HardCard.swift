import SwiftUI

/// The offset hard-shadow "sticker" look used for buttons and cards throughout the design.
struct HardCardModifier: ViewModifier {
    var fill: Color
    var cornerRadius: CGFloat
    var borderWidth: CGFloat
    var shadowOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Theme.ink)
                        .offset(x: shadowOffset, y: shadowOffset)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Theme.ink, lineWidth: borderWidth)
                        )
                }
            )
    }
}

extension View {
    func hardCard(
        fill: Color = Theme.card,
        cornerRadius: CGFloat = 5,
        borderWidth: CGFloat = 2,
        shadowOffset: CGFloat = 5
    ) -> some View {
        modifier(HardCardModifier(fill: fill, cornerRadius: cornerRadius, borderWidth: borderWidth, shadowOffset: shadowOffset))
    }
}

struct RoundBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
        }
    }
}
