//
//  SplashView.swift
//  AIEmotions
//
//  Launch splash using the shared Theme design system (ported from the
//  "Writing" branch's visual style) and the app's Logo asset.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 220)
        }
    }
}

#Preview {
    SplashView()
}
