import SwiftUI

// MARK: - Deterministic Noise Helpers

private func fract(_ value: Double) -> Double {
    value - floor(value)
}

/// Deterministic pseudo-random number in 0..<1 for a seed and salt.
private func sceneNoise(_ seed: Double, _ salt: Double) -> Double {
    fract(sin(seed * 12.9898 + salt * 78.233) * 43_758.5453)
}

// MARK: - World Palette

/// Bespoke multi-plane gouache & paper-cut color system per (AppTheme, SkyPhase).
/// The top sky color seamlessly anchors to `phase.sky[0]` so pull-to-overscroll
/// above the hero never reveals a seam, while mid-sky, landforms, water, caustics
/// and ambient particles diverge into five unmistakably distinct worlds.
private struct WorldPalette {
    var skyTop: Color
    var skyMid: Color
    var skyLow: Color
    var horizonGlow: Color

    var sunCore: Color
    var sunRing: Color
    var sunHalo: Color

    var cloudLit: Color
    var cloudShade: Color

    var farLand: Color
    var midLand: Color
    var nearLand: Color
    var landHighlight: Color
    var accentA: Color
    var accentB: Color
    var contourInk: Color

    var waterTop: Color
    var waterMid: Color
    var waterDeep: Color
    var waterLip: Color
    var causticTint: Color
    var causticStrength: Double

    var particleColor: Color
    var isNight: Bool

    static func make(theme: AppTheme, phase: SkyPhase) -> WorldPalette {
        var palette: WorldPalette
        switch theme {
        case .lagoon: palette = lagoonPalette(phase)
        case .peach: palette = seasidePalette(phase)
        case .matcha: palette = meadowPalette(phase)
        case .lavender: palette = cloudlandPalette(phase)
        case .midnight: palette = starlightPalette()
        }
        let worldSky = theme.sky(for: phase)
        if worldSky.count >= 3 {
            palette.skyTop = worldSky[0]
            palette.skyMid = worldSky[1]
            palette.skyLow = worldSky[2]
        }
        return palette
    }

    private static func lagoonPalette(_ phase: SkyPhase) -> WorldPalette {
        let top = phase.sky[0]
        switch phase {
        case .dawn:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xFFD9C7), skyLow: Color(hex: 0xFFF0D9),
                horizonGlow: Color(hex: 0xFFF6D6),
                sunCore: Color(hex: 0xFFF7D6), sunRing: Color(hex: 0xFFD58A), sunHalo: Color(hex: 0xFFE9BA),
                cloudLit: Color(hex: 0xFFF9F1), cloudShade: Color(hex: 0xF3C7B8),
                farLand: Color(hex: 0xB8C7D6), midLand: Color(hex: 0x7BA9A8), nearLand: Color(hex: 0xE7C29E),
                landHighlight: Color(hex: 0xFFF0D4), accentA: Color(hex: 0x4E8E7A), accentB: Color(hex: 0x2F6B5D),
                contourInk: Color(hex: 0x564A5E).opacity(0.28),
                waterTop: Color(hex: 0xAEE6E8), waterMid: Color(hex: 0x6EC6D6), waterDeep: Color(hex: 0x459EC0),
                waterLip: Color(hex: 0xFFF4E2), causticTint: Color(hex: 0xFFF3D4), causticStrength: 0.17,
                particleColor: Color(hex: 0xFFF2BF), isNight: false
            )
        case .day:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xA9E6FA), skyLow: Color(hex: 0xDCF8FA),
                horizonGlow: Color(hex: 0xF4FFF9),
                sunCore: Color(hex: 0xFFFBE2), sunRing: Color(hex: 0xFFE38C), sunHalo: Color(hex: 0xFFF5C8),
                cloudLit: Color(hex: 0xFFFFFF), cloudShade: Color(hex: 0xC6E5F4),
                farLand: Color(hex: 0x9AD2DF), midLand: Color(hex: 0x62B9B4), nearLand: Color(hex: 0xF2D4A9),
                landHighlight: Color(hex: 0xFFF5DF), accentA: Color(hex: 0x42A37D), accentB: Color(hex: 0x2A7E62),
                contourInk: Color(hex: 0x2F5F6D).opacity(0.24),
                waterTop: Color(hex: 0x8DE7EE), waterMid: Color(hex: 0x42BBD8), waterDeep: Color(hex: 0x218DBB),
                waterLip: Color(hex: 0xE8FDFF), causticTint: Color(hex: 0xD9FFFF), causticStrength: 0.19,
                particleColor: Color(hex: 0xFFF5B8), isNight: false
            )
        case .dusk:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xE5B5D9), skyLow: Color(hex: 0xFFD2BE),
                horizonGlow: Color(hex: 0xFFE3C8),
                sunCore: Color(hex: 0xFFF0CF), sunRing: Color(hex: 0xFFB08A), sunHalo: Color(hex: 0xFFD2B8),
                cloudLit: Color(hex: 0xFFEBE4), cloudShade: Color(hex: 0xB894C9),
                farLand: Color(hex: 0x9C92C2), midLand: Color(hex: 0x6D7B9E), nearLand: Color(hex: 0xC99E9A),
                landHighlight: Color(hex: 0xFFD9C7), accentA: Color(hex: 0x4F637A), accentB: Color(hex: 0x3A4763),
                contourInk: Color(hex: 0x3D2E52).opacity(0.32),
                waterTop: Color(hex: 0xB7BBE6), waterMid: Color(hex: 0x7A90C9), waterDeep: Color(hex: 0x5264A8),
                waterLip: Color(hex: 0xFFE3EC), causticTint: Color(hex: 0xFFE0D4), causticStrength: 0.15,
                particleColor: Color(hex: 0xFFD99E), isNight: false
            )
        case .night:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0x3E468A), skyLow: Color(hex: 0x6273AD),
                horizonGlow: Color(hex: 0x89A3CF),
                sunCore: Color(hex: 0xFFF8DF), sunRing: Color(hex: 0xCBD5FF), sunHalo: Color(hex: 0x9EBBFF),
                cloudLit: Color(hex: 0x8594C8), cloudShade: Color(hex: 0x454D8C),
                farLand: Color(hex: 0x3E4E86), midLand: Color(hex: 0x293D6B), nearLand: Color(hex: 0x3A4B6F),
                landHighlight: Color(hex: 0x8FB4D9), accentA: Color(hex: 0x203D58), accentB: Color(hex: 0x152A44),
                contourInk: Color(hex: 0x12193B).opacity(0.45),
                waterTop: Color(hex: 0x46629B), waterMid: Color(hex: 0x2D457C), waterDeep: Color(hex: 0x1E2F62),
                waterLip: Color(hex: 0xB8D4F5), causticTint: Color(hex: 0xB3D6FF), causticStrength: 0.12,
                particleColor: Color(hex: 0xFFE599), isNight: true
            )
        }
    }

    private static func seasidePalette(_ phase: SkyPhase) -> WorldPalette {
        let top = phase.sky[0]
        switch phase {
        case .dawn:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xFFCFB8), skyLow: Color(hex: 0xFFE9CE),
                horizonGlow: Color(hex: 0xFFF3D4),
                sunCore: Color(hex: 0xFFF6D4), sunRing: Color(hex: 0xFFBA86), sunHalo: Color(hex: 0xFFE1BC),
                cloudLit: Color(hex: 0xFFF7EE), cloudShade: Color(hex: 0xEEBCA9),
                farLand: Color(hex: 0xBC8A99), midLand: Color(hex: 0xB85F4B), nearLand: Color(hex: 0x8C3F37),
                landHighlight: Color(hex: 0xFFF0DC), accentA: Color(hex: 0xDC4C44), accentB: Color(hex: 0xFFFBF5),
                contourInk: Color(hex: 0x4E2424).opacity(0.42),
                waterTop: Color(hex: 0xB9D8EA), waterMid: Color(hex: 0x7BAED2), waterDeep: Color(hex: 0x5282B5),
                waterLip: Color(hex: 0xFFF0DF), causticTint: Color(hex: 0xFFEAD4), causticStrength: 0.17,
                particleColor: Color(hex: 0xFFF0CF), isNight: false
            )
        case .day:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xB8DFEF), skyLow: Color(hex: 0xFFE6D6),
                horizonGlow: Color(hex: 0xFFF2E2),
                sunCore: Color(hex: 0xFFF9DD), sunRing: Color(hex: 0xFFD480), sunHalo: Color(hex: 0xFFF0C4),
                cloudLit: Color(hex: 0xFFFDF9), cloudShade: Color(hex: 0xE3CDD0),
                farLand: Color(hex: 0xB88B9A), midLand: Color(hex: 0xBE634D), nearLand: Color(hex: 0x924338),
                landHighlight: Color(hex: 0xFFF3E2), accentA: Color(hex: 0xD94B43), accentB: Color(hex: 0xFFFDF8),
                contourInk: Color(hex: 0x4E2424).opacity(0.42),
                waterTop: Color(hex: 0x9AD2EB), waterMid: Color(hex: 0x5A9ED4), waterDeep: Color(hex: 0x3B77B4),
                waterLip: Color(hex: 0xFFF7F0), causticTint: Color(hex: 0xFFEFE0), causticStrength: 0.18,
                particleColor: Color(hex: 0xFFF7DF), isNight: false
            )
        case .dusk:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xECAEBF), skyLow: Color(hex: 0xFFC5A8),
                horizonGlow: Color(hex: 0xFFE0BA),
                sunCore: Color(hex: 0xFFF1C8), sunRing: Color(hex: 0xFF9675), sunHalo: Color(hex: 0xFFC6A3),
                cloudLit: Color(hex: 0xFFE6DC), cloudShade: Color(hex: 0xB383AC),
                farLand: Color(hex: 0xA880A6), midLand: Color(hex: 0x9A667E), nearLand: Color(hex: 0x7A4961),
                landHighlight: Color(hex: 0xFFBD9B), accentA: Color(hex: 0xD95354), accentB: Color(hex: 0xFFF0E4),
                contourInk: Color(hex: 0x4A2542).opacity(0.34),
                waterTop: Color(hex: 0xC6A9D4), waterMid: Color(hex: 0x7F7EB8), waterDeep: Color(hex: 0x525594),
                waterLip: Color(hex: 0xFFDEC9), causticTint: Color(hex: 0xFFD9B8), causticStrength: 0.15,
                particleColor: Color(hex: 0xFFDC9C), isNight: false
            )
        case .night:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0x3D4085), skyLow: Color(hex: 0x6665A4),
                horizonGlow: Color(hex: 0x8F8AC2),
                sunCore: Color(hex: 0xFFF6DB), sunRing: Color(hex: 0xD2D5FF), sunHalo: Color(hex: 0xAAB4FF),
                cloudLit: Color(hex: 0x8685BA), cloudShade: Color(hex: 0x454580),
                farLand: Color(hex: 0x48477E), midLand: Color(hex: 0x393866), nearLand: Color(hex: 0x2B2A52),
                landHighlight: Color(hex: 0xA9A6D4), accentA: Color(hex: 0xC64F5B), accentB: Color(hex: 0xDCE0F5),
                contourInk: Color(hex: 0x161438).opacity(0.45),
                waterTop: Color(hex: 0x4B538F), waterMid: Color(hex: 0x313870), waterDeep: Color(hex: 0x202554),
                waterLip: Color(hex: 0xC7CDF7), causticTint: Color(hex: 0xC8D1FF), causticStrength: 0.11,
                particleColor: Color(hex: 0xFFE39E), isNight: true
            )
        }
    }

    private static func meadowPalette(_ phase: SkyPhase) -> WorldPalette {
        let top = phase.sky[0]
        switch phase {
        case .dawn:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xFFE2C9), skyLow: Color(hex: 0xF5F4D8),
                horizonGlow: Color(hex: 0xFFF9DC),
                sunCore: Color(hex: 0xFFF8D6), sunRing: Color(hex: 0xFFD77C), sunHalo: Color(hex: 0xFFF1BE),
                cloudLit: Color(hex: 0xFFFCF2), cloudShade: Color(hex: 0xE7CBBF),
                farLand: Color(hex: 0xB4CFAF), midLand: Color(hex: 0x85BC8A), nearLand: Color(hex: 0x5D9C6C),
                landHighlight: Color(hex: 0xDCEBB8), accentA: Color(hex: 0x488257), accentB: Color(hex: 0xFFD17A),
                contourInk: Color(hex: 0x355C45).opacity(0.26),
                waterTop: Color(hex: 0xB8E4CE), waterMid: Color(hex: 0x77C2A8), waterDeep: Color(hex: 0x4B9985),
                waterLip: Color(hex: 0xF3FBE9), causticTint: Color(hex: 0xF5F8D0), causticStrength: 0.15,
                particleColor: Color(hex: 0xFFF9DE), isNight: false
            )
        case .day:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xC5EBEE), skyLow: Color(hex: 0xEEF8E4),
                horizonGlow: Color(hex: 0xFBFCE8),
                sunCore: Color(hex: 0xFFFCE0), sunRing: Color(hex: 0xFFE484), sunHalo: Color(hex: 0xFFF6C6),
                cloudLit: Color(hex: 0xFFFFFF), cloudShade: Color(hex: 0xCEE5DF),
                farLand: Color(hex: 0xA8D9B5), midLand: Color(hex: 0x74C289), nearLand: Color(hex: 0x4EA36A),
                landHighlight: Color(hex: 0xCBEFB0), accentA: Color(hex: 0x3A8354), accentB: Color(hex: 0xFFDC78),
                contourInk: Color(hex: 0x2B5B40).opacity(0.24),
                waterTop: Color(hex: 0xA2E2C9), waterMid: Color(hex: 0x5AB89C), waterDeep: Color(hex: 0x378E7B),
                waterLip: Color(hex: 0xEEFFF5), causticTint: Color(hex: 0xE9FFE8), causticStrength: 0.16,
                particleColor: Color(hex: 0xFFFCEE), isNight: false
            )
        case .dusk:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xDEB9D6), skyLow: Color(hex: 0xFADAC2),
                horizonGlow: Color(hex: 0xFFE9C9),
                sunCore: Color(hex: 0xFFF1CD), sunRing: Color(hex: 0xFFB88C), sunHalo: Color(hex: 0xFFD9BE),
                cloudLit: Color(hex: 0xFFF0E8), cloudShade: Color(hex: 0xAE94BC),
                farLand: Color(hex: 0x949DB2), midLand: Color(hex: 0x67887F), nearLand: Color(hex: 0x476B62),
                landHighlight: Color(hex: 0xD7CAA8), accentA: Color(hex: 0x36544F), accentB: Color(hex: 0xFFD29E),
                contourInk: Color(hex: 0x2B3B45).opacity(0.32),
                waterTop: Color(hex: 0xA9C1C9), waterMid: Color(hex: 0x699499), waterDeep: Color(hex: 0x466C75),
                waterLip: Color(hex: 0xF5E7DD), causticTint: Color(hex: 0xFDE6CC), causticStrength: 0.14,
                particleColor: Color(hex: 0xFFE9B3), isNight: false
            )
        case .night:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0x394580), skyLow: Color(hex: 0x5B739E),
                horizonGlow: Color(hex: 0x82A1BF),
                sunCore: Color(hex: 0xFFF7DD), sunRing: Color(hex: 0xCAD8FF), sunHalo: Color(hex: 0x9EBEEB),
                cloudLit: Color(hex: 0x7D96BC), cloudShade: Color(hex: 0x3F4E7F),
                farLand: Color(hex: 0x3A5476), midLand: Color(hex: 0x26445F), nearLand: Color(hex: 0x1A344B),
                landHighlight: Color(hex: 0x7BA9B2), accentA: Color(hex: 0x12263A), accentB: Color(hex: 0xFFE08C),
                contourInk: Color(hex: 0x0E1D30).opacity(0.45),
                waterTop: Color(hex: 0x3D6384), waterMid: Color(hex: 0x274A69), waterDeep: Color(hex: 0x1A3452),
                waterLip: Color(hex: 0xB5D9E6), causticTint: Color(hex: 0xB8E6E0), causticStrength: 0.11,
                particleColor: Color(hex: 0xFFE58F), isNight: true
            )
        }
    }

    private static func cloudlandPalette(_ phase: SkyPhase) -> WorldPalette {
        let top = phase.sky[0]
        switch phase {
        case .dawn:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xF3CDE4), skyLow: Color(hex: 0xFFF0EA),
                horizonGlow: Color(hex: 0xFFF8F2),
                sunCore: Color(hex: 0xFFF9E2), sunRing: Color(hex: 0xFFD4B5), sunHalo: Color(hex: 0xFFE9DB),
                cloudLit: Color(hex: 0xFFFAF8), cloudShade: Color(hex: 0xDFC1E0),
                farLand: Color(hex: 0xE6D0F0), midLand: Color(hex: 0xD3BAE8), nearLand: Color(hex: 0xFFF4F7),
                landHighlight: Color(hex: 0xFFFFFF), accentA: Color(hex: 0xB596E6), accentB: Color(hex: 0xF7C699),
                contourInk: Color(hex: 0x6F578F).opacity(0.24),
                waterTop: Color(hex: 0xDDD4F8), waterMid: Color(hex: 0xABA7E8), waterDeep: Color(hex: 0x827FD1),
                waterLip: Color(hex: 0xFFF6FC), causticTint: Color(hex: 0xFFEFF8), causticStrength: 0.17,
                particleColor: Color(hex: 0xFFF0C7), isNight: false
            )
        case .day:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xC9D5FC), skyLow: Color(hex: 0xF4EBFF),
                horizonGlow: Color(hex: 0xFFF7FE),
                sunCore: Color(hex: 0xFFFCE8), sunRing: Color(hex: 0xFFE6A8), sunHalo: Color(hex: 0xF6EAFF),
                cloudLit: Color(hex: 0xFFFFFF), cloudShade: Color(hex: 0xD2C8F2),
                farLand: Color(hex: 0xDDD4FA), midLand: Color(hex: 0xC5B8F2), nearLand: Color(hex: 0xFAF6FF),
                landHighlight: Color(hex: 0xFFFFFF), accentA: Color(hex: 0x9C88E8), accentB: Color(hex: 0xF5B5C8),
                contourInk: Color(hex: 0x5D4E8C).opacity(0.22),
                waterTop: Color(hex: 0xCFC7FA), waterMid: Color(hex: 0x9693E6), waterDeep: Color(hex: 0x6D6BC9),
                waterLip: Color(hex: 0xFBF8FF), causticTint: Color(hex: 0xF2EAFF), causticStrength: 0.18,
                particleColor: Color(hex: 0xFFF5D4), isNight: false
            )
        case .dusk:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0xDDAEE6), skyLow: Color(hex: 0xFFD2DA),
                horizonGlow: Color(hex: 0xFFE8ED),
                sunCore: Color(hex: 0xFFF3D9), sunRing: Color(hex: 0xFFB8C9), sunHalo: Color(hex: 0xFFD9E6),
                cloudLit: Color(hex: 0xFFF0F6), cloudShade: Color(hex: 0xAF8AC9),
                farLand: Color(hex: 0xC9A7DE), midLand: Color(hex: 0xA888C9), nearLand: Color(hex: 0xEFE0F5),
                landHighlight: Color(hex: 0xFFF6FA), accentA: Color(hex: 0x8467B5), accentB: Color(hex: 0xFFCA9C),
                contourInk: Color(hex: 0x4A336E).opacity(0.30),
                waterTop: Color(hex: 0xC8B4EB), waterMid: Color(hex: 0x8B7BC9), waterDeep: Color(hex: 0x5E52A6),
                waterLip: Color(hex: 0xFFEBF5), causticTint: Color(hex: 0xFFE3F2), causticStrength: 0.16,
                particleColor: Color(hex: 0xFFE5B4), isNight: false
            )
        case .night:
            return WorldPalette(
                skyTop: top, skyMid: Color(hex: 0x45458F), skyLow: Color(hex: 0x756EB8),
                horizonGlow: Color(hex: 0x9F96DB),
                sunCore: Color(hex: 0xFFF8E0), sunRing: Color(hex: 0xD9D2FF), sunHalo: Color(hex: 0xB5A8FF),
                cloudLit: Color(hex: 0x958EC9), cloudShade: Color(hex: 0x4B4687),
                farLand: Color(hex: 0x5D569E), midLand: Color(hex: 0x474182), nearLand: Color(hex: 0x7A73B5),
                landHighlight: Color(hex: 0xCCC5F5), accentA: Color(hex: 0x39346E), accentB: Color(hex: 0xFFE0A3),
                contourInk: Color(hex: 0x1E1A47).opacity(0.42),
                waterTop: Color(hex: 0x5B579E), waterMid: Color(hex: 0x3D397A), waterDeep: Color(hex: 0x28245E),
                waterLip: Color(hex: 0xD8D1FF), causticTint: Color(hex: 0xD9D1FF), causticStrength: 0.13,
                particleColor: Color(hex: 0xFFE8A8), isNight: true
            )
        }
    }

    private static func starlightPalette() -> WorldPalette {
        WorldPalette(
            skyTop: SkyPhase.night.sky[0], skyMid: Color(hex: 0x262B6B), skyLow: Color(hex: 0x4B4F96),
            horizonGlow: Color(hex: 0x7579BA),
            sunCore: Color(hex: 0xFFF6D6), sunRing: Color(hex: 0xD3DBFF), sunHalo: Color(hex: 0x9EAEF5),
            cloudLit: Color(hex: 0x6B72B0), cloudShade: Color(hex: 0x323770),
            farLand: Color(hex: 0x3C4182), midLand: Color(hex: 0x272D61), nearLand: Color(hex: 0x192047),
            landHighlight: Color(hex: 0x7E8BC9), accentA: Color(hex: 0x13193B), accentB: Color(hex: 0xFFD978),
            contourInk: Color(hex: 0x0D112B).opacity(0.5),
            waterTop: Color(hex: 0x3D468A), waterMid: Color(hex: 0x252D69), waterDeep: Color(hex: 0x161C4D),
            waterLip: Color(hex: 0xB8C2F5), causticTint: Color(hex: 0xB8C8FF), causticStrength: 0.13,
            particleColor: Color(hex: 0xFFD978), isNight: true
        )
    }
}

