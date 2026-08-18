//
//  SplashView.swift
//  AIEmotions
//
//  Launch splash using the shared Theme design system (ported from the
//  "Writing" branch's visual style). Deliberately a text wordmark rather
//  than reusing that branch's "Pen Pals" logo asset, which belongs to a
//  different app identity.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Theme.ink)

                Text("AIEmotions")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
        }
    }
}

#Preview {
    SplashView()
}
