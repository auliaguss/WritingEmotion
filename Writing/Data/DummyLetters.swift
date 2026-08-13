import Foundation

enum DummyLetters {
    static let all: [Letter] = [
        Letter(
            emotion: .sad,
            media: .bowl,
            body: "I still keep my grandmother's number saved in my phone. I know she's gone, but deleting it feels like losing her all over again.",
            signature: "A stranger from Bandung",
            dateLabel: "March 2, 2026"
        ),
        Letter(
            emotion: .sad,
            media: .bowl,
            body: "I moved to a new city for a job I thought I wanted. Most nights I eat dinner alone and pretend I'm fine when I call my parents.",
            signature: "A stranger from Surabaya",
            dateLabel: "January 14, 2026"
        ),
        Letter(
            emotion: .angry,
            media: .bowl,
            body: "My best friend borrowed money from me right before she stopped replying to my texts. It's been two years and I still think about it every payday.",
            signature: "A stranger from Jakarta",
            dateLabel: "February 9, 2026"
        ),
        Letter(
            emotion: .angry,
            media: .bowl,
            body: "I trained the person who ended up taking my promotion. Nobody at the office knows I still smile at him every single morning.",
            signature: "A stranger from Medan",
            dateLabel: "April 21, 2026"
        ),
        Letter(
            emotion: .happy,
            media: .bowl,
            body: "My dad called me just to say he was proud of me, for no particular reason at all. I've replayed that call in my head for weeks.",
            signature: "A stranger from Yogyakarta",
            dateLabel: "June 3, 2026"
        ),
        Letter(
            emotion: .happy,
            media: .bowl,
            body: "I ran into my childhood best friend at the airport after twelve years apart. We talked for three hours like no time had passed at all.",
            signature: "A stranger from Bali",
            dateLabel: "May 30, 2026"
        )
    ]

    static func random(for emotion: Emotion) -> Letter {
        all.filter { $0.emotion == emotion }.randomElement()
            ?? Letter(emotion: emotion, media: .bowl, body: "No letters yet for this emotion.", signature: "—", dateLabel: "")
    }
}
