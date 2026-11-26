import SwiftUI

// MARK: - Color helpers

extension Color {
    /// Creates a color from a 0xRRGGBB literal.
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - Themes

/// The bold color worlds Dewy can live in. Lagoon is free, the rest are part of Dewy+.
///
/// Every screen is built from the same few layers: a saturated `hero` color field up top,
/// a calm `canvas` underneath, and solid `card`s that hold the content.
enum AppTheme: String, CaseIterable, Codable, Identifiable {
    case lagoon, peach, matcha, lavender, midnight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lagoon: "Lagoon"
        case .peach: "Peachy"
        case .matcha: "Matcha"
        case .lavender: "Lavender"
        case .midnight: "Midnight"
        }
    }

    var isPremium: Bool { self != .lagoon }

    var isDark: Bool { self == .midnight }

    var colorScheme: ColorScheme { isDark ? .dark : .light }

    // MARK: Hero color field

    /// The signature color of the theme, used for big full-bleed areas.
    var hero: Color {
        switch self {
        case .lagoon: Color(hex: 0x15BEEC)
        case .peach: Color(hex: 0xFF7E67)
        case .matcha: Color(hex: 0x2CC17C)
        case .lavender: Color(hex: 0x8D6CFF)
        case .midnight: Color(hex: 0x262D74)
        }
    }

    /// A deeper shade of the hero color for depth, discs and shadows.
    var heroDeep: Color {
        switch self {
        case .lagoon: Color(hex: 0x0793D7)
        case .peach: Color(hex: 0xEF5468)
        case .matcha: Color(hex: 0x139E62)
        case .lavender: Color(hex: 0x6846EE)
        case .midnight: Color(hex: 0x141846)
        }
    }

    /// A lighter tint of the hero color.
    var heroLight: Color {
        switch self {
        case .lagoon: Color(hex: 0x6BDDFF)
        case .peach: Color(hex: 0xFFB59E)
        case .matcha: Color(hex: 0x86E3B3)
        case .lavender: Color(hex: 0xBCA8FF)
        case .midnight: Color(hex: 0x4652BD)
        }
    }

    /// Brand color that stays readable on cards and the canvas.
    var accent: Color {
        switch self {
        case .lagoon: Color(hex: 0x0A8ED3)
        case .peach: Color(hex: 0xEC4F63)
        case .matcha: Color(hex: 0x12985D)
        case .lavender: Color(hex: 0x6846EE)
        case .midnight: Color(hex: 0x93A6FF)
        }
    }

    /// Dewy's default water color in this theme.
    var water: Color {
        switch self {
        case .lagoon: Color(hex: 0x2E8BFF)
        case .peach: Color(hex: 0xFF5D7E)
        case .matcha: Color(hex: 0x1FB06B)
        case .lavender: Color(hex: 0x7A55FF)
        case .midnight: Color(hex: 0x4FC3FF)
        }
    }

    // MARK: Surfaces

    /// Page background under the hero.
    var canvas: Color { isDark ? Color(hex: 0x0E1131) : Color(hex: 0xF2F5FB) }

    /// Solid card surface.
    var card: Color { isDark ? Color(hex: 0x1B2054) : .white }

    /// Slightly raised fill used for chips, tracks and empty glasses.
    var well: Color { isDark ? Color.white.opacity(0.09) : Color(hex: 0xEDF1F8) }

    /// Hairlines and dividers.
    var line: Color { isDark ? Color.white.opacity(0.08) : Color(hex: 0xE7EBF3) }

    var shadow: Color { isDark ? Color.black.opacity(0.45) : Color(hex: 0x1E2340).opacity(0.09) }

    // MARK: Text

    /// Primary text color: a deep, friendly navy instead of harsh black.
    var ink: Color { isDark ? Color(hex: 0xF4F3FF) : Color(hex: 0x1E2340) }

    /// Secondary text color.
    var inkSoft: Color { isDark ? Color(hex: 0xA8AEDC) : Color(hex: 0x7D84A3) }

    /// Text placed on the hero color.
    var onHero: Color { .white }

    var onHeroSoft: Color { Color.white.opacity(0.78) }

    // MARK: Call to action

    /// Background of the big pill buttons (a dark navy, like a marker on paper).
    var cta: Color { isDark ? Color(hex: 0xFFD45C) : Color(hex: 0x1E2340) }

    var onCta: Color { isDark ? Color(hex: 0x1E2340) : .white }

    /// Ink used to draw Dewy's face.
    var faceInk: Color { Color(hex: 0x1E2340) }

    // MARK: Gradients

    var heroGradient: LinearGradient {
        LinearGradient(colors: [hero, heroDeep], startPoint: .top, endPoint: .bottom)
    }

    var waterGradient: LinearGradient {
        LinearGradient(colors: [water.opacity(0.85), water], startPoint: .top, endPoint: .bottom)
    }

    /// Sky colors for the garden landscape.
    var sky: [Color] {
        switch self {
        case .lagoon: [Color(hex: 0x47CFF5), Color(hex: 0xB9EEFF)]
        case .peach: [Color(hex: 0xFF8E73), Color(hex: 0xFFD7B8)]
        case .matcha: [Color(hex: 0x5BD3C0), Color(hex: 0xD3F7E6)]
        case .lavender: [Color(hex: 0x9C7DFF), Color(hex: 0xE3D8FF)]
        case .midnight: [Color(hex: 0x10133C), Color(hex: 0x353F9E)]
        }
    }
}

// MARK: - Shared palette

/// Bold, flat colors shared by every theme.
enum Palette {
    static let sunshine = Color(hex: 0xFFC83D)
    static let tangerine = Color(hex: 0xFF9F1C)
    static let coral = Color(hex: 0xFF6B5E)
    static let berry = Color(hex: 0xE5384F)
    static let blush = Color(hex: 0xFF7FA8)
    static let grape = Color(hex: 0x6C5CE7)
    static let sky = Color(hex: 0x2FB4FF)
    static let aqua = Color(hex: 0x19C6D9)
    static let mint = Color(hex: 0x37CB8B)
    static let leaf = Color(hex: 0x48C46F)
    static let leafDeep = Color(hex: 0x2B9F57)
    static let soil = Color(hex: 0xB98563)
    static let flame = LinearGradient(colors: [Color(hex: 0xFFC03F), Color(hex: 0xFF5A4E)], startPoint: .top, endPoint: .bottom)
    static let gold = LinearGradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0xFFAE2B)], startPoint: .top, endPoint: .bottom)
    static let confetti: [Color] = [sunshine, blush, mint, grape, sky, coral, tangerine]

    /// Colors for streak runs on the calendar, picked in order.
    static let runs: [Color] = [
        Color(hex: 0x5B5BD6), Color(hex: 0xE5384F), Color(hex: 0x1FA463),
        Color(hex: 0x10A7E0), Color(hex: 0xFF8A1C), Color(hex: 0xF0508D)
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

extension Font {
    /// Dewy speaks in chunky, rounded letters.
    static func dewy(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