// MARK: - Scene Layout Metrics

private struct WorldLayout {
    var size: CGSize
    var horizon: CGFloat
    var hasPond: Bool
    var skyBottom: CGFloat
    var hasHeaderZone: Bool
    var headerSafeTop: CGFloat
    var floatingDecorY: CGFloat?
    var celestialCenter: CGPoint

    init(
        size: CGSize,
        horizon: CGFloat,
        phase: SkyPhase,
        customSafeTop: CGFloat? = nil,
        customFloatingY: CGFloat? = nil
    ) {
        self.size = size
        self.horizon = horizon
        self.floatingDecorY = customFloatingY
        let pond = horizon < size.height
        self.hasPond = pond
        let bottom = pond ? horizon : size.height
        self.skyBottom = bottom
        let headerZone = bottom > 180
        self.hasHeaderZone = headerZone

        // Default safe band covers Dynamic Island + Date + Greeting + CountPills.
        let defaultSafeTop: CGFloat = headerZone ? 168 : 14
        let requestedSafe = customSafeTop ?? defaultSafeTop
        let safeTop = min(requestedSafe, max(bottom - 44, 14))
        self.headerSafeTop = safeTop

        let cx = size.width * 0.73
        let minCelestialY = safeTop + 21
        let maxCelestialY = max(minCelestialY, bottom - 22)
        let rawY: CGFloat = headerZone ? max(bottom * 0.72, minCelestialY) : bottom * 0.44
        let phaseOffset: CGFloat = (phase == .dawn || phase == .dusk) ? 8 : 0
        self.celestialCenter = CGPoint(x: cx, y: min(max(rawY + phaseOffset, minCelestialY), maxCelestialY))
    }
}

// MARK: - Clay / Storybook World

/// The living backdrop: five handcrafted multi-layer paper-cut & gouache worlds
/// with Metal water caustics, cold-press watercolor grain, collision-free safe zones
/// and interactive pond ripples.
struct ClayWorld: View {
    /// Distance of the pond's far shore from the top. Pass a value larger than the view to show only sky.
    var horizon: CGFloat
    var animated = true
    /// Decorations bought in the Friends tab.
    var decor: [Decor] = []
    /// Lets the pond ripple where it's tapped.
    var interactive = false
    /// Hides the landmark (for compact headers where it would crowd the title).
    var showsLandmark = true
    /// Optional explicit top safe band clear of stars, celestial bodies and dense clouds.
    var headerSafeTop: CGFloat? = nil
    /// Optional explicit Y position for floating pond decor (duck/swan) in outer foreground water.
    var floatingDecorY: CGFloat? = nil

    @Environment(\.dewyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taps: [(Date, CGPoint)] = []

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let phase = theme.phase()
            let palette = WorldPalette.make(theme: theme, phase: phase)
            let layout = WorldLayout(
                size: size,
                horizon: horizon,
                phase: phase,
                customSafeTop: headerSafeTop,
                customFloatingY: floatingDecorY
            )

            Group {
                if animated {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isLive)) { timeline in
                        let t = isLive ? timeline.date.timeIntervalSinceReferenceDate : 120.0
                        composedWorld(layout: layout, palette: palette, phase: phase, time: t, now: timeline.date)
                    }
                } else {
                    composedWorld(layout: layout, palette: palette, phase: phase, time: 120.0, now: .now)
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                guard interactive, location.y > horizon else { return }
                Haptics.tap()
                SoundFX.play(.pop, volume: 0.2)
                taps = taps.filter { Date.now.timeIntervalSince($0.0) < 2.0 } + [(Date.now, location)]
            }
            .allowsHitTesting(interactive)
        }
        .accessibilityHidden(true)
    }

    private func composedWorld(
        layout: WorldLayout,
        palette: WorldPalette,
        phase: SkyPhase,
        time t: Double,
        now: Date
    ) -> some View {
        let pondTop = max(layout.horizon - 8, 0)
        let pondHeight = max(layout.size.height - pondTop, 1)

        return ZStack(alignment: .topLeading) {
            // Layer 1: Sky, celestial, clouds, world architecture/landforms & sky/shore decor.
            Canvas { context, _ in
                drawSkyBackdrop(in: &context, layout: layout, palette: palette, phase: phase, time: t)
                if showsLandmark && layout.hasPond {
                    drawWorldLandmarks(in: &context, theme: theme, layout: layout, palette: palette, phase: phase, time: t)
                }
                drawFlyingAndStandingDecor(in: &context, theme: theme, decor: decor, layout: layout, palette: palette, phase: phase, time: t)
            }
            .gouacheBloom(0.032)

            // Layer 1b: Handcrafted gouache assets for flying & standing decor when present.
            flyingAndStandingAssetDecor(layout: layout, phase: phase, time: t)

            // Layer 2: Dedicated pond water plane with perspective Metal caustics.
            if layout.hasPond {
                Canvas { context, canvasSize in
                    drawPondSurface(
                        in: &context,
                        canvasSize: canvasSize,
                        pondTop: pondTop,
                        theme: theme,
                        layout: layout,
                        palette: palette,
                        time: t
                    )
                }
                .frame(width: layout.size.width, height: pondHeight)
                .pondCaustics(time: t, tint: palette.causticTint, strength: palette.causticStrength)
                .offset(y: pondTop)
            }

            // Layer 3: Interactive ripples, floating ripples/fallback & foreground reeds.
            Canvas { context, _ in
                if layout.hasPond {
                    drawPondForegroundDetails(in: &context, theme: theme, layout: layout, palette: palette, time: t)
                    drawFloatingDecor(in: &context, decor: decor, layout: layout, palette: palette, phase: phase, time: t)
                    drawTapRipples(in: &context, taps: taps, now: now, lipColor: palette.waterLip)
                }
            }

            // Layer 3b: Handcrafted gouache assets for floating decor above their water ripples.
            if layout.hasPond {
                floatingAssetDecor(layout: layout, phase: phase, time: t)
            }

            // Layer 4: Living atmospheric particles drifting over the entire scene.
            Canvas { context, _ in
                drawAmbientParticles(in: &context, theme: theme, layout: layout, palette: palette, phase: phase, time: t)
            }
        }
        .paperGrain(0.026)
    }

    @ViewBuilder
    private func flyingAndStandingAssetDecor(layout: WorldLayout, phase: SkyPhase, time t: Double) -> some View {
        let flying = decor.filter(\.flies)
        let standing = decor.filter { !$0.flies && !$0.floats }
        let w = layout.size.width

        ForEach(Array(flying.enumerated()), id: \.element) { index, item in
            if Art.exists(item.imageName) {
                let isRainbow = item == .rainbow
                let itemW: CGFloat = isRainbow ? 142 : 52
                let bob = isRainbow ? 0 : CGFloat(sin(t * 0.7 + Double(index))) * 5.0
                let cx = isRainbow ? w * 0.50 : w * (index == 0 ? 0.16 : 0.84)
                let minY = layout.headerSafeTop + itemW * (isRainbow ? 0.28 : 0.52)
                let cy = max(minY, layout.skyBottom - (isRainbow ? 42 : 54)) + bob
                decorAssetImage(item, size: itemW, phase: phase)
                    .opacity(isRainbow && phase.isNight ? 0.45 : (isRainbow ? 0.78 : 0.96))
                    .position(x: cx, y: cy)
            }
        }

        if layout.hasPond {
            let slots = standingDecorSlots(for: theme)
            ForEach(Array(standing.prefix(3).enumerated()), id: \.element) { index, item in
                if Art.exists(item.imageName) {
                    let itemW: CGFloat = item == .blossom ? 72 : 50
                    let base = CGPoint(x: w * slots[index], y: layout.horizon + 7)
                    decorAssetImage(item, size: itemW, phase: phase)
                        .position(x: base.x, y: base.y - itemW * 0.46)
                }
            }
        }
    }

    @ViewBuilder
    private func floatingAssetDecor(layout: WorldLayout, phase: SkyPhase, time t: Double) -> some View {
        let floating = decor.filter(\.floats)
        ForEach(Array(floating.prefix(2).enumerated()), id: \.element) { index, item in
            if Art.exists(item.imageName) {
                let pt = floatingDecorPoint(index: index, layout: layout, time: t)
                let itemW: CGFloat = 44
                let tilt = sin(t * 1.1 + Double(index) * 1.7) * 2.4
                decorAssetImage(item, size: itemW, phase: phase)
                    .scaleEffect(x: index == 0 ? 1 : -1, y: 1)
                    .rotationEffect(.degrees(tilt))
                    .position(x: pt.x, y: pt.y - itemW * 0.34)
            }
        }
    }

    private func decorAssetImage(_ item: Decor, size: CGFloat, phase: SkyPhase) -> some View {
        let multiply: Color = switch phase {
        case .day: .white
        case .dawn: Color(hex: 0xFFF2E6)
        case .dusk: item == .lantern ? Color(hex: 0xFFF0D4) : Color(hex: 0xE2CCE8)
        case .night: item == .lantern ? Color(hex: 0xFFE8BE) : Color(hex: 0x8290C8)
        }
        return Image(item.imageName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size, alignment: .bottom)
            .colorMultiply(multiply)
    }
}

/// Alias for the handcrafted storybook world backdrop.
typealias StorybookWorld = ClayWorld

// MARK: - Sky, Celestial & Paper-Cut Clouds

private func drawSkyBackdrop(
    in context: inout GraphicsContext,
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let w = layout.size.width
    let skyH = min(layout.skyBottom + 24, layout.size.height)
    let skyRect = CGRect(x: 0, y: 0, width: w, height: skyH)

    // Multi-stop gouache sky gradient anchored to phase.sky[0] at top.
    let skyGrad = Gradient(stops: [
        .init(color: palette.skyTop, location: 0.0),
        .init(color: palette.skyMid, location: 0.36),
        .init(color: palette.skyLow, location: 0.78),
        .init(color: palette.horizonGlow, location: 1.0)
    ])
    context.fill(
        Path(skyRect),
        with: .linearGradient(skyGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: skyH))
    )

    // Soft atmospheric skylight wash around sun/moon.
    let center = layout.celestialCenter
    let glowRadius = min(w * 0.62, 230)
    let haloGrad = Gradient(colors: [
        palette.sunHalo.opacity(palette.isNight ? 0.34 : 0.62),
        palette.sunHalo.opacity(palette.isNight ? 0.10 : 0.22),
        palette.sunHalo.opacity(0)
    ])
    context.fill(
        Path(skyRect),
        with: .radialGradient(haloGrad, center: center, startRadius: 6, endRadius: glowRadius)
    )

    // Subtle warm sunbeams during dawn & day (never crowding header).
    if !palette.isNight && (phase == .dawn || phase == .day) && layout.hasPond {
        drawSkySunbeams(in: &context, layout: layout, color: palette.sunHalo, time: t)
    }

    // Night stars & poetic constellations strictly inside the safe sky band.
    if palette.isNight {
        drawNightStars(in: &context, layout: layout, time: t)
        drawConstellations(in: &context, layout: layout, time: t)
        drawShootingStar(in: &context, layout: layout, time: t)
    }

    // Celestial body (hand-cut sun or crescent moon).
    drawCelestialBody(in: &context, center: center, palette: palette, phase: phase, time: t)

    // Two parallax lanes of sculpted paper-cut gouache clouds, safely below header.
    drawPaperCutClouds(in: &context, layout: layout, palette: palette, time: t)
}

