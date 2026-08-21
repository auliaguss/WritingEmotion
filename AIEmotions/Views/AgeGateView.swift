//
//  AgeGateView.swift
//  AIEmotions
//
//  One-time, on-device age question. ContentView presents this after the
//  branded splash whenever the local User has no confirmed age.
//

import SwiftUI

struct AgeGateView: View {
    let onContinue: (Int) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .accessibilityHidden(true)

                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("How old are you?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.ink)

                        Text("We use your age to decide whether writing with strong language should be censored.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkMuted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 14) {
                        ageOption(
                            title: "18 or older",         systemImage: "figure.stand",
                            storedAge: 18
                        )

                        ageOption(
                            title: "Under 18",
                            systemImage: "figure.and.child.holdinghands",
                            storedAge: 17
                        )
                    }
                }
                .padding(22)
                .hardCard(cornerRadius: 12, shadowOffset: 6)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
    }

    private func ageOption(
        title: String,
        systemImage: String,
        storedAge: Int
    ) -> some View {
        Button {
            onContinue(storedAge)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .hardCard(cornerRadius: 16, shadowOffset: 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Under 18") {
    AgeGateView { _ in }
}
