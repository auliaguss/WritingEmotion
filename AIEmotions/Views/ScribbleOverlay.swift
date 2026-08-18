//
//  ScribbleOverlay.swift
//  AIEmotions
//
//  A quick hand-drawn-looking strike across a control to show it's
//  "used up" for the day, rather than just greying it out.
//

import SwiftUI

struct ScribbleOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: CGPoint(x: w * 0.03, y: h * 0.75))
                path.addLine(to: CGPoint(x: w * 0.97, y: h * 0.25))
                path.move(to: CGPoint(x: w * 0.05, y: h * 0.35))
                path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.68))
            }
            .stroke(Color.primary.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        RoundedRectangle(cornerRadius: 12)
            .fill(.orange.opacity(0.3))
            .frame(width: 200, height: 50)
        ScribbleOverlay()
            .frame(width: 200, height: 50)
    }
    .padding()
}
