import Foundation

enum WritingPrompts {
    static let all: [String] = [
        "Losing a childhood home.",
        "A letter you never sent.",
        "The apology you never got.",
        "Something you wish you'd said sooner.",
        "A memory that still makes you smile.",
        "The version of you five years ago."
    ]

    static func random(excluding current: String?) -> String {
        var options = all
        if let current, options.count > 1 {
            options.removeAll { $0 == current }
        }
        return options.randomElement() ?? all[0]
    }
}
