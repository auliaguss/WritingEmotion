//
//  StickyNoteCard.swift
//  AIEmotions
//
//  Shared sticky-note look for grids of pieces — Profile's Published and
//  Bookmark tabs. A generic card (title, date, body preview, emotion
//  pills) so both real Posts and placeholder SampleNotes render the same
//  way. Distinct from ReadView's own StickyNoteView, which drives its
//  freeform pannable corkboard rather than a fixed grid.
//

import SwiftUI

let stickyNoteColors: [Color] = [
    Color(hex: 0x9BF6FF),
    Color(hex: 0xA0C4FF),
    Color(hex: 0xBDB2FF),
    Color(hex: 0xCAFFBF),
    Color(hex: 0xFDFFB6),
    Color(hex: 0xFFADAD),
    Color(hex: 0xFFC6FF),
    Color(hex: 0xFFD6A5),
]

/// Deterministic per-index tilt, so a card's rotation stays stable across
/// view updates instead of re-randomizing on every redraw.
func stickyNoteRotation(for index: Int) -> Double {
    Double((index * 47 + 3) % 11) - 5
}

struct StickyNoteCard: View {
    let title: String
    let date: Date
    let bodyPreview: String
    let emotions: [String]
    let color: Color
    let rotation: Double

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("pin")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(Theme.accent)
                .rotationEffect(.degrees(-45))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 12)
            
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)

            Text(Self.dateFormatter.string(from: date))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.ink.opacity(0.6))

            Text(bodyPreview)
                .font(.custom("WaitingfortheSunrise", size: 16))
//                .font(.system(size: 13))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineLimit(2)

            if !emotions.isEmpty {
                HStack(spacing: 6) {
                    ForEach(emotions, id: \.self) { emotion in
                        Text(emotion)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.card))
                            .overlay(Capsule().stroke(Theme.ink.opacity(0.4), lineWidth: 1))
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.1))
                    .offset(x: 3, y: 4)
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.ink.opacity(0.15), lineWidth: 0.5)
            }
        )
        .padding(.top, 8)
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    VStack {
        StickyNoteCard(title: "Hello", date: Date(), bodyPreview: "Hello, I'm Emo boi..", emotions: ["Hmm", "Hmm pt2"], color: stickyNoteColors[0], rotation: 4.0)
    }.padding(128)
}
