import SwiftUI
import UIKit

enum Theme {
    static let background = Color(light: 0xFFFFFF, dark: 0x0A0A0A)
    static let surface = Color(light: 0xFFFFFF, dark: 0x171717)
    static let ink = Color(light: 0x111111, dark: 0xF2F2F2)
    static let muted = Color(light: 0x6B6B6B, dark: 0x9A9A9A)
    static let line = Color(light: 0xDDDDDD, dark: 0x2C2C2C)
    static let accent = Color(light: 0x111111, dark: 0xF2F2F2)
    static let accentInk = Color(light: 0xFFFFFF, dark: 0x0A0A0A)
    static let accentSoft = Color(light: 0xEDEDED, dark: 0x232323)
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