private func drawSkySunbeams(
    in context: inout GraphicsContext,
    layout: WorldLayout,
    color: Color,
    time t: Double
) {
    let origin = layout.celestialCenter
    let baseH = layout.skyBottom
    for idx in 0..<3 {
        let sway = CGFloat(sin(t * 0.25 + Double(idx) * 1.4)) * 12
        let spread: CGFloat = CGFloat(idx) * 46 - 48
        let leftX = origin.x - 140 + spread + sway
        let rightX = leftX + 46 + CGFloat(idx) * 10
        var beam = Path()
        beam.move(to: CGPoint(x: origin.x - 12, y: origin.y + 8))
        beam.addLine(to: CGPoint(x: origin.x + 16, y: origin.y + 8))
        beam.addLine(to: CGPoint(x: rightX, y: baseH + 8))
        beam.addLine(to: CGPoint(x: leftX, y: baseH + 8))
        beam.closeSubpath()

        let grad = Gradient(colors: [color.opacity(0.18), color.opacity(0.0)])
        context.fill(
            beam,
            with: .linearGradient(grad, startPoint: origin, endPoint: CGPoint(x: leftX, y: baseH + 8))
        )
    }
}

private func drawNightStars(in context: inout GraphicsContext, layout: WorldLayout, time t: Double) {
    let minY = layout.headerSafeTop + 4
    let maxY = max(minY + 14, layout.skyBottom - 16)
    let spanY = maxY - minY
    let w = layout.size.width

    for index in 0..<34 {
        let seed = Double(index)
        let x = CGFloat(sceneNoise(seed, 1.3)) * (w - 24) + 12
        let y = minY + CGFloat(sceneNoise(seed, 2.7)) * spanY

        // Keep stars slightly clear of the moon disc itself.
        let dx = x - layout.celestialCenter.x
        let dy = y - layout.celestialCenter.y
        if dx * dx + dy * dy < 900 { continue }

        let phase = sin(t * (0.9 + sceneNoise(seed, 3.1) * 1.6) + seed * 2.1)
        let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * phase)
        let size = CGFloat(2.2 + sceneNoise(seed, 4.7) * 4.4)

        context.drawLayer { layer in
            layer.opacity = twinkle
            if index.isMultiple(of: 5) {
                let rect = CGRect(x: x - size, y: y - size, width: size * 2, height: size * 2)
                layer.fill(StarletShape().path(in: rect), with: .color(Color(hex: 0xFFF5CC)))
                let pearl = CGRect(x: x - 1.1, y: y - 1.1, width: 2.2, height: 2.2)
                layer.fill(Path(ellipseIn: pearl), with: .color(Color(hex: 0xFFFDF8)))
            } else {
                let r = size * 0.23
                let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                layer.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xFFFDF8)))
            }
        }
    }
}

private func drawConstellations(in context: inout GraphicsContext, layout: WorldLayout, time t: Double) {
    let minY = layout.headerSafeTop + 10
    let maxY = layout.skyBottom - 22
    guard maxY - minY > 36 else { return }

    let w = layout.size.width
    let hSpan = maxY - minY

    // Left sky mini constellation (4 linked stars in open left corridor).
    let leftStars: [CGPoint] = [
        CGPoint(x: w * 0.10, y: minY + hSpan * 0.24),
        CGPoint(x: w * 0.16, y: minY + hSpan * 0.14),
        CGPoint(x: w * 0.23, y: minY + hSpan * 0.32),
        CGPoint(x: w * 0.29, y: minY + hSpan * 0.22)
    ]

    // Right-edge mini constellation (3 linked stars clear of moon).
    let rightStars: [CGPoint] = [
        CGPoint(x: w * 0.85, y: minY + hSpan * 0.18),
        CGPoint(x: w * 0.91, y: minY + hSpan * 0.36),
        CGPoint(x: w * 0.83, y: minY + hSpan * 0.56)
    ]

    let groups = [leftStars, rightStars]
    for (gIdx, stars) in groups.enumerated() {
        var line = Path()
        for (i, pt) in stars.enumerated() {
            if i == 0 { line.move(to: pt) } else { line.addLine(to: pt) }
        }
        context.stroke(
            line,
            with: .color(Color(hex: 0xD4DCFF).opacity(0.24)),
            style: StrokeStyle(lineWidth: 0.9, lineCap: .round, dash: [3, 3])
        )
        for (i, pt) in stars.enumerated() {
            let pulse = 0.65 + 0.35 * sin(t * 1.4 + Double(gIdx * 4 + i))
            let r: CGFloat = 2.0
            let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xFFF5D4).opacity(pulse)))
        }
    }
}

private func drawShootingStar(in context: inout GraphicsContext, layout: WorldLayout, time t: Double) {
    let minY = layout.headerSafeTop + 8
    let maxY = layout.skyBottom - 26
    guard maxY - minY > 32 else { return }

    // Appears gracefully for 1.1s every 11s in the safe sky zone.
    let cycle = t.truncatingRemainder(dividingBy: 11.0)
    guard cycle >= 0.0, cycle < 1.1 else { return }

    let p = CGFloat(cycle / 1.1)
    let fade = sin(Double(p) * .pi)
    let startX = layout.size.width * 0.24
    let startY = minY + (maxY - minY) * 0.18
    let head = CGPoint(x: startX + p * 86, y: startY + p * 32)
    let tail = CGPoint(x: head.x - 32 * (1 - p * 0.3), y: head.y - 12 * (1 - p * 0.3))

    var streak = Path()
    streak.move(to: tail)
    streak.addLine(to: head)
    let grad = Gradient(colors: [Color.white.opacity(0), Color(hex: 0xFFF6D6).opacity(0.85 * fade)])
    context.stroke(
        streak,
        with: .linearGradient(grad, startPoint: tail, endPoint: head),
        style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
    )
}

private func drawCelestialBody(
    in context: inout GraphicsContext,
    center: CGPoint,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    if palette.isNight {
        // Serene gouache crescent moon with soft halo and evening star.
        let r: CGFloat = 20
        let outerHalo = CGRect(x: center.x - r * 2.1, y: center.y - r * 2.1, width: r * 4.2, height: r * 4.2)
        context.fill(
            Path(ellipseIn: outerHalo),
            with: .radialGradient(
                Gradient(colors: [palette.sunRing.opacity(0.32), palette.sunRing.opacity(0)]),
                center: center, startRadius: r * 0.4, endRadius: r * 2.1
            )
        )

        // Subtle earthshine disc.
        let discRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        context.fill(Path(ellipseIn: discRect), with: .color(palette.sunRing.opacity(0.14)))

        // Crisp mathematically exact crescent built from two meeting arcs.
        let tilt = Angle.degrees(-22 + sin(t * 0.45) * 3.0)
        context.drawLayer { layer in
            layer.translateBy(x: center.x, y: center.y)
            layer.rotate(by: tilt)
            let hornRad = 64.0 * Double.pi / 180.0
            let innerCenterX = r * CGFloat(cos(hornRad))
            let innerRadius = r * CGFloat(sin(hornRad))
            var crescent = Path()
            crescent.addArc(center: .zero, radius: r, startAngle: .degrees(296), endAngle: .degrees(64), clockwise: true)
            crescent.addArc(
                center: CGPoint(x: innerCenterX, y: 0),
                radius: innerRadius,
                startAngle: .degrees(90),
                endAngle: .degrees(270),
                clockwise: false
            )
            crescent.closeSubpath()

            let moonGrad = Gradient(colors: [Color(hex: 0xFFFDF0), palette.sunCore, palette.sunRing])
            layer.fill(
                crescent,
                with: .linearGradient(moonGrad, startPoint: CGPoint(x: -r, y: -r), endPoint: CGPoint(x: r, y: r))
            )
            layer.stroke(crescent, with: .color(.white.opacity(0.65)), lineWidth: 1.0)
        }

        // Delicate 6-point companion evening starlet beside crescent.
        let starPt = CGPoint(x: center.x + r * 0.74, y: center.y - r * 0.56)
        let starS: CGFloat = 5.0 + CGFloat(sin(t * 1.7)) * 0.7
        let starRect = CGRect(x: starPt.x - starS, y: starPt.y - starS, width: starS * 2, height: starS * 2)
        context.fill(StarletShape().path(in: starRect), with: .color(Color(hex: 0xFFF7D6).opacity(0.94)))
        context.fill(Path(ellipseIn: CGRect(x: starPt.x - 1.4, y: starPt.y - 1.4, width: 2.8, height: 2.8)), with: .color(Color(hex: 0xFFFDF8)))
    } else {
        // Hand-cut gouache storybook sun with gentle rotating petal rays.
        let r: CGFloat = (phase == .dawn || phase == .dusk) ? 23 : 21
        let raySpin = t * 0.08

        context.drawLayer { layer in
            layer.translateBy(x: center.x, y: center.y)
            layer.rotate(by: Angle.radians(raySpin))

            let rayCount = 12
            let baseR = Double(r)
            for i in 0..<rayCount {
                let angle = Double(i) * (.pi * 2.0 / Double(rayCount))
                let inner = baseR + 5.0
                let outer = baseR + (i.isMultiple(of: 2) ? 14.5 : 10.5)
                let halfAngle = 0.10
                var ray = Path()
                ray.move(to: CGPoint(x: cos(angle - halfAngle) * inner, y: sin(angle - halfAngle) * inner))
                ray.addLine(to: CGPoint(x: cos(angle) * outer, y: sin(angle) * outer))
                ray.addLine(to: CGPoint(x: cos(angle + halfAngle) * inner, y: sin(angle + halfAngle) * inner))
                ray.closeSubpath()
                layer.fill(ray, with: .color(palette.sunRing.opacity(0.38)))
            }
        }

        let coronaRect = CGRect(x: center.x - r * 1.42, y: center.y - r * 1.42, width: r * 2.84, height: r * 2.84)
        context.fill(Path(ellipseIn: coronaRect), with: .color(palette.sunHalo.opacity(0.36)))

        let coreRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        let sunGrad = Gradient(colors: [Color(hex: 0xFFFFF4), palette.sunCore, palette.sunRing])
        context.fill(
            Path(ellipseIn: coreRect),
            with: .radialGradient(sunGrad, center: CGPoint(x: center.x - r * 0.2, y: center.y - r * 0.25), startRadius: 2, endRadius: r * 1.15)
        )
    }
}

private func drawPaperCutClouds(
    in context: inout GraphicsContext,
    layout: WorldLayout,
    palette: WorldPalette,
    time t: Double
) {
    let w = layout.size.width
    let safeMaxY = max(layout.headerSafeTop + 26, layout.skyBottom - 18)

    // Three gentle parallax clouds strictly below resolved headerSafeTop.
    let specs: [(width: CGFloat, yFrac: CGFloat, speed: Double, offset: Double, alpha: Double)] = [
        (86, 0.28, 3.2, 0.14, palette.isNight ? 0.38 : 0.76),
        (74, 0.56, 2.1, 0.68, palette.isNight ? 0.34 : 0.66),
        (104, 0.82, 4.8, 0.38, palette.isNight ? 0.42 : 0.86)
    ]

    for spec in specs {
        let travelSpan = Double(w + spec.width * 2.2)
        let rawX = (spec.offset * travelSpan + t * spec.speed).truncatingRemainder(dividingBy: travelSpan)
        let cx = CGFloat(rawX) - spec.width * 0.6
        // Cloud puff rises ~0.26 * width above center; keep top edge >= headerSafeTop.
        let minCenterY = layout.headerSafeTop + spec.width * 0.27
        let spanY = max(safeMaxY - minCenterY, 2)
        let cy = min(minCenterY + spanY * spec.yFrac, safeMaxY)
        drawSinglePaperCutCloud(
            in: &context,
            center: CGPoint(x: cx, y: cy),
            width: spec.width,
            lit: palette.cloudLit,
            shade: palette.cloudShade,
            alpha: spec.alpha
        )
    }
}

/// Sculpted flat-base Studio Ghibli / paper-cut cumulus cloud with sunlit crown and soft belly shadow.
private func drawSinglePaperCutCloud(
    in context: inout GraphicsContext,
    center: CGPoint,
    width: CGFloat,
    lit: Color,
    shade: Color,
    alpha: Double
) {
    let h = width * 0.34
    let left = center.x - width * 0.5
    let baseY = center.y + h * 0.35

    var body = Path()
    body.move(to: CGPoint(x: left + width * 0.08, y: baseY))
    body.addQuadCurve(
        to: CGPoint(x: left + width * 0.24, y: baseY - h * 0.62),
        control: CGPoint(x: left - width * 0.02, y: baseY - h * 0.46)
    )
    body.addCurve(
        to: CGPoint(x: left + width * 0.56, y: baseY - h * 0.92),
        control1: CGPoint(x: left + width * 0.30, y: baseY - h * 1.12),
        control2: CGPoint(x: left + width * 0.50, y: baseY - h * 1.16)
    )
    body.addCurve(
        to: CGPoint(x: left + width * 0.82, y: baseY - h * 0.52),
        control1: CGPoint(x: left + width * 0.68, y: baseY - h * 1.02),
        control2: CGPoint(x: left + width * 0.82, y: baseY - h * 0.80)
    )
    body.addQuadCurve(
        to: CGPoint(x: left + width * 0.92, y: baseY),
        control: CGPoint(x: left + width * 1.02, y: baseY - h * 0.28)
    )
    body.closeSubpath()

    context.drawLayer { layer in
        layer.opacity = alpha
        let grad = Gradient(stops: [
            .init(color: lit, location: 0.0),
            .init(color: lit.blended(with: shade, by: 0.22), location: 0.62),
            .init(color: shade, location: 1.0)
        ])
        layer.fill(
            body,
            with: .linearGradient(grad, startPoint: CGPoint(x: center.x, y: baseY - h), endPoint: CGPoint(x: center.x, y: baseY))
        )
        layer.stroke(body, with: .color(lit.opacity(0.65)), lineWidth: 1.0)
    }
}

// MARK: - 5 Distinct World Landmarks

private func drawWorldLandmarks(
    in context: inout GraphicsContext,
    theme: AppTheme,
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    switch theme {
    case .lagoon:
        drawLagoonWorld(in: &context, layout: layout, palette: palette, phase: phase, time: t)
    case .peach:
        drawSeasideWorld(in: &context, layout: layout, palette: palette, phase: phase, time: t)
    case .matcha:
        drawMeadowWorld(in: &context, layout: layout, palette: palette, phase: phase, time: t)
    case .lavender:
        drawCloudlandWorld(in: &context, layout: layout, palette: palette, phase: phase, time: t)
    case .midnight:
        drawStarlightWorld(in: &context, layout: layout, palette: palette, phase: phase, time: t)
    }
}

/// Whisper-soft Alto's Odyssey drifting gouache mist veil nestled between far
/// mountain/cliff planes and the mid-ground shoreline for genuine aerial depth.
private func drawHorizonMistVeil(
    in context: inout GraphicsContext,
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let w = layout.size.width
    let y = layout.horizon + 4
    let mistColor: Color = switch phase {
    case .dawn: Color(hex: 0xFFF3D6)
    case .day: palette.horizonGlow
    case .dusk: Color(hex: 0xF5D4E8)
    case .night: Color(hex: 0x9EADDE)
    }
    let bandRect = CGRect(x: 0, y: y - 26, width: w, height: 30)
    let veilGrad = Gradient(stops: [
        .init(color: mistColor.opacity(0.0), location: 0.0),
        .init(color: mistColor.opacity(palette.isNight ? 0.22 : 0.34), location: 0.58),
        .init(color: mistColor.opacity(palette.isNight ? 0.14 : 0.20), location: 1.0)
    ])
    context.fill(
        Path(bandRect),
        with: .linearGradient(veilGrad, startPoint: CGPoint(x: 0, y: bandRect.minY), endPoint: CGPoint(x: 0, y: bandRect.maxY))
    )

    // Three slowly drifting horizontal gouache mist wisps.
    for i in 0..<3 {
        let seed = Double(i) + 19.0
        let span = Double(w + 180)
        let speed = 2.4 + Double(i) * 0.9
        let rawX = (sceneNoise(seed, 1.3) * span + t * speed).truncatingRemainder(dividingBy: span)
        let cx = CGFloat(rawX) - 90
        let cy = y - 8 - CGFloat(i) * 5.5
        let rx = CGFloat(66 + i * 18)
        let ry: CGFloat = 7.5
        let rect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
        context.fill(Path(ellipseIn: rect), with: .color(mistColor.opacity(palette.isNight ? 0.14 : 0.24)))
    }
}

// MARK: World 1 — Lagoon (Coral Arch, Misty Atoll & Swaying Palms)

