import SwiftUI
import UIKit
import CoreText

// MARK: - Color helpers

extension Color {
    /// Creates a color from a 0xRRGGBB literal.
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    /// Blends this color toward `other` by `amount` (0…1). Works on iOS 17, unlike `mix(with:by:)`.
    func blended(with other: Color, by amount: Double) -> Color {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = CGFloat(min(max(amount, 0), 1))
        return Color(
            .sRGB,
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t),
            opacity: Double(a1 + (a2 - a1) * t)
        )
    }
}

// MARK: - Worlds

/// The little worlds Dewy can live in. Lagoon is free, the rest are part of Dewy+.
///
/// Every world is described the same way: a three-stop sky, a body of water at the horizon,
/// a sun (or moon), and one brand accent with a deeper "lip" shade for candy buttons.
/// Screens never pick raw colors; they read them from the current world.
enum AppTheme: String, CaseIterable, Codable, Identifiable {
    case lagoon, peach, matcha, lavender, midnight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lagoon: "Lagoon"
        case .peach: "Sunset"
        case .matcha: "Meadow"
        case .lavender: "Dreamy"
        case .midnight: "Midnight"
        }
    }

    var tagline: String {
        switch self {
        case .lagoon: "Turquoise island days"
        case .peach: "Golden hour by the sea"
        case .matcha: "A pond in the hills"
        case .lavender: "Floating above the clouds"
        case .midnight: "Moonlit and cozy"
        }
    }

    var isPremium: Bool { self != .lagoon }

    var isDark: Bool { self == .midnight }

    var colorScheme: ColorScheme { isDark ? .dark : .light }

    // MARK: Sky

    /// Sky from the top of the screen down to the horizon.
    var sky: [Color] {
        switch self {
        case .lagoon: [Color(hex: 0x1C9EFF), Color(hex: 0x54C3FF), Color(hex: 0xA8E5FF)]
        case .peach: [Color(hex: 0xFF6F91), Color(hex: 0xFF9A7B), Color(hex: 0xFFD9A8)]
        case .matcha: [Color(hex: 0x2DBE9B), Color(hex: 0x71D9B4), Color(hex: 0xD2F5DC)]
        case .lavender: [Color(hex: 0x7F63FF), Color(hex: 0xAE8CFF), Color(hex: 0xF1DDFF)]
        case .midnight: [Color(hex: 0x0B0F3B), Color(hex: 0x1C2470), Color(hex: 0x3A3F9E)]
        }
    }

    /// Glow of the sun (or moon) in the upper corner.
    var sunGlow: Color {
        switch self {
        case .lagoon: Color(hex: 0xFFF6C9)
        case .peach: Color(hex: 0xFFF0B8)
        case .matcha: Color(hex: 0xFFFBD6)
        case .lavender: Color(hex: 0xFFE3F4)
        case .midnight: Color(hex: 0xB9C4FF)
        }
    }

    /// The water at the horizon, top to bottom.
    var sea: [Color] {
        switch self {
        case .lagoon: [Color(hex: 0x3FD0E8), Color(hex: 0x12A4D4)]
        case .peach: [Color(hex: 0xFFAE95), Color(hex: 0xF0728E)]
        case .matcha: [Color(hex: 0x5ED3B0), Color(hex: 0x23AA86)]
        case .lavender: [Color(hex: 0xC6B1FF), Color(hex: 0x9C80F7)]
        case .midnight: [Color(hex: 0x27338A), Color(hex: 0x141B57)]
        }
    }

    /// The bright line where the water meets the sky.
    var seaGlint: Color {
        switch self {
        case .lagoon: Color(hex: 0xA6F0F8)
        case .peach: Color(hex: 0xFFE0C2)
        case .matcha: Color(hex: 0xB9F3D6)
        case .lavender: Color(hex: 0xF1E6FF)
        case .midnight: Color(hex: 0x6E7DE0)
        }
    }

    /// Shadow tone used on the underside of clouds.
    var cloudShade: Color {
        switch self {
        case .lagoon: Color(hex: 0xDDF2FF)
        case .peach: Color(hex: 0xFFE2D6)
        case .matcha: Color(hex: 0xE2F8EC)
        case .lavender: Color(hex: 0xEDE2FF)
        case .midnight: Color(hex: 0x8E98E0)
        }
    }

    /// The lily pad Dewy stands on.
    var pad: Color {
        switch self {
        case .lavender: Color(hex: 0xFFB8DD)
        case .peach: Color(hex: 0x8EDC8F)
        case .midnight: Color(hex: 0x52B788)
        default: Color(hex: 0x7BD88F)
        }
    }

    var padLight: Color {
        switch self {
        case .lavender: Color(hex: 0xFFD6EC)
        case .midnight: Color(hex: 0x74CDA0)
        default: Color(hex: 0xA3E9AE)
        }
    }

    // MARK: Brand

    /// The world's brand color: links, selected states and primary buttons.
    var accent: Color {
        switch self {
        case .lagoon: Color(hex: 0x1F8CE6)
        case .peach: Color(hex: 0xF4546E)
        case .matcha: Color(hex: 0x14A46D)
        case .lavender: Color(hex: 0x7A55F5)
        case .midnight: Color(hex: 0xFFC94A)
        }
    }

    /// The darker "lip" under candy buttons in the accent color.
    var accentDeep: Color {
        switch self {
        case .lagoon: Color(hex: 0x1570C4)
        case .peach: Color(hex: 0xD23A57)
        case .matcha: Color(hex: 0x0D8656)
        case .lavender: Color(hex: 0x5D3CD8)
        case .midnight: Color(hex: 0xE0A21E)
        }
    }

    /// A soft wash of the accent for selected backgrounds.
    var accentSoft: Color {
        switch self {
        case .lagoon: Color(hex: 0xE3F3FF)
        case .peach: Color(hex: 0xFFE6EA)
        case .matcha: Color(hex: 0xDDF6EA)
        case .lavender: Color(hex: 0xEEE8FF)
        case .midnight: Color.white.opacity(0.1)
        }
    }

    /// Text placed on the accent color.
    var onAccent: Color { isDark ? Color(hex: 0x241F52) : .white }

    /// Accent used for text links (stays readable in the dark world).
    var link: Color { isDark ? Color(hex: 0xA9B6FF) : accent }

    // MARK: Compatibility names

    var hero: Color { sky[1] }
    var heroDeep: Color { sky[0] }
    var heroLight: Color { sky[2] }

    /// Dewy's default water color in this world.
    var water: Color {
        switch self {
        case .lagoon: Color(hex: 0x4DB4FF)
        case .peach: Color(hex: 0xFF8AA0)
        case .matcha: Color(hex: 0x4FCB9A)
        case .lavender: Color(hex: 0x9A7BFF)
        case .midnight: Color(hex: 0x5EC8FF)
        }
    }

    // MARK: Surfaces

    var canvas: Color { isDark ? Color(hex: 0x0F1235) : Color(hex: 0xF5F6FB) }

    var card: Color { isDark ? Color(hex: 0x1C2156) : .white }

    /// Raised fill for chips, tracks and wells.
    var well: Color { isDark ? Color.white.opacity(0.08) : Color(hex: 0xEEF0F7) }

    var line: Color { isDark ? Color.white.opacity(0.08) : Color(hex: 0xE9EBF4) }

    /// Card shadows are tinted with the world's sky instead of plain gray.
    var shadow: Color { isDark ? Color.black.opacity(0.4) : sky[0].opacity(0.10) }

    // MARK: Text

    var ink: Color { isDark ? Color(hex: 0xF4F3FF) : Color(hex: 0x262150) }

    var inkSoft: Color { isDark ? Color(hex: 0xA6ACDC) : Color(hex: 0x8A88A8) }

    var onHero: Color { .white }

    var onHeroSoft: Color { Color.white.opacity(0.82) }

    // MARK: Call to action

    var cta: Color { accent }
    var ctaDeep: Color { accentDeep }
    var onCta: Color { onAccent }

    var faceInk: Color { Color(hex: 0x2A2350) }

    // MARK: Gradients

    var skyGradient: LinearGradient {
        LinearGradient(stops: [
            .init(color: sky[0], location: 0),
            .init(color: sky[1], location: 0.55),
            .init(color: sky[2], location: 1)
        ], startPoint: .top, endPoint: .bottom)
    }

    var heroGradient: LinearGradient { skyGradient }

    var seaGradient: LinearGradient {
        LinearGradient(colors: sea, startPoint: .top, endPoint: .bottom)
    }

    var waterGradient: LinearGradient {
        LinearGradient(colors: [water.opacity(0.85), water], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Shared palette

/// Bright accents shared by every world.
enum Palette {
    static let sunshine = Color(hex: 0xFFC83D)
    static let tangerine = Color(hex: 0xFF9F1C)
    static let coral = Color(hex: 0xFF6B5E)
    static let berry = Color(hex: 0xEC4F7B)
    static let blush = Color(hex: 0xFF8FB1)
    static let grape = Color(hex: 0x7A5CF0)
    static let sky = Color(hex: 0x3AAEFF)
    static let aqua = Color(hex: 0x2CC9D9)
    static let mint = Color(hex: 0x39C98E)
    static let leaf = Color(hex: 0x5CC46F)
    static let leafDeep = Color(hex: 0x3A9F52)
    static let soil = Color(hex: 0xB98563)
    static let ink = Color(hex: 0x262150)
    static let cheek = Color(hex: 0xFF7FA6)
    static let flame = LinearGradient(colors: [Color(hex: 0xFFC63F), Color(hex: 0xFF6A3D)], startPoint: .top, endPoint: .bottom)
    static let gold = LinearGradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0xFFAE2B)], startPoint: .top, endPoint: .bottom)
    static let confetti: [Color] = [sunshine, blush, mint, grape, sky, coral, tangerine]

    /// Colors for streak runs on the calendar, picked in order.
    static let runs: [Color] = [
        Color(hex: 0x6A5CF0), Color(hex: 0xF4546E), Color(hex: 0x22B07D),
        Color(hex: 0x1F9BEF), Color(hex: 0xFF9524), Color(hex: 0xEC4FA0)
    ]
}

