//
//  ProfanityFilter.swift
//  AIEmotions
//
//  A deterministic, offline presentation filter. It deliberately uses
//  Unicode-aware whole-word boundaries: a blocked word such as "ass"
//  is censored on its own, while harmless words such as "class" and
//  "assignment" remain untouched.
//

import Foundation

enum ProfanityFilter {
    /// High-confidence English profanity and common written variants.
    /// Keep entries lowercase; matching itself is case-insensitive.
    /// Longer phrases are compiled first so they win over shorter terms.
    private static let terms: [String] = [
        "arseholes", "motherfuckers", "motherfucking", "son of a bitch",
        "bullshitting", "cocksuckers", "dumbasses", "fuckfaces",
        "motherfucker", "shitheads", "assholes", "bastards",
        "bullshit", "cocksucker", "dickheads", "dipshits",
        "douchebags", "fuckface", "fuckheads", "jackasses",
        "motherfuck", "pissheads", "shithead", "smartasses",
        "arsehole", "asshole", "bastard", "bitching",
        "cockheads", "dickhead", "dumbass", "fuckhead",
        "horseshit", "jackass", "pisshead", "shitfaced",
        "smartass", "clusterfuck", "douchebag", "fucktards",
        "shitstorm", "slutty", "whoring", "bollocks",
        "buggers", "bullshits", "dammit", "dickhead",
        "douche", "fucking", "fuckers", "fuckwit",
        "goddamn", "pissing", "pricks", "shitshow",
        "shitting", "titties", "twats", "wankers",
        "arse", "bitches", "bloody", "bugger",
        "cocks", "crapping", "dicks", "fucker",
        "fucked", "fuckup", "jackoff", "pissed",
        "shitbag", "shitty", "sluts", "whores",
        "bitch", "cock", "crappy", "dick",
        "dipshit", "fuck", "fuckups", "goddammit",
        "piss", "prick", "shit", "shits",
        "slut", "twat", "wanker", "whore",
        "asses", "damned", "dickwad", "fuckwad",
        "knobhead", "shitface", "wank", "arse",
        "ass", "damn", "hell", "crap"
    ]

    static var termCount: Int { Set(terms).count }

    private static let expression: NSRegularExpression = {
        let alternatives = Set(terms)
            .sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        let pattern = "(?<![\\p{L}\\p{N}_])(?:\(alternatives))(?![\\p{L}\\p{N}_])"
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    static func containsProfanity(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.firstMatch(in: text, range: range) != nil
    }

    static func censor(_ text: String) -> String {
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = expression.matches(in: text, range: fullRange)
        guard !matches.isEmpty else { return text }

        let censored = NSMutableString(string: text)
        for match in matches.reversed() {
            guard let swiftRange = Range(match.range, in: text) else { continue }
            let replacement = masked(String(text[swiftRange]))
            censored.replaceCharacters(in: match.range, with: replacement)
        }
        return censored as String
    }

    /// Leaves the first letter visible as a recognition cue, masks every
    /// following letter/number, and preserves spaces and punctuation.
    private static func masked(_ match: String) -> String {
        var keptFirstLetter = false
        return String(match.map { character in
            guard character.isLetter || character.isNumber else { return character }
            if !keptFirstLetter {
                keptFirstLetter = true
                return character
            }
            return "•"
        })
    }
}