private func drawLagoonWorld(
    in context: inout GraphicsContext,
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let w = layout.size.width
    let y = layout.horizon + 4

    // Distant hazy lagoon atoll & natural coral-limestone sea arch on mid-right.
    var farAtoll = Path()
    farAtoll.move(to: CGPoint(x: w * 0.56, y: y + 4))
    farAtoll.addQuadCurve(to: CGPoint(x: w * 0.72, y: y - 24), control: CGPoint(x: w * 0.63, y: y - 24))
    farAtoll.addCurve(
        to: CGPoint(x: w * 0.94, y: y - 10),
        control1: CGPoint(x: w * 0.80, y: y - 26),
        control2: CGPoint(x: w * 0.86, y: y - 34)
    )
    farAtoll.addLine(to: CGPoint(x: w * 1.02, y: y + 4))
    farAtoll.closeSubpath()
    context.fill(farAtoll, with: .color(palette.farLand.opacity(0.62)))

    // Cutout glow under the distant natural sea arch.
    var archHole = Path()
    archHole.addArc(center: CGPoint(x: w * 0.82, y: y + 2), radius: 11, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
    archHole.closeSubpath()
    context.fill(archHole, with: .color(palette.horizonGlow.opacity(0.75)))

    // Midground misty lagoon ridge sweeping left.
    var midRidge = Path()
    midRidge.move(to: CGPoint(x: -4, y: y + 4))
    midRidge.addQuadCurve(to: CGPoint(x: w * 0.34, y: y - 14), control: CGPoint(x: w * 0.16, y: y - 32))
    midRidge.addQuadCurve(to: CGPoint(x: w * 0.50, y: y + 4), control: CGPoint(x: w * 0.43, y: y - 4))
    midRidge.closeSubpath()
    context.fill(midRidge, with: .color(palette.midLand.opacity(0.52)))

    // Drifting horizon mist separating far lagoon atoll from foreground coral islet.
    drawHorizonMistVeil(in: &context, layout: layout, palette: palette, phase: phase, time: t)

    // Left foreground coral-sand islet anchored cleanly clear of Dewy.
    var islet = Path()
    islet.move(to: CGPoint(x: -6, y: y + 6))
    islet.addCurve(
        to: CGPoint(x: w * 0.27, y: y + 5),
        control1: CGPoint(x: w * 0.05, y: y - 24),
        control2: CGPoint(x: w * 0.21, y: y - 20)
    )
    islet.closeSubpath()
    let sandGrad = Gradient(colors: [palette.landHighlight, palette.nearLand])
    context.fill(
        islet,
        with: .linearGradient(sandGrad, startPoint: CGPoint(x: 0, y: y - 20), endPoint: CGPoint(x: 0, y: y + 6))
    )
    context.stroke(islet, with: .color(palette.contourInk), lineWidth: 1.0)

    // Lush moss crown patch on the islet.
    var turf = Path()
    turf.move(to: CGPoint(x: w * 0.02, y: y - 10))
    turf.addQuadCurve(to: CGPoint(x: w * 0.21, y: y - 6), control: CGPoint(x: w * 0.11, y: y - 22))
    turf.addQuadCurve(to: CGPoint(x: w * 0.02, y: y - 10), control: CGPoint(x: w * 0.11, y: y - 6))
    context.fill(turf, with: .color(palette.accentA.opacity(0.85)))

    // Two gracefully swaying gouache palm trees.
    let swayA = CGFloat(sin(t * 0.9)) * 4.2
    let swayB = CGFloat(sin(t * 0.9 + 1.3)) * 3.4
    drawPalmTree(
        in: &context,
        base: CGPoint(x: w * 0.11, y: y - 12),
        height: 54,
        lean: 12 + swayA,
        trunkColor: palette.nearLand.blended(with: palette.contourInk, by: 0.45),
        frondLight: palette.accentA,
        frondDark: palette.accentB
    )
    drawPalmTree(
        in: &context,
        base: CGPoint(x: w * 0.17, y: y - 9),
        height: 40,
        lean: -10 + swayB,
        trunkColor: palette.nearLand.blended(with: palette.contourInk, by: 0.45),
        frondLight: palette.accentA,
        frondDark: palette.accentB
    )

    // Small far-right sandbar & tufts.
    var rightBar = Path()
    rightBar.move(to: CGPoint(x: w * 0.85, y: y + 6))
    rightBar.addQuadCurve(to: CGPoint(x: w + 6, y: y - 8), control: CGPoint(x: w * 0.94, y: y - 11))
    rightBar.addLine(to: CGPoint(x: w + 6, y: y + 6))
    rightBar.closeSubpath()
    context.fill(rightBar, with: .color(palette.nearLand.opacity(0.9)))
}

private func drawPalmTree(
    in context: inout GraphicsContext,
    base: CGPoint,
    height: CGFloat,
    lean: CGFloat,
    trunkColor: Color,
    frondLight: Color,
    frondDark: Color
) {
    let crown = CGPoint(x: base.x + lean, y: base.y - height)
    let ctrl = CGPoint(x: base.x + lean * 0.25, y: base.y - height * 0.55)

    var trunk = Path()
    trunk.move(to: CGPoint(x: base.x - 3.6, y: base.y))
    trunk.addQuadCurve(to: CGPoint(x: crown.x - 1.4, y: crown.y), control: CGPoint(x: ctrl.x - 2.4, y: ctrl.y))
    trunk.addLine(to: CGPoint(x: crown.x + 1.4, y: crown.y))
    trunk.addQuadCurve(to: CGPoint(x: base.x + 3.6, y: base.y), control: CGPoint(x: ctrl.x + 2.4, y: ctrl.y))
    trunk.closeSubpath()
    context.fill(trunk, with: .color(trunkColor))

    // Five layered arching botanical palm fronds.
    let frondSpecs: [(dx: CGFloat, dy: CGFloat, droop: CGFloat, dark: Bool)] = [
        (-28, -8, 12, true),
        (-22, -20, 6, false),
        (4, -22, 4, false),
        (26, -15, 9, false),
        (28, -2, 14, true)
    ]
    for spec in frondSpecs {
        let tip = CGPoint(x: crown.x + spec.dx, y: crown.y + spec.dy + spec.droop)
        let upperCtrl = CGPoint(x: crown.x + spec.dx * 0.52, y: crown.y + spec.dy - 9)
        let lowerCtrl = CGPoint(x: crown.x + spec.dx * 0.48, y: crown.y + spec.dy + 2)
        var frond = Path()
        frond.move(to: crown)
        frond.addQuadCurve(to: tip, control: upperCtrl)
        frond.addQuadCurve(to: crown, control: lowerCtrl)
        frond.closeSubpath()
        context.fill(frond, with: .color(spec.dark ? frondDark : frondLight))
    }
}

// MARK: World 2 — Seaside (Terracotta Cliffs, Striped Lighthouse, Sailboat & Gulls)

private func drawSeasideWorld(
    in context: inout GraphicsContext,
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let w = layout.size.width
    let y = layout.horizon + 5

    // Distant coastal headland mist silhouettes.
    var farCoast = Path()
    farCoast.move(to: CGPoint(x: -4, y: y + 4))
    farCoast.addLine(to: CGPoint(x: w * 0.32, y: y - 22))
    farCoast.addQuadCurve(to: CGPoint(x: w * 0.54, y: y + 4), control: CGPoint(x: w * 0.44, y: y - 16))
    farCoast.closeSubpath()
    context.fill(farCoast, with: .color(palette.farLand.opacity(0.56)))

    var rightHeadland = Path()
    rightHeadland.move(to: CGPoint(x: w * 0.68, y: y + 4))
    rightHeadland.addQuadCurve(to: CGPoint(x: w + 4, y: y - 20), control: CGPoint(x: w * 0.84, y: y - 24))
    rightHeadland.addLine(to: CGPoint(x: w + 4, y: y + 4))
    rightHeadland.closeSubpath()
    context.fill(rightHeadland, with: .color(palette.farLand.opacity(0.48)))

    // Atmospheric coastal haze mist between far headlands and near terracotta cliff.
    drawHorizonMistVeil(in: &context, layout: layout, palette: palette, phase: phase, time: t)

    // Left tiered terracotta-sienna coastal cliff headland (framed cleanly below headerSafeTop).
    var cliff = Path()
    cliff.move(to: CGPoint(x: -6, y: y + 6))
    cliff.addLine(to: CGPoint(x: -6, y: y - 24))
    cliff.addLine(to: CGPoint(x: w * 0.16, y: y - 21))
    cliff.addLine(to: CGPoint(x: w * 0.24, y: y - 9))
    cliff.addLine(to: CGPoint(x: w * 0.28, y: y + 6))
    cliff.closeSubpath()
    let cliffGrad = Gradient(colors: [palette.midLand, palette.nearLand])
    context.fill(cliff, with: .linearGradient(cliffGrad, startPoint: CGPoint(x: 0, y: y - 24), endPoint: CGPoint(x: 0, y: y + 6)))
    context.stroke(cliff, with: .color(palette.contourInk), lineWidth: 1.1)

    // Paper-cut sunlit top facet & crisp warm cream rim edge on the cliff.
    var facet = Path()
    facet.move(to: CGPoint(x: -6, y: y - 24))
    facet.addLine(to: CGPoint(x: w * 0.16, y: y - 21))
    facet.addLine(to: CGPoint(x: w * 0.12, y: y - 15))
    facet.addLine(to: CGPoint(x: -6, y: y - 16))
    facet.closeSubpath()
    context.fill(facet, with: .color(palette.landHighlight.opacity(0.46)))

    var cliffRim = Path()
    cliffRim.move(to: CGPoint(x: -4, y: y - 24))
    cliffRim.addLine(to: CGPoint(x: w * 0.16, y: y - 21))
    cliffRim.addLine(to: CGPoint(x: w * 0.24, y: y - 9))
    context.stroke(cliffRim, with: .color(palette.landHighlight.opacity(0.88)), style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))

    // Crisp hand-inked candy-striped storybook lighthouse on the headland.
    drawStorybookLighthouse(
        in: &context,
        base: CGPoint(x: w * 0.115, y: y - 22),
        palette: palette,
        showBeam: phase == .dusk || phase == .night,
        time: t
    )

    // Gently rocking paper-cut sailboat on the far right horizon.
    let boatBob = CGFloat(sin(t * 1.15)) * 2.2
    let boatTilt = sin(t * 0.85) * 0.055
    drawPaperCutSailboat(
        in: &context,
        base: CGPoint(x: w * 0.86, y: y + 2 + boatBob),
        tilt: boatTilt,
        palette: palette,
        time: t
    )

    // Soaring distant coastal seabird silhouettes in safe sky corridor.
    drawSeabirds(in: &context, layout: layout, color: palette.contourInk.opacity(0.9), time: t)
}

private func drawStorybookLighthouse(
    in context: inout GraphicsContext,
    base: CGPoint,
    palette: WorldPalette,
    showBeam: Bool,
    time t: Double
) {
    let towerH: CGFloat = 33
    let bottomHalf: CGFloat = 8.4
    let topHalf: CGFloat = 5.0
    let topY = base.y - towerH

    // Sweeping translucent volumetric lantern beam at dusk/night.
    if showBeam {
        let lanternCenter = CGPoint(x: base.x, y: topY - 5)
        let sweep = CGFloat(sin(t * 0.55)) * 18
        var beam = Path()
        beam.move(to: lanternCenter)
        beam.addLine(to: CGPoint(x: lanternCenter.x + 150, y: lanternCenter.y - 26 + sweep))
        beam.addLine(to: CGPoint(x: lanternCenter.x + 150, y: lanternCenter.y + 18 + sweep))
        beam.closeSubpath()
        let beamGrad = Gradient(colors: [Color(hex: 0xFFF3B0).opacity(0.45), Color(hex: 0xFFF3B0).opacity(0)])
        context.fill(
            beam,
            with: .linearGradient(beamGrad, startPoint: lanternCenter, endPoint: CGPoint(x: lanternCenter.x + 148, y: lanternCenter.y + sweep))
        )
    }

    // Tapered lighthouse tower body.
    var tower = Path()
    tower.move(to: CGPoint(x: base.x - bottomHalf, y: base.y))
    tower.addLine(to: CGPoint(x: base.x - topHalf, y: topY))
    tower.addLine(to: CGPoint(x: base.x + topHalf, y: topY))
    tower.addLine(to: CGPoint(x: base.x + bottomHalf, y: base.y))
    tower.closeSubpath()
    context.fill(tower, with: .color(palette.accentB))

    // Two crisp coral-red stripes clipped inside the tower silhouette.
    context.drawLayer { layer in
        layer.clip(to: tower)
        let stripe1 = CGRect(x: base.x - bottomHalf - 2, y: topY + towerH * 0.22, width: bottomHalf * 2 + 4, height: towerH * 0.20)
        let stripe2 = CGRect(x: base.x - bottomHalf - 2, y: topY + towerH * 0.62, width: bottomHalf * 2 + 4, height: towerH * 0.20)
        layer.fill(Path(stripe1), with: .color(palette.accentA))
        layer.fill(Path(stripe2), with: .color(palette.accentA))
    }
    context.stroke(tower, with: .color(palette.contourInk), lineWidth: 1.0)

    // Observation gallery ledge.
    let gallery = CGRect(x: base.x - topHalf - 2.6, y: topY - 2.5, width: (topHalf + 2.6) * 2, height: 3.0)
    context.fill(Path(roundedRect: gallery, cornerRadius: 1.5), with: .color(palette.accentA))

    // Glowing glass lantern room.
    let lanternRect = CGRect(x: base.x - topHalf * 0.72, y: topY - 10.5, width: topHalf * 1.44, height: 8.2)
    let glassColor = showBeam ? Color(hex: 0xFFF4AD) : Color(hex: 0xE6F7FF)
    context.fill(Path(roundedRect: lanternRect, cornerRadius: 1.2), with: .color(glassColor))
    context.stroke(Path(roundedRect: lanternRect, cornerRadius: 1.2), with: .color(palette.contourInk), lineWidth: 0.9)

    // Domed crimson cap + tiny spire.
    var roof = Path()
    roof.move(to: CGPoint(x: base.x - topHalf * 0.92, y: topY - 10.5))
    roof.addQuadCurve(to: CGPoint(x: base.x + topHalf * 0.92, y: topY - 10.5), control: CGPoint(x: base.x, y: topY - 19.5))
    roof.closeSubpath()
    context.fill(roof, with: .color(palette.accentA))
}

private func drawPaperCutSailboat(
    in context: inout GraphicsContext,
    base: CGPoint,
    tilt: Double,
    palette: WorldPalette,
    time t: Double
) {
    let billow = CGFloat(sin(t * 1.4)) * 1.6
    context.drawLayer { layer in
        layer.translateBy(x: base.x, y: base.y)
        layer.rotate(by: Angle.radians(tilt))

        // Mast.
        var mast = Path()
        mast.move(to: CGPoint(x: 0, y: -4))
        mast.addLine(to: CGPoint(x: 0, y: -38))
        layer.stroke(mast, with: .color(palette.contourInk.opacity(0.9)), lineWidth: 1.4)

        // Billowing cream mainsail.
        var mainSail = Path()
        mainSail.move(to: CGPoint(x: 1, y: -36))
        mainSail.addQuadCurve(to: CGPoint(x: 18, y: -8), control: CGPoint(x: 14 + billow, y: -23))
        mainSail.addLine(to: CGPoint(x: 1, y: -8))
        mainSail.closeSubpath()
        layer.fill(mainSail, with: .color(palette.accentB))
        layer.stroke(mainSail, with: .color(palette.contourInk), lineWidth: 0.8)

        // Apricot-coral jib sail.
        var jib = Path()
        jib.move(to: CGPoint(x: -1, y: -31))
        jib.addQuadCurve(to: CGPoint(x: -14, y: -8), control: CGPoint(x: -10 - billow * 0.6, y: -18))
        jib.addLine(to: CGPoint(x: -1, y: -8))
        jib.closeSubpath()
        layer.fill(jib, with: .color(palette.accentA.blended(with: palette.accentB, by: 0.35)))

        // Fluttering pennant.
        var pennant = Path()
        pennant.move(to: CGPoint(x: 0, y: -38))
        pennant.addLine(to: CGPoint(x: -9, y: -36 + billow * 0.5))
        pennant.addLine(to: CGPoint(x: 0, y: -34))
        pennant.closeSubpath()
        layer.fill(pennant, with: .color(palette.accentA))

        // Warm cedar-coral hull.
        var hull = Path()
        hull.move(to: CGPoint(x: -19, y: -6))
        hull.addLine(to: CGPoint(x: 20, y: -6))
        hull.addQuadCurve(to: CGPoint(x: 13, y: 2), control: CGPoint(x: 18, y: 1))
        hull.addLine(to: CGPoint(x: -13, y: 2))
        hull.addQuadCurve(to: CGPoint(x: -19, y: -6), control: CGPoint(x: -17, y: 1))
        hull.closeSubpath()
        layer.fill(hull, with: .color(palette.nearLand))
        layer.stroke(hull, with: .color(palette.contourInk), lineWidth: 0.9)
    }
}

private func drawSeabirds(in context: inout GraphicsContext, layout: WorldLayout, color: Color, time t: Double) {
    let baseY = max(layout.headerSafeTop + 26, layout.skyBottom - 54)
    let birds: [(xFrac: CGFloat, dy: CGFloat, scale: CGFloat, phase: Double)] = [
        (0.24, 0, 1.0, 0.0),
        (0.30, -10, 0.78, 1.2),
        (0.82, -16, 0.84, 2.4)
    ]
    for bird in birds {
        let drift = CGFloat(sin(t * 0.35 + bird.phase)) * 8
        let cx = layout.size.width * bird.xFrac + drift
        let cy = baseY + bird.dy + CGFloat(cos(t * 0.6 + bird.phase)) * 3
        let flap = CGFloat(sin(t * 3.1 + bird.phase)) * 2.5 * bird.scale
        let span = 8.5 * bird.scale

        var gull = Path()
        gull.move(to: CGPoint(x: cx - span, y: cy - 1 + flap))
        gull.addQuadCurve(to: CGPoint(x: cx, y: cy + 2), control: CGPoint(x: cx - span * 0.45, y: cy - 4.5 + flap * 0.4))
        gull.addQuadCurve(to: CGPoint(x: cx + span, y: cy - 1 + flap), control: CGPoint(x: cx + span * 0.45, y: cy - 4.5 + flap * 0.4))
        context.stroke(gull, with: .color(color), style: StrokeStyle(lineWidth: 1.3 * bird.scale, lineCap: .round))
    }
}

