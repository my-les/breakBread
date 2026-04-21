import SwiftUI

// MARK: - Typography

enum BBFont {
    static func courier(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return .custom("CourierNewPS-BoldMT", size: size)
        default:
            return .custom("CourierNewPSMT", size: size)
        }
    }

    static let heroNumber = courier(32, weight: .bold)
    static let title = courier(24, weight: .bold)
    static let sectionHeader = courier(20, weight: .bold)
    static let body = courier(16)
    static let bodyBold = courier(16, weight: .bold)
    static let button = courier(16, weight: .bold)
    static let caption = courier(13)
    static let captionBold = courier(13, weight: .bold)
    static let small = courier(11)
}

// MARK: - Colors

enum BBColor {
    static let background = Color("BBBackground", bundle: nil)
    static let cardSurface = Color("BBCardSurface", bundle: nil)
    static let primaryText = Color("BBPrimaryText", bundle: nil)
    static let secondaryText = Color("BBSecondaryText", bundle: nil)
    static let accent = Color("BBAccent", bundle: nil)
    static let onAccent = Color("BBOnAccent", bundle: nil)
    static let success = Color(hex: "008A05")
    static let error = Color(hex: "FF385C")
    static let border = Color("BBBorder", bundle: nil)

    static let white = Color.white
    static let black = Color(hex: "222222")
}

// MARK: - Spacing

enum BBSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum BBRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Shadow

struct BBShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func bbShadow() -> some View {
        modifier(BBShadow())
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
