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

// MARK: - Visual language
//
// Dewy's look in one paragraph: soft clay toys on warm cream paper.
// - Surfaces are cream (#FFF8F0) with white clay cards: an inner top highlight and a warm,
//   colored drop shadow instead of gray.
// - Text is a warm plum-cocoa ink, never pure black.
// - One accent (aqua) means "water / do this". Coral means rewards and Dew Drops.
//   Butter yellow means streaks. Other pastels only ever tint illustrations and charts.
// - Skies follow the real time of day: peach dawn, aqua day, lilac dusk, indigo night.
// - Headlines and numbers are Fredoka; everything else is SF Pro Rounded.

enum Ink {
    static let primary = Color(hex: 0x3E2F45)
    static let soft = Color(hex: 0x9A8A9E)
    static let faint = Color(hex: 0xC8BAC4)
}

/// The pastel palette. Only `aqua`, `coral` and `butter` carry meaning in the UI;
/// the rest are for illustration, charts and friend tints.
enum Palette {
    static let cream = Color(hex: 0xFFF8F0)
    static let creamDeep = Color(hex: 0xFBEFE3)
    static let paper = Color(hex: 0xFFFDFA)

    static let aqua = Color(hex: 0x2EAEE6)
    static let aquaDeep = Color(hex: 0x1C8CC6)
    static let aquaLight = Color(hex: 0x7FD3F5)
    static let aquaSoft = Color(hex: 0xDDF3FC)

    static let coral = Color(hex: 0xFF8A78)
    static let coralDeep = Color(hex: 0xE5675A)
    static let coralSoft = Color(hex: 0xFFE7E1)

    static let butter = Color(hex: 0xFFCF56)
    static let butterDeep = Color(hex: 0xE9A52A)
    static let butterSoft = Color(hex: 0xFFF3D0)

    static let lilac = Color(hex: 0xB6A3FF)
    static let lilacSoft = Color(hex: 0xEEE9FF)
    static let mint = Color(hex: 0x7FD6A6)
    static let mintSoft = Color(hex: 0xE2F6EA)
    static let pink = Color(hex: 0xFF9EC4)
    static let pinkSoft = Color(hex: 0xFFE6F0)
    static let peach = Color(hex: 0xFFC2A0)
    static let peachSoft = Color(hex: 0xFFEDE2)

    // Compatibility names used by older views and the widget.
    static let sunshine = butter
    static let tangerine = Color(hex: 0xFFAE6B)
    static let berry = Color(hex: 0xF27BA5)
    static let blush = pink
    static let grape = lilac
    static let sky = aqua
    static let leaf = mint
    static let leafDeep = Color(hex: 0x4FB27F)
    static let soil = Color(hex: 0xC99B7C)
    static let ink = Ink.primary
    static let cheek = Color(hex: 0xFF8DB0)

    static let flame = LinearGradient(colors: [Color(hex: 0xFFD978), Color(hex: 0xFF9E5E)], startPoint: .top, endPoint: .bottom)
    static let gold = LinearGradient(colors: [Color(hex: 0xFFE48F), Color(hex: 0xFFB940)], startPoint: .top, endPoint: .bottom)
    static let dropGradient = LinearGradient(colors: [Color(hex: 0xFFB2A3), coral], startPoint: .top, endPoint: .bottom)
    static let confetti: [Color] = [butter, pink, mint, lilac, aquaLight, coral, peach]

    /// Colors for streak runs on the calendar, picked in order.
    static let runs: [Color] = [aqua, coral, mint, lilac, butterDeep, pink]

    /// Warm shadow tone for clay surfaces.
    static let shadow = Color(hex: 0xB98E7A)
}

// MARK: - Time of day

/// The sky follows the real time of day: a peach dawn, aqua day, lilac dusk and an indigo night.
enum SkyPhase: String, CaseIterable {
    case dawn, day, dusk, night

    static func at(_ date: Date) -> SkyPhase {
        if let forced = LaunchOptions.phase { return forced }
        if LaunchOptions.isDemo { return .day }
        switch Calendar.current.component(.hour, from: date) {
        case 5..<8: return .dawn
        case 8..<17: return .day
        case 17..<20: return .dusk
        default: return .night
        }
    }

    /// Sky from the top of the screen down to the horizon.
    var sky: [Color] {
        switch self {
        case .dawn: [Color(hex: 0xFFC9B5), Color(hex: 0xFFDCC8), Color(hex: 0xFFEEDD)]
        case .day: [Color(hex: 0x8FD6FA), Color(hex: 0xBDE8FC), Color(hex: 0xE6F7FF)]
        case .dusk: [Color(hex: 0xB9A6F5), Color(hex: 0xE9B9E0), Color(hex: 0xFFD4C4)]
        case .night: [Color(hex: 0x2F3279), Color(hex: 0x4A4C9E), Color(hex: 0x7D78C4)]
        }
    }

    /// The pond, from the far shore to the near edge.
    var pond: [Color] {
        switch self {
        case .dawn: [Color(hex: 0xBCE6EF), Color(hex: 0x86CDE2)]
        case .day: [Color(hex: 0x9DE3F4), Color(hex: 0x56BEE3)]
        case .dusk: [Color(hex: 0xC6C2F2), Color(hex: 0x9192DE)]
        case .night: [Color(hex: 0x50579F), Color(hex: 0x323778)]
        }
    }

    /// Light glinting on the water and on cloud tops.
    var glint: Color {
        switch self {
        case .dawn: Color(hex: 0xFFF1E2)
        case .day: .white
        case .dusk: Color(hex: 0xFFE8F1)
        case .night: Color(hex: 0xB9C0FF)
        }
    }