// MARK: World 3 — Meadow (Studio Ghibli Rolling Hills, Storybook Trees & Reeds)

private func drawMeadowWorld(
    in context: inout GraphicsContext,
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let w = layout.size.width
    let y = layout.horizon + 6

    // Plane 1: Far misty pistachio pastoral ridge.
    var farHills = Path()
    farHills.move(to: CGPoint(x: -4, y: y + 4))
    farHills.addLine(to: CGPoint(x: -4, y: y - 24))
    farHills.addCurve(
        to: CGPoint(x: w * 0.48, y: y - 16),
        control1: CGPoint(x: w * 0.14, y: y - 44),
        control2: CGPoint(x: w * 0.32, y: y - 10)
    )
    farHills.addCurve(
        to: CGPoint(x: w + 4, y: y - 28),
        control1: CGPoint(x: w * 0.66, y: y - 24),
        control2: CGPoint(x: w * 0.82, y: y - 46)
    )
    farHills.addLine(to: CGPoint(x: w + 4, y: y + 4))
    farHills.closeSubpath()
    context.fill(farHills, with: .color(palette.farLand.opacity(0.82)))

    // Soft valley mist separating far pastoral ridge from sunlit mid hills.
    drawHorizonMistVeil(in: &context, layout: layout, palette: palette, phase: phase, time: t)

    // Plane 2: Sunlit sage rolling mid hills.
    var midHills = Path()
    midHills.move(to: CGPoint(x: -4, y: y + 6))
    midHills.addLine(to: CGPoint(x: -4, y: y - 28))
    midHills.addCurve(
        to: CGPoint(x: w * 0.52, y: y - 6),
        control1: CGPoint(x: w * 0.16, y: y - 34),
        control2: CGPoint(x: w * 0.34, y: y - 6)
    )
    midHills.addCurve(
        to: CGPoint(x: w + 4, y: y - 24),
        control1: CGPoint(x: w * 0.72, y: y - 6),
        control2: CGPoint(x: w * 0.85, y: y - 34)
    )
    midHills.addLine(to: CGPoint(x: w + 4, y: y + 6))
    midHills.closeSubpath()
    let midGrad = Gradient(colors: [palette.landHighlight.blended(with: palette.midLand, by: 0.65), palette.midLand])
    context.fill(midHills, with: .linearGradient(midGrad, startPoint: CGPoint(x: 0, y: y - 34), endPoint: CGPoint(x: 0, y: y + 6)))

    // Plane 3: Near mossy shoreline banks dipping open in center for Dewy.
    var nearLeft = Path()
    nearLeft.move(to: CGPoint(x: -4, y: y + 6))
    nearLeft.addQuadCurve(to: CGPoint(x: w * 0.36, y: y + 6), control: CGPoint(x: w * 0.15, y: y - 26))
    nearLeft.closeSubpath()
    context.fill(nearLeft, with: .color(palette.nearLand))

    var nearRight = Path()
    nearRight.move(to: CGPoint(x: w * 0.66, y: y + 6))
    nearRight.addQuadCurve(to: CGPoint(x: w + 4, y: y + 6), control: CGPoint(x: w * 0.86, y: y - 26))
    nearRight.closeSubpath()
    context.fill(nearRight, with: .color(palette.nearLand))

    // Storybook round trees & Tuscan cypress clusters on left & right crests.
    let sway = CGFloat(sin(t * 0.7)) * 1.4
    drawGouacheTree(in: &context, base: CGPoint(x: w * 0.08, y: y - 16), radius: 14, sway: sway, lit: palette.landHighlight, mid: palette.midLand, deep: palette.accentA)
    drawGouacheTree(in: &context, base: CGPoint(x: w * 0.17, y: y - 13), radius: 10.5, sway: -sway * 0.7, lit: palette.landHighlight, mid: palette.nearLand, deep: palette.accentA)
    drawCypress(in: &context, base: CGPoint(x: w * 0.83, y: y - 15), height: 28, sway: sway * 0.6, color: palette.accentA)
    drawGouacheTree(in: &context, base: CGPoint(x: w * 0.91, y: y - 17), radius: 13.5, sway: sway, lit: palette.landHighlight, mid: palette.midLand, deep: palette.accentA)
}

private func drawGouacheTree(
    in context: inout GraphicsContext,
    base: CGPoint,
    radius: CGFloat,
    sway: CGFloat,
    lit: Color,
    mid: Color,
    deep: Color
) {
    // Trunk.
    let trunk = CGRect(x: base.x - 1.8, y: base.y - radius * 0.9, width: 3.6, height: radius * 1.15)
    context.fill(Path(roundedRect: trunk, cornerRadius: 1.4), with: .color(Color(hex: 0x7A5B4B).opacity(0.85)))

    let crownCenter = CGPoint(x: base.x + sway, y: base.y - radius * 1.35)
    let crownRect = CGRect(x: crownCenter.x - radius, y: crownCenter.y - radius * 0.95, width: radius * 2, height: radius * 1.9)
    let grad = Gradient(colors: [lit, mid, deep])
    context.fill(
        Path(ellipseIn: crownRect),
        with: .radialGradient(grad, center: CGPoint(x: crownCenter.x - radius * 0.3, y: crownCenter.y - radius * 0.35), startRadius: 1, endRadius: radius * 1.2)
    )
}

private func drawCypress(in context: inout GraphicsContext, base: CGPoint, height: CGFloat, sway: CGFloat, color: Color) {
    let tip = CGPoint(x: base.x + sway, y: base.y - height)
    var shape = Path()
    shape.move(to: CGPoint(x: base.x - 4.5, y: base.y))
    shape.addQuadCurve(to: tip, control: CGPoint(x: base.x - 6, y: base.y - height * 0.55))
    shape.addQuadCurve(to: CGPoint(x: base.x + 4.5, y: base.y), control: CGPoint(x: base.x + 6, y: base.y - height * 0.55))
    shape.closeSubpath()
    context.fill(shape, with: .color(color))
}

// MARK: World 4 — Cloudland (Monument Valley Terraces & Floating Spire Sanctuary)

private func drawCloudlandWorld(
    in context: inout GraphicsContext,
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let w = layout.size.width
    let y = layout.horizon + 5

    // Layered pastel paper-cut cloud terraces across the horizon.
    drawCloudTerraceBand(in: &context, width: w, baseY: y - 10, amplitude: 22, puffs: 6, color: palette.farLand.opacity(0.75), highlight: palette.landHighlight.opacity(0.5))
    drawHorizonMistVeil(in: &context, layout: layout, palette: palette, phase: phase, time: t)
    drawCloudTerraceBand(in: &context, width: w, baseY: y + 2, amplitude: 15, puffs: 7, color: palette.midLand.opacity(0.78), highlight: palette.landHighlight.opacity(0.65))

    // Left companion floating cloud arch pavilion (counter-phase ethereal bob).
    let leftBob = CGFloat(sin(t * 0.75 + 1.8)) * 3.2
    drawFloatingArchPavilion(
        in: &context,
        center: CGPoint(x: w * 0.13, y: y - 24 + leftBob),
        palette: palette
    )

    // Right signature floating Monument-Valley watercolor spire sanctuary (cleanly below headerSafeTop).
    let rightBob = CGFloat(sin(t * 0.75)) * 3.0
    drawFloatingSpireSanctuary(
        in: &context,
        center: CGPoint(x: w * 0.85, y: y - 20 + rightBob),
        palette: palette,
        time: t
    )
}

private func drawCloudTerraceBand(
    in context: inout GraphicsContext,
    width: CGFloat,
    baseY: CGFloat,
    amplitude: CGFloat,
    puffs: Int,
    color: Color,
    highlight: Color
) {
    var band = Path()
    band.move(to: CGPoint(x: -12, y: baseY + 14))
    band.addLine(to: CGPoint(x: -12, y: baseY))
    let step = (width + 24) / CGFloat(puffs)
    for i in 0..<puffs {
        let x0 = -12 + CGFloat(i) * step
        let x1 = x0 + step
        let peak = amplitude * (i.isMultiple(of: 2) ? 1.0 : 0.65)
        band.addQuadCurve(to: CGPoint(x: x1, y: baseY), control: CGPoint(x: (x0 + x1) * 0.5, y: baseY - peak))
    }
    band.addLine(to: CGPoint(x: width + 12, y: baseY + 14))
    band.closeSubpath()
    context.fill(band, with: .color(color))
    context.stroke(band, with: .color(highlight), lineWidth: 1.2)
}

