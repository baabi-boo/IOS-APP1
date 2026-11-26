import SwiftUI
import UIKit

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

// MARK: - Editorial Storybook Palette
//
// Dewy's visual language: tactile cotton rag paper paired with hand-mixed storybook gouache
// and deep botanical ink.
// - Paper grounds stay warm and unbleached (#FAF4EA / #FFFDF8), anchored by fine ink hairlines.
// - Copy is deep plum-espresso ink (#251E2B) and readable warm slate (#685E6D) — never pure black.
// - Cerulean spring (#237FA3) marks hydration & primary actions; terracotta coral (#D45842)
//   marks Dew Drops & rewards; antique ochre (#DC982B) marks streaks and Dewy+.
// - Each world holds its own hand-painted 4-phase atmosphere (dawn, day, dusk, night).
// - Display typography speaks in Apple New York (.serif); data and pills use SF Pro Rounded.

enum Ink {
    static let primary = Color(hex: 0x251E2B)
    static let soft = Color(hex: 0x685E6D)
    static let faint = Color(hex: 0xA398A6)
    static let hairline = Color(hex: 0x251E2B, opacity: 0.10)
    static let hairlineStrong = Color(hex: 0x251E2B, opacity: 0.17)
    static let starlight = Color(hex: 0xFAF5EC)
}

/// Hand-mixed storybook gouache pigments and cotton-paper surfaces.
enum Palette {
    // Cotton rag paper & archival wells
    static let cream = Color(hex: 0xFAF4EA)
    static let creamDeep = Color(hex: 0xF1E7D7)
    static let paper = Color(hex: 0xFFFDF8)
    static let parchment = Color(hex: 0xF5ECDE)

    // Cerulean spring water (primary interactive accent)
    static let aqua = Color(hex: 0x237FA3)
    static let aquaDeep = Color(hex: 0x185C78)
    static let aquaLight = Color(hex: 0x6EB4CE)
    static let aquaSoft = Color(hex: 0xE3F1F5)

    // Terracotta coral / persimmon (rewards & Dew Drops)
    static let coral = Color(hex: 0xD45842)
    static let coralDeep = Color(hex: 0xA83D2B)
    static let coralSoft = Color(hex: 0xFBE9E4)

    // Ochre marigold & antique brass (streaks & Dewy+)
    static let butter = Color(hex: 0xDC982B)
    static let butterDeep = Color(hex: 0xAA6C12)
    static let butterSoft = Color(hex: 0xFAF0D7)

    // Botanical gouache accents (illustrations, charts & companions)
    static let lilac = Color(hex: 0x7D6BB5)
    static let lilacSoft = Color(hex: 0xEEEBF8)
    static let mint = Color(hex: 0x4D8E6D)
    static let mintSoft = Color(hex: 0xE5F1EA)
    static let pink = Color(hex: 0xD27192)
    static let pinkSoft = Color(hex: 0xFAECF1)
    static let peach = Color(hex: 0xDE8864)
    static let peachSoft = Color(hex: 0xFBECE4)

    // Compatibility aliases used across views and widgets
    static let sunshine = butter
    static let tangerine = Color(hex: 0xD97D45)
    static let berry = Color(hex: 0xC95A82)
    static let blush = pink
    static let grape = lilac
    static let sky = aqua
    static let leaf = mint
    static let leafDeep = Color(hex: 0x376F52)
    static let soil = Color(hex: 0x9E755A)
    static let ink = Ink.primary
    static let cheek = Color(hex: 0xE07B9A)

    static let flame = LinearGradient(
        colors: [Color(hex: 0xE8AA3D), Color(hex: 0xD45842)],
        startPoint: .top, endPoint: .bottom
    )
    static let gold = LinearGradient(
        colors: [Color(hex: 0xCFA042), Color(hex: 0xA8751E)],
        startPoint: .top, endPoint: .bottom
    )
    static let dropGradient = LinearGradient(
        colors: [Color(hex: 0xE8826E), coral],
        startPoint: .top, endPoint: .bottom
    )
    static let confetti: [Color] = [butter, pink, mint, lilac, aquaLight, coral, peach]

    /// Colors for streak runs on the calendar, picked in order.
    static let runs: [Color] = [aqua, coral, mint, lilac, butterDeep, pink]

    /// Clean archival espresso shadow tone for cotton-paper surfaces.
    static let shadow = Color(hex: 0x3B2B23)
}

// MARK: - Time of day

