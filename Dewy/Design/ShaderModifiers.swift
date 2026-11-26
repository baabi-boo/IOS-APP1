import SwiftUI

// MARK: - Metal Shader View Modifiers (Main App Target Only)
//
// Wraps the [[stitchable]] MSL effects from DewyShaders.metal into ergonomic,
// layout-neutral iOS 17+ SwiftUI modifiers that respect accessibilityReduceMotion
// and LaunchOptions.freezesMotion without altering intrinsic view layout.

private enum ShaderTime {
    /// Frozen phase chosen for balanced, picturesque caustic filaments in still captures.
    static let frozen: Double = 18.4

    /// Wraps epoch time into a compact range before Float conversion so 32-bit
    /// Metal floats preserve sub-millisecond smoothness.
    static func wrap(_ time: Double, frozen isFrozen: Bool) -> Float {
        if isFrozen {
            return Float(frozen)
        }
        return Float(time.truncatingRemainder(dividingBy: 1_200.0))
    }
}

private struct PaperGrainModifier: ViewModifier {
    var intensity: Double

    func body(content: Content) -> some View {
        let clamped = Float(max(intensity, 0))
        content.colorEffect(
            ShaderLibrary.paperGrain(.float(clamped)),
            isEnabled: clamped > 0.0001
        )
    }
}

private struct PondCausticsModifier: ViewModifier {
    var time: Double
    var tint: Color
    var strength: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isFrozen = reduceMotion || LaunchOptions.freezesMotion
        let wrappedTime = ShaderTime.wrap(time, frozen: isFrozen)
        let clampedStrength = Float(max(strength, 0))

        content.colorEffect(
            ShaderLibrary.pondCausticsRect(
                .boundingRect,
                .float(wrappedTime),
                .color(tint),
                .float(clampedStrength)
            ),
            isEnabled: clampedStrength > 0.0001
        )
    }
}

private struct GouacheBloomModifier: ViewModifier {
    var strength: Double

    func body(content: Content) -> some View {
        let clampedStrength = Float(max(strength, 0))

        content.colorEffect(
            ShaderLibrary.gouacheBloomRect(
                .boundingRect,
                .float(clampedStrength)
            ),
            isEnabled: clampedStrength > 0.0001
        )
    }
}

private struct MeniscusGlowModifier: ViewModifier {
    var time: Double
    var strength: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isFrozen = reduceMotion || LaunchOptions.freezesMotion
        let wrappedTime = ShaderTime.wrap(time, frozen: isFrozen)
        let clampedStrength = Float(max(strength, 0))

        content.colorEffect(
            ShaderLibrary.meniscusGlowRect(
                .boundingRect,
                .float(wrappedTime),
                .float(clampedStrength)
            ),
            isEnabled: clampedStrength > 0.0001
        )
    }
}

private struct LiveMeniscusGlowModifier: ViewModifier {
    var strength: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLive: Bool { !reduceMotion && !LaunchOptions.freezesMotion }

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isLive)) { timeline in
            let t = isLive ? timeline.date.timeIntervalSinceReferenceDate : ShaderTime.frozen
            content.meniscusGlow(time: t, strength: strength)
        }
    }
}

extension View {
    /// Adds subtle cold-press cotton-rag watercolor paper texture.
    func paperGrain(_ intensity: Double = 0.032) -> some View {
        modifier(PaperGrainModifier(intensity: intensity))
    }

    /// Adds flowing sunlit gouache caustic ribbons across pond water.
    func pondCaustics(time: Double, tint: Color, strength: Double = 0.16) -> some View {
        modifier(PondCausticsModifier(time: time, tint: tint, strength: strength))
    }

    /// Adds gentle painterly gouache pigment granulation and skylight warmth.
    func gouacheBloom(_ strength: Double = 0.035) -> some View {
        modifier(GouacheBloomModifier(strength: strength))
    }

    /// Adds an organic animated liquid meniscus shimmer highlight.
    func meniscusGlow(time: Double, strength: Double = 0.14) -> some View {
        modifier(MeniscusGlowModifier(time: time, strength: strength))
    }

    /// Adds a self-animating liquid meniscus caustic shimmer that freezes cleanly
    /// under Reduce Motion or LaunchOptions.freezesMotion.
    func liveMeniscusGlow(strength: Double = 0.14) -> some View {
        modifier(LiveMeniscusGlowModifier(strength: strength))
    }
}
