import SwiftUI

struct LetterPaperCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            envelope
            paper
        }
    }

    private var envelope: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
                .frame(height: 180)

            EnvelopeFlap()
                .stroke(Theme.line, lineWidth: 1)
                .frame(height: 64)
        }
        .padding(.horizontal, 26)
        .offset(y: -14)
    }

    private var paper: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1.2))
            .frame(height: 360)
            .padding(.horizontal, 8)
            .overlay(content.padding(22))
            .shadow(color: .black.opacity(0.14), radius: 12, y: 8)
    }
}

private struct EnvelopeFlap: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