/// The four storybook hours of the sky: dawn, day, dusk, and night.
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

    /// Default Lagoon storybook sky from zenith to horizon.
    var sky: [Color] { AppTheme.lagoon.sky(for: self) }

    /// Default Lagoon water from far shore to foreground edge.
    var pond: [Color] { AppTheme.lagoon.sea(for: self) }

    /// Light glinting on the water and cloud crests.
    var glint: Color { AppTheme.lagoon.glint(for: self) }

    var sunGlow: Color { AppTheme.lagoon.sunGlow(for: self) }

    /// Atmospheric tint applied to clouds in the hour's light.
    var cloudTint: Color? { AppTheme.lagoon.cloudTint(for: self) }

    var isNight: Bool { self == .night }

    /// Text drawn directly over the sky — calibrated for WCAG AA+ contrast in every phase.
    var onSky: Color { isNight ? Ink.starlight : Ink.primary }
    var onSkySoft: Color { isNight ? Ink.starlight.opacity(0.78) : Ink.primary.opacity(0.68) }

    var greeting: String {
        switch self {
        case .dawn: "Good morning"
        case .day: "Hello"
        case .dusk: "Good evening"
        case .night: "Sweet dreams"
        }
    }

    var gradient: LinearGradient { AppTheme.lagoon.skyGradient(for: self) }
}

// MARK: - Worlds

