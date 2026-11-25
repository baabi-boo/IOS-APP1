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

/// The dreamy color worlds Dewy can live in. Lagoon is free, the rest are part of Dewy+.
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

    // Water inside Dewy
    var waterTop: Color {
        switch self {
        case .lagoon: Color(hex: 0x8EE0FF)
        case .peach: Color(hex: 0xFFC2A8)
        case .matcha: Color(hex: 0xA8EBC0)
        case .lavender: Color(hex: 0xCDB6FF)
        case .midnight: Color(hex: 0x7FE7FF)
        }
    }

    var waterBottom: Color {
        switch self {
        case .lagoon: Color(hex: 0x4F9BFF)
        case .peach: Color(hex: 0xFF7FA3)
        case .matcha: Color(hex: 0x3FBF85)
        case .lavender: Color(hex: 0x8C78FF)
        case .midnight: Color(hex: 0x6C6CFF)
        }
    }

    // Screen background
    var backgroundTop: Color {
        switch self {
        case .lagoon: Color(hex: 0xE6F6FF)
        case .peach: Color(hex: 0xFFF1EA)
        case .matcha: Color(hex: 0xEEFAEE)
        case .lavender: Color(hex: 0xF2EDFF)
        case .midnight: Color(hex: 0x141833)
        }
    }

    var backgroundBottom: Color {
        switch self {
        case .lagoon: Color(hex: 0xF7EFFF)
        case .peach: Color(hex: 0xFFE4EF)
        case .matcha: Color(hex: 0xF7F6E2)
        case .lavender: Color(hex: 0xFFEEF7)
        case .midnight: Color(hex: 0x271B45)
        }
    }

    /// Soft floating blobs that drift behind every screen.
    var blobs: [Color] {
        switch self {
        case .lagoon: [Color(hex: 0x9BE4FF), Color(hex: 0xFFC6E0), Color(hex: 0xC9C2FF)]
        case .peach: [Color(hex: 0xFFC9A8), Color(hex: 0xFFB3CF), Color(hex: 0xFFE3A3)]
        case .matcha: [Color(hex: 0xB5F0C8), Color(hex: 0xE6F5A6), Color(hex: 0xA8E6E0)]
        case .lavender: [Color(hex: 0xD3C2FF), Color(hex: 0xFFC4E4), Color(hex: 0xB8D4FF)]
        case .midnight: [Color(hex: 0x3B3FA8), Color(hex: 0x7A3E9E), Color(hex: 0x1F6E9E)]
        }
    }

    var accent: Color {
        switch self {
        case .lagoon: Color(hex: 0x3E8BFF)
        case .peach: Color(hex: 0xFF6F91)
        case .matcha: Color(hex: 0x27A86B)
        case .lavender: Color(hex: 0x7A5CFF)
        case .midnight: Color(hex: 0x8FA8FF)
        }
    }

    var accentSecondary: Color {
        switch self {
        case .lagoon: Color(hex: 0x7CC8FF)
        case .peach: Color(hex: 0xFFA07A)
        case .matcha: Color(hex: 0x7BD9A0)
        case .lavender: Color(hex: 0xC08CFF)
        case .midnight: Color(hex: 0xB78CFF)
        }
    }

    /// Primary text color — a deep, friendly ink instead of harsh black.
    var ink: Color { isDark ? Color(hex: 0xF3F1FF) : Color(hex: 0x27304F) }

    /// Secondary text color.
    var inkSoft: Color { isDark ? Color(hex: 0xB3B0D6) : Color(hex: 0x7A809C) }

    /// Fill used under glass cards.
    var card: Color { isDark ? Color.white.opacity(0.07) : Color.white.opacity(0.55) }

    var cardStroke: Color { isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.85) }

    var shadow: Color { isDark ? Color.black.opacity(0.35) : waterBottom.opacity(0.16) }

    /// Ink used to draw Dewy's face.
    var faceInk: Color { Color(hex: 0x27304F) }

    var waterGradient: LinearGradient {
        LinearGradient(colors: [waterTop, waterBottom], startPoint: .top, endPoint: .bottom)
    }

    var accentGradient: LinearGradient {
        LinearGradient(colors: [accentSecondary, accent], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [backgroundTop, backgroundBottom], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Shared palette

enum Palette {
    static let blush = Color(hex: 0xFF8FB1)
    static let sunshine = Color(hex: 0xFFD66B)
    static let mint = Color(hex: 0x8FE3C0)
    static let coral = Color(hex: 0xFF8A7A)
    static let lilac = Color(hex: 0xC3A8FF)
    static let sky = Color(hex: 0x8ED8FF)
    static let flame = LinearGradient(colors: [Color(hex: 0xFFC15E), Color(hex: 0xFF6B6B)], startPoint: .top, endPoint: .bottom)
    static let leaf = Color(hex: 0x6CCB8C)
    static let soil = Color(hex: 0xC9A27E)
    static let confetti: [Color] = [blush, sunshine, mint, lilac, sky, coral]
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
    /// Dewy speaks in soft, rounded letters.
    static func dewy(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
