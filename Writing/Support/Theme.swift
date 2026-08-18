import SwiftUI

/// Fixed warm palette matching the Figma design — intentionally not dark-mode adaptive.
enum Theme {
    static let background = Color(hex: 0xFFE59E)
    static let card = Color(hex: 0xF5F2E8)
    static let ink = Color(hex: 0x482615)
    static let inkMuted = Color(hex: 0x482615).opacity(0.65)
    static let accent = Color(hex: 0xA3541A)
    static let tipFill = Color(hex: 0xA3541A)
    static let tipText = Color(hex: 0xF5F2E8)
    static let error = Color(hex: 0xC5392E)
    static let overlay = Color.black.opacity(0.35)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