private func drawFloatingArchPavilion(
    in context: inout GraphicsContext,
    center: CGPoint,
    palette: WorldPalette
) {
    // Cloud base pedestal.
    drawSinglePaperCutCloud(in: &context, center: CGPoint(x: center.x, y: center.y + 10), width: 64, lit: palette.nearLand, shade: palette.midLand, alpha: 0.95)

    // Minimalist arched stone pavilion.
    let wallRect = CGRect(x: center.x - 14, y: center.y - 14, width: 28, height: 22)
    context.fill(Path(roundedRect: wallRect, cornerRadius: 3), with: .color(palette.nearLand))
    context.stroke(Path(roundedRect: wallRect, cornerRadius: 3), with: .color(palette.contourInk), lineWidth: 0.9)

    // Arched opening.
    var arch = Path()
    arch.move(to: CGPoint(x: center.x - 5.5, y: center.y + 8))
    arch.addLine(to: CGPoint(x: center.x - 5.5, y: center.y - 2))
    arch.addArc(center: CGPoint(x: center.x, y: center.y - 2), radius: 5.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
    arch.addLine(to: CGPoint(x: center.x + 5.5, y: center.y + 8))
    arch.closeSubpath()
    context.fill(arch, with: .color(palette.accentA.opacity(0.68)))

    // Pastel roof dome.
    var dome = Path()
    dome.move(to: CGPoint(x: center.x - 15, y: center.y - 14))
    dome.addQuadCurve(to: CGPoint(x: center.x + 15, y: center.y - 14), control: CGPoint(x: center.x, y: center.y - 26))
    dome.closeSubpath()
    context.fill(dome, with: .color(palette.accentB))
}

private func drawFloatingSpireSanctuary(
    in context: inout GraphicsContext,
    center: CGPoint,
    palette: WorldPalette,
    time t: Double
) {
    // Sculpted floating cloud island pedestal.
    drawSinglePaperCutCloud(in: &context, center: CGPoint(x: center.x, y: center.y + 16), width: 92, lit: palette.nearLand, shade: palette.midLand, alpha: 0.96)

    // Connecting arched aqueduct gallery.
    let gallery = CGRect(x: center.x - 24, y: center.y - 10, width: 48, height: 18)
    context.fill(Path(roundedRect: gallery, cornerRadius: 3), with: .color(palette.nearLand))
    context.stroke(Path(roundedRect: gallery, cornerRadius: 3), with: .color(palette.contourInk), lineWidth: 0.8)

    // Three slender Monument-Valley towers (left, tall central spire, right).
    let towers: [(dx: CGFloat, w: CGFloat, h: CGFloat, spire: CGFloat)] = [
        (-19, 11, 23, 10),
        (0, 15, 34, 13),
        (19, 10, 20, 9)
    ]
    for tw in towers {
        let tx = center.x + tw.dx
        let rect = CGRect(x: tx - tw.w / 2, y: center.y + 8 - tw.h, width: tw.w, height: tw.h)
        let grad = Gradient(colors: [palette.landHighlight, palette.nearLand, palette.farLand])
        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .linearGradient(grad, startPoint: CGPoint(x: rect.minX, y: rect.minY), endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
        context.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(palette.contourInk), lineWidth: 0.8)

        // Tapered pastel spire cap.
        var roof = Path()
        roof.move(to: CGPoint(x: tx - tw.w * 0.58, y: rect.minY))
        roof.addQuadCurve(to: CGPoint(x: tx, y: rect.minY - tw.spire), control: CGPoint(x: tx - tw.w * 0.18, y: rect.minY - tw.spire * 0.55))
        roof.addQuadCurve(to: CGPoint(x: tx + tw.w * 0.58, y: rect.minY), control: CGPoint(x: tx + tw.w * 0.18, y: rect.minY - tw.spire * 0.55))
        roof.closeSubpath()
        context.fill(roof, with: .color(tw.dx == 0 ? palette.accentB : palette.accentA))

        // Warm glowing arched window slit.
        let winRect = CGRect(x: tx - 2.0, y: rect.minY + 6, width: 4.0, height: 6.5)
        context.fill(Path(roundedRect: winRect, cornerRadius: 2.0), with: .color(Color(hex: 0xFFF3BF).opacity(palette.isNight ? 0.95 : 0.72)))
    }

    // Fluttering ribbon pennant on the central spire.
    let tip = CGPoint(x: center.x, y: center.y + 8 - 34 - 13)
    let wave = CGFloat(sin(t * 2.2)) * 2.2
    var flag = Path()
    flag.move(to: tip)
    flag.addQuadCurve(to: CGPoint(x: tip.x + 11, y: tip.y + 2 + wave), control: CGPoint(x: tip.x + 5, y: tip.y - 2 - wave))
    flag.addLine(to: CGPoint(x: tip.x, y: tip.y + 4))
    flag.closeSubpath()
    context.fill(flag, with: .color(palette.accentB))
}

// MARK: World 5 — Starlight (Velvet Alpine Ridges & Pine Silhouettes)

private func drawStarlightWorld(
    in context: inout GraphicsContext,
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let w = layout.size.width
    let y = layout.horizon + 5

    // Far misty violet-indigo alpine mountain ridge (eased on right for generous crescent moon clearance).
    var farPeaks = Path()
    farPeaks.move(to: CGPoint(x: -4, y: y + 4))
    farPeaks.addLine(to: CGPoint(x: w * 0.12, y: y - 38))
    farPeaks.addLine(to: CGPoint(x: w * 0.28, y: y - 15))
    farPeaks.addLine(to: CGPoint(x: w * 0.44, y: y - 22))
    farPeaks.addLine(to: CGPoint(x: w * 0.63, y: y - 10))
    farPeaks.addLine(to: CGPoint(x: w * 0.88, y: y - 30))
    farPeaks.addLine(to: CGPoint(x: w + 4, y: y - 16))
    farPeaks.addLine(to: CGPoint(x: w + 4, y: y + 4))
    farPeaks.closeSubpath()
    context.fill(farPeaks, with: .color(palette.farLand.opacity(0.82)))

    // Cool silver-indigo alpine mist drifting between far peaks and shoreline pines.
    drawHorizonMistVeil(in: &context, layout: layout, palette: palette, phase: phase, time: t)

    // Mid dark cobalt alpine ridge (gently eased under crescent moon pocket).
    var midPeaks = Path()
    midPeaks.move(to: CGPoint(x: -4, y: y + 4))
    midPeaks.addLine(to: CGPoint(x: w * 0.06, y: y - 26))
    midPeaks.addLine(to: CGPoint(x: w * 0.24, y: y - 8))
    midPeaks.addLine(to: CGPoint(x: w * 0.50, y: y + 2))
    midPeaks.addLine(to: CGPoint(x: w * 0.76, y: y - 7))
    midPeaks.addLine(to: CGPoint(x: w * 0.93, y: y - 21))
    midPeaks.addLine(to: CGPoint(x: w + 4, y: y - 12))
    midPeaks.addLine(to: CGPoint(x: w + 4, y: y + 4))
    midPeaks.closeSubpath()
    context.fill(midPeaks, with: .color(palette.midLand))

    // Left & right evergreen pine silhouettes (right flank eased ~10pt lower for serene moon clearance).
    let pineSpecs: [(xFrac: CGFloat, h: CGFloat)] = [
        (0.03, 35), (0.08, 42), (0.14, 30), (0.19, 24), (0.24, 18),
        (0.79, 15), (0.85, 22), (0.91, 30), (0.96, 33), (0.99, 24)
    ]
    let sway = CGFloat(sin(t * 0.5)) * 0.8
    for pine in pineSpecs {
        drawAlpinePine(in: &context, base: CGPoint(x: w * pine.xFrac, y: y + 4), height: pine.h, sway: sway, color: palette.nearLand)
    }
}

private func drawAlpinePine(in context: inout GraphicsContext, base: CGPoint, height: CGFloat, sway: CGFloat, color: Color) {
    let tiers = 3
    for tier in 0..<tiers {
        let frac = CGFloat(tier) / CGFloat(tiers)
        let tierBottom = base.y - height * frac * 0.62
        let tierTop = tierBottom - height * (0.48 - frac * 0.08)
        let halfW = height * (0.24 - frac * 0.055)
        let xShift = sway * (frac + 0.3)

        var tri = Path()
        tri.move(to: CGPoint(x: base.x + xShift, y: tierTop))
        tri.addLine(to: CGPoint(x: base.x + halfW + xShift * 0.4, y: tierBottom))
        tri.addLine(to: CGPoint(x: base.x - halfW + xShift * 0.4, y: tierBottom))
        tri.closeSubpath()
        context.fill(tri, with: .color(color))
    }
}

// MARK: - Pond Surface (Metal Caustics Layer)

private func drawPondSurface(
    in context: inout GraphicsContext,
    canvasSize: CGSize,
    pondTop: CGFloat,
    theme: AppTheme,
    layout: WorldLayout,
    palette: WorldPalette,
    time t: Double
) {
    let w = canvasSize.width
    let h = canvasSize.height
    let lipY = layout.horizon - pondTop

    func shoreY(_ x: CGFloat) -> CGFloat {
        let waveAmp: CGFloat = theme == .peach ? 2.6 : 1.6
        return lipY + waveAmp * CGFloat(sin(Double(x / max(w, 1)) * .pi * 3.0 + t * 0.55))
    }

    var water = Path()
    water.move(to: CGPoint(x: 0, y: shoreY(0)))
    var x: CGFloat = 0
    while x <= w + 8 {
        water.addLine(to: CGPoint(x: x, y: shoreY(x)))
        x += 8
    }
    water.addLine(to: CGPoint(x: w, y: h))
    water.addLine(to: CGPoint(x: 0, y: h))
    water.closeSubpath()

    let waterGrad = Gradient(stops: [
        .init(color: palette.waterTop, location: 0.0),
        .init(color: palette.waterMid, location: 0.48),
        .init(color: palette.waterDeep, location: 1.0)
    ])
    context.fill(water, with: .linearGradient(waterGrad, startPoint: CGPoint(x: 0, y: lipY), endPoint: CGPoint(x: 0, y: h)))

    // Soft shoreline reflected color bands (pine mirror in Starlight, hill mirror in Meadow).
    if theme == .midnight || theme == .matcha {
        let reflectColor = palette.nearLand.opacity(theme == .midnight ? 0.30 : 0.16)
        let leftRef = CGRect(x: -10, y: lipY, width: w * 0.30, height: 22)
        let rightRef = CGRect(x: w * 0.72, y: lipY, width: w * 0.32, height: 22)
        context.fill(Path(ellipseIn: leftRef), with: .color(reflectColor))
        context.fill(Path(ellipseIn: rightRef), with: .color(reflectColor))
    }

    // Sun or moon shimmering reflection column down the water.
    let cx = layout.celestialCenter.x
    let rows = theme == .midnight ? 8 : 6
    for row in 0..<rows {
        let yRow = lipY + 12 + CGFloat(row) * 14
        if yRow > h - 10 { break }
        let shimmer = 0.82 + 0.18 * sin(t * 1.5 + Double(row) * 0.9)
        let sway = CGFloat(sin(t * 0.9 + Double(row) * 1.3)) * 3.5
        let halfW = CGFloat(max(32.0 - Double(row) * 3.5, 8.0)) * CGFloat(shimmer)
        var stripe = Path()
        stripe.move(to: CGPoint(x: cx - halfW + sway, y: yRow))
        stripe.addLine(to: CGPoint(x: cx + halfW + sway, y: yRow))
        let alpha = (theme == .midnight ? 0.56 : 0.44) - Double(row) * 0.055
        context.stroke(
            stripe,
            with: .color(palette.sunCore.opacity(max(alpha, 0.08))),
            style: StrokeStyle(lineWidth: row < 2 ? 3.8 : 2.8, lineCap: .round)
        )
    }

    // Painterly drifting water glints & seaside wave swells.
    let dashCount = theme == .peach ? 14 : 9
    for idx in 0..<dashCount {
        let seed = Double(idx)
        let py = lipY + 20 + CGFloat(sceneNoise(seed, 7.1)) * max(h - lipY - 36, 1)
        let span = Double(w + 90)
        let speed = theme == .peach ? (4.5 + sceneNoise(seed, 8.2) * 5.0) : (2.2 + sceneNoise(seed, 8.2) * 3.5)
        let px = CGFloat((sceneNoise(seed, 9.3) * span + t * speed).truncatingRemainder(dividingBy: span)) - 45
        let len = CGFloat(14 + sceneNoise(seed, 10.4) * 24)
        let pulse = 0.22 + 0.32 * (0.5 + 0.5 * sin(t * 1.3 + seed))

        var swell = Path()
        swell.move(to: CGPoint(x: px, y: py))
        swell.addQuadCurve(to: CGPoint(x: px + len, y: py), control: CGPoint(x: px + len * 0.5, y: py - (theme == .peach ? 2.4 : 0.6)))
        context.stroke(
            swell,
            with: .color(palette.waterLip.opacity(pulse)),
            style: StrokeStyle(lineWidth: theme == .peach ? 2.4 : 2.0, lineCap: .round)
        )
    }

    // Crisp luminous gouache water-meets-sky shore lip.
    var lip = Path()
    lip.move(to: CGPoint(x: 0, y: shoreY(0)))
    x = 0
    while x <= w + 8 {
        lip.addLine(to: CGPoint(x: x, y: shoreY(x)))
        x += 8
    }
    context.stroke(lip, with: .color(palette.waterLip.opacity(0.78)), lineWidth: 3.0)
}

// MARK: - Foreground Shore Details & Interactive Tap Ripples

private func drawPondForegroundDetails(
    in context: inout GraphicsContext,
    theme: AppTheme,
    layout: WorldLayout,
    palette: WorldPalette,
    time t: Double
) {
    let w = layout.size.width
    let yShore = layout.horizon + 12
    let sway = CGFloat(sin(t * 1.1)) * 2.4

    // Ultra-delicate silhouetted shoreline reeds & sea-grass blades tucked strictly inside
    // extreme outer margins (x < 0.052*w and x > 0.948*w) — zero overlap with decor or pads.
    let reedColor: Color = switch theme {
    case .lagoon: palette.accentB.opacity(palette.isNight ? 0.52 : 0.42)
    case .peach: palette.nearLand.opacity(palette.isNight ? 0.48 : 0.36)
    case .matcha: palette.accentA.opacity(palette.isNight ? 0.56 : 0.72)
    case .lavender: palette.accentA.opacity(palette.isNight ? 0.44 : 0.34)
    case .midnight: palette.nearLand.opacity(0.62)
    }

    let leftShore: [(x: CGFloat, h: CGFloat, lean: CGFloat)] = [
        (w * 0.010, 26, 4), (w * 0.025, 34, 7), (w * 0.040, 21, 5)
    ]
    let rightShore: [(x: CGFloat, h: CGFloat, lean: CGFloat)] = [
        (w * 0.960, 22, -5), (w * 0.975, 34, -7), (w * 0.990, 25, -4)
    ]

    for stem in leftShore + rightShore {
        var blade = Path()
        blade.move(to: CGPoint(x: stem.x, y: yShore))
        blade.addQuadCurve(
            to: CGPoint(x: stem.x + stem.lean + sway, y: yShore - stem.h),
            control: CGPoint(x: stem.x + stem.lean * 0.35, y: yShore - stem.h * 0.55)
        )
        context.stroke(blade, with: .color(reedColor), style: StrokeStyle(lineWidth: theme == .matcha ? 2.0 : 1.5, lineCap: .round))
    }

    // Whisper-soft lower outer corner framing grass blades (strictly x < 0.045*w / x > 0.955*w, well below floating decor).
    let bottomY = layout.size.height - 6
    if bottomY > layout.horizon + 210 {
        let lowerBlades: [(x: CGFloat, h: CGFloat, lean: CGFloat)] = [
            (w * 0.008, 36, 9), (w * 0.024, 26, 7),
            (w * 0.976, 26, -7), (w * 0.992, 36, -9)
        ]
        for bladeSpec in lowerBlades {
            var grass = Path()
            grass.move(to: CGPoint(x: bladeSpec.x, y: bottomY))
            grass.addQuadCurve(
                to: CGPoint(x: bladeSpec.x + bladeSpec.lean + sway * 0.7, y: bottomY - bladeSpec.h),
                control: CGPoint(x: bladeSpec.x + bladeSpec.lean * 0.3, y: bottomY - bladeSpec.h * 0.55)
            )
            context.stroke(grass, with: .color(reedColor.opacity(0.72)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
    }
}

private func drawTapRipples(
    in context: inout GraphicsContext,
    taps: [(Date, CGPoint)],
    now: Date,
    lipColor: Color
) {
    for (start, point) in taps {
        let age = now.timeIntervalSince(start)
        guard age >= 0, age < 1.65 else { continue }
        let progress = age / 1.65
        for ring in 0..<3 {
            let p = progress - Double(ring) * 0.14
            guard p > 0, p < 1 else { continue }
            let eased = 1.0 - pow(1.0 - p, 2.0)
            let rx = CGFloat(10 + eased * 74)
            let ry = rx * 0.27
            let rect = CGRect(x: point.x - rx, y: point.y - ry, width: rx * 2, height: ry * 2)
            let alpha = (0.85 - Double(ring) * 0.2) * (1.0 - p)
            context.stroke(Path(ellipseIn: rect), with: .color(lipColor.opacity(alpha)), lineWidth: 2.2 - CGFloat(ring) * 0.45)
        }
    }
}

// MARK: - Ambient Atmospheric Particles (Per-World Life)

private func drawAmbientParticles(
    in context: inout GraphicsContext,
    theme: AppTheme,
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let w = layout.size.width
    let minY = layout.hasHeaderZone ? layout.headerSafeTop + 10 : 18
    let maxY = layout.hasPond ? min(layout.horizon + 170, layout.size.height - 20) : layout.size.height - 16
    guard maxY > minY + 12 else { return }

    switch theme {
    case .midnight:
        // Warm glowing golden fireflies drifting in organic Lissajous loops near shore edges.
        drawFireflies(in: &context, width: w, minY: max(minY, layout.horizon - 42), maxY: maxY, time: t)

    case .matcha:
        // Soft floating dandelion seeds & warm sunlit meadow motes.
        drawDandelionSeeds(in: &context, width: w, minY: minY, maxY: layout.skyBottom + 60, tint: palette.particleColor, time: t)

    case .lavender:
        // Ethereal starlight dust & tiny prismatic sparkles.
        drawStarlightMotes(in: &context, width: w, minY: minY, maxY: layout.skyBottom + 80, tint: palette.particleColor, time: t)

    case .lagoon, .peach:
        // Sunlit drifting pollen / sea-spray sparkle motes.
        if palette.isNight {
            drawFireflies(in: &context, width: w, minY: max(minY, layout.horizon - 36), maxY: maxY, time: t)
        } else {
            drawPollenMotes(in: &context, width: w, minY: minY, maxY: layout.skyBottom + 80, tint: palette.particleColor, dense: phase != .dusk, time: t)
        }
    }
}

private func drawFireflies(in context: inout GraphicsContext, width: CGFloat, minY: CGFloat, maxY: CGFloat, time t: Double) {
    let spanY = max(maxY - minY, 20)
    for i in 0..<11 {
        let seed = Double(i) + 21.0
        // Bias fireflies toward outer atmospheric edges so Dewy's face stays clean.
        let side: CGFloat = i.isMultiple(of: 2) ? 0.0 : 1.0
        let edgeOffset = CGFloat(sceneNoise(seed, 1.1)) * 0.28
        let baseX = width * (side == 0 ? (0.04 + edgeOffset) : (0.96 - edgeOffset))
        let baseY = minY + CGFloat(sceneNoise(seed, 2.2)) * spanY

        let x = baseX + CGFloat(sin(t * (0.45 + sceneNoise(seed, 3.3) * 0.4) + seed)) * 14
        let y = baseY + CGFloat(cos(t * (0.38 + sceneNoise(seed, 4.4) * 0.35) + seed * 1.4)) * 10
        let glow = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * (1.5 + sceneNoise(seed, 5.5) * 1.4) + seed * 2.0))

        let haloR: CGFloat = 10.0
        let haloRect = CGRect(x: x - haloR, y: y - haloR, width: haloR * 2, height: haloR * 2)
        context.fill(
            Path(ellipseIn: haloRect),
            with: .radialGradient(
                Gradient(colors: [Color(hex: 0xFFE38A).opacity(0.55 * glow), Color(hex: 0xFFB84D).opacity(0)]),
                center: CGPoint(x: x, y: y), startRadius: 1, endRadius: haloR
            )
        )
        let coreRect = CGRect(x: x - 2.0, y: y - 2.0, width: 4.0, height: 4.0)
        context.fill(Path(ellipseIn: coreRect), with: .color(Color(hex: 0xFFF9D4).opacity(glow)))
    }
}

private func drawDandelionSeeds(in context: inout GraphicsContext, width: CGFloat, minY: CGFloat, maxY: CGFloat, tint: Color, time t: Double) {
    let spanY = max(maxY - minY, 20)
    let spanX = Double(width + 40)
    for i in 0..<10 {
        let seed = Double(i) + 41.0
        let px = CGFloat((sceneNoise(seed, 1.5) * spanX + t * (5.5 + sceneNoise(seed, 2.5) * 4.0)).truncatingRemainder(dividingBy: spanX)) - 20
        let py = minY + CGFloat(sceneNoise(seed, 3.5)) * spanY + CGFloat(sin(t * 0.9 + seed)) * 8
        let alpha = 0.35 + 0.40 * (0.5 + 0.5 * sin(t * 1.2 + seed))

        var stem = Path()
        stem.move(to: CGPoint(x: px, y: py + 4))
        stem.addLine(to: CGPoint(x: px + 2, y: py - 2))
        context.stroke(stem, with: .color(tint.opacity(alpha)), lineWidth: 0.9)

        let puff = CGRect(x: px - 1.5, y: py - 5.5, width: 6, height: 4.5)
        context.fill(Path(ellipseIn: puff), with: .color(tint.opacity(alpha * 0.85)))
    }
}

private func drawStarlightMotes(in context: inout GraphicsContext, width: CGFloat, minY: CGFloat, maxY: CGFloat, tint: Color, time t: Double) {
    let spanY = max(maxY - minY, 20)
    for i in 0..<12 {
        let seed = Double(i) + 61.0
        let x = CGFloat(sceneNoise(seed, 1.7)) * width + CGFloat(sin(t * 0.4 + seed)) * 9
        let y = minY + CGFloat(sceneNoise(seed, 2.7)) * spanY + CGFloat(cos(t * 0.5 + seed)) * 7
        let pulse = 0.22 + 0.62 * (0.5 + 0.5 * sin(t * 1.4 + seed * 1.9))
        let s = CGFloat(2.4 + sceneNoise(seed, 3.7) * 3.6)

        if i.isMultiple(of: 3) {
            let rect = CGRect(x: x - s, y: y - s, width: s * 2, height: s * 2)
            context.fill(StarletShape().path(in: rect), with: .color(tint.opacity(pulse)))
            let pearl = CGRect(x: x - 1.0, y: y - 1.0, width: 2.0, height: 2.0)
            context.fill(Path(ellipseIn: pearl), with: .color(Color(hex: 0xFFFDF8).opacity(pulse)))
        } else {
            let r = s * 0.36
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(pulse * 0.85)))
        }
    }
}

private func drawPollenMotes(in context: inout GraphicsContext, width: CGFloat, minY: CGFloat, maxY: CGFloat, tint: Color, dense: Bool, time t: Double) {
    let count = dense ? 10 : 6
    let spanY = max(maxY - minY, 20)
    for i in 0..<count {
        let seed = Double(i) + 81.0
        let x = CGFloat(sceneNoise(seed, 1.9)) * width + CGFloat(sin(t * 0.45 + seed)) * 10
        let y = minY + CGFloat(sceneNoise(seed, 2.9)) * spanY + CGFloat(cos(t * 0.35 + seed * 1.3)) * 7
        let pulse = 0.2 + 0.48 * (0.5 + 0.5 * sin(t * 1.1 + seed))
        let r = CGFloat(1.6 + sceneNoise(seed, 3.9) * 2.0)
        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
        context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(pulse)))
    }
}

// MARK: - Handcrafted Storybook Decor (Collision-Free Safe Slots & Night Harmony)

private func standingDecorSlots(for theme: AppTheme) -> [CGFloat] {
    switch theme {
    case .lagoon: return [0.66, 0.30, 0.90]
    case .peach: return [0.30, 0.72, 0.50]
    case .matcha: return [0.30, 0.72, 0.50]
    case .lavender: return [0.30, 0.66, 0.48]
    case .midnight: return [0.30, 0.70, 0.48]
    }
}