/// The five illustrated worlds Dewy can inhabit.
/// Each world carries its own hand-mixed 4-phase gouache sky and water palette while the
/// surrounding cotton-paper interface remains serene and cohesive.
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
        case .lagoon: "A quiet palm isle in turquoise shallows"
        case .peach: "Sunlit limestone cliffs and a red-striped beacon"
        case .matcha: "Rolling sage hills along a jade spring creek"
        case .lavender: "Rose-periwinkle towers floating on high clouds"
        case .midnight: "Velvet indigo peaks and a starlit mirror lake"
        }
    }

    var isPremium: Bool { self != .lagoon }

    /// Signature gouache swatch for pickers and badges.
    var tint: Color {
        switch self {
        case .lagoon: Color(hex: 0x5DB2CE)
        case .peach: Color(hex: 0xE69A7B)
        case .matcha: Color(hex: 0x6AA889)
        case .lavender: Color(hex: 0x9B89CE)
        case .midnight: Color(hex: 0x4B5799)
        }
    }

    /// The time of day rendered in this world (`midnight` is permanently starlit).
    func phase(at date: Date = .now) -> SkyPhase {
        self == .midnight ? .night : SkyPhase.at(date)
    }

    /// True whenever the world's active sky is dark enough to require light status bar ink.
    var prefersLightStatusBar: Bool { phase().isNight }

    /// The cotton-paper UI always stays warm light; only the night sky hero goes deep indigo.
    var isDark: Bool { false }
    var colorScheme: ColorScheme { .light }

    // MARK: Per-World 4-Phase Atmosphere

    /// Sky colors from zenith to horizon for this specific world and hour.
    func sky(for phase: SkyPhase) -> [Color] {
        if self == .midnight {
            return [Color(hex: 0x171D3D), Color(hex: 0x262F5F), Color(hex: 0x454B84)]
        }
        switch (self, phase) {
        case (.lagoon, .dawn):
            return [Color(hex: 0xF2BEA7), Color(hex: 0xF8D7C0), Color(hex: 0xFCF0DF)]
        case (.lagoon, .day):
            return [Color(hex: 0x7EC5DF), Color(hex: 0xB4DFEE), Color(hex: 0xE7F4F7)]
        case (.lagoon, .dusk):
            return [Color(hex: 0xA696CE), Color(hex: 0xDBA8C6), Color(hex: 0xF6CEBA)]
        case (.lagoon, .night):
            return [Color(hex: 0x1C244A), Color(hex: 0x2E3A6E), Color(hex: 0x4E5A94)]

        case (.peach, .dawn):
            return [Color(hex: 0xEEAA92), Color(hex: 0xF7CCB5), Color(hex: 0xFDF0E2)]
        case (.peach, .day):
            return [Color(hex: 0xF2BD9C), Color(hex: 0xF9DAC2), Color(hex: 0xFCF1E3)]
        case (.peach, .dusk):
            return [Color(hex: 0xC9838E), Color(hex: 0xE8AA9B), Color(hex: 0xF8D7BE)]
        case (.peach, .night):
            return [Color(hex: 0x242042), Color(hex: 0x3C3463), Color(hex: 0x625382)]

        case (.matcha, .dawn):
            return [Color(hex: 0xD5DFC3), Color(hex: 0xEAEAD2), Color(hex: 0xF8F4E5)]
        case (.matcha, .day):
            return [Color(hex: 0x98CCB8), Color(hex: 0xC6E3D2), Color(hex: 0xEDF6EC)]
        case (.matcha, .dusk):
            return [Color(hex: 0x91A7A1), Color(hex: 0xCBC0B0), Color(hex: 0xF1DDC4)]
        case (.matcha, .night):
            return [Color(hex: 0x192B34), Color(hex: 0x27424D), Color(hex: 0x40646E)]

        case (.lavender, .dawn):
            return [Color(hex: 0xD6B3DD), Color(hex: 0xEBC9DF), Color(hex: 0xFAE8EC)]
        case (.lavender, .day):
            return [Color(hex: 0xB3A4DE), Color(hex: 0xD2C6EE), Color(hex: 0xF0E9FA)]
        case (.lavender, .dusk):
            return [Color(hex: 0xA48ECE), Color(hex: 0xCE9FCC), Color(hex: 0xF3C9D1)]
        case (.lavender, .night):
            return [Color(hex: 0x221E48), Color(hex: 0x39316D), Color(hex: 0x5D5096)]

        case (.midnight, _):
            return [Color(hex: 0x171D3D), Color(hex: 0x262F5F), Color(hex: 0x454B84)]
        }
    }

    /// Water colors from far shore to foreground edge for this world and hour.
    func sea(for phase: SkyPhase) -> [Color] {
        if self == .midnight {
            return [Color(hex: 0x222C5B), Color(hex: 0x141A3B)]
        }
        switch (self, phase) {
        case (.lagoon, .dawn): return [Color(hex: 0x9BD5DB), Color(hex: 0x56A5BA)]
        case (.lagoon, .day): return [Color(hex: 0x6CC3D6), Color(hex: 0x2F8EAA)]
        case (.lagoon, .dusk): return [Color(hex: 0x8F8AC4), Color(hex: 0x595C9E)]
        case (.lagoon, .night): return [Color(hex: 0x2B3B6B), Color(hex: 0x172145)]

        case (.peach, .dawn): return [Color(hex: 0x84B9CF), Color(hex: 0x4784A6)]
        case (.peach, .day): return [Color(hex: 0x67B2CB), Color(hex: 0x2A7298)]
        case (.peach, .dusk): return [Color(hex: 0x6E7AA8), Color(hex: 0x3D4C7A)]
        case (.peach, .night): return [Color(hex: 0x323A64), Color(hex: 0x1B2242)]

        case (.matcha, .dawn): return [Color(hex: 0x9CCBB6), Color(hex: 0x5E9B84)]
        case (.matcha, .day): return [Color(hex: 0x7BC3A7), Color(hex: 0x428A71)]
        case (.matcha, .dusk): return [Color(hex: 0x6C9A8E), Color(hex: 0x3F6D66)]
        case (.matcha, .night): return [Color(hex: 0x264A50), Color(hex: 0x152E34)]

        case (.lavender, .dawn): return [Color(hex: 0xC9B8E6), Color(hex: 0x9080C2)]
        case (.lavender, .day): return [Color(hex: 0xB5A8E0), Color(hex: 0x7A6CB8)]
        case (.lavender, .dusk): return [Color(hex: 0x937DC0), Color(hex: 0x5B4B8E)]
        case (.lavender, .night): return [Color(hex: 0x3D3573), Color(hex: 0x211B48)]

        case (.midnight, _): return [Color(hex: 0x222C5B), Color(hex: 0x141A3B)]
        }
    }

    func glint(for phase: SkyPhase) -> Color {
        let effective = self == .midnight ? .night : phase
        switch effective {
        case .dawn: return Color(hex: 0xFFF3E2)
        case .day: return Color(hex: 0xFFFDF8)
        case .dusk: return Color(hex: 0xFFE9EE)
        case .night: return Color(hex: 0xC2CAFF)
        }
    }

    func sunGlow(for phase: SkyPhase) -> Color {
        let effective = self == .midnight ? .night : phase
        switch effective {
        case .dawn: return Color(hex: 0xFCEAC2)
        case .day: return Color(hex: 0xFFF9DD)
        case .dusk: return Color(hex: 0xFAD8B8)
        case .night: return Color(hex: 0xC9D0FF)
        }
    }

    func cloudTint(for phase: SkyPhase) -> Color? {
        let effective = self == .midnight ? .night : phase
        switch (self, effective) {
        case (_, .night): return Color(hex: 0x4B538F)
        case (.peach, .day): return Color(hex: 0xFFE8D8)
        case (.matcha, .day): return Color(hex: 0xEFF7EE)
        case (.lavender, .day): return Color(hex: 0xF3ECFA)
        case (_, .day): return nil
        case (_, .dawn): return Color(hex: 0xF7C9AE)
        case (_, .dusk): return Color(hex: 0xD8A8D6)
        }
    }

    func skyGradient(for phase: SkyPhase) -> LinearGradient {
        let stops = sky(for: phase)
        return LinearGradient(
            stops: [
                .init(color: stops[0], location: 0),
                .init(color: stops[1], location: 0.54),
                .init(color: stops[2], location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func seaGradient(for phase: SkyPhase) -> LinearGradient {
        LinearGradient(colors: sea(for: phase), startPoint: .top, endPoint: .bottom)
    }

    func onHero(for phase: SkyPhase) -> Color {
        let effective = self == .midnight ? .night : phase
        return effective.isNight ? Ink.starlight : Ink.primary
    }

    func onHeroSoft(for phase: SkyPhase) -> Color {
        let effective = self == .midnight ? .night : phase
        return effective.isNight ? Ink.starlight.opacity(0.80) : Ink.primary.opacity(0.68)
    }

    // MARK: Scenery (active time of day)

    var sky: [Color] { sky(for: phase()) }
    var sea: [Color] { sea(for: phase()) }
    var seaGlint: Color { glint(for: phase()) }
    var sunGlow: Color { sunGlow(for: phase()) }
    var cloudTint: Color? { cloudTint(for: phase()) }

    var cloudShade: Color {
        switch self {
        case .lagoon: Color(hex: 0xDCEAF0)
        case .peach: Color(hex: 0xF0DDD2)
        case .matcha: Color(hex: 0xDCE8DF)
        case .lavender: Color(hex: 0xE6DFF5)
        case .midnight: Color(hex: 0x353E72)
        }
    }

    var pad: Color {
        switch self {
        case .matcha: Color(hex: 0x5B9E78)
        case .midnight: Color(hex: 0x4A7E74)
        default: Color(hex: 0x65A67E)
        }
    }

    var padLight: Color {
        switch self {
        case .matcha: Color(hex: 0x8BC49F)
        case .midnight: Color(hex: 0x6EA398)
        default: Color(hex: 0x94CBA6)
        }
    }

    // MARK: Brand (shared by every world)

    var accent: Color { Palette.aqua }
    var accentDeep: Color { Palette.aquaDeep }
    var accentSoft: Color { Palette.aquaSoft }
    var onAccent: Color { Palette.paper }
    var link: Color { Palette.aquaDeep }

    var hero: Color { sky[1] }
    var heroDeep: Color { sky[0] }
    var heroLight: Color { sky[2] }

    /// Dewy's default spring-water hue.
    var water: Color { Color(hex: 0x4EAAD0) }

    // MARK: Cotton-Paper Surfaces

    var canvas: Color { Palette.cream }
    var card: Color { Palette.paper }
    var well: Color { Palette.creamDeep }
    var line: Color { Color(hex: 0xE5D9C8) }
    var shadow: Color { Palette.shadow.opacity(0.14) }

    // MARK: Ink

    var ink: Color { Ink.primary }
    var inkSoft: Color { Ink.soft }
    var inkFaint: Color { Ink.faint }
    var onHero: Color { onHero(for: phase()) }
    var onHeroSoft: Color { onHeroSoft(for: phase()) }

    var cta: Color { accent }
    var ctaDeep: Color { accentDeep }
    var onCta: Color { onAccent }
    var faceInk: Color { Ink.primary }

    // MARK: Gradients

    var skyGradient: LinearGradient { skyGradient(for: phase()) }
    var heroGradient: LinearGradient { skyGradient }
    var seaGradient: LinearGradient { seaGradient(for: phase()) }
    var waterGradient: LinearGradient {
        LinearGradient(colors: [water.opacity(0.84), water], startPoint: .top, endPoint: .bottom)
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

// MARK: - Editorial Storybook Typography

/// Display weights mapped onto Apple's New York editorial serif face.
enum DisplayWeight {
    case medium, semibold, bold

    var swiftUIWeight: Font.Weight {
        switch self {
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }
}

extension Font {
    /// Compact UI metadata, pills, controls and tabular numbers: SF Pro Rounded.
    static func dewy(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Editorial storybook titles, chapter headings and sculpted hero numerals: Apple New York serif.
    static func display(_ size: CGFloat, _ weight: DisplayWeight = .semibold) -> Font {
        .system(size: size, weight: weight.swiftUIWeight, design: .serif)
    }

    /// Poetic greetings, Journey story beats and italic pull quotes: Apple New York italic serif.
    static func editorialItalic(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif).italic()
    }

    /// Small tracked archival kickers above editorial titles.
    static func kicker(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

/// Kept as a harmless no-op so existing app and widget startup hooks remain intact.
enum FontRegistry {
    static func registerFonts() {}
}

// MARK: - Art

/// Asset-catalog art lookup with a graceful fallback.
enum Art {
    static func exists(_ name: String) -> Bool { UIImage(named: name) != nil }
}
