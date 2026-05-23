import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: — Hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    // Adaptive color — light/dark mode aware
    init(lightHex: String, darkHex: String) {
        #if canImport(UIKit)
        let light = UIColor(Color(hex: lightHex))
        let dark  = UIColor(Color(hex: darkHex))
        self.init(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
        #else
        self.init(hex: lightHex)
        #endif
    }
}

// MARK: — Colors

extension Color {
    // Primary
    static let aquaPrimary = Color(hex: "#2A96A8")
    static let aquaLight   = Color(hex: "#4BB8C8")
    static let aquaDark    = Color(hex: "#146F7E")

    // Secondary
    static let sagePrimary = Color(hex: "#357A54")
    static let sageLight   = Color(hex: "#5A9E78")
    static let sageDark    = Color(hex: "#1E5939")

    // Neutral — adaptive (light / dark)
    static let backgroundPage = Color(lightHex: "#F2F2F7", darkHex: "#1C1C1E")
    static let backgroundCard = Color(lightHex: "#FDFAF6", darkHex: "#2C2C2E")
    static let borderDefault  = Color(lightHex: "#C6C6C8", darkHex: "#38383A")
    static let textPrimary    = Color(lightHex: "#3A3830", darkHex: "#F5F5F0")
    static let textSecondary  = Color(lightHex: "#706C60", darkHex: "#AEAEB2")
    static let textTertiary   = Color(lightHex: "#8E8E93", darkHex: "#636366")

    // Severity — use ONLY for interaction flag badges
    static let criticalBG  = Color(hex: "#FDE8E8")
    static let criticalFG  = Color(hex: "#7B1010")
    static let advisoryBG  = Color(hex: "#FEF0C7")
    static let advisoryFG  = Color(hex: "#7A3B0A")
    static let positiveBG  = Color(hex: "#E6F2EC")
    static let positiveFG  = Color(hex: "#175232")
    static let notFoundBG  = Color(hex: "#F0EEE9")
    static let notFoundFG  = Color(hex: "#5E5C56")
}

// MARK: — ShapeStyle forwarding (enables dot-syntax in foregroundStyle/background)

extension ShapeStyle where Self == Color {
    static var aquaPrimary: Color { Color.aquaPrimary }
    static var aquaLight:   Color { Color.aquaLight }
    static var aquaDark:    Color { Color.aquaDark }
    static var sagePrimary: Color { Color.sagePrimary }
    static var sageLight:   Color { Color.sageLight }
    static var sageDark:    Color { Color.sageDark }
    static var backgroundPage: Color { Color.backgroundPage }
    static var backgroundCard: Color { Color.backgroundCard }
    static var borderDefault:  Color { Color.borderDefault }
    static var textPrimary:    Color { Color.textPrimary }
    static var textSecondary:  Color { Color.textSecondary }
    static var textTertiary:   Color { Color.textTertiary }
    static var criticalBG: Color { Color.criticalBG }
    static var criticalFG: Color { Color.criticalFG }
    static var advisoryBG: Color { Color.advisoryBG }
    static var advisoryFG: Color { Color.advisoryFG }
    static var positiveBG: Color { Color.positiveBG }
    static var positiveFG: Color { Color.positiveFG }
    static var notFoundBG: Color { Color.notFoundBG }
    static var notFoundFG: Color { Color.notFoundFG }
}

// MARK: — Typography

extension Font {
    static let swLargeTitle = Font.system(size: 34, weight: .bold,     design: .default)
    static let swTitle1     = Font.system(size: 28, weight: .bold,     design: .default)
    static let swTitle2     = Font.system(size: 22, weight: .bold,     design: .default)
    static let swHeadline   = Font.system(size: 17, weight: .semibold, design: .default)
    static let swBody       = Font.system(size: 17, weight: .regular,  design: .default)
    static let swCallout    = Font.system(size: 16, weight: .regular,  design: .default)
    static let swFootnote   = Font.system(size: 13, weight: .regular,  design: .default)
    static let swCaption    = Font.system(size: 11, weight: .regular,  design: .default)
}