private func floatingDecorPoint(index: Int, layout: WorldLayout, time t: Double) -> CGPoint {
    let w = layout.size.width
    let waterDepth = max(layout.size.height - layout.horizon, 1)
    let baseY: CGFloat
    let xSlots: [CGFloat]
    if let explicitY = layout.floatingDecorY {
        baseY = min(explicitY, layout.size.height - 22)
        xSlots = [0.105, 0.895]
    } else if waterDepth > 220 {
        baseY = min(layout.horizon + 158, layout.size.height - 24)
        xSlots = [0.10, 0.90]
    } else if waterDepth > 140 {
        baseY = layout.horizon + min(132, waterDepth * 0.62)
        xSlots = [0.10, 0.90]
    } else {
        baseY = layout.horizon + waterDepth * 0.68
        xSlots = [0.12, 0.88]
    }
    let bob = CGFloat(sin(t * 1.45 + Double(index) * 1.9)) * 2.0
    let sway = CGFloat(sin(t * 0.42 + Double(index))) * 3.2
    return CGPoint(x: w * xSlots[index % 2] + sway, y: baseY + bob)
}

private func drawFlyingAndStandingDecor(
    in context: inout GraphicsContext,
    theme: AppTheme,
    decor: [Decor],
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let flying = decor.filter(\.flies)
    let standing = decor.filter { !$0.flies && !$0.floats }
    let w = layout.size.width

    for (index, item) in flying.enumerated() where !Art.exists(item.imageName) {
        switch item {
        case .rainbow:
            drawDecorRainbow(in: &context, layout: layout, isNight: palette.isNight)
        case .balloon:
            let bob = CGFloat(sin(t * 0.7 + Double(index))) * 5.0
            let bx = w * (index == 0 ? 0.16 : 0.84)
            let by = max(layout.headerSafeTop + 26, layout.skyBottom - 54) + bob
            drawDecorBalloon(in: &context, center: CGPoint(x: bx, y: by), isNight: palette.isNight, ink: palette.contourInk)
        default:
            break
        }
    }

    guard layout.hasPond else { return }

    // World-aware non-overlapping shore slots cleanly clear of landmarks and companion pads.
    let xSlots = standingDecorSlots(for: theme)
    for (index, item) in standing.prefix(3).enumerated() {
        let base = CGPoint(x: w * xSlots[index], y: layout.horizon + 6)
        // Always cast a cozy dusk/night radial glow behind lanterns (for both asset & Canvas).
        if item == .lantern && (phase == .dusk || phase == .night) {
            let haloCenter = CGPoint(x: base.x, y: base.y - 26)
            let glowR: CGFloat = 28 + CGFloat(sin(t * 2.9)) * 2.2
            let glowRect = CGRect(x: haloCenter.x - glowR, y: haloCenter.y - glowR, width: glowR * 2, height: glowR * 2)
            context.fill(
                Path(ellipseIn: glowRect),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: 0xFFE38E).opacity(0.68), Color(hex: 0xFFA764).opacity(0)]),
                    center: haloCenter, startRadius: 2, endRadius: glowR
                )
            )
        }
        if !Art.exists(item.imageName) {
            drawStandingDecorItem(in: &context, item: item, base: base, phase: phase, ink: palette.contourInk, time: t)
        }
    }
}

private func drawFloatingDecor(
    in context: inout GraphicsContext,
    decor: [Decor],
    layout: WorldLayout,
    palette: WorldPalette,
    phase: SkyPhase,
    time t: Double
) {
    let floating = decor.filter(\.floats)
    guard !floating.isEmpty else { return }

    for (index, item) in floating.prefix(2).enumerated() {
        let pt = floatingDecorPoint(index: index, layout: layout, time: t)
        let facingRight = index == 0

        // Soft dark-tinted buoyancy reflection directly beneath the hull on the water surface.
        let reflectTint = palette.waterDeep.blended(with: Color(hex: 0x0E1538), by: palette.isNight ? 0.45 : 0.22)
        let hullShadow = CGRect(x: pt.x - 16, y: pt.y - 1.5, width: 32, height: 8.5)
        context.fill(Path(ellipseIn: hullShadow), with: .color(reflectTint.opacity(palette.isNight ? 0.34 : 0.22)))
        let lowerRef = CGRect(x: pt.x - 11, y: pt.y + 4.5, width: 22, height: 4.5)
        context.fill(Path(ellipseIn: lowerRef), with: .color(reflectTint.opacity(palette.isNight ? 0.18 : 0.12)))

        // Staggered animated concentric watercolor ripples around the buoyant waterline.
        let phaseWave = sin(t * 1.45 + Double(index) * 1.9)
        let innerScale = 1.0 + CGFloat(phaseWave) * 0.06
        let innerRect = CGRect(x: pt.x - 20 * innerScale, y: pt.y - 3.2 * innerScale, width: 40 * innerScale, height: 10.5 * innerScale)
        context.stroke(Path(ellipseIn: innerRect), with: .color(palette.waterLip.opacity(palette.isNight ? 0.56 : 0.72)), lineWidth: 1.6)

        let outerScale = 1.30 + CGFloat(sin(t * 1.45 + Double(index) * 1.9 - 0.9)) * 0.09
        let outerRect = CGRect(x: pt.x - 21 * outerScale, y: pt.y - 3.4 * outerScale, width: 42 * outerScale, height: 11.0 * outerScale)
        context.stroke(Path(ellipseIn: outerRect), with: .color(palette.waterLip.opacity(palette.isNight ? 0.24 : 0.34)), lineWidth: 1.1)

        if !Art.exists(item.imageName) {
            if item == .duck {
                drawDecorDuck(in: &context, base: pt, facingRight: facingRight, phase: phase, ink: palette.contourInk)
            } else {
                drawDecorSwan(in: &context, base: pt, facingRight: facingRight, phase: phase, ink: palette.contourInk)
            }
        }
    }
}

private func atmosColor(_ color: Color, phase: SkyPhase) -> Color {
    switch phase {
    case .day: return color
    case .dawn: return color.blended(with: Color(hex: 0xFFD9B8), by: 0.14)
    case .dusk: return color.blended(with: Color(hex: 0xC69AE8), by: 0.22)
    case .night: return color.blended(with: Color(hex: 0x262E6B), by: 0.42)
    }
}

private func drawDecorRainbow(in context: inout GraphicsContext, layout: WorldLayout, isNight: Bool) {
    let w = layout.size.width
    let radius = min(w * 0.46, 178)
    let center = CGPoint(x: w * 0.50, y: layout.horizon + 12)
    let bands: [Color] = [
        Color(hex: 0xFF9EA8),
        Color(hex: 0xFFD08C),
        Color(hex: 0xB5E8AC),
        Color(hex: 0x9ADFF5),
        Color(hex: 0xCBB5FF)
    ]
    let alpha = isNight ? 0.22 : 0.46
    for (idx, color) in bands.enumerated() {
        let r = radius - CGFloat(idx) * 5.2
        guard center.y - r >= layout.headerSafeTop + 4 else { continue }
        var arc = Path()
        arc.addArc(center: center, radius: r, startAngle: .degrees(185), endAngle: .degrees(355), clockwise: false)
        context.stroke(arc, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: 5.2, lineCap: .round))
    }
}

private func drawDecorBalloon(in context: inout GraphicsContext, center: CGPoint, isNight: Bool, ink: Color) {
    let r: CGFloat = 18
    let phase: SkyPhase = isNight ? .night : .day

    // Wicker basket + ropes.
    let basket = CGRect(x: center.x - 5.5, y: center.y + r + 7, width: 11, height: 8)
    var ropes = Path()
    ropes.move(to: CGPoint(x: center.x - 6, y: center.y + r - 1))
    ropes.addLine(to: CGPoint(x: basket.minX + 1.5, y: basket.minY))
    ropes.move(to: CGPoint(x: center.x + 6, y: center.y + r - 1))
    ropes.addLine(to: CGPoint(x: basket.maxX - 1.5, y: basket.minY))
    context.stroke(ropes, with: .color(ink), lineWidth: 1.0)
    context.fill(Path(roundedRect: basket, cornerRadius: 2.0), with: .color(atmosColor(Color(hex: 0xC99366), phase: phase)))

    // Warm burner glow inside balloon at night.
    if isNight {
        let glowRect = CGRect(x: center.x - 10, y: center.y + r - 4, width: 20, height: 14)
        context.fill(Path(ellipseIn: glowRect), with: .color(Color(hex: 0xFFDF8C).opacity(0.65)))
    }

    // Teardrop envelope.
    let angle35 = 35.0 * Double.pi / 180.0
    let leftRim = CGPoint(x: center.x - r * CGFloat(cos(angle35)), y: center.y + r * CGFloat(sin(angle35)))
    var env = Path()
    env.addArc(center: center, radius: r, startAngle: .degrees(145), endAngle: .degrees(35), clockwise: false)
    env.addQuadCurve(to: CGPoint(x: center.x + 6, y: center.y + r + 2), control: CGPoint(x: center.x + r * 0.72, y: center.y + r * 0.85))
    env.addLine(to: CGPoint(x: center.x - 6, y: center.y + r + 2))
    env.addQuadCurve(to: leftRim, control: CGPoint(x: center.x - r * 0.72, y: center.y + r * 0.85))
    env.closeSubpath()

    context.fill(env, with: .color(atmosColor(Color(hex: 0xC9B4FF), phase: phase)))
    context.drawLayer { layer in
        layer.clip(to: env)
        let stripe = CGRect(x: center.x - 6.5, y: center.y - r, width: 13, height: r * 2.2)
        layer.fill(Path(ellipseIn: stripe), with: .color(atmosColor(Color(hex: 0xFFAEBD), phase: phase)))
    }
    context.stroke(env, with: .color(ink), lineWidth: 1.0)
}

private func drawStandingDecorItem(
    in context: inout GraphicsContext,
    item: Decor,
    base: CGPoint,
    phase: SkyPhase,
    ink: Color,
    time t: Double
) {
    switch item {
    case .flowers:
        drawDecorFlowers(in: &context, base: base, phase: phase, time: t)
    case .mushroom:
        drawDecorMushrooms(in: &context, base: base, phase: phase, ink: ink)
    case .lantern:
        drawDecorLantern(in: &context, base: base, phase: phase, ink: ink, time: t)
    case .umbrella:
        drawDecorUmbrella(in: &context, base: base, phase: phase, ink: ink)
    case .blossom:
        drawDecorBlossomTree(in: &context, base: base, phase: phase, ink: ink, time: t)
    case .fountain:
        drawDecorFountain(in: &context, base: base, phase: phase, ink: ink, time: t)
    default:
        break
    }
}

private func drawDecorFlowers(in context: inout GraphicsContext, base: CGPoint, phase: SkyPhase, time t: Double) {
    let tuft = Path(ellipseIn: CGRect(x: base.x - 19, y: base.y - 7, width: 38, height: 11))
    context.fill(tuft, with: .color(atmosColor(Color(hex: 0x6EB87E), phase: phase)))

    let specs: [(dx: CGFloat, h: CGFloat, color: Color)] = [
        (-11, 20, Color(hex: 0xFF9EC4)),
        (0, 26, Color(hex: 0xFFD66B)),
        (11, 19, Color(hex: 0xC3A8FF))
    ]
    let sway = CGFloat(sin(t * 1.2)) * 1.8
    for (idx, sp) in specs.enumerated() {
        let top = CGPoint(x: base.x + sp.dx + sway * (idx == 1 ? 1.1 : 0.8), y: base.y - sp.h)
        var stem = Path()
        stem.move(to: CGPoint(x: base.x + sp.dx, y: base.y - 3))
        stem.addQuadCurve(to: top, control: CGPoint(x: base.x + sp.dx * 0.8, y: base.y - sp.h * 0.5))
        context.stroke(stem, with: .color(atmosColor(Color(hex: 0x4A9261), phase: phase)), lineWidth: 2.0)

        // Tulip cup blossom.
        let cup = CGRect(x: top.x - 5.5, y: top.y - 7.5, width: 11, height: 9)
        context.fill(Path(ellipseIn: cup), with: .color(atmosColor(sp.color, phase: phase)))
        let tip = CGRect(x: top.x - 2.5, y: top.y - 9.0, width: 5, height: 4)
        context.fill(Path(ellipseIn: tip), with: .color(atmosColor(sp.color.blended(with: .white, by: 0.35), phase: phase)))
    }
}

private func drawDecorMushrooms(in context: inout GraphicsContext, base: CGPoint, phase: SkyPhase, ink: Color) {
    let items: [(dx: CGFloat, r: CGFloat, h: CGFloat)] = [(-8, 12, 16), (9, 8.5, 11)]
    for m in items {
        let mx = base.x + m.dx
        let stem = CGRect(x: mx - m.r * 0.32, y: base.y - m.h, width: m.r * 0.64, height: m.h)
        context.fill(Path(roundedRect: stem, cornerRadius: 3), with: .color(atmosColor(Color(hex: 0xFFF4E6), phase: phase)))

        var cap = Path()
        cap.move(to: CGPoint(x: mx - m.r, y: base.y - m.h + 2))
        cap.addQuadCurve(to: CGPoint(x: mx + m.r, y: base.y - m.h + 2), control: CGPoint(x: mx, y: base.y - m.h - m.r * 1.15))
        cap.closeSubpath()
        context.fill(cap, with: .color(atmosColor(Color(hex: 0xF06E6E), phase: phase)))
        context.stroke(cap, with: .color(ink), lineWidth: 0.9)

        let dot1 = CGRect(x: mx - m.r * 0.42, y: base.y - m.h - m.r * 0.32, width: 3.4, height: 3.0)
        let dot2 = CGRect(x: mx + m.r * 0.16, y: base.y - m.h - m.r * 0.44, width: 2.8, height: 2.5)
        context.fill(Path(ellipseIn: dot1), with: .color(atmosColor(.white, phase: phase)))
        context.fill(Path(ellipseIn: dot2), with: .color(atmosColor(.white, phase: phase)))
    }
}

private func drawDecorLantern(in context: inout GraphicsContext, base: CGPoint, phase: SkyPhase, ink: Color, time t: Double) {
    let postX = base.x - 6
    var post = Path()
    post.move(to: CGPoint(x: postX, y: base.y))
    post.addLine(to: CGPoint(x: postX, y: base.y - 40))
    post.addLine(to: CGPoint(x: postX + 16, y: base.y - 40))
    context.stroke(post, with: .color(atmosColor(Color(hex: 0x7A5748), phase: phase)), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))

    let swing = CGFloat(sin(t * 1.4)) * 2.0
    let lc = CGPoint(x: postX + 15 + swing, y: base.y - 27)
    let isLit = phase == .dusk || phase == .night

    if isLit {
        let glowR: CGFloat = 24 + CGFloat(sin(t * 3.1)) * 2.0
        let glowRect = CGRect(x: lc.x - glowR, y: lc.y - glowR, width: glowR * 2, height: glowR * 2)
        context.fill(
            Path(ellipseIn: glowRect),
            with: .radialGradient(
                Gradient(colors: [Color(hex: 0xFFE38E).opacity(0.68), Color(hex: 0xFFA764).opacity(0)]),
                center: lc, startRadius: 2, endRadius: glowR
            )
        )
    }

    let bodyRect = CGRect(x: lc.x - 7.5, y: lc.y - 9.5, width: 15, height: 19)
    let lanternColor = isLit ? Color(hex: 0xFFCF78) : atmosColor(Color(hex: 0xFFB88C), phase: phase)
    context.fill(Path(roundedRect: bodyRect, cornerRadius: 6), with: .color(lanternColor))
    context.stroke(Path(roundedRect: bodyRect, cornerRadius: 6), with: .color(ink), lineWidth: 0.9)
}