    var sunGlow: Color {
        switch self {
        case .dawn: Color(hex: 0xFFF0C9)
        case .day: Color(hex: 0xFFFBE0)
        case .dusk: Color(hex: 0xFFE0C2)
        case .night: Color(hex: 0xC9CCFF)
        }
    }

    /// Tint laid over cloud art so it sits in the light of the hour.
    var cloudTint: Color? {
        switch self {
        case .day: nil
        case .dawn: Color(hex: 0xFFC7A8)
        case .dusk: Color(hex: 0xD9A8E8)
        case .night: Color(hex: 0x5A5BAA)
        }
    }

    var isNight: Bool { self == .night }

    /// Text drawn straight on the sky.
    var onSky: Color { isNight ? .white : Ink.primary }
    var onSkySoft: Color { isNight ? .white.opacity(0.75) : Ink.primary.opacity(0.6) }

    var greeting: String {
        switch self {
        case .dawn: "Good morning"
        case .day: "Hello"
        case .dusk: "Good evening"
        case .night: "Sweet dreams"
        }
    }

    var gradient: LinearGradient {
        LinearGradient(stops: [
            .init(color: sky[0], location: 0),
            .init(color: sky[1], location: 0.55),
            .init(color: sky[2], location: 1)
        ], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Worlds

/// The places Dewy can live. Lagoon is free, the rest are part of Dewy+.
///
/// A world only changes the scenery (its landmark, the pond and, for Starlight, a forced night).
/// The interface itself always stays on cream with the aqua accent, so the app reads as one product.
enum AppTheme: String, CaseIterable, Codable, Identifiable {
    case lagoon, peach, matcha, lavender, midnight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lagoon: "Lagoon"
        case .peach: "Seaside"
        case .matcha: "Meadow"
        case .lavender: "Cloudland"
        case .midnight: "Starlight"
        }
    }

    var tagline: String {
        switch self {
        case .lagoon: "A palm island in turquoise water"
        case .peach: "Sailboats and a candy lighthouse"
        case .matcha: "Rolling hills and round little trees"
        case .lavender: "A castle floating on clouds"
        case .midnight: "Always night, always cozy"
        }
    }

    var isPremium: Bool { self != .lagoon }

    /// Landmark art drawn at the horizon, in the World asset folder.
    var landmarks: [String] {
        switch self {
        case .lagoon: ["prop-island"]
        case .peach: ["prop-lighthouse", "prop-sailboat"]
        case .matcha: ["prop-hills"]
        case .lavender: ["prop-castle"]
        case .midnight: ["prop-island"]
        }
    }

    /// The world's signature tint, used on its picker card.
    var tint: Color {
        switch self {
        case .lagoon: Color(hex: 0x7FD3F5)
        case .peach: Color(hex: 0xFFB59C)
        case .matcha: Color(hex: 0x8EDDB0)
        case .lavender: Color(hex: 0xC9B6FF)
        case .midnight: Color(hex: 0x8F93E8)
        }
    }

    /// The time of day to show in this world.
    func phase(at date: Date = .now) -> SkyPhase {
        self == .midnight ? .night : SkyPhase.at(date)
    }

    /// The UI never goes dark; only Starlight's scenery does.
    var isDark: Bool { false }
    var colorScheme: ColorScheme { .light }

    // MARK: Scenery (current time of day)

    var sky: [Color] { phase().sky }
    var sea: [Color] { phase().pond }
    var seaGlint: Color { phase().glint }
    var sunGlow: Color { phase().sunGlow }
    var cloudShade: Color { Color(hex: 0xEDE6FA) }
    var pad: Color { Color(hex: 0x8FD9A0) }
    var padLight: Color { Color(hex: 0xB9EBC3) }

    // MARK: Brand (shared by every world)

    var accent: Color { Palette.aqua }
    var accentDeep: Color { Palette.aquaDeep }
    var accentSoft: Color { Palette.aquaSoft }
    var onAccent: Color { .white }
    var link: Color { Palette.aquaDeep }

    var hero: Color { sky[1] }
    var heroDeep: Color { sky[0] }
    var heroLight: Color { sky[2] }

    /// Dewy's default water color.
    var water: Color { Color(hex: 0x5CC4F2) }

    // MARK: Surfaces

    var canvas: Color { Palette.cream }
    var card: Color { .white }
    var well: Color { Color(hex: 0xF8EEE4) }
    var line: Color { Color(hex: 0xF1E4D8) }
    var shadow: Color { Palette.shadow.opacity(0.2) }

    // MARK: Text

    var ink: Color { Ink.primary }
    var inkSoft: Color { Ink.soft }
    var inkFaint: Color { Ink.faint }
    var onHero: Color { phase().onSky }
    var onHeroSoft: Color { phase().onSkySoft }

    var cta: Color { accent }
    var ctaDeep: Color { accentDeep }
    var onCta: Color { onAccent }
    var faceInk: Color { Color(hex: 0x3A2A44) }

    // MARK: Gradients

    var skyGradient: LinearGradient { phase().gradient }
    var heroGradient: LinearGradient { skyGradient }
    var seaGradient: LinearGradient { LinearGradient(colors: sea, startPoint: .top, endPoint: .bottom) }
    var waterGradient: LinearGradient {
        LinearGradient(colors: [water.opacity(0.85), water], startPoint: .top, endPoint: .bottom)
    }
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

// MARK: - Art

/// Asset-catalog art with a graceful fallback, so a missing image never shows a blank square.
enum Art {
    static func exists(_ name: String) -> Bool { UIImage(named: name) != nil }
}