// MARK: - Environment

private struct DewyThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .lagoon
}

extension EnvironmentValues {
    var dewyTheme: AppTheme {
        get { self[DewyThemeKey.self] }
        set { self[DewyThemeKey.self] = newValue }
    }
}

// MARK: - Typography

/// Dewy's display face. Fredoka's round terminals echo Dewy's own shape;
/// it is used for headlines, numbers and buttons, while body copy stays in SF Rounded.
enum DisplayWeight {
    case medium, semibold, bold

    var fontName: String {
        switch self {
        case .medium: "Fredoka-Medium"
        case .semibold: "Fredoka-SemiBold"
        case .bold: "Fredoka-Bold"
        }
    }
}

extension Font {
    /// Body copy: SF Pro Rounded.
    static func dewy(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Headlines, numbers and buttons: Fredoka.
    static func display(_ size: CGFloat, _ weight: DisplayWeight = .semibold) -> Font {
        .custom(weight.fontName, fixedSize: size)
    }
}

/// Registers the bundled Fredoka fonts once at launch.
enum FontRegistry {
    static func registerFonts() {
        for weight in [DisplayWeight.medium, .semibold, .bold] {
            let url = Bundle.main.url(forResource: weight.fontName, withExtension: "ttf")
                ?? Bundle.main.url(forResource: weight.fontName, withExtension: "ttf", subdirectory: "Fonts")
            guard let url else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