private func drawDecorUmbrella(in context: inout GraphicsContext, base: CGPoint, phase: SkyPhase, ink: Color) {
    let top = CGPoint(x: base.x + 4, y: base.y - 34)
    var pole = Path()
    pole.move(to: base)
    pole.addLine(to: top)
    context.stroke(pole, with: .color(atmosColor(Color(hex: 0xB58969), phase: phase)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

    var canopy = Path()
    canopy.move(to: CGPoint(x: top.x - 20, y: top.y + 8))
    canopy.addQuadCurve(to: CGPoint(x: top.x + 20, y: top.y + 4), control: CGPoint(x: top.x - 1, y: top.y - 14))
    canopy.closeSubpath()
    context.fill(canopy, with: .color(atmosColor(Color(hex: 0xFF8C7A), phase: phase)))

    var stripe = Path()
    stripe.move(to: CGPoint(x: top.x - 7, y: top.y + 6.5))
    stripe.addQuadCurve(to: CGPoint(x: top.x + 7, y: top.y + 5.2), control: CGPoint(x: top.x, y: top.y - 12))
    stripe.closeSubpath()
    context.fill(stripe, with: .color(atmosColor(Color(hex: 0xFFF8EF), phase: phase)))
    context.stroke(canopy, with: .color(ink), lineWidth: 0.9)
}

private func drawDecorBlossomTree(in context: inout GraphicsContext, base: CGPoint, phase: SkyPhase, ink: Color, time t: Double) {
    let sway = CGFloat(sin(t * 0.8)) * 1.8
    var trunk = Path()
    trunk.move(to: CGPoint(x: base.x - 3, y: base.y))
    trunk.addQuadCurve(to: CGPoint(x: base.x + 2, y: base.y - 26), control: CGPoint(x: base.x - 4, y: base.y - 14))
    trunk.addLine(to: CGPoint(x: base.x + 5, y: base.y - 26))
    trunk.addQuadCurve(to: CGPoint(x: base.x + 3, y: base.y), control: CGPoint(x: base.x + 2, y: base.y - 14))
    trunk.closeSubpath()
    context.fill(trunk, with: .color(atmosColor(Color(hex: 0x7A5754), phase: phase)))

    let puffs: [(dx: CGFloat, dy: CGFloat, r: CGFloat, color: Color)] = [
        (-11, -28, 12, Color(hex: 0xFFB5D2)),
        (10, -27, 11, Color(hex: 0xFFA4C8)),
        (0, -35, 14, Color(hex: 0xFFC7DE))
    ]
    for puff in puffs {
        let rect = CGRect(x: base.x + puff.dx + sway - puff.r, y: base.y + puff.dy - puff.r * 0.85, width: puff.r * 2, height: puff.r * 1.7)
        context.fill(Path(ellipseIn: rect), with: .color(atmosColor(puff.color, phase: phase)))
    }
    _ = ink
}

private func drawDecorFountain(in context: inout GraphicsContext, base: CGPoint, phase: SkyPhase, ink: Color, time t: Double) {
    let stone = atmosColor(Color(hex: 0xE8EEF2), phase: phase)
    let basin = CGRect(x: base.x - 16, y: base.y - 10, width: 32, height: 10)
    context.fill(Path(roundedRect: basin, cornerRadius: 5), with: .color(stone))
    context.stroke(Path(roundedRect: basin, cornerRadius: 5), with: .color(ink), lineWidth: 0.9)

    let pillar = CGRect(x: base.x - 3.5, y: base.y - 26, width: 7, height: 17)
    context.fill(Path(roundedRect: pillar, cornerRadius: 2), with: .color(stone))

    let topBowl = CGRect(x: base.x - 9, y: base.y - 29, width: 18, height: 6)
    context.fill(Path(roundedRect: topBowl, cornerRadius: 3), with: .color(stone))

    // Animated sparkling fountain water arcs.
    let shimmer = 0.65 + 0.35 * sin(t * 3.0)
    let waterCol = atmosColor(Color(hex: 0x9BE9FA), phase: phase).opacity(shimmer)
    for dir in [-1.0, 1.0] {
        let sign = CGFloat(dir)
        var arc = Path()
        arc.move(to: CGPoint(x: base.x, y: base.y - 30))
        arc.addQuadCurve(to: CGPoint(x: base.x + sign * 12, y: base.y - 10), control: CGPoint(x: base.x + sign * 8, y: base.y - 42))
        context.stroke(arc, with: .color(waterCol), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }
}

private func drawDecorDuck(in context: inout GraphicsContext, base: CGPoint, facingRight: Bool, phase: SkyPhase, ink: Color) {
    let dir: CGFloat = facingRight ? 1 : -1
    let yellow = atmosColor(Color(hex: 0xFFD95E), phase: phase)
    let bill = atmosColor(Color(hex: 0xFF9159), phase: phase)

    let body = CGRect(x: base.x - 14, y: base.y - 13, width: 28, height: 16)
    context.fill(Path(ellipseIn: body), with: .color(yellow))
    context.stroke(Path(ellipseIn: body), with: .color(ink), lineWidth: 0.9)

    let headCenter = CGPoint(x: base.x + dir * 8, y: base.y - 17)
    let headRect = CGRect(x: headCenter.x - 8, y: headCenter.y - 8, width: 16, height: 16)
    context.fill(Path(ellipseIn: headRect), with: .color(yellow))
    context.stroke(Path(ellipseIn: headRect), with: .color(ink), lineWidth: 0.9)

    let beakRect = CGRect(x: headCenter.x + dir * 6 - 3, y: headCenter.y - 1.5, width: 6.5, height: 4.5)
    context.fill(Path(ellipseIn: beakRect), with: .color(bill))

    let eyeRect = CGRect(x: headCenter.x + dir * 2.2 - 1.4, y: headCenter.y - 2.6, width: 2.8, height: 2.8)
    context.fill(Path(ellipseIn: eyeRect), with: .color(Ink.primary))
}

private func drawDecorSwan(in context: inout GraphicsContext, base: CGPoint, facingRight: Bool, phase: SkyPhase, ink: Color) {
    let dir: CGFloat = facingRight ? 1 : -1
    let cream = atmosColor(Color(hex: 0xFFFBF7), phase: phase)
    let gold = atmosColor(Color(hex: 0xFFD46B), phase: phase)

    let body = CGRect(x: base.x - 16, y: base.y - 13, width: 32, height: 16)
    context.fill(Path(ellipseIn: body), with: .color(cream))
    context.stroke(Path(ellipseIn: body), with: .color(ink), lineWidth: 0.9)

    // Graceful S-curved neck.
    var neck = Path()
    neck.move(to: CGPoint(x: base.x + dir * 9, y: base.y - 9))
    neck.addCurve(
        to: CGPoint(x: base.x + dir * 11, y: base.y - 25),
        control1: CGPoint(x: base.x + dir * 16, y: base.y - 15),
        control2: CGPoint(x: base.x + dir * 5, y: base.y - 23)
    )
    context.stroke(neck, with: .color(cream), style: StrokeStyle(lineWidth: 5.5, lineCap: .round))

    // Tiny golden crown on swan head.
    let crown = CGRect(x: base.x + dir * 11 - 3.5, y: base.y - 30.5, width: 7, height: 4)
    context.fill(Path(roundedRect: crown, cornerRadius: 1.5), with: .color(gold))
}

// MARK: - Botanical Gouache Lily Pad

/// Handcrafted botanical lily pad Dewy stands on, with radial leaf veins, glistening
/// dewdrops, a blooming storybook lotus bud and concentric watercolor ripples.
struct LilyPad: View {
    var width: CGFloat
    var rippleTrigger: Int = 0
    var animated = true

    @Environment(\.dewyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var splashes: [Date] = []

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        let phase = theme.phase()
        Group {
            if animated {
                TimelineView(.animation(minimumInterval: splashes.isEmpty ? 1.0 / 30.0 : 1.0 / 60.0, paused: !isLive && splashes.isEmpty)) { timeline in
                    let now = timeline.date
                    let t = isLive ? now.timeIntervalSinceReferenceDate : 0.0
                    padCanvas(phase: phase, time: t, now: now)
                }
            } else {
                padCanvas(phase: phase, time: 0.0, now: .now)
            }
        }
        .frame(width: width * 1.9, height: width * 0.5)
        .onChange(of: rippleTrigger) {
            splashes = splashes.filter { Date.now.timeIntervalSince($0) < 2.0 } + [Date.now]
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                splashes = splashes.filter { Date.now.timeIntervalSince($0) < 1.9 }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func padCanvas(phase: SkyPhase, time t: Double, now: Date) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.54)
            let rx = width * 0.5
            let ry = rx * 0.275
            let night = phase.isNight

            drawPadRipples(in: &context, center: center, rx: rx, ry: ry, night: night, time: t, now: now)
            drawPadBody(in: &context, center: center, rx: rx, ry: ry, phase: phase)
            drawPadVeinsAndDewdrops(in: &context, center: center, rx: rx, ry: ry, night: night)
            drawPadLotusBlossom(in: &context, center: CGPoint(x: center.x - rx * 0.72, y: center.y - ry * 0.36), scale: max(width / 164.0, 0.55), phase: phase)
        }
    }

    private func drawPadRipples(
        in context: inout GraphicsContext,
        center: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        night: Bool,
        time t: Double,
        now: Date
    ) {
        let ringTint = night ? Color(hex: 0xC0CCFF) : Color.white

        func strokeRing(_ scale: CGFloat, opacity: Double, line: CGFloat) {
            let rect = CGRect(
                x: center.x - rx * scale,
                y: center.y - ry * scale + 2,
                width: rx * 2 * scale,
                height: ry * 2 * scale
            )
            context.stroke(Path(ellipseIn: rect), with: .color(ringTint.opacity(opacity)), lineWidth: line)
        }

        // Gentle breathing water rings.
        let breathe = CGFloat(sin(t * 1.25)) * 0.035
        strokeRing(1.26 + breathe, opacity: night ? 0.34 : 0.48, line: 2.0)
        strokeRing(1.66 + breathe * 1.5, opacity: night ? 0.18 : 0.24, line: 1.5)

        // Concentric expanding watercolor splash rings when a drink lands.
        for start in splashes {
            let age = now.timeIntervalSince(start)
            guard age >= 0, age < 1.85 else { continue }
            for wave in 0..<3 {
                let p = (age - Double(wave) * 0.16) / 1.65
                guard p > 0, p < 1 else { continue }
                let eased = 1.0 - pow(1.0 - p, 2.0)
                let scale = 1.08 + CGFloat(eased) * (1.55 - CGFloat(wave) * 0.2)
                let alpha = (0.88 - Double(wave) * 0.22) * (1.0 - p)
                strokeRing(scale, opacity: alpha, line: 3.0 - CGFloat(wave) * 0.6)
            }
        }

        // Deep water shadow underneath pad.
        let shadowRect = CGRect(x: center.x - rx * 1.02, y: center.y - ry + 6.5, width: rx * 2.04, height: ry * 2.04)
        context.fill(Path(ellipseIn: shadowRect), with: .color(Color(hex: night ? 0x0E1436 : 0x1A5A78).opacity(night ? 0.34 : 0.20)))
    }

    private func drawPadBody(in context: inout GraphicsContext, center: CGPoint, rx: CGFloat, ry: CGFloat, phase: SkyPhase) {
        let leafPath = notchedLeafPath(center: center, rx: rx, ry: ry)
        let rimPath = notchedLeafPath(center: CGPoint(x: center.x, y: center.y + 4.5), rx: rx, ry: ry)

        let topLight: Color
        let midGreen: Color
        let rimDeep: Color
        let inkColor: Color

        switch phase {
        case .dawn:
            topLight = Color(hex: 0xC8F0B4)
            midGreen = Color(hex: 0x7ED194)
            rimDeep = Color(hex: 0x4E9B6F)
            inkColor = Color(hex: 0x356950).opacity(0.45)
        case .day:
            topLight = Color(hex: 0xC2F2B6)
            midGreen = Color(hex: 0x75CE8E)
            rimDeep = Color(hex: 0x439B68)
            inkColor = Color(hex: 0x2B6B4D).opacity(0.42)
        case .dusk:
            topLight = Color(hex: 0xB4DFB8)
            midGreen = Color(hex: 0x6BB08C)
            rimDeep = Color(hex: 0x427B6D)
            inkColor = Color(hex: 0x2B4F4F).opacity(0.48)
        case .night:
            topLight = Color(hex: 0x6AA89F)
            midGreen = Color(hex: 0x3D7A7E)
            rimDeep = Color(hex: 0x244C5E)
            inkColor = Color(hex: 0x162E44).opacity(0.65)
        }

        // Sculpted buoyant lower rim thickness.
        context.fill(rimPath, with: .color(rimDeep))

        // Sunlit gouache top leaf face.
        let grad = Gradient(stops: [
            .init(color: topLight, location: 0.0),
            .init(color: midGreen, location: 0.65),
            .init(color: rimDeep.blended(with: midGreen, by: 0.4), location: 1.0)
        ])
        context.fill(
            leafPath,
            with: .radialGradient(grad, center: CGPoint(x: center.x - rx * 0.2, y: center.y - ry * 0.35), startRadius: 4, endRadius: rx * 1.15)
        )

        // Subtle sunlit rim highlight + warm hand-inked botanical outline.
        context.stroke(leafPath, with: .color(topLight.opacity(phase.isNight ? 0.35 : 0.72)), lineWidth: 1.8)
        context.stroke(leafPath, with: .color(inkColor), lineWidth: 1.0)
    }

    private func notchedLeafPath(center: CGPoint, rx: CGFloat, ry: CGFloat) -> Path {
        // Organic V-notch tucked at the front-right angle (~24 degrees).
        let notchCenter: Double = 0.42
        let notchHalf: Double = 0.14
        let steps = 56
        let startAngle = notchCenter + notchHalf
        let endAngle = notchCenter - notchHalf + .pi * 2.0

        var path = Path()
        let innerNotch = CGPoint(x: center.x + rx * 0.32, y: center.y + ry * 0.24)
        path.move(to: innerNotch)
        for i in 0...steps {
            let a = startAngle + (endAngle - startAngle) * (Double(i) / Double(steps))
            // Subtle organic botanical undulation along the rim.
            let wobble = 1.0 + 0.015 * sin(a * 5.0)
            let pt = CGPoint(
                x: center.x + CGFloat(cos(a) * wobble) * rx,
                y: center.y + CGFloat(sin(a) * wobble) * ry
            )
            path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }

    private func drawPadVeinsAndDewdrops(
        in context: inout GraphicsContext,
        center: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        night: Bool
    ) {
        let veinColor = night ? Color(hex: 0xA8DFCE).opacity(0.32) : Color(hex: 0xE9FFCF).opacity(0.55)
        let origin = CGPoint(x: center.x + rx * 0.04, y: center.y + ry * 0.04)
        let angles: [Double] = [1.15, 1.85, 2.55, 3.25, 4.05, 4.85, 5.65]

        for a in angles {
            let tip = CGPoint(x: center.x + CGFloat(cos(a)) * rx * 0.84, y: center.y + CGFloat(sin(a)) * ry * 0.82)
            let ctrl = CGPoint(x: center.x + CGFloat(cos(a + 0.16)) * rx * 0.46, y: center.y + CGFloat(sin(a + 0.16)) * ry * 0.46)
            var vein = Path()
            vein.move(to: origin)
            vein.addQuadCurve(to: tip, control: ctrl)
            context.stroke(vein, with: .color(veinColor), style: StrokeStyle(lineWidth: 1.15, lineCap: .round))
        }

        // Glistening dewdrop beads resting near the outer rim.
        let beads: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
            (center.x + rx * 0.64, center.y - ry * 0.34, 3.0),
            (center.x + rx * 0.54, center.y - ry * 0.12, 2.0),
            (center.x - rx * 0.44, center.y + ry * 0.44, 2.4)
        ]
        for b in beads {
            let dropRect = CGRect(x: b.x - b.r, y: b.y - b.r * 0.72, width: b.r * 2, height: b.r * 1.44)
            context.fill(Path(ellipseIn: dropRect), with: .color(Color(hex: night ? 0xB8E0FF : 0xE6FBFF).opacity(0.82)))
            let glintRect = CGRect(x: b.x - b.r * 0.45, y: b.y - b.r * 0.45, width: b.r * 0.7, height: b.r * 0.55)
            context.fill(Path(ellipseIn: glintRect), with: .color(.white.opacity(0.95)))
        }
    }

    private func drawPadLotusBlossom(in context: inout GraphicsContext, center: CGPoint, scale: CGFloat, phase: SkyPhase) {
        let outerPetal = atmosColor(Color(hex: 0xFF9AC2), phase: phase)
        let innerPetal = atmosColor(Color(hex: 0xFFD0E3), phase: phase)
        let stamen = atmosColor(Color(hex: 0xFFE074), phase: phase)

        let petalSpecs: [(angle: Double, len: CGFloat, w: CGFloat, color: Color)] = [
            (-0.95, 16, 8, outerPetal),
            (0.95, 16, 8, outerPetal),
            (-0.45, 17, 8.5, innerPetal),
            (0.45, 17, 8.5, innerPetal),
            (0.0, 18, 9, innerPetal.blended(with: .white, by: 0.25))
        ]

        context.drawLayer { layer in
            layer.translateBy(x: center.x, y: center.y)
            layer.scaleBy(x: scale, y: scale)

            for spec in petalSpecs {
                layer.drawLayer { petalLayer in
                    petalLayer.rotate(by: Angle.radians(spec.angle))
                    var p = Path()
                    p.move(to: .zero)
                    p.addQuadCurve(to: CGPoint(x: 0, y: -spec.len), control: CGPoint(x: -spec.w, y: -spec.len * 0.55))
                    p.addQuadCurve(to: .zero, control: CGPoint(x: spec.w, y: -spec.len * 0.55))
                    p.closeSubpath()
                    petalLayer.fill(p, with: .color(spec.color))
                }
            }
            let core = CGRect(x: -4, y: -6, width: 8, height: 5)
            layer.fill(Path(ellipseIn: core), with: .color(stamen))
        }
    }
}

// MARK: - Sky Header

/// The sky behind the top of a screen. It keeps going upward in the sky's top color,
/// so the status bar area and overscrolling always show sky.
struct SkyHeaderBackground: View {
    var height: CGFloat
    /// Horizon measured from the top of the header; `nil` shows only sky.
    var horizon: CGFloat?
    var showsLandmark = true

    @Environment(\.dewyTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            theme.sky[0].frame(height: 800)
            ClayWorld(horizon: horizon ?? height + 1_000, showsLandmark: showsLandmark)
                .frame(height: height)
        }
        .frame(height: height, alignment: .bottom)
        .allowsHitTesting(false)
    }
}
