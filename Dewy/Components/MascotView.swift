import SwiftUI

/// How Dewy feels, based on today's progress.
enum DewyMood: String, CaseIterable {
    case thirsty, okay, happy, ecstatic

    init(progress: Double) {
        switch progress {
        case ..<0.25: self = .thirsty
        case ..<0.6: self = .okay
        case ..<1: self = .happy
        default: self = .ecstatic
        }
    }

    var lines: [String] {
        switch self {
        case .thirsty: ["I'm a little dry…", "A sip would be lovely", "Psst… water?"]
        case .okay: ["Off to a good start!", "Keep the sips coming", "Feeling fresher!"]
        case .happy: ["Ahh, so refreshing!", "You're glowing today", "Almost there!"]
        case .ecstatic: ["Goal smashed!", "I'm overflowing with joy!", "Best. Day. Ever."]
        }
    }

    /// A stable line for the given day so the bubble doesn't flicker.
    func line(for date: Date = .now) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return lines[day % lines.count]
    }
}

/// What Dewy is standing on: a colored scene, a colored tile, or a light card.
enum MascotBackdrop {
    case color, tile, light
}

/// One colored layer of liquid inside Dewy. Each drink you log stacks a new layer.
struct LiquidBand: Hashable {
    var color: Color
    /// Where this layer ends, as a cumulative fraction of the daily goal.
    var upTo: Double
}

// MARK: - Tilt

/// Where the liquid inside Dewy leans. The app's motion manager writes to it from CoreMotion
/// (a spring follows the phone's roll, so the water sloshes and settles); Dewy reads it every
/// frame. It is a plain reference so 60 Hz updates never invalidate the view tree.
final class SloshSource {
    /// Tilt of the liquid surface in radians (positive leans right).
    var angle: Double = 0
    /// 0…1 extra choppiness after a shake.
    var energy: Double = 0
    init() {}
}

private struct SloshKey: EnvironmentKey {
    static let defaultValue: SloshSource? = nil
}

extension EnvironmentValues {
    var dewySlosh: SloshSource? {
        get { self[SloshKey.self] }
        set { self[SloshKey.self] = newValue }
    }
}

// MARK: - Geometry

/// Dewy is drawn in a 200×220 design box. The canvas adds a 10-point margin around it
/// for the arms, outfits and shadow. Outfit placements use the same design units.
enum DewyGeometry {
    /// Width and height of the canvas in design units.
    static let canvas = CGSize(width: 220, height: 250)
    /// Bottom and top of the body, where the liquid goes from empty to full.
    static let bodyBottom: CGFloat = 216
    static let bodyTop: CGFloat = 14

    /// Organic storybook water-spirit droplet with a graceful calligraphic crown curl.
    static func body(_ p: (CGFloat, CGFloat) -> CGPoint) -> Path {
        var path = Path()
        path.move(to: p(86, 39))
        path.addCurve(to: p(122, 6), control1: p(90, 18), control2: p(105, 4))
        path.addCurve(to: p(113, 39), control1: p(116, 14), control2: p(110, 25))
        path.addCurve(to: p(169, 110), control1: p(129, 62), control2: p(160, 81))
        path.addCurve(to: p(161, 195), control1: p(181, 140), control2: p(179, 175))
        path.addCurve(to: p(100, 218), control1: p(145, 212), control2: p(124, 218))
        path.addCurve(to: p(39, 195), control1: p(76, 218), control2: p(55, 212))
        path.addCurve(to: p(31, 110), control1: p(21, 175), control2: p(19, 140))
        path.addCurve(to: p(86, 39), control1: p(40, 81), control2: p(70, 62))
        path.closeSubpath()
        return path
    }

    /// Rounded crown variant used when wearing solid hats so Dewy's curl tucks cleanly inside the hat.
    static func tuckedBody(_ p: (CGFloat, CGFloat) -> CGPoint) -> Path {
        var path = Path()
        path.move(to: p(100, 46))
        path.addCurve(to: p(169, 110), control1: p(124, 46), control2: p(155, 74))
        path.addCurve(to: p(161, 195), control1: p(181, 140), control2: p(179, 175))
        path.addCurve(to: p(100, 218), control1: p(145, 212), control2: p(124, 218))
        path.addCurve(to: p(39, 195), control1: p(76, 218), control2: p(55, 212))
        path.addCurve(to: p(31, 110), control1: p(21, 175), control2: p(19, 140))
        path.addCurve(to: p(100, 46), control1: p(45, 74), control2: p(76, 46))
        path.closeSubpath()
        return path
    }
}

/// Dewy's silhouette, stretched to fill a rect. Handy for progress glyphs and clipping.
struct DewyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX: CGFloat = rect.width / 156
        let scaleY: CGFloat = rect.height / 214
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + (x - 22) * scaleX, y: rect.minY + (y - 4) * scaleY)
        }
        return DewyGeometry.body(point)
    }
}

/// Dewy's body inside the full mascot canvas (with its 10-unit margin).
private struct DewyCanvasShape: Shape {
    var tucksCrown = false

    func path(in rect: CGRect) -> Path {
        let u = rect.width / DewyGeometry.canvas.width
        let map: (CGFloat, CGFloat) -> CGPoint = { x, y in
            CGPoint(x: rect.minX + (x + 10) * u, y: rect.minY + (y + 10) * u)
        }
        return tucksCrown ? DewyGeometry.tuckedBody(map) : DewyGeometry.body(map)
    }
}

// MARK: - Storybook Palette

private enum Storybook {
    /// Warm botanical plum-charcoal ink used for hand-drawn contours and eyes.
    static let ink = Color(hex: 0x251E2B)
    static let inkSoft = Color(hex: 0x453752)

    // Day translucent porcelain-glass vessel
    static let core = Color(hex: 0xF1FDFB)
    static let mid = Color(hex: 0xBCECEB)
    static let edge = Color(hex: 0x76CCD9)
    static let deep = Color(hex: 0x3D99B2)
    static let warmBounce = Color(hex: 0xFFF3D9)
    static let limbTop = Color(hex: 0xD4F6F4)
    static let limbBottom = Color(hex: 0x82D2DE)

    // Night moonlit porcelain-glass vessel
    static let nightCore = Color(hex: 0xE2ECFF)
    static let nightMid = Color(hex: 0xA6C7F0)
    static let nightEdge = Color(hex: 0x628AC9)
    static let nightDeep = Color(hex: 0x34528A)
    static let nightBounce = Color(hex: 0xEDE5FF)
    static let nightLimbTop = Color(hex: 0xBED5FA)
    static let nightLimbBottom = Color(hex: 0x7195D1)
}

// MARK: - Mascot

private struct Squish {
    var x: CGFloat = 1
    var y: CGFloat = 1
    var lift: CGFloat = 0
}

/// Dewy — a handcrafted storybook porcelain-glass water spirit that fills with gouache drink layers.
///
/// Built in layers so only what moves is redrawn each frame: the porcelain shell is composed of
/// crisp vector highlights and warm ink contours, while the liquid, limbs, face, and 2-layer
/// rigged outfits animate smoothly at 60 Hz.
struct MascotView: View {
    var progress: Double
    var mood: DewyMood
    /// Width of the whole figure in points.
    var size: CGFloat = 220
    var bounceTrigger: Int = 0
    /// Fires a blissful sip-gulp delight face and an internal burst of effervescent fizz bubbles.
    var sipTrigger: Int = 0
    /// Wardrobe items to wear.
    var outfits: [Outfit] = []
    /// Little twinkles around Dewy (always on when the goal is met).
    var sparkles = false
    /// Layers to stack, oldest first. Empty means a single layer of `liquid`.
    var bands: [LiquidBand] = []
    var liquid: Color?
    var backdrop: MascotBackdrop = .color
    /// Set to `false` for small decorative mascots to save rendering work.
    var animated = true
    var showsShadow = true
    /// Softly shifts Dewy's porcelain reflection toward moonlit indigo at night.
    var isNight: Bool = false

    @Environment(\.dewyTheme) private var theme
    @Environment(\.dewySlosh) private var slosh
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var level: Double = 0
    @State private var waveStart: Date?
    @State private var sipStart: Date?

    private var height: CGFloat { size * DewyGeometry.canvas.height / DewyGeometry.canvas.width }

    /// Overflowing days squeeze every layer into a full droplet.
    private var overflowScale: Double { max(progress, 1) }

    private func visualLevel(_ fraction: Double) -> Double {
        0.06 + 0.84 * min(max(fraction / overflowScale, 0), 1)
    }

    private var targetLevel: Double { visualLevel(progress) }

    private var resolvedBands: [LiquidBand] {
        guard !bands.isEmpty else {
            return [LiquidBand(color: liquid ?? theme.water, upTo: targetLevel)]
        }
        return bands.map { LiquidBand(color: $0.color, upTo: visualLevel($0.upTo)) }
    }

    private var isLive: Bool { animated && !reduceMotion && !LaunchOptions.freezesMotion }

    var body: some View {
        Group {
            if animated {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isLive)) { timeline in
                    let now = timeline.date
                    let t = isLive ? now.timeIntervalSinceReferenceDate : 0.6
                    let wave = isLive ? waveAmount(at: now) : 0
                    let gulp = isLive ? gulpAmount(at: now) : 0
                    let sipP = isLive ? sipProgress(at: now) : 0
                    figure(time: t, wave: wave, gulp: gulp, sipProgress: sipP)
                }
            } else {
                // Decorative and widget mascots are a single still frame: no timeline at all.
                figure(time: 0.6, wave: 0, gulp: 0, sipProgress: 0)
            }
        }
        .frame(width: size, height: height)
        .modifier(SquishEffect(trigger: bounceTrigger, size: size, enabled: animated))
        .onAppear {
            withAnimation(.spring(duration: 1.4, bounce: 0.3).delay(0.15)) {
                level = targetLevel
            }
        }
        .onChange(of: progress) {
            withAnimation(.spring(duration: 1.1, bounce: 0.35)) {
                level = targetLevel
            }
        }
        .onChange(of: bounceTrigger) {
            waveStart = .now
        }
        .onChange(of: sipTrigger) {
            sipStart = .now
        }
        .accessibilityElement()
        .accessibilityLabel("Dewy is \(mood.rawValue), \(Int(progress * 100)) percent of today's goal")
    }

    private func figure(time t: Double, wave: Double, gulp: Double, sipProgress: Double) -> some View {
        let u = size / DewyGeometry.canvas.width
        let tilt = isLive ? (slosh?.angle ?? 0) : 0
        let chop = isLive ? (slosh?.energy ?? 0) : 0
        let twinkles = sparkles || mood == .ecstatic
        let tucksCrown = outfits.contains(where: \.coversCrown)
        let shadowTone = isNight ? Color(hex: 0x16193B) : Color(hex: 0x2F5F73)
        let shadowAlpha: Double = backdrop == .light ? 0.13 : (isNight ? 0.28 : 0.20)

        return ZStack(alignment: .topLeading) {
            if showsShadow {
                Ellipse()
                    .fill(shadowTone.opacity(shadowAlpha))
                    .frame(width: (116 - CGFloat(sin(t * 2.2)) * 4) * u, height: 15 * u)
                    .blur(radius: 4.2 * u)
                    .position(x: 110 * u, y: 236 * u)
            }

            // Back layer of rigged outfits (wraps & brims behind Dewy's silhouette).
            if !outfits.isEmpty {
                MascotOutfitLayer(outfits: outfits, layer: .back, time: t, tilt: tilt, wave: wave)
            }

            MascotLimbs(time: t, wave: wave, onLight: backdrop == .light, isNight: isNight)

            PorcelainBack(u: u, isNight: isNight, tucksCrown: tucksCrown)

            MascotLiquid(
                level: animated ? level : targetLevel,
                bands: resolvedBands,
                time: t,
                tilt: tilt,
                chop: chop + wave * 0.6 + gulp * 0.52,
                gulp: gulp,
                sipProgress: sipProgress,
                isNight: isNight
            )
            .clipShape(DewyCanvasShape(tucksCrown: tucksCrown))

            PorcelainFront(u: u, onLight: backdrop == .light, isNight: isNight, tucksCrown: tucksCrown)

            MascotFace(
                mood: mood,
                time: t,
                blinks: isLive && (!LaunchOptions.isDemo || LaunchOptions.screenshot == "celebrate"),
                hidesEyes: outfits.contains(.sunglasses),
                gulp: gulp,
                sipProgress: sipProgress,
                isNight: isNight
            )

            // Front layer of rigged outfits (crowns, lenses, knit scarf folds, bows).
            if !outfits.isEmpty {
                MascotOutfitLayer(outfits: outfits, layer: .front, time: t, tilt: tilt, wave: wave)
            }

            if twinkles {
                MascotSparkles(time: t, isNight: isNight)
            }
        }
        .frame(width: size, height: height, alignment: .topLeading)
        .scaleEffect(x: breath(t, by: -0.01), y: breath(t, by: 0.015), anchor: .bottom)
    }

    /// Dewy's slow breathing, as a scale factor around 1.
    private func breath(_ t: Double, by amount: Double) -> CGFloat {
        CGFloat(1 + sin(t * 2.2) * amount)
    }

    /// 0…1 envelope of the little wave Dewy does after being tapped.
    private func waveAmount(at now: Date) -> Double {
        guard let waveStart else { return 0 }
        let elapsed = now.timeIntervalSince(waveStart)
        guard elapsed >= 0, elapsed < 1.6 else { return 0 }
        let rise = min(elapsed / 0.18, 1)
        let fall = min(max((1.6 - elapsed) / 0.35, 0), 1)
        return rise * fall
    }

    /// 0…1 blissful 0.85s sip-gulp envelope (0.14s rise, 0.42s radiant hold, 0.29s ease-back).
    private func gulpAmount(at now: Date) -> Double {
        guard let sipStart else { return 0 }
        let elapsed = now.timeIntervalSince(sipStart)
        guard elapsed >= 0, elapsed < 0.85 else { return 0 }
        if elapsed < 0.14 {
            return sin((elapsed / 0.14) * (.pi / 2))
        }
        if elapsed < 0.56 {
            return 1.0
        }
        let tail = (elapsed - 0.56) / 0.29
        return 0.5 * (1.0 + cos(tail * .pi))
    }

    /// 0…1 normalized elapsed progress across the 0.85s sip window for fizz rise & mouth morph.
    private func sipProgress(at now: Date) -> Double {
        guard let sipStart else { return 0 }
        let elapsed = now.timeIntervalSince(sipStart)
        guard elapsed >= 0, elapsed < 0.85 else { return 0 }
        return elapsed / 0.85
    }
}

/// The squash-and-stretch hop Dewy does when you drink or poke it.
private struct SquishEffect: ViewModifier {
    var trigger: Int
    var size: CGFloat
    var enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content.keyframeAnimator(initialValue: Squish(), trigger: trigger) { view, value in
                view
                    .scaleEffect(x: value.x, y: value.y, anchor: .bottom)
                    .offset(y: value.lift)
            } keyframes: { _ in
                KeyframeTrack(\.x) {
                    CubicKeyframe(1.13, duration: 0.12)
                    SpringKeyframe(0.94, duration: 0.2)
                    SpringKeyframe(1.0, duration: 0.55, spring: .bouncy)
                }
                KeyframeTrack(\.y) {
                    CubicKeyframe(0.87, duration: 0.12)
                    SpringKeyframe(1.08, duration: 0.2)
                    SpringKeyframe(1.0, duration: 0.55, spring: .bouncy)
                }
                KeyframeTrack(\.lift) {
                    CubicKeyframe(0, duration: 0.12)
                    SpringKeyframe(-size * 0.09, duration: 0.2)
                    SpringKeyframe(0, duration: 0.55, spring: .bouncy)
                }
            }
        } else {
            content
        }
    }
}

// MARK: - Porcelain-Glass Material

/// Translucent porcelain-glass body behind the liquid: soft sunlit celadon-ivory wash.
private struct PorcelainBack: View {
    var u: CGFloat
    var isNight: Bool
    var tucksCrown: Bool = false

    var body: some View {
        let core = isNight ? Storybook.nightCore : Storybook.core
        let mid = isNight ? Storybook.nightMid : Storybook.mid
        let edge = isNight ? Storybook.nightEdge : Storybook.edge

        DewyCanvasShape(tucksCrown: tucksCrown)
            .fill(RadialGradient(
                stops: [
                    .init(color: core, location: 0),
                    .init(color: mid, location: 0.56),
                    .init(color: edge, location: 1)
                ],
                center: UnitPoint(x: 0.38, y: 0.38),
                startRadius: 0,
                endRadius: 124 * u
            ))
            .opacity(0.95)
    }
}

/// Optical glass-rim shading, warm under-belly bounce light, gouache highlight crescents,
/// and Dewy's delicate hand-inked plum-charcoal contour.
private struct PorcelainFront: View {
    var u: CGFloat
    var onLight: Bool
    var isNight: Bool
    var tucksCrown: Bool = false

    var body: some View {
        let rimTone = isNight ? Storybook.nightDeep : Storybook.deep
        let bounceTone = isNight ? Storybook.nightBounce : Storybook.warmBounce
        let inkAlpha: Double = onLight ? 0.62 : (isNight ? 0.48 : 0.44)
        let shape = DewyCanvasShape(tucksCrown: tucksCrown)

        ZStack(alignment: .topLeading) {
            // Soft inner watercolor vessel depth along the lower/outer wall.
            shape
                .stroke(rimTone.opacity(isNight ? 0.48 : 0.42), lineWidth: 13 * u)
                .blur(radius: 6.5 * u)
                .clipShape(shape)

            // Warm sunlit bounce light scattering out through Dewy's belly.
            Ellipse()
                .fill(bounceTone.opacity(isNight ? 0.34 : 0.48))
                .frame(width: 96 * u, height: 28 * u)
                .blur(radius: 9 * u)
                .position(x: 110 * u, y: 212 * u)
                .clipShape(shape)

            // Painterly gouache sheen on the upper-left cheek.
            Ellipse()
                .fill(Color.white.opacity(isNight ? 0.42 : 0.54))
                .frame(width: 30 * u, height: 58 * u)
                .rotationEffect(.degrees(27))
                .blur(radius: 5.5 * u)
                .position(x: 66 * u, y: 104 * u)
                .clipShape(shape)

            // Crisp hand-painted porcelain glints and optical glass rim caustics.
            Canvas { context, size in
                let s = size.width / DewyGeometry.canvas.width
                func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                    CGPoint(x: (x + 10) * s, y: (y + 10) * s)
                }
                let glintColor = isNight ? Color(hex: 0xF0F4FF) : Color(hex: 0xFFFEFA)

                // Primary curved gouache crescent highlight.
                var gloss = Path()
                gloss.move(to: p(49, 119))
                gloss.addCurve(to: p(84, 62), control1: p(51, 97), control2: p(65, 76))
                context.stroke(
                    gloss,
                    with: .color(glintColor.opacity(0.9)),
                    style: StrokeStyle(lineWidth: 6.2 * s, lineCap: .round)
                )

                // Companion pearl dot below the highlight.
                let dotOrigin = p(42, 131)
                context.fill(
                    Path(ellipseIn: CGRect(x: dotOrigin.x, y: dotOrigin.y, width: 6.5 * s, height: 6.5 * s)),
                    with: .color(glintColor.opacity(0.88))
                )

                // Delicate glint tracing the crown curl (hidden when tucked beneath a solid hat).
                if !tucksCrown {
                    var curl = Path()
                    curl.move(to: p(98, 28))
                    curl.addQuadCurve(to: p(115, 13), control: p(103, 17))
                    context.stroke(
                        curl,
                        with: .color(glintColor.opacity(0.84)),
                        style: StrokeStyle(lineWidth: 3.2 * s, lineCap: .round)
                    )
                }

                // Optical caustic rim light on the opposite flank.
                var rim = Path()
                rim.move(to: p(157, 102))
                rim.addCurve(to: p(156, 182), control1: p(173, 128), control2: p(172, 162))
                context.stroke(
                    rim,
                    with: .color(glintColor.opacity(isNight ? 0.45 : 0.56)),
                    style: StrokeStyle(lineWidth: 2.8 * s, lineCap: .round)
                )
            }

            // Delicate warm hand-inked botanical plum-charcoal contour.
            shape
                .stroke(
                    Storybook.ink.opacity(inkAlpha),
                    style: StrokeStyle(lineWidth: 2.1 * u, lineCap: .round, lineJoin: .round)
                )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Limbs

/// Expressive storybook porcelain feet and arms with soft warm ink contours.
private struct MascotLimbs: View {
    var time: Double
    var wave: Double
    var onLight: Bool
    var isNight: Bool

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: (x + 10) * u, y: (y + 10) * u)
            }
            let top = isNight ? Storybook.nightLimbTop : Storybook.limbTop
            let bottom = isNight ? Storybook.nightLimbBottom : Storybook.limbBottom
            let fill = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [top, bottom]),
                startPoint: p(0, 118),
                endPoint: p(0, 232)
            )
            let inkAlpha: Double = onLight ? 0.56 : 0.44
            let inkStroke = StrokeStyle(lineWidth: 1.9 * u, lineCap: .round, lineJoin: .round)

            // Little grounded feet with tiny gouache glints.
            let footOffset: CGFloat = CGFloat(sin(time * 2.2) * 0.6)
            for (idx, x) in [CGFloat(76), 124].enumerated() {
                let sign: CGFloat = idx == 0 ? -1 : 1
                let origin = p(x - 17, 204 + footOffset)
                let foot = Path(ellipseIn: CGRect(x: origin.x, y: origin.y, width: 34 * u, height: 19 * u))
                context.fill(foot, with: fill)
                context.stroke(foot, with: .color(Storybook.ink.opacity(inkAlpha)), style: inkStroke)
                let glint = p(x - 8 + sign * 2, 208 + footOffset)
                context.fill(
                    Path(ellipseIn: CGRect(x: glint.x, y: glint.y, width: 9 * u, height: 4.5 * u)),
                    with: .color(.white.opacity(0.68))
                )
            }

            // Expressive arms — right arm lifts into a lively wave on tap/sip.
            let sway: Double = sin(time * 1.65) * 0.065
            let deg: Double = .pi / 180

            let leftArm = armPath(center: p(29, 150), radians: 28 * deg + sway, u: u)
            context.fill(leftArm, with: fill)
            context.stroke(leftArm, with: .color(Storybook.ink.opacity(inkAlpha)), style: inkStroke)

            let w = CGFloat(wave)
            let rest = p(171, 150)
            let raised = p(181, 112)
            let rightCenter = CGPoint(x: rest.x + (raised.x - rest.x) * w, y: rest.y + (raised.y - rest.y) * w)
            let flap: Double = 58 + sin(time * 16) * 15
            let rightArm = armPath(center: rightCenter, radians: (flap * wave - 28) * deg - sway, u: u)
            context.fill(rightArm, with: fill)
            context.stroke(rightArm, with: .color(Storybook.ink.opacity(inkAlpha)), style: inkStroke)
        }
        .allowsHitTesting(false)
    }

    private func armPath(center: CGPoint, radians: Double, u: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: -11.5 * u, y: -16.5 * u, width: 23 * u, height: 33 * u))
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .applying(CGAffineTransform(translationX: center.x, y: center.y))
    }
}

// MARK: - Liquid

/// Hand-painted watercolor/gouache drink bands with wavy meniscus shimmer, optical caustics,
/// and rising botanical bubbles. Animatable on `level` for smooth spring pours.
private struct MascotLiquid: View, Animatable {
    var level: Double
    var bands: [LiquidBand]
    var time: Double
    var tilt: Double
    var chop: Double
    var gulp: Double
    var sipProgress: Double
    var isNight: Bool

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: (x + 10) * u, y: (y + 10) * u)
            }
            drawLiquid(in: &context, p: p, u: u)
            drawCaustics(in: &context, p: p, u: u)
            drawBubbles(in: &context, p: p, u: u)
            if gulp > 0.02 {
                drawSipFizz(in: &context, p: p, u: u)
            }
        }
        .allowsHitTesting(false)
    }

    private var slope: CGFloat { CGFloat(max(min(tan(tilt), 0.7), -0.7)) }

    private func surfaceY(level: Double, x: CGFloat, amplitude: CGFloat, phase: Double, leans: Bool) -> CGFloat {
        let base = DewyGeometry.bodyBottom - CGFloat(level) * (DewyGeometry.bodyBottom - DewyGeometry.bodyTop)
        let lean = leans ? (x - 100) * slope : 0
        let primary = sin(Double(x / 200) * .pi * 2.3 + phase)
        let secondary = 0.25 * sin(Double(x / 200) * .pi * 4.6 - phase * 0.7)
        return base + lean + amplitude * CGFloat(primary + secondary)
    }

    private func wavePath(
        level: Double,
        amplitude: CGFloat,
        phase: Double,
        leans: Bool,
        p: (CGFloat, CGFloat) -> CGPoint,
        closed: Bool
    ) -> Path {
        var path = Path()
        var x: CGFloat = -10
        var first = true
        if closed {
            path.move(to: p(-10, 240))
            first = false
        }
        while x <= 210 {
            let y = surfaceY(level: level, x: x, amplitude: amplitude, phase: phase, leans: leans)
            if first {
                path.move(to: p(x, y))
                first = false
            } else {
                path.addLine(to: p(x, y))
            }
            x += 5
        }
        if closed {
            path.addLine(to: p(210, 240))
            path.closeSubpath()
        }
        return path
    }

    private func drawLiquid(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        guard !bands.isEmpty else { return }
        let surface = bands.firstIndex { $0.upTo >= level - 0.0005 } ?? (bands.count - 1)
        let amp = CGFloat(4.2 + chop * 6.8 + gulp * 2.4)
        let foamTint = isNight ? Color(hex: 0xE6EEFF) : Color(hex: 0xFFFBF2)

        // Translucent back meniscus adds painterly glass-vessel depth.
        context.fill(
            wavePath(level: level + 0.016, amplitude: amp * 0.85, phase: time * 1.6 + 2.3, leans: true, p: p, closed: true),
            with: .color(bands[surface].color.blended(with: foamTint, by: 0.48).opacity(0.74))
        )

        for index in stride(from: surface, through: 0, by: -1) {
            let isSurface = index == surface
            let top = isSurface ? level : bands[index].upTo
            guard top > 0.001 else { continue }
            let amplitude: CGFloat = isSurface ? amp : 2.2
            let phase = isSurface ? time * 2.15 + 0.4 : time * 0.55 + Double(index) * 1.85
            let rawColor = bands[index].color
            let pigment = isNight ? rawColor.blended(with: Color(hex: 0x39448A), by: 0.16) : rawColor
            let fillPath = wavePath(level: top, amplitude: amplitude, phase: phase, leans: isSurface, p: p, closed: true)
            let topY = surfaceY(level: top, x: 100, amplitude: 0, phase: 0, leans: false)

            // Rich per-drink watercolor depth: sunlit top wash, vibrant core, translucent deeper base.
            context.fill(fillPath, with: .linearGradient(
                Gradient(stops: [
                    .init(color: pigment.blended(with: foamTint, by: 0.28), location: 0),
                    .init(color: pigment, location: 0.42),
                    .init(color: pigment.blended(with: Storybook.ink, by: 0.14), location: 1)
                ]),
                startPoint: p(0, topY),
                endPoint: p(0, 222)
            ))

            // Subtle luminous sunlit refraction sheen glowing along the left porcelain wall.
            context.fill(fillPath, with: .linearGradient(
                Gradient(colors: [
                    pigment.blended(with: foamTint, by: 0.58).opacity(isNight ? 0.18 : 0.30),
                    Color.clear
                ]),
                startPoint: p(34, topY + 24),
                endPoint: p(88, topY + 24)
            ))

            // Hand-painted hue-tailored creamy meniscus foam ribbon along each layer's crest.
            let crestWidth: CGFloat = isSurface ? (5.8 + CGFloat(gulp) * 1.6) : 3.4
            context.stroke(
                wavePath(level: top - 0.011, amplitude: amplitude, phase: phase, leans: isSurface, p: p, closed: false),
                with: .color(pigment.blended(with: foamTint, by: 0.64).opacity(0.9)),
                style: StrokeStyle(lineWidth: crestWidth * u, lineCap: .round)
            )
            context.stroke(
                wavePath(level: top, amplitude: amplitude, phase: phase, leans: isSurface, p: p, closed: false),
                with: .color(foamTint.opacity(isSurface ? (0.86 + gulp * 0.10) : 0.52)),
                style: StrokeStyle(lineWidth: 1.8 * u, lineCap: .round)
            )
        }
    }

    /// Subtle undulating sunlit caustic threads drifting inside the liquid.
    private func drawCaustics(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        guard level > 0.18 else { return }
        let topY = DewyGeometry.bodyBottom - CGFloat(level) * (DewyGeometry.bodyBottom - DewyGeometry.bodyTop)
        let ribbonY = min(DewyGeometry.bodyBottom - 26, max(topY + 26, 178))
        guard ribbonY > topY + 12 else { return }

        let shift = CGFloat(sin(time * 1.4) * 7 + tilt * 14)
        var caustic1 = Path()
        caustic1.move(to: p(58 + shift, ribbonY))
        caustic1.addQuadCurve(to: p(114 + shift, ribbonY + 4), control: p(86 + shift, ribbonY - 7))
        context.stroke(
            caustic1,
            with: .color(.white.opacity(isNight ? 0.18 : 0.28)),
            style: StrokeStyle(lineWidth: 2.6 * u, lineCap: .round)
        )

        var caustic2 = Path()
        caustic2.move(to: p(94 - shift * 0.7, ribbonY + 15))
        caustic2.addQuadCurve(to: p(142 - shift * 0.7, ribbonY + 12), control: p(118 - shift * 0.7, ribbonY + 21))
        context.stroke(
            caustic2,
            with: .color(.white.opacity(isNight ? 0.14 : 0.22)),
            style: StrokeStyle(lineWidth: 2.0 * u, lineCap: .round)
        )
    }

    private func drawBubbles(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let surface = DewyGeometry.bodyBottom - CGFloat(level) * (DewyGeometry.bodyBottom - DewyGeometry.bodyTop)
        let column = Double(DewyGeometry.bodyBottom - surface)
        guard column > 16 else { return }
        for index in 0..<7 {
            let seed = Double(index)
            let x0 = 56 + 88 * fract(sin(seed * 12.9898) * 43758.5453)
            let radius = 1.9 + 2.3 * fract(sin(seed * 78.233) * 12543.21)
            let speed = 11 + 15 * fract(sin(seed * 39.425) * 9631.7)
            let travel = (time * speed + seed * 97).truncatingRemainder(dividingBy: column)
            let y = Double(DewyGeometry.bodyBottom) - travel
            guard y > Double(surface) + radius + 6 else { continue }
            let x = x0 + sin(time * 2.1 + seed) * 2.6
            let fade = min(1, (y - Double(surface)) / 22)
            let c = p(CGFloat(x), CGFloat(y))
            let r = CGFloat(radius) * u
            let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
            context.opacity = fade
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.32)))
            context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.86)), lineWidth: 0.95 * u)
            let glint = CGRect(x: c.x - r * 0.45, y: c.y - r * 0.48, width: r * 0.42, height: r * 0.42)
            context.fill(Path(ellipseIn: glint), with: .color(.white.opacity(0.9)))
            context.opacity = 1
        }
    }

    /// Lively celebratory burst of 12 rising pearlescent fizz bubbles triggered on every sip.
    private func drawSipFizz(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let surface = Double(DewyGeometry.bodyBottom - CGFloat(level) * (DewyGeometry.bodyBottom - DewyGeometry.bodyTop))
        let column = Double(DewyGeometry.bodyBottom) - surface
        guard column > 14 else { return }

        let pearl = isNight ? Color(hex: 0xEEF4FF) : Color(hex: 0xFFFDF8)
        for index in 0..<12 {
            let seed = Double(index) + 13.7
            let delay = 0.22 * fract(sin(seed * 41.31) * 18421.7)
            let localT = min(max((sipProgress - delay) / max(0.25, 1.0 - delay), 0), 1)
            guard localT > 0.01 && localT < 0.98 else { continue }

            let eased = 1.0 - pow(1.0 - localT, 1.7)
            let xBase = 48.0 + 104.0 * fract(sin(seed * 19.73) * 35123.4)
            let wobble = sin(localT * .pi * 3.0 + seed) * 3.8
            let startY = Double(DewyGeometry.bodyBottom) - 6.0 - 18.0 * fract(sin(seed * 63.17) * 9143.2)
            let travelDist = max(14.0, (startY - surface - 5.0) * (0.72 + 0.28 * fract(sin(seed * 27.9) * 14123.0)))
            let y = startY - eased * travelDist
            guard y > surface + 2.5 else { continue }

            let baseR = 1.6 + 2.5 * fract(sin(seed * 91.5) * 11213.9)
            let scale = 0.75 + 0.35 * sin(localT * .pi)
            let r = CGFloat(baseR * scale) * u
            let c = p(CGFloat(xBase + wobble), CGFloat(y))
            let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
            let alpha = gulp * sin(localT * .pi)

            context.opacity = min(1, alpha * 1.15)
            context.fill(Path(ellipseIn: rect), with: .color(pearl.opacity(0.42)))
            context.stroke(Path(ellipseIn: rect), with: .color(pearl.opacity(0.92)), lineWidth: 1.05 * u)
            let glint = CGRect(x: c.x - r * 0.44, y: c.y - r * 0.46, width: r * 0.44, height: r * 0.44)
            context.fill(Path(ellipseIn: glint), with: .color(.white.opacity(0.96)))
            context.opacity = 1
        }
    }

    private func fract(_ value: Double) -> Double { value - floor(value) }
}

// MARK: - Storybook Face (Zero Anime Sparkle-Eye Clichés)

/// Soulful hand-inked storybook face with natural blinking, expressive eyebrows/eyelids per mood,
/// chalky gouache cheek washes, and warm organic catchlights.
private struct MascotFace: View {
    var mood: DewyMood
    var time: Double
    var blinks: Bool
    var hidesEyes: Bool
    var gulp: Double
    var sipProgress: Double
    var isNight: Bool

    private var isSipping: Bool { gulp > 0.18 }

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: (x + 10) * u, y: (y + 10) * u)
            }
            func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
                Path(ellipseIn: CGRect(
                    x: (cx - rx + 10) * u,
                    y: (cy - ry + 10) * u,
                    width: rx * 2 * u,
                    height: ry * 2 * u
                ))
            }

            drawBlush(in: &context, p: p, oval: oval, u: u)

            let openness = blinkOpenness(at: time)
            if !hidesEyes {
                drawEyes(in: &context, p: p, oval: oval, u: u, openness: openness)
            }
            drawBrowsAndExtras(in: &context, p: p, u: u)
            drawMouth(in: &context, p: p, oval: oval, u: u)
        }
        .allowsHitTesting(false)
    }

    /// Smooth natural cosine blink cycle (~every 4.5s).
    private func blinkOpenness(at t: Double) -> CGFloat {
        guard blinks else { return 1 }
        let cycle = t.truncatingRemainder(dividingBy: 4.5)
        guard cycle < 0.18 else { return 1 }
        let phase = cycle / 0.18
        let shut = sin(phase * .pi)
        return max(0.05, CGFloat(1 - shut))
    }

    private func drawBlush(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        oval: (CGFloat, CGFloat, CGFloat, CGFloat) -> Path,
        u: CGFloat
    ) {
        let bloom = CGFloat(gulp)
        let blushOuter = (mood == .ecstatic || isSipping) ? Color(hex: 0xF57D96) : Color(hex: 0xF797A7)
        let baseAlpha: Double = mood == .thirsty ? 0.36 : (mood == .ecstatic ? 0.64 : 0.52)
        let blushAlpha = min(0.74, baseAlpha + gulp * 0.24)
        let rx: CGFloat = 14.5 + bloom * 3.0
        let ry: CGFloat = 8.8 + bloom * 1.9

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 3.4 * u))
            layer.fill(oval(54, 154, rx, ry), with: .color(blushOuter.opacity(blushAlpha)))
            layer.fill(oval(146, 154, rx, ry), with: .color(blushOuter.opacity(blushAlpha)))
        }

        // Delicate picture-book blush chalk hatches on joyful moods or blissful sip-gulp.
        if mood == .happy || mood == .ecstatic || isSipping {
            let stroke = StrokeStyle(lineWidth: 1.6 * u, lineCap: .round)
            let alpha = isSipping ? max(0.46, gulp * 0.56) : (mood == .ecstatic ? 0.52 : 0.34)
            let tint = Color(hex: 0xD95B7A).opacity(alpha)
            for cx in [CGFloat(53), 147] {
                for dx in [CGFloat(-4), 2] {
                    var tick = Path()
                    tick.move(to: p(cx + dx, 156))
                    tick.addLine(to: p(cx + dx + 3.2, 151.5))
                    context.stroke(tick, with: .color(tint), style: stroke)
                }
            }
        }
    }

    private func drawEyes(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        oval: (CGFloat, CGFloat, CGFloat, CGFloat) -> Path,
        u: CGFloat,
        openness: CGFloat
    ) {
        let ey: CGFloat = 133
        let xs: [CGFloat] = [75, 125]

        // Radiant blissful closed-arc eyes while savoring a sip, overriding even thirsty/okay!
        if isSipping {
            for (index, ex) in xs.enumerated() {
                drawBlissSipEye(in: &context, cx: ex, cy: ey + 1.5, isLeft: index == 0, p: p, u: u)
            }
            return
        }

        for (index, ex) in xs.enumerated() {
            let isLeft = index == 0
            switch mood {
            case .ecstatic:
                drawLaughArcEye(in: &context, cx: ex, cy: ey + 1, p: p, u: u)
            case .thirsty:
                if openness < 0.22 {
                    drawClosedBlinkEye(in: &context, cx: ex, cy: ey + 4, p: p, u: u)
                } else {
                    drawStorybookEye(
                        in: &context,
                        cx: ex,
                        cy: ey + 3,
                        rx: 9.2,
                        ry: 10.2 * openness,
                        isLeft: isLeft,
                        droopyLid: true,
                        cheekLift: false,
                        p: p,
                        oval: oval,
                        u: u
                    )
                }
            case .okay:
                if openness < 0.22 {
                    drawClosedBlinkEye(in: &context, cx: ex, cy: ey + 2, p: p, u: u)
                } else {
                    drawStorybookEye(
                        in: &context,
                        cx: ex,
                        cy: ey,
                        rx: 9.6,
                        ry: 11.4 * openness,
                        isLeft: isLeft,
                        droopyLid: false,
                        cheekLift: false,
                        p: p,
                        oval: oval,
                        u: u
                    )
                }
            case .happy:
                if openness < 0.22 {
                    drawClosedBlinkEye(in: &context, cx: ex, cy: ey + 1, p: p, u: u)
                } else {
                    drawStorybookEye(
                        in: &context,
                        cx: ex,
                        cy: ey - 0.5,
                        rx: 10.4,
                        ry: 12.2 * openness,
                        isLeft: isLeft,
                        droopyLid: false,
                        cheekLift: true,
                        p: p,
                        oval: oval,
                        u: u
                    )
                }
            }
        }
    }

    /// Warm happy curved closed-arc eyes with subtle upturned lash flourish during sip-gulp delight.
    private func drawBlissSipEye(
        in context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        isLeft: Bool,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        var arc = Path()
        arc.move(to: p(cx - 11.2, cy + 3.2))
        arc.addCurve(
            to: p(cx + 11.2, cy + 3.2),
            control1: p(cx - 6.0, cy - 8.2),
            control2: p(cx + 6.0, cy - 8.2)
        )
        context.stroke(arc, with: .color(Storybook.ink), style: StrokeStyle(lineWidth: 4.2 * u, lineCap: .round))

        // Tiny warm outer smile crease curl for extra storybook expression.
        let sign: CGFloat = isLeft ? -1 : 1
        var lash = Path()
        lash.move(to: p(cx + sign * 10.2, cy + 2.6))
        lash.addLine(to: p(cx + sign * 13.4, cy + 0.6))
        context.stroke(lash, with: .color(Storybook.ink.opacity(0.75)), style: StrokeStyle(lineWidth: 2.2 * u, lineCap: .round))
    }

    private func drawStorybookEye(
        in context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        rx: CGFloat,
        ry: CGFloat,
        isLeft: Bool,
        droopyLid: Bool,
        cheekLift: Bool,
        p: (CGFloat, CGFloat) -> CGPoint,
        oval: (CGFloat, CGFloat, CGFloat, CGFloat) -> Path,
        u: CGFloat
    ) {
        let eye = oval(cx, cy, rx, ry)
        context.fill(eye, with: .linearGradient(
            Gradient(colors: [Storybook.ink, Storybook.inkSoft]),
            startPoint: p(cx, cy - ry),
            endPoint: p(cx, cy + ry)
        ))

        if ry > rx * 0.45 {
            // Subtle warm plum undertone inside the lower iris (soft gouache depth).
            context.drawLayer { layer in
                layer.clip(to: eye)
                layer.fill(
                    oval(cx + 0.5, cy + ry * 0.72, rx * 0.78, ry * 0.36),
                    with: .color(Color(hex: 0x6F5C82).opacity(0.45))
                )
            }

            // Single delicate hand-painted organic catchlight (NO anime sparkle shapes).
            let catchX = cx - rx * 0.28
            let catchY = cy - ry * 0.32
            let catchR = droopyLid ? rx * 0.24 : rx * 0.31
            context.fill(
                oval(catchX, catchY, catchR, catchR * 0.92),
                with: .color(Color(hex: 0xFFFDF8).opacity(droopyLid ? 0.82 : 0.94))
            )
        }

        // Gentle drooping porcelain eyelid on .thirsty mood.
        if droopyLid && ry > 4 {
            let lidColor = isNight ? Storybook.nightMid : Storybook.mid
            let lidY = cy - ry * 0.36
            context.drawLayer { layer in
                layer.clip(to: eye)
                var lid = Path()
                lid.move(to: p(cx - rx - 2, cy - ry - 4))
                lid.addLine(to: p(cx + rx + 2, cy - ry - 4))
                let outerY = isLeft ? lidY + 2.4 : lidY - 1.2
                let innerY = isLeft ? lidY - 1.2 : lidY + 2.4
                lid.addLine(to: p(cx + rx + 2, innerY))
                lid.addQuadCurve(to: p(cx - rx - 2, outerY), control: p(cx, lidY + 0.8))
                lid.closeSubpath()
                layer.fill(lid, with: .color(lidColor.opacity(0.95)))
            }
            var lash = Path()
            let leftY = isLeft ? lidY + 2.4 : lidY - 1.2
            let rightY = isLeft ? lidY - 1.2 : lidY + 2.4
            lash.move(to: p(cx - rx - 0.8, leftY))
            lash.addQuadCurve(to: p(cx + rx + 0.8, rightY), control: p(cx, lidY + 0.6))
            context.stroke(lash, with: .color(Storybook.ink), style: StrokeStyle(lineWidth: 2.3 * u, lineCap: .round))
        }

        // Subtle joyful cheek curve softening the lower lash on .happy.
        if cheekLift && ry > 5 {
            var smileLash = Path()
            smileLash.move(to: p(cx - rx * 0.72, cy + ry * 0.85))
            smileLash.addQuadCurve(to: p(cx + rx * 0.72, cy + ry * 0.85), control: p(cx, cy + ry * 0.56))
            context.stroke(
                smileLash,
                with: .color(Storybook.ink.opacity(0.28)),
                style: StrokeStyle(lineWidth: 1.4 * u, lineCap: .round)
            )
        }
    }

    private func drawClosedBlinkEye(
        in context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        var arc = Path()
        arc.move(to: p(cx - 9.5, cy))
        arc.addQuadCurve(to: p(cx + 9.5, cy), control: p(cx, cy + 4.5))
        context.stroke(arc, with: .color(Storybook.ink), style: StrokeStyle(lineWidth: 3.4 * u, lineCap: .round))
    }

    private func drawLaughArcEye(
        in context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        var arc = Path()
        arc.move(to: p(cx - 11.5, cy + 4))
        arc.addCurve(
            to: p(cx + 11.5, cy + 4),
            control1: p(cx - 6.5, cy - 10),
            control2: p(cx + 6.5, cy - 10)
        )
        context.stroke(arc, with: .color(Storybook.ink), style: StrokeStyle(lineWidth: 4.8 * u, lineCap: .round))
    }

    private func drawBrowsAndExtras(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        let browStyle = StrokeStyle(lineWidth: 2.8 * u, lineCap: .round)
        let browColor = Storybook.ink.opacity(0.76)

        if isSipping {
            // Relaxed joyful raised eyebrows during sip-gulp (clears thirsty worry drop).
            for (outer, inner) in [(CGFloat(63), CGFloat(82)), (137, 118)] {
                var brow = Path()
                brow.move(to: p(outer, 111.5))
                brow.addQuadCurve(to: p(inner, 109.5), control: p((outer + inner) * 0.5, 105.5))
                context.stroke(brow, with: .color(Storybook.ink.opacity(0.62)), style: StrokeStyle(lineWidth: 2.4 * u, lineCap: .round))
            }
            return
        }

        switch mood {
        case .thirsty:
            for (outer, inner) in [(CGFloat(62), CGFloat(82)), (138, 118)] {
                var brow = Path()
                brow.move(to: p(outer, 117))
                brow.addQuadCurve(to: p(inner, 112), control: p((outer + inner) * 0.5, 115.5))
                context.stroke(brow, with: .color(browColor), style: browStyle)
            }
            // Tiny hand-inked longing dewdrop near temple.
            let dropOrigin = p(150, 96)
            let drop = DewyShape().path(in: CGRect(x: dropOrigin.x, y: dropOrigin.y, width: 10.5 * u, height: 14.5 * u))
            context.fill(drop, with: .color(Color(hex: 0xA8E5F5)))
            context.stroke(drop, with: .color(Storybook.ink.opacity(0.55)), lineWidth: 1.2 * u)
            let spec = p(153, 103)
            context.fill(
                Path(ellipseIn: CGRect(x: spec.x, y: spec.y, width: 2.8 * u, height: 3.6 * u)),
                with: .color(.white.opacity(0.92))
            )

        case .okay:
            for (outer, inner) in [(CGFloat(65), CGFloat(82)), (135, 118)] {
                var brow = Path()
                brow.move(to: p(outer, 114))
                brow.addQuadCurve(to: p(inner, 113), control: p((outer + inner) * 0.5, 110.5))
                context.stroke(brow, with: .color(Storybook.ink.opacity(0.52)), style: StrokeStyle(lineWidth: 2.2 * u, lineCap: .round))
            }

        case .happy:
            for (outer, inner) in [(CGFloat(63), CGFloat(82)), (137, 118)] {
                var brow = Path()
                brow.move(to: p(outer, 113))
                brow.addQuadCurve(to: p(inner, 111.5), control: p((outer + inner) * 0.5, 108))
                context.stroke(brow, with: .color(Storybook.ink.opacity(0.58)), style: StrokeStyle(lineWidth: 2.3 * u, lineCap: .round))
            }

        case .ecstatic:
            for (outer, inner) in [(CGFloat(62), CGFloat(82)), (138, 118)] {
                var brow = Path()
                brow.move(to: p(outer, 111))
                brow.addQuadCurve(to: p(inner, 109), control: p((outer + inner) * 0.5, 104.5))
                context.stroke(brow, with: .color(Storybook.ink.opacity(0.62)), style: StrokeStyle(lineWidth: 2.5 * u, lineCap: .round))
            }
        }
    }

    private func drawMouth(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        oval: (CGFloat, CGFloat, CGFloat, CGFloat) -> Path,
        u: CGFloat
    ) {
        // Delighted rounded "o"-to-grin gulp mouth while savoring a sip!
        if isSipping {
            if sipProgress < 0.34 {
                let gulpMouth = oval(100, 156, 6.2, 7.6)
                context.fill(gulpMouth, with: .color(Color(hex: 0x622943)))
                context.drawLayer { layer in
                    layer.clip(to: gulpMouth)
                    layer.fill(oval(100, 161.5, 4.8, 3.6), with: .color(Color(hex: 0xF7879C)))
                }
                context.stroke(
                    gulpMouth,
                    with: .color(Storybook.ink.opacity(0.88)),
                    style: StrokeStyle(lineWidth: 2.0 * u, lineCap: .round, lineJoin: .round)
                )
            } else {
                let half: CGFloat = 9.8
                let depth: CGFloat = 13.0
                var grin = Path()
                grin.move(to: p(100 - half, 150))
                grin.addQuadCurve(to: p(100 + half, 150), control: p(100, 148.5))
                grin.addQuadCurve(to: p(100, 150 + depth), control: p(100 + half - 0.5, 150 + depth))
                grin.addQuadCurve(to: p(100 - half, 150), control: p(100 - half + 0.5, 150 + depth))
                grin.closeSubpath()
                context.fill(grin, with: .color(Color(hex: 0x622943)))
                context.drawLayer { layer in
                    layer.clip(to: grin)
                    layer.fill(oval(100, 150 + depth * 0.88, half * 0.74, depth * 0.38), with: .color(Color(hex: 0xF7879C)))
                }
                context.stroke(
                    grin,
                    with: .color(Storybook.ink.opacity(0.86)),
                    style: StrokeStyle(lineWidth: 1.9 * u, lineCap: .round, lineJoin: .round)
                )
            }
            return
        }

        switch mood {
        case .thirsty:
            var mouth = Path()
            mouth.move(to: p(93, 160))
            mouth.addQuadCurve(to: p(107, 160), control: p(100, 154))
            context.stroke(mouth, with: .color(Storybook.ink), style: StrokeStyle(lineWidth: 3.3 * u, lineCap: .round))

        case .okay:
            var mouth = Path()
            mouth.move(to: p(91, 153))
            mouth.addQuadCurve(to: p(109, 153), control: p(100, 161.5))
            context.stroke(mouth, with: .color(Storybook.ink), style: StrokeStyle(lineWidth: 3.3 * u, lineCap: .round))

        case .happy, .ecstatic:
            let half: CGFloat = mood == .ecstatic ? 10.5 : 8.2
            let depth: CGFloat = mood == .ecstatic ? 14.5 : 10.2
            var mouth = Path()
            mouth.move(to: p(100 - half, 150))
            mouth.addQuadCurve(to: p(100 + half, 150), control: p(100, 148.5))
            mouth.addQuadCurve(to: p(100, 150 + depth), control: p(100 + half - 0.5, 150 + depth))
            mouth.addQuadCurve(to: p(100 - half, 150), control: p(100 - half + 0.5, 150 + depth))
            mouth.closeSubpath()

            context.fill(mouth, with: .color(Color(hex: 0x622943)))
            context.drawLayer { layer in
                layer.clip(to: mouth)
                layer.fill(oval(100, 150 + depth * 0.88, half * 0.74, depth * 0.38), with: .color(Color(hex: 0xF7879C)))
            }
            context.stroke(
                mouth,
                with: .color(Storybook.ink.opacity(0.86)),
                style: StrokeStyle(lineWidth: 1.8 * u, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - Ambient Storybook Shimmer (Pearl Dewdrops & Slender 6-Point Starlets)

private struct MascotSparkles: View {
    var time: Double
    var isNight: Bool

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            let gold = isNight ? Color(hex: 0xF5D97E) : Palette.butter
            let pearl = isNight ? Color(hex: 0xE6EDFF) : Color(hex: 0xFFFDF6)

            // Delicate slender 6-point storybook starlets (8…12pt, never bulky 4-point AI sparkles).
            let starlets: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (10, 62, 11.0, 0.2),
                (192, 74, 10.0, 1.6),
                (180, 28, 8.5, 2.7)
            ]
            for (index, star) in starlets.enumerated() {
                let pulse = 0.62 + 0.38 * sin(time * 2.5 + star.3)
                let drift = CGFloat(sin(time * 1.4 + star.3) * 2.0)
                let r = (star.2 * 0.5) * u * CGFloat(pulse)
                let c = CGPoint(x: (star.0 + 10) * u, y: (star.1 + 10 + drift) * u)
                let tint = index.isMultiple(of: 2) ? gold : pearl
                context.opacity = 0.55 + pulse * 0.42
                drawSixPointStarlet(in: &context, center: c, radius: r, color: tint, lineWidth: 1.35 * u)
                context.opacity = 1
            }

            // Mixed translucent pearl dewdrop beads floating softly nearby.
            let beads: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (22, 42, 4.6, 0.9),
                (14, 172, 5.4, 2.2),
                (194, 152, 4.8, 3.4),
                (166, 22, 3.8, 4.1)
            ]
            for (index, bead) in beads.enumerated() {
                let pulse = 0.72 + 0.28 * sin(time * 2.1 + bead.3)
                let drift = CGFloat(cos(time * 1.3 + bead.3) * 1.8)
                let r = (bead.2 * 0.5) * u * CGFloat(pulse)
                let c = CGPoint(x: (bead.0 + 10) * u, y: (bead.1 + 10 + drift) * u)
                let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
                context.opacity = 0.52 + pulse * 0.42
                context.fill(Path(ellipseIn: rect), with: .color(index.isMultiple(of: 2) ? pearl : gold.opacity(0.85)))
                context.stroke(Path(ellipseIn: rect), with: .color(Storybook.ink.opacity(0.28)), lineWidth: 0.8 * u)
                context.opacity = 1
            }
        }
        .allowsHitTesting(false)
    }

    private func drawSixPointStarlet(
        in context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        lineWidth: CGFloat
    ) {
        let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        let angles: [Double] = [0, .pi / 3, 2 * .pi / 3]
        for (idx, a) in angles.enumerated() {
            let scale: CGFloat = idx == 0 ? 1.0 : 0.78
            let dx = CGFloat(cos(a)) * radius * scale
            let dy = CGFloat(sin(a)) * radius * scale
            var ray = Path()
            ray.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
            ray.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
            context.stroke(ray, with: .color(color), style: style)
        }
        let coreR = radius * 0.24
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - coreR, y: center.y - coreR, width: coreR * 2, height: coreR * 2)),
            with: .color(color)
        )
    }
}

// MARK: - Native 2-Layer Canvas Outfit Engine (All 14 Outfits)

private enum OutfitLayer {
    case back, front
}

/// Draws Dewy's currently worn outfits in either the `.back` layer (behind silhouette)
/// or `.front` layer (over silhouette), dynamically swaying with Dewy's tilt & bounce!
private struct MascotOutfitLayer: View {
    var outfits: [Outfit]
    var layer: OutfitLayer
    var time: Double
    var tilt: Double
    var wave: Double

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            let swayIdle: Double = sin(time * 2.2 - 0.5) * 0.022
            let swayWave: Double = wave * sin(time * 14.0) * 0.05
            let headSway = CGFloat(tilt * 0.14 + swayIdle + swayWave)
            let liftBob: Double = sin(time * 2.2 - 0.8) * 0.9
            let headLift = CGFloat(-wave * 3.0 + liftBob)
            let neckBob: Double = sin(time * 2.2 - 0.9) * 0.016
            let neckSway = CGFloat(tilt * 0.07 + neckBob)
            let wagIdle: Double = sin(time * 2.4 - 1.1) * 0.055
            let wagWave: Double = wave * sin(time * 13.0) * 0.09
            let tailWag = CGFloat(tilt * 0.22 + wagIdle + wagWave)

            // Draw neckwear first, then eyewear, then headwear.
            let ordered = outfits.sorted { lhs, rhs in
                OutfitArt.sortOrder(lhs) < OutfitArt.sortOrder(rhs)
            }

            for outfit in ordered {
                let anchor: CGPoint
                let angle: CGFloat
                let liftY: CGFloat
                switch outfit.slot {
                case .head:
                    anchor = CGPoint(x: 110 * u, y: 66 * u)
                    angle = headSway
                    liftY = headLift * u
                case .face:
                    anchor = CGPoint(x: 110 * u, y: 144 * u)
                    angle = headSway * 0.45
                    liftY = headLift * 0.35 * u
                case .neck:
                    anchor = CGPoint(x: 110 * u, y: 196 * u)
                    angle = neckSway
                    liftY = 0
                }

                context.drawLayer { itemCtx in
                    itemCtx.translateBy(x: anchor.x, y: anchor.y + liftY)
                    itemCtx.rotate(by: Angle(radians: Double(angle)))
                    itemCtx.translateBy(x: -anchor.x, y: -anchor.y)
                    let origin = CGPoint(x: 10 * u, y: 10 * u)
                    OutfitArt.draw(
                        outfit,
                        layer: layer,
                        in: &itemCtx,
                        origin: origin,
                        u: u,
                        sway: tailWag
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Standalone native storybook gouache illustration of any outfit for Wardrobe & Challenge cards.
struct OutfitArtView: View {
    var outfit: Outfit
    var size: CGFloat = 64

    var body: some View {
        Canvas { context, canvasSize in
            let box = OutfitArt.standaloneBounds(for: outfit)
            let pad: CGFloat = 0.84
            let scale = min(canvasSize.width, canvasSize.height) * pad / max(box.width, box.height)
            let origin = CGPoint(
                x: canvasSize.width * 0.5 - box.midX * scale,
                y: canvasSize.height * 0.5 - box.midY * scale
            )

            // Soft grounded paper-craft shadow underneath the piece.
            context.drawLayer { shadowCtx in
                shadowCtx.addFilter(.blur(radius: max(1.5, scale * 2.4)))
                shadowCtx.translateBy(x: 0, y: scale * 2.2)
                let shadowOval = Path(ellipseIn: CGRect(
                    x: canvasSize.width * 0.22,
                    y: canvasSize.height * 0.78,
                    width: canvasSize.width * 0.56,
                    height: canvasSize.height * 0.12
                ))
                shadowCtx.fill(shadowOval, with: .color(Storybook.ink.opacity(0.10)))
            }

            OutfitArt.draw(outfit, layer: .back, in: &context, origin: origin, u: scale, sway: 0)
            OutfitArt.draw(outfit, layer: .front, in: &context, origin: origin, u: scale, sway: 0)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Hand-Crafted Gouache Outfit Illustrations

/// All 14 wardrobe pieces drawn in Dewy's 200×220 design coordinates with warm botanical ink
/// contours, layered gouache washes, stitched seams, and back/front depth separation.
private enum OutfitArt {
    static func sortOrder(_ outfit: Outfit) -> Int {
        switch outfit.slot {
        case .neck: 0
        case .face: 1
        case .head: 2
        }
    }

    /// Tight bounding rect in Dewy's 200×220 design box used by `OutfitArtView` for centered cards.
    static func standaloneBounds(for outfit: Outfit) -> CGRect {
        switch outfit {
        case .beanie: CGRect(x: 54, y: 8, width: 92, height: 70)
        case .crown: CGRect(x: 62, y: 8, width: 82, height: 56)
        case .flowercrown: CGRect(x: 46, y: 40, width: 108, height: 42)
        case .bow: CGRect(x: 102, y: 24, width: 74, height: 68)
        case .sunglasses: CGRect(x: 30, y: 106, width: 140, height: 56)
        case .partyhat: CGRect(x: 68, y: 2, width: 72, height: 68)
        case .headphones: CGRect(x: 14, y: 18, width: 172, height: 144)
        case .froghat: CGRect(x: 54, y: 20, width: 92, height: 58)
        case .strawhat: CGRect(x: 14, y: 14, width: 172, height: 68)
        case .wizardhat: CGRect(x: 28, y: 4, width: 146, height: 76)
        case .chefhat: CGRect(x: 58, y: 8, width: 84, height: 62)
        case .scarf: CGRect(x: 26, y: 158, width: 148, height: 56)
        case .bowtie: CGRect(x: 68, y: 168, width: 64, height: 34)
        case .leafhat: CGRect(x: 30, y: 12, width: 142, height: 66)
        }
    }

    static func draw(
        _ outfit: Outfit,
        layer: OutfitLayer,
        in context: inout GraphicsContext,
        origin: CGPoint,
        u: CGFloat,
        sway: CGFloat
    ) {
        let p: (CGFloat, CGFloat) -> CGPoint = { x, y in
            CGPoint(x: origin.x + x * u, y: origin.y + y * u)
        }
        switch outfit {
        case .beanie:
            if layer == .front { drawBeanie(in: &context, p: p, u: u) }
        case .crown:
            if layer == .front { drawCrown(in: &context, p: p, u: u) }
        case .flowercrown:
            drawFlowerCrown(layer: layer, in: &context, p: p, u: u)
        case .bow:
            if layer == .front { drawBow(in: &context, p: p, u: u, sway: sway) }
        case .sunglasses:
            if layer == .front { drawSunglasses(in: &context, p: p, u: u) }
        case .partyhat:
            if layer == .front { drawPartyHat(in: &context, p: p, u: u) }
        case .headphones:
            drawHeadphones(layer: layer, in: &context, p: p, u: u)
        case .froghat:
            if layer == .front { drawFrogHat(in: &context, p: p, u: u) }
        case .strawhat:
            drawStrawHat(layer: layer, in: &context, p: p, u: u, sway: sway)
        case .wizardhat:
            drawWizardHat(layer: layer, in: &context, p: p, u: u)
        case .chefhat:
            if layer == .front { drawChefHat(in: &context, p: p, u: u) }
        case .scarf:
            drawScarf(layer: layer, in: &context, p: p, u: u, sway: sway)
        case .bowtie:
            if layer == .front { drawBowTie(in: &context, p: p, u: u) }
        case .leafhat:
            drawLeafHat(layer: layer, in: &context, p: p, u: u)
        }
    }

    private static func stroke(_ u: CGFloat, width: CGFloat = 2.0) -> StrokeStyle {
        StrokeStyle(lineWidth: width * u, lineCap: .round, lineJoin: .round)
    }

    private static func oval(
        _ cx: CGFloat,
        _ cy: CGFloat,
        _ rx: CGFloat,
        _ ry: CGFloat,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) -> Path {
        let topLeft = p(cx - rx, cy - ry)
        return Path(ellipseIn: CGRect(x: topLeft.x, y: topLeft.y, width: rx * 2 * u, height: ry * 2 * u))
    }

    // 1. Cozy Beanie (snug tapered fit hugging Dewy's upper brow slopes)
    private static func drawBeanie(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let tealLight = Color(hex: 0x8CE0D6)
        let tealMid = Color(hex: 0x52B8B0)
        let tealDeep = Color(hex: 0x358B8A)
        let pomCream = Color(hex: 0xFFF3DF)
        let pomPeach = Color(hex: 0xF7C9B0)

        // Fluffy yarn pom-pom comfortably inside top canvas margin.
        let pom = oval(100, 20, 10.5, 9.8, p: p, u: u)
        context.fill(pom, with: .radialGradient(
            Gradient(colors: [pomCream, pomPeach]),
            center: p(96, 16),
            startRadius: 1 * u,
            endRadius: 12 * u
        ))
        context.stroke(pom, with: .color(Storybook.ink.opacity(0.75)), style: stroke(u, width: 1.8))

        // Tapered knit dome hugging Dewy's crown.
        var dome = Path()
        dome.move(to: p(62, 62))
        dome.addCurve(to: p(100, 27), control1: p(64, 37), control2: p(79, 27))
        dome.addCurve(to: p(138, 62), control1: p(121, 27), control2: p(136, 37))
        dome.addQuadCurve(to: p(62, 62), control: p(100, 54))
        dome.closeSubpath()

        context.fill(dome, with: .linearGradient(
            Gradient(colors: [tealLight, tealMid, tealDeep]),
            startPoint: p(78, 27),
            endPoint: p(122, 66)
        ))
        context.stroke(dome, with: .color(Storybook.ink.opacity(0.78)), style: stroke(u))

        // Curved knit rib lines across dome.
        for dx in [CGFloat(-22), -11, 0, 11, 22] {
            var rib = Path()
            rib.move(to: p(100 + dx * 0.28, 30))
            rib.addQuadCurve(to: p(100 + dx * 1.12, 58), control: p(100 + dx * 0.88, 42))
            context.stroke(rib, with: .color(tealDeep.opacity(0.48)), style: stroke(u, width: 1.4))
        }

        // Folded chunky ribbed cuff seated snugly along y = 60...73 (width ~82).
        var cuff = Path()
        cuff.move(to: p(59, 61))
        cuff.addQuadCurve(to: p(141, 61), control: p(100, 51))
        cuff.addCurve(to: p(139, 73), control1: p(144, 66), control2: p(143, 72))
        cuff.addQuadCurve(to: p(61, 73), control: p(100, 62))
        cuff.addCurve(to: p(59, 61), control1: p(57, 72), control2: p(56, 66))
        cuff.closeSubpath()

        context.fill(cuff, with: .linearGradient(
            Gradient(colors: [Color(hex: 0xA8EBE2), tealMid]),
            startPoint: p(100, 52),
            endPoint: p(100, 74)
        ))
        for x in stride(from: CGFloat(68), through: 132, by: 9) {
            let yTop = 57 + abs(x - 100) * 0.09
            var stitch = Path()
            stitch.move(to: p(x, yTop))
            stitch.addLine(to: p(x + (x < 100 ? -1.2 : 1.2), yTop + 11.5))
            context.stroke(stitch, with: .color(tealDeep.opacity(0.55)), style: stroke(u, width: 1.45))
        }
        context.stroke(cuff, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u))
    }

    // 2. Royal Crown
    private static func drawCrown(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let goldTop = Color(hex: 0xFFE68A)
        let goldMid = Color(hex: 0xF5B942)
        let goldDeep = Color(hex: 0xC98220)

        context.drawLayer { layer in
            let pivot = p(104, 42)
            layer.translateBy(x: pivot.x, y: pivot.y)
            layer.rotate(by: .degrees(8))
            layer.translateBy(x: -pivot.x, y: -pivot.y)

            // Berry velvet inner lining peeking behind the peaks.
            var lining = Path()
            lining.move(to: p(76, 46))
            lining.addQuadCurve(to: p(104, 24), control: p(84, 24))
            lining.addQuadCurve(to: p(132, 46), control: p(124, 24))
            lining.closeSubpath()
            layer.fill(lining, with: .color(Color(hex: 0xB84664)))

            // Sculpted 3-peak hammered gold crown body.
            var crown = Path()
            crown.move(to: p(73, 52))
            crown.addLine(to: p(69, 25))
            crown.addQuadCurve(to: p(88, 35), control: p(79, 36))
            crown.addLine(to: p(104, 16))
            crown.addLine(to: p(120, 35))
            crown.addQuadCurve(to: p(139, 25), control: p(129, 36))
            crown.addLine(to: p(135, 52))
            crown.addQuadCurve(to: p(73, 52), control: p(104, 58))
            crown.closeSubpath()

            layer.fill(crown, with: .linearGradient(
                Gradient(colors: [goldTop, goldMid, goldDeep]),
                startPoint: p(74, 18),
                endPoint: p(134, 56)
            ))
            layer.stroke(crown, with: .color(Storybook.ink.opacity(0.82)), style: stroke(u))

            // Embossed lower band line.
            var band = Path()
            band.move(to: p(74, 45))
            band.addQuadCurve(to: p(134, 45), control: p(104, 51))
            layer.stroke(band, with: .color(goldDeep.opacity(0.75)), style: stroke(u, width: 1.6))

            // Pearl tips on peaks.
            for tip in [(CGFloat(69), CGFloat(23)), (104, 14), (139, 23)] {
                let pearl = oval(tip.0, tip.1, 4.2, 4.2, p: p, u: u)
                layer.fill(pearl, with: .color(Color(hex: 0xFFF9EA)))
                layer.stroke(pearl, with: .color(Storybook.ink.opacity(0.75)), style: stroke(u, width: 1.5))
            }

            // Cabochon gems.
            let gems: [(CGFloat, CGFloat, Color)] = [
                (85, 44, Color(hex: 0x5CC4C8)),
                (104, 41, Color(hex: 0xE6556E)),
                (123, 44, Color(hex: 0x5CC4C8))
            ]
            for gem in gems {
                let shape = oval(gem.0, gem.1, 3.8, 4.6, p: p, u: u)
                layer.fill(shape, with: .color(gem.2))
                layer.stroke(shape, with: .color(Storybook.ink.opacity(0.72)), style: stroke(u, width: 1.3))
                layer.fill(oval(gem.0 - 1.1, gem.1 - 1.3, 1.3, 1.3, p: p, u: u), with: .color(.white.opacity(0.85)))
            }
        }
    }

    // 3. Flower Crown (snug 3/4 perspective garland hugging Dewy's brow slopes)
    private static func drawFlowerCrown(
        layer: OutfitLayer,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        let sageDark = Color(hex: 0x4E865B)
        let sageMid = Color(hex: 0x7AB97E)
        let sageLight = Color(hex: 0xA8D99B)

        if layer == .back {
            // Rear woven vine curving snugly behind Dewy's upper silhouette.
            var backVine = Path()
            backVine.move(to: p(57, 62))
            backVine.addQuadCurve(to: p(143, 62), control: p(100, 45))
            context.stroke(backVine, with: .color(sageDark), style: stroke(u, width: 5.0))
            context.stroke(backVine, with: .color(Storybook.ink.opacity(0.55)), style: stroke(u, width: 1.4))
            return
        }

        // Curved front braided botanical stem resting snugly across the brow (y = 62...72).
        var stem = Path()
        stem.move(to: p(56, 63))
        stem.addQuadCurve(to: p(144, 63), control: p(100, 78))
        context.stroke(stem, with: .color(sageDark), style: stroke(u, width: 4.6))
        context.stroke(stem, with: .color(sageLight), style: stroke(u, width: 1.8))

        // Botanical sage leaves fanning organically along the garland.
        let leaves: [(CGFloat, CGFloat, Double)] = [
            (60, 62, -35), (76, 68, 24), (90, 71, -18),
            (110, 71, 18), (124, 68, -24), (140, 62, 35)
        ]
        for leaf in leaves {
            drawLeaf(cx: leaf.0, cy: leaf.1, angle: leaf.2, fill: sageMid, in: &context, p: p, u: u)
        }

        // Five hand-painted storybook blossoms curving in 3/4 depth.
        drawBlossom(cx: 62, cy: 63, radius: 8.4, petals: Color(hex: 0xC6ADF5), center: Color(hex: 0xFFE07A), in: &context, p: p, u: u)
        drawBlossom(cx: 81, cy: 68, radius: 9.8, petals: Color(hex: 0xFFF6E0), center: Color(hex: 0xF5B942), in: &context, p: p, u: u)
        drawBlossom(cx: 100, cy: 70, radius: 11.0, petals: Color(hex: 0xF78EA8), center: Color(hex: 0xFFE17D), in: &context, p: p, u: u)
        drawBlossom(cx: 119, cy: 68, radius: 9.8, petals: Color(hex: 0xFFD97D), center: Color(hex: 0xE57A54), in: &context, p: p, u: u)
        drawBlossom(cx: 138, cy: 63, radius: 8.4, petals: Color(hex: 0xFFAEC8), center: Color(hex: 0xFFF1A8), in: &context, p: p, u: u)
    }

    private static func drawLeaf(
        cx: CGFloat,
        cy: CGFloat,
        angle: Double,
        fill: Color,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        context.drawLayer { layer in
            let pt = p(cx, cy)
            layer.translateBy(x: pt.x, y: pt.y)
            layer.rotate(by: .degrees(angle))
            var leaf = Path()
            leaf.move(to: CGPoint(x: -10 * u, y: 0))
            leaf.addQuadCurve(to: CGPoint(x: 10 * u, y: 0), control: CGPoint(x: 0, y: -7.5 * u))
            leaf.addQuadCurve(to: CGPoint(x: -10 * u, y: 0), control: CGPoint(x: 0, y: 7.5 * u))
            leaf.closeSubpath()
            layer.fill(leaf, with: .color(fill))
            layer.stroke(leaf, with: .color(Storybook.ink.opacity(0.68)), style: stroke(u, width: 1.4))
        }
    }

    private static func drawBlossom(
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat,
        petals: Color,
        center: Color,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        for i in 0..<5 {
            let a = Double(i) * (.pi * 2 / 5) - .pi / 2
            let px = cx + CGFloat(cos(a)) * radius * 0.56
            let py = cy + CGFloat(sin(a)) * radius * 0.56
            let petal = oval(px, py, radius * 0.46, radius * 0.46, p: p, u: u)
            context.fill(petal, with: .color(petals))
            context.stroke(petal, with: .color(Storybook.ink.opacity(0.62)), style: stroke(u, width: 1.25))
        }
        let heart = oval(cx, cy, radius * 0.34, radius * 0.34, p: p, u: u)
        context.fill(heart, with: .color(center))
        context.stroke(heart, with: .color(Storybook.ink.opacity(0.68)), style: stroke(u, width: 1.2))
    }

    // 4. Big Bow
    private static func drawBow(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        sway: CGFloat
    ) {
        let roseLight = Color(hex: 0xFFB5CD)
        let roseMid = Color(hex: 0xF0779C)
        let roseDeep = Color(hex: 0xC64D73)

        context.drawLayer { layer in
            let pivot = p(138, 56)
            layer.translateBy(x: pivot.x, y: pivot.y)
            layer.rotate(by: .degrees(20 + Double(sway) * 14))
            layer.translateBy(x: -pivot.x, y: -pivot.y)

            // Trailing ribbon tails.
            var leftTail = Path()
            leftTail.move(to: p(134, 60))
            leftTail.addQuadCurve(to: p(118, 86), control: p(122, 72))
            leftTail.addLine(to: p(127, 81))
            leftTail.addLine(to: p(133, 88))
            leftTail.addQuadCurve(to: p(139, 62), control: p(138, 76))
            leftTail.closeSubpath()

            var rightTail = Path()
            rightTail.move(to: p(142, 60))
            rightTail.addQuadCurve(to: p(158, 86), control: p(155, 72))
            rightTail.addLine(to: p(149, 81))
            rightTail.addLine(to: p(144, 88))
            rightTail.addQuadCurve(to: p(138, 62), control: p(140, 76))
            rightTail.closeSubpath()

            for tail in [leftTail, rightTail] {
                layer.fill(tail, with: .linearGradient(
                    Gradient(colors: [roseMid, roseDeep]),
                    startPoint: p(138, 60),
                    endPoint: p(138, 88)
                ))
                layer.stroke(tail, with: .color(Storybook.ink.opacity(0.78)), style: stroke(u, width: 1.7))
            }

            // Sculpted pleated ribbon wings.
            var leftLoop = Path()
            leftLoop.move(to: p(135, 56))
            leftLoop.addCurve(to: p(107, 46), control1: p(124, 38), control2: p(109, 34))
            leftLoop.addCurve(to: p(135, 62), control1: p(105, 62), control2: p(121, 70))
            leftLoop.closeSubpath()

            var rightLoop = Path()
            rightLoop.move(to: p(141, 56))
            rightLoop.addCurve(to: p(169, 46), control1: p(152, 38), control2: p(167, 34))
            rightLoop.addCurve(to: p(141, 62), control1: p(171, 62), control2: p(155, 70))
            rightLoop.closeSubpath()

            for loop in [leftLoop, rightLoop] {
                layer.fill(loop, with: .linearGradient(
                    Gradient(colors: [roseLight, roseMid, roseDeep]),
                    startPoint: p(138, 36),
                    endPoint: p(138, 70)
                ))
                layer.stroke(loop, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.85))
            }

            // Inner silk pleat crease lines.
            var creaseL = Path()
            creaseL.move(to: p(133, 58))
            creaseL.addQuadCurve(to: p(118, 53), control: p(125, 54))
            var creaseR = Path()
            creaseR.move(to: p(143, 58))
            creaseR.addQuadCurve(to: p(158, 53), control: p(151, 54))
            layer.stroke(creaseL, with: .color(roseDeep.opacity(0.7)), style: stroke(u, width: 1.6))
            layer.stroke(creaseR, with: .color(roseDeep.opacity(0.7)), style: stroke(u, width: 1.6))

            // Plump center silk knot.
            let knot = oval(138, 58, 7.5, 8.5, p: p, u: u)
            layer.fill(knot, with: .linearGradient(
                Gradient(colors: [roseLight, roseMid]),
                startPoint: p(134, 50),
                endPoint: p(142, 66)
            ))
            layer.stroke(knot, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.8))
        }
    }

    // 5. Heart Shades
    private static func drawSunglasses(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let frameCream = Color(hex: 0xFFF4E8)
        let frameRose = Color(hex: 0xF59BB3)
        let lensTop = Color(hex: 0xA83E6A)
        let lensBottom = Color(hex: 0x562348)

        // Temple arms hugging Dewy's left and right sides.
        var armL = Path()
        armL.move(to: p(46, 126))
        armL.addQuadCurve(to: p(34, 130), control: p(39, 125))
        var armR = Path()
        armR.move(to: p(154, 126))
        armR.addQuadCurve(to: p(166, 130), control: p(161, 125))
        context.stroke(armL, with: .color(frameRose), style: stroke(u, width: 5.0))
        context.stroke(armR, with: .color(frameRose), style: stroke(u, width: 5.0))
        context.stroke(armL, with: .color(Storybook.ink.opacity(0.75)), style: stroke(u, width: 1.6))
        context.stroke(armR, with: .color(Storybook.ink.opacity(0.75)), style: stroke(u, width: 1.6))

        // Delicate arched nose bridge.
        var bridge = Path()
        bridge.move(to: p(92, 129))
        bridge.addQuadCurve(to: p(108, 129), control: p(100, 122))
        context.stroke(bridge, with: .color(frameCream), style: stroke(u, width: 4.5))
        context.stroke(bridge, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.7))

        // Twin heart frames + translucent plum-rose lenses.
        for cx in [CGFloat(72), 128] {
            let outerRect = CGRect(x: p(cx - 26, 113).x, y: p(cx - 26, 113).y, width: 52 * u, height: 44 * u)
            let outerHeart = HeartShape().path(in: outerRect)
            context.fill(outerHeart, with: .linearGradient(
                Gradient(colors: [frameCream, frameRose]),
                startPoint: p(cx, 112),
                endPoint: p(cx, 158)
            ))
            context.stroke(outerHeart, with: .color(Storybook.ink.opacity(0.84)), style: stroke(u, width: 2.0))

            let innerRect = CGRect(x: p(cx - 20.5, 118.5).x, y: p(cx - 20.5, 118.5).y, width: 41 * u, height: 34 * u)
            let innerHeart = HeartShape().path(in: innerRect)
            context.fill(innerHeart, with: .linearGradient(
                Gradient(colors: [lensTop.opacity(0.92), lensBottom.opacity(0.94)]),
                startPoint: p(cx - 10, 118),
                endPoint: p(cx + 12, 152)
            ))

            // Diagonal gouache glass reflections inside each lens.
            context.drawLayer { layer in
                layer.clip(to: innerHeart)
                var streak = Path()
                streak.move(to: p(cx - 16, 146))
                streak.addLine(to: p(cx + 4, 116))
                layer.stroke(streak, with: .color(.white.opacity(0.42)), style: stroke(u, width: 5.5))
                var thin = Path()
                thin.move(to: p(cx - 4, 149))
                thin.addLine(to: p(cx + 14, 121))
                layer.stroke(thin, with: .color(.white.opacity(0.28)), style: stroke(u, width: 2.2))
            }
            context.stroke(innerHeart, with: .color(Storybook.ink.opacity(0.55)), style: stroke(u, width: 1.2))
        }
    }

    // 6. Party Hat (seated snugly with safe top canvas clearance for pom-pom)
    private static func drawPartyHat(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let mintLight = Color(hex: 0xB8F0D6)
        let mintDeep = Color(hex: 0x58BC9A)
        let coralStripe = Color(hex: 0xF57E78)
        let butter = Color(hex: 0xFFE074)

        context.drawLayer { layer in
            let pivot = p(103, 54)
            layer.translateBy(x: pivot.x, y: pivot.y)
            layer.rotate(by: .degrees(9))
            layer.translateBy(x: -pivot.x, y: -pivot.y)

            // Paper cone body safely inside y >= 15 (pom-pom top stays >= 6).
            var cone = Path()
            cone.move(to: p(103, 16))
            cone.addLine(to: p(77, 59))
            cone.addQuadCurve(to: p(129, 59), control: p(103, 66))
            cone.closeSubpath()

            layer.fill(cone, with: .linearGradient(
                Gradient(colors: [mintLight, mintDeep]),
                startPoint: p(92, 18),
                endPoint: p(126, 62)
            ))

            // Clipped festive watercolor ribbons & confetti dots.
            layer.drawLayer { clipped in
                clipped.clip(to: cone)
                for y in [CGFloat(34), 48] {
                    var stripe = Path()
                    stripe.move(to: p(72, y + 5))
                    stripe.addQuadCurve(to: p(134, y - 4), control: p(103, y + 6))
                    clipped.stroke(stripe, with: .color(coralStripe.opacity(0.88)), style: stroke(u, width: 5.0))
                }
                for dot in [(CGFloat(98), CGFloat(27)), (108, 42), (90, 53), (116, 54)] {
                    clipped.fill(oval(dot.0, dot.1, 2.4, 2.4, p: p, u: u), with: .color(butter))
                }
            }
            layer.stroke(cone, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.9))

            // Scalloped crepe-paper ruffle base hugging Dewy's brow.
            for idx in 0..<6 {
                let t = Double(idx) / 5.0
                let rx: CGFloat = 78 + CGFloat(t) * 50
                let ry: CGFloat = 60 + CGFloat(sin(t * .pi)) * 4.2
                let puff = oval(rx, ry, 5.8, 4.8, p: p, u: u)
                layer.fill(puff, with: .color(idx.isMultiple(of: 2) ? Color(hex: 0xFFF3D4) : Color(hex: 0xFFD0C4)))
                layer.stroke(puff, with: .color(Storybook.ink.opacity(0.72)), style: stroke(u, width: 1.4))
            }

            // Fluffy butter-gold pom-pom at summit (top at y ≈ 5.5 — never clips!).
            let pom = oval(103, 13, 7.8, 7.8, p: p, u: u)
            layer.fill(pom, with: .radialGradient(
                Gradient(colors: [Color(hex: 0xFFF5B8), Color(hex: 0xF5B942)]),
                center: p(100, 10),
                startRadius: 1 * u,
                endRadius: 9 * u
            ))
            layer.stroke(pom, with: .color(Storybook.ink.opacity(0.78)), style: stroke(u, width: 1.7))
        }
    }

    // 7. Lo-fi Phones (2-Layer arch behind Dewy's curl + plush cheek-hugging earcups in front)
    private static func drawHeadphones(
        layer: OutfitLayer,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        let coralLight = Color(hex: 0xFFD4BA)
        let coralMid = Color(hex: 0xF29979)
        let coralDeep = Color(hex: 0xC9684F)
        let cream = Color(hex: 0xFFF5E6)
        let brass = Color(hex: 0xE5B654)

        if layer == .back {
            // Studio headband arches cleanly BEHIND Dewy's crown curl so it never slices across the tip!
            var band = Path()
            band.move(to: p(30, 114))
            band.addCurve(to: p(100, 26), control1: p(22, 58), control2: p(54, 26))
            band.addCurve(to: p(170, 114), control1: p(146, 26), control2: p(178, 58))

            context.stroke(band, with: .color(Storybook.ink.opacity(0.84)), style: stroke(u, width: 15.0))
            context.stroke(band, with: .color(coralMid), style: stroke(u, width: 11.2))

            // Top cream stitched leatherette cushion along the apex.
            var pad = Path()
            pad.move(to: p(66, 35))
            pad.addQuadCurve(to: p(134, 35), control: p(100, 21))
            context.stroke(pad, with: .color(cream), style: stroke(u, width: 7.0))
            context.stroke(pad, with: .color(coralLight), style: stroke(u, width: 2.0))

            // Subtle inner acoustic cup depth behind Dewy's left/right cheeks.
            for cx in [CGFloat(34), 166] {
                let backPad = oval(cx, 132, 14, 24, p: p, u: u)
                context.fill(backPad, with: .color(Color(hex: 0x5E4352)))
                context.stroke(backPad, with: .color(Storybook.ink.opacity(0.7)), style: stroke(u, width: 1.8))
            }
            return
        }

        // Front brass slider yokes & plush oval earcups hugging Dewy's cheeks.
        for side in [CGFloat(-1), 1] {
            let x = 100 + side * 69
            let slider = Path(roundedRect: CGRect(x: p(x - 4.5, 98).x, y: p(x - 4.5, 98).y, width: 9 * u, height: 18 * u), cornerRadius: 3 * u)
            context.fill(slider, with: .color(brass))
            context.stroke(slider, with: .color(Storybook.ink.opacity(0.78)), style: stroke(u, width: 1.5))

            // Cushioned inner ring hugging cheek.
            let cushion = oval(100 + side * 65, 132, 9.5, 22, p: p, u: u)
            context.fill(cushion, with: .color(cream))
            context.stroke(cushion, with: .color(Storybook.ink.opacity(0.75)), style: stroke(u, width: 1.7))

            // Outer sculpted oval earcup shell.
            let shell = oval(100 + side * 72, 132, 11.5, 21, p: p, u: u)
            context.fill(shell, with: .linearGradient(
                Gradient(colors: [coralLight, coralMid, coralDeep]),
                startPoint: p(100 + side * 72, 110),
                endPoint: p(100 + side * 72, 154)
            ))
            context.stroke(shell, with: .color(Storybook.ink.opacity(0.82)), style: stroke(u, width: 1.9))

            // Minimalist brushed-brass acoustic medallion.
            let badge = oval(100 + side * 74, 132, 4.5, 8.0, p: p, u: u)
            context.fill(badge, with: .color(brass.opacity(0.88)))
            context.stroke(badge, with: .color(Storybook.ink.opacity(0.6)), style: stroke(u, width: 1.1))
        }
    }

    // 8. Froggy Hat (snug tapered fit hugging Dewy's upper brow slopes)
    private static func drawFrogHat(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let mossLight = Color(hex: 0xB8E8A5)
        let mossMid = Color(hex: 0x77C278)
        let mossDeep = Color(hex: 0x4C9154)

        // Two perky frog-eye domes rising above the snug cap.
        for ex in [CGFloat(79), 121] {
            let dome = oval(ex, 37, 12.5, 12.5, p: p, u: u)
            context.fill(dome, with: .linearGradient(
                Gradient(colors: [mossLight, mossMid]),
                startPoint: p(ex, 25),
                endPoint: p(ex, 49)
            ))
            context.stroke(dome, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.85))

            let sclera = oval(ex, 37, 8.2, 8.2, p: p, u: u)
            context.fill(sclera, with: .color(Color(hex: 0xFFFDF5)))
            context.stroke(sclera, with: .color(Storybook.ink.opacity(0.55)), style: stroke(u, width: 1.15))

            let pupil = oval(ex, 37.5, 4.5, 4.8, p: p, u: u)
            context.fill(pupil, with: .color(Storybook.ink))
            context.fill(oval(ex - 1.7, 35.8, 1.6, 1.6, p: p, u: u), with: .color(.white))
        }

        // Tapered knitted frog cap hugging Dewy's upper slopes.
        var cap = Path()
        cap.move(to: p(61, 63))
        cap.addCurve(to: p(100, 38), control1: p(64, 42), control2: p(80, 38))
        cap.addCurve(to: p(139, 63), control1: p(120, 38), control2: p(136, 42))
        cap.addQuadCurve(to: p(61, 63), control: p(100, 54))
        cap.closeSubpath()

        context.fill(cap, with: .linearGradient(
            Gradient(colors: [mossLight, mossMid, mossDeep]),
            startPoint: p(82, 38),
            endPoint: p(118, 66)
        ))
        context.stroke(cap, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.85))

        // Rolled curved brim seated snugly at y = 62...73 (width ~84).
        var brim = Path()
        brim.move(to: p(58, 62))
        brim.addQuadCurve(to: p(142, 62), control: p(100, 52))
        brim.addCurve(to: p(140, 73), control1: p(144, 67), control2: p(143, 72))
        brim.addQuadCurve(to: p(60, 73), control: p(100, 62))
        brim.addCurve(to: p(58, 62), control1: p(57, 72), control2: p(56, 67))
        brim.closeSubpath()

        context.fill(brim, with: .color(mossMid))
        context.stroke(brim, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.85))

        // Tiny embroidered frog smile & rosy blushes on the cap.
        for bx in [CGFloat(76), 124] {
            context.fill(oval(bx, 53.5, 5.2, 3.2, p: p, u: u), with: .color(Color(hex: 0xF79AA8).opacity(0.72)))
        }
        var smile = Path()
        smile.move(to: p(93, 52))
        smile.addQuadCurve(to: p(107, 52), control: p(100, 57.5))
        context.stroke(smile, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.9))
    }

    // 9. Sun Hat (2-Layer woven straw brim + coral ribbon)
    private static func drawStrawHat(
        layer: OutfitLayer,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        sway: CGFloat
    ) {
        let strawLight = Color(hex: 0xFCE5AE)
        let strawMid = Color(hex: 0xEBBE6F)
        let strawDeep = Color(hex: 0xC48E40)
        let ribbon = Color(hex: 0xEA756C)
        let ribbonDeep = Color(hex: 0xBC4B45)

        context.drawLayer { ctx in
            let pivot = p(100, 52)
            ctx.translateBy(x: pivot.x, y: pivot.y)
            ctx.rotate(by: .degrees(-5))
            ctx.translateBy(x: -pivot.x, y: -pivot.y)

            if layer == .back {
                // Shaded underside of the wide woven brim behind Dewy's head.
                let backBrim = oval(100, 56, 80, 21, p: p, u: u)
                ctx.fill(backBrim, with: .linearGradient(
                    Gradient(colors: [strawDeep, Color(hex: 0x9C6C2D)]),
                    startPoint: p(100, 36),
                    endPoint: p(100, 78)
                ))
                ctx.stroke(backBrim, with: .color(Storybook.ink.opacity(0.78)), style: stroke(u, width: 2.0))
                return
            }

            // Wide front sweeping straw brim.
            var frontBrim = Path()
            frontBrim.move(to: p(20, 56))
            frontBrim.addCurve(to: p(180, 56), control1: p(42, 37), control2: p(158, 37))
            frontBrim.addCurve(to: p(20, 56), control1: p(150, 74), control2: p(50, 74))
            frontBrim.closeSubpath()

            ctx.fill(frontBrim, with: .linearGradient(
                Gradient(colors: [strawLight, strawMid, strawDeep]),
                startPoint: p(52, 40),
                endPoint: p(150, 72)
            ))

            // Hand-drawn concentric straw-weave lines.
            var weave = Path()
            weave.move(to: p(32, 57))
            weave.addQuadCurve(to: p(168, 57), control: p(100, 67))
            ctx.stroke(weave, with: .color(strawDeep.opacity(0.5)), style: stroke(u, width: 1.4))
            ctx.stroke(frontBrim, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 2.0))

            // Rounded woven crown dome.
            var crown = Path()
            crown.move(to: p(58, 51))
            crown.addCurve(to: p(100, 19), control1: p(60, 25), control2: p(78, 19))
            crown.addCurve(to: p(142, 51), control1: p(122, 19), control2: p(140, 25))
            crown.addQuadCurve(to: p(58, 51), control: p(100, 59))
            crown.closeSubpath()

            ctx.fill(crown, with: .linearGradient(
                Gradient(colors: [strawLight, strawMid]),
                startPoint: p(76, 20),
                endPoint: p(128, 56)
            ))
            // Subtle straw cross-hatch lines on crown.
            for rowY in [CGFloat(30), 38] {
                var row = Path()
                row.move(to: p(68, rowY))
                row.addQuadCurve(to: p(132, rowY), control: p(100, rowY + 4))
                ctx.stroke(row, with: .color(strawDeep.opacity(0.4)), style: stroke(u, width: 1.3))
            }
            ctx.stroke(crown, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.9))

            // Dusty-coral grosgrain hatband + fluttering side bow.
            var hatband = Path()
            hatband.move(to: p(58, 45))
            hatband.addQuadCurve(to: p(142, 45), control: p(100, 54))
            hatband.addLine(to: p(142, 52))
            hatband.addQuadCurve(to: p(58, 52), control: p(100, 61))
            hatband.closeSubpath()
            ctx.fill(hatband, with: .linearGradient(
                Gradient(colors: [ribbon, ribbonDeep]),
                startPoint: p(60, 46),
                endPoint: p(142, 58)
            ))
            ctx.stroke(hatband, with: .color(Storybook.ink.opacity(0.75)), style: stroke(u, width: 1.5))

            // Trailing ribbon streamer on the right side.
            var streamer = Path()
            streamer.move(to: p(139, 50))
            streamer.addQuadCurve(to: p(164 + sway * 16, 68), control: p(156, 56))
            ctx.stroke(streamer, with: .color(ribbon), style: stroke(u, width: 5.5))
            ctx.stroke(streamer, with: .color(Storybook.ink.opacity(0.65)), style: stroke(u, width: 1.4))

            let knot = oval(140, 49, 5.5, 4.5, p: p, u: u)
            ctx.fill(knot, with: .color(Color(hex: 0xFA978E)))
            ctx.stroke(knot, with: .color(Storybook.ink.opacity(0.76)), style: stroke(u, width: 1.5))
        }
    }

    // 10. Wizard Hat (2-Layer twilight-indigo brim + bent starry spire safely inside top margin)
    private static func drawWizardHat(
        layer: OutfitLayer,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        let indigoLight = Color(hex: 0x7A74CE)
        let indigoMid = Color(hex: 0x4F4B9E)
        let indigoDeep = Color(hex: 0x2F2C6B)
        let gold = Color(hex: 0xF7CA59)

        context.drawLayer { ctx in
            let pivot = p(102, 56)
            ctx.translateBy(x: pivot.x, y: pivot.y)
            ctx.rotate(by: .degrees(6))
            ctx.translateBy(x: -pivot.x, y: -pivot.y)

            if layer == .back {
                let backBrim = oval(100, 62, 68, 16, p: p, u: u)
                ctx.fill(backBrim, with: .color(indigoDeep))
                ctx.stroke(backBrim, with: .color(Storybook.ink.opacity(0.84)), style: stroke(u, width: 2.0))
                return
            }

            // Wide curved storybook brim seated snugly on Dewy's brow.
            var brim = Path()
            brim.move(to: p(32, 63))
            brim.addCurve(to: p(168, 62), control1: p(56, 47), control2: p(144, 46))
            brim.addCurve(to: p(32, 63), control1: p(142, 76), control2: p(58, 77))
            brim.closeSubpath()

            ctx.fill(brim, with: .linearGradient(
                Gradient(colors: [indigoMid, indigoDeep]),
                startPoint: p(48, 48),
                endPoint: p(146, 76)
            ))
            ctx.stroke(brim, with: .color(Storybook.ink.opacity(0.86)), style: stroke(u, width: 2.0))

            // Playfully bent conical wizard spire comfortably inside top canvas margin (y >= 9).
            var spire = Path()
            spire.move(to: p(64, 58))
            spire.addCurve(to: p(105, 10), control1: p(71, 30), control2: p(86, 14))
            spire.addCurve(to: p(131, 20), control1: p(117, 7), control2: p(129, 13))
            spire.addCurve(to: p(116, 22), control1: p(126, 19), control2: p(120, 19))
            spire.addCurve(to: p(136, 58), control1: p(124, 34), control2: p(133, 44))
            spire.addQuadCurve(to: p(64, 58), control: p(100, 65))
            spire.closeSubpath()

            ctx.fill(spire, with: .linearGradient(
                Gradient(colors: [indigoLight, indigoMid, indigoDeep]),
                startPoint: p(76, 14),
                endPoint: p(132, 62)
            ))
            ctx.stroke(spire, with: .color(Storybook.ink.opacity(0.86)), style: stroke(u, width: 2.0))

            // Antique gold hatband & buckle.
            var band = Path()
            band.move(to: p(66, 51))
            band.addQuadCurve(to: p(134, 51), control: p(100, 59))
            band.addLine(to: p(136, 58))
            band.addQuadCurve(to: p(64, 58), control: p(100, 65))
            band.closeSubpath()
            ctx.fill(band, with: .color(Color(hex: 0xD99636)))
            ctx.stroke(band, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.5))

            let buckle = Path(roundedRect: CGRect(x: p(93, 51).x, y: p(93, 51).y, width: 14 * u, height: 10.5 * u), cornerRadius: 2.5 * u)
            ctx.stroke(buckle, with: .color(gold), style: stroke(u, width: 2.5))

            // Painted crescent moon & tiny golden celestial pinpoints.
            var moon = Path()
            moon.move(to: p(97, 25))
            moon.addCurve(to: p(97, 40), control1: p(87, 27), control2: p(87, 38))
            moon.addCurve(to: p(97, 25), control1: p(92, 36), control2: p(92, 29))
            moon.closeSubpath()
            ctx.fill(moon, with: .color(gold))

            for dot in [(CGFloat(110), CGFloat(31), CGFloat(2.2)), (82, 42, 1.8), (116, 43, 1.7)] {
                ctx.fill(oval(dot.0, dot.1, dot.2, dot.2, p: p, u: u), with: .color(gold))
            }
        }
    }

    // 11. Chef Toque (snug banded cuff & billowy cloud pouf inside safe top clearance)
    private static func drawChefHat(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let ivory = Color(hex: 0xFFFEFA)
        let cream = Color(hex: 0xF5EFE6)
        let shade = Color(hex: 0xD8D4E4)

        // Billowy 3-lobe cloud pouf (top cleanly at y = 12).
        var pouf = Path()
        pouf.move(to: p(69, 52))
        pouf.addCurve(to: p(74, 24), control1: p(57, 41), control2: p(60, 23))
        pouf.addCurve(to: p(100, 12), control1: p(80, 11), control2: p(92, 10))
        pouf.addCurve(to: p(126, 24), control1: p(108, 10), control2: p(120, 11))
        pouf.addCurve(to: p(131, 52), control1: p(140, 23), control2: p(143, 41))
        pouf.addQuadCurve(to: p(69, 52), control: p(100, 57))
        pouf.closeSubpath()

        context.fill(pouf, with: .linearGradient(
            Gradient(colors: [ivory, cream, shade]),
            startPoint: p(82, 14),
            endPoint: p(126, 56)
        ))
        context.stroke(pouf, with: .color(Storybook.ink.opacity(0.76)), style: stroke(u, width: 1.9))

        // Soft vertical gouache pleat folds.
        for dx in [CGFloat(-14), 0, 14] {
            var pleat = Path()
            pleat.move(to: p(100 + dx * 0.85, 50))
            pleat.addQuadCurve(to: p(100 + dx * 1.15, 29), control: p(100 + dx, 39))
            context.stroke(pleat, with: .color(Color(hex: 0xB9B5CC).opacity(0.72)), style: stroke(u, width: 1.6))
        }

        // Neatly structured headband cuff hugging Dewy's brow snugly.
        var cuff = Path()
        cuff.move(to: p(68, 51))
        cuff.addQuadCurve(to: p(132, 51), control: p(100, 45))
        cuff.addLine(to: p(134, 65))
        cuff.addQuadCurve(to: p(66, 65), control: p(100, 58))
        cuff.closeSubpath()

        context.fill(cuff, with: .linearGradient(
            Gradient(colors: [ivory, Color(hex: 0xEAE6F0)]),
            startPoint: p(100, 46),
            endPoint: p(100, 66)
        ))
        context.stroke(cuff, with: .color(Storybook.ink.opacity(0.78)), style: stroke(u, width: 1.9))

        var trim = Path()
        trim.move(to: p(68, 59))
        trim.addQuadCurve(to: p(132, 59), control: p(100, 53))
        context.stroke(trim, with: .color(Color(hex: 0xC4C0D4)), style: stroke(u, width: 1.4))
    }

    // 12. Knit Scarf (TRUE 2-Layer wrap lifted to y = 166...190, tails end cleanly by y = 210 above feet!)
    private static func drawScarf(
        layer: OutfitLayer,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat,
        sway: CGFloat
    ) {
        let coralLight = Color(hex: 0xFFB09E)
        let coralMid = Color(hex: 0xEB7764)
        let coralDeep = Color(hex: 0xBF4D42)
        let creamStripe = Color(hex: 0xFFF2DC)

        if layer == .back {
            // Back collar wrap hugging snugly behind Dewy's flanks (clearly above feet).
            var backWrap = Path()
            backWrap.move(to: p(30, 168))
            backWrap.addCurve(to: p(170, 168), control1: p(58, 154), control2: p(142, 154))
            backWrap.addCurve(to: p(167, 187), control1: p(175, 174), control2: p(173, 183))
            backWrap.addQuadCurve(to: p(33, 187), control: p(100, 195))
            backWrap.addCurve(to: p(30, 168), control1: p(27, 183), control2: p(25, 174))
            backWrap.closeSubpath()

            context.fill(backWrap, with: .color(coralDeep))
            context.stroke(backWrap, with: .color(Storybook.ink.opacity(0.78)), style: stroke(u, width: 2.0))
            return
        }

        // Front dangling fringed knit tails angled softly right, terminating cleanly by y = 209 above feet!
        let tailShift = sway * 13
        var backTail = Path()
        backTail.move(to: p(128, 180))
        backTail.addCurve(to: p(144 + tailShift * 0.7, 203), control1: p(134, 189), control2: p(140 + tailShift * 0.4, 196))
        backTail.addLine(to: p(158 + tailShift * 0.7, 199))
        backTail.addCurve(to: p(142, 176), control1: p(154 + tailShift * 0.4, 191), control2: p(148, 183))
        backTail.closeSubpath()

        context.fill(backTail, with: .linearGradient(
            Gradient(colors: [coralMid, coralDeep]),
            startPoint: p(134, 178),
            endPoint: p(150, 203)
        ))
        context.stroke(backTail, with: .color(Storybook.ink.opacity(0.78)), style: stroke(u, width: 1.75))

        // Main front dangling tail with cream stripe & dainty yarn fringe ending <= y = 209.
        var frontTail = Path()
        frontTail.move(to: p(118, 180))
        frontTail.addCurve(to: p(128 + tailShift, 204), control1: p(120, 190), control2: p(124 + tailShift * 0.5, 197))
        frontTail.addLine(to: p(146 + tailShift, 202))
        frontTail.addCurve(to: p(138, 178), control1: p(144 + tailShift * 0.5, 193), control2: p(142, 185))
        frontTail.closeSubpath()

        context.fill(frontTail, with: .linearGradient(
            Gradient(colors: [coralLight, coralMid]),
            startPoint: p(122, 179),
            endPoint: p(140, 204)
        ))
        context.drawLayer { clipped in
            clipped.clip(to: frontTail)
            var stripe = Path()
            stripe.move(to: p(116, 195))
            stripe.addLine(to: p(154 + tailShift, 193))
            clipped.stroke(stripe, with: .color(creamStripe), style: stroke(u, width: 4.8))
        }
        context.stroke(frontTail, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.85))

        // Dainty yarn fringes ending cleanly at y = 209 (never overlapping feet or lily pad!).
        for f in 0..<4 {
            let fx = 130 + CGFloat(f) * 4.8 + tailShift
            var fringe = Path()
            fringe.move(to: p(fx, 203.5))
            fringe.addLine(to: p(fx + sway * 3.5, 209))
            context.stroke(fringe, with: .color(creamStripe), style: stroke(u, width: 2.0))
            context.stroke(fringe, with: .color(Storybook.ink.opacity(0.55)), style: stroke(u, width: 0.85))
        }

        // Plush curved front neck-wrap nestled at y = 167...190 (below mouth, well above feet!).
        var collar = Path()
        collar.move(to: p(33, 168))
        collar.addQuadCurve(to: p(167, 168), control: p(100, 181))
        collar.addCurve(to: p(163, 186), control1: p(171, 175), control2: p(169, 182))
        collar.addQuadCurve(to: p(37, 186), control: p(100, 198))
        collar.addCurve(to: p(33, 168), control1: p(31, 182), control2: p(29, 175))
        collar.closeSubpath()

        context.fill(collar, with: .linearGradient(
            Gradient(colors: [coralLight, coralMid, coralDeep]),
            startPoint: p(100, 169),
            endPoint: p(100, 196)
        ))

        // Hand-knitted vertical stripes & yarn stitch ridges.
        context.drawLayer { clipped in
            clipped.clip(to: collar)
            for sx in [CGFloat(56), 92, 142] {
                var band = Path()
                band.move(to: p(sx, 165))
                band.addQuadCurve(to: p(sx + 2, 198), control: p(sx - 3, 182))
                clipped.stroke(band, with: .color(creamStripe.opacity(0.9)), style: stroke(u, width: 6.2))
            }
            for rx in stride(from: CGFloat(44), through: 156, by: 12) {
                var rib = Path()
                rib.move(to: p(rx, 170))
                rib.addLine(to: p(rx, 192))
                clipped.stroke(rib, with: .color(coralDeep.opacity(0.32)), style: stroke(u, width: 1.3))
            }
        }
        context.stroke(collar, with: .color(Storybook.ink.opacity(0.82)), style: stroke(u, width: 2.0))

        // Cozy tucked knot fold where tails emerge.
        let knot = oval(128, 180, 10.5, 8.2, p: p, u: u)
        context.fill(knot, with: .linearGradient(
            Gradient(colors: [coralLight, coralMid]),
            startPoint: p(124, 172),
            endPoint: p(134, 188)
        ))
        context.stroke(knot, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.8))
    }

    // 13. Bow Tie
    private static func drawBowTie(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let goldLight = Color(hex: 0xFFE68A)
        let goldMid = Color(hex: 0xF5BE41)
        let goldDeep = Color(hex: 0xCE8B22)
        let cream = Color(hex: 0xFFF9E6)

        // Subtle cast shadow on Dewy's belly.
        context.fill(oval(100, 188, 22, 6.5, p: p, u: u), with: .color(Storybook.ink.opacity(0.14)))

        var leftWing = Path()
        leftWing.move(to: p(96, 181))
        leftWing.addCurve(to: p(73, 173), control1: p(88, 174), control2: p(78, 170))
        leftWing.addCurve(to: p(73, 195), control1: p(69, 180), control2: p(69, 189))
        leftWing.addCurve(to: p(96, 187), control1: p(78, 198), control2: p(88, 194))
        leftWing.closeSubpath()

        var rightWing = Path()
        rightWing.move(to: p(104, 181))
        rightWing.addCurve(to: p(127, 173), control1: p(112, 174), control2: p(122, 170))
        rightWing.addCurve(to: p(127, 195), control1: p(131, 180), control2: p(131, 189))
        rightWing.addCurve(to: p(104, 187), control1: p(122, 198), control2: p(112, 194))
        rightWing.closeSubpath()

        for wing in [leftWing, rightWing] {
            context.fill(wing, with: .linearGradient(
                Gradient(colors: [goldLight, goldMid, goldDeep]),
                startPoint: p(100, 172),
                endPoint: p(100, 196)
            ))
            context.stroke(wing, with: .color(Storybook.ink.opacity(0.82)), style: stroke(u, width: 1.85))
        }

        // Cream polka dots + subtle silk crease lines.
        for dot in [(CGFloat(81), CGFloat(180)), (86, 188), (119, 180), (114, 188)] {
            context.fill(oval(dot.0, dot.1, 2.0, 2.0, p: p, u: u), with: .color(cream.opacity(0.88)))
        }
        var creaseL = Path()
        creaseL.move(to: p(94, 184))
        creaseL.addLine(to: p(84, 184))
        var creaseR = Path()
        creaseR.move(to: p(106, 184))
        creaseR.addLine(to: p(116, 184))
        context.stroke(creaseL, with: .color(goldDeep.opacity(0.65)), style: stroke(u, width: 1.4))
        context.stroke(creaseR, with: .color(goldDeep.opacity(0.65)), style: stroke(u, width: 1.4))

        // Rounded central knot.
        let knot = Path(roundedRect: CGRect(x: p(94.5, 177.5).x, y: p(94.5, 177.5).y, width: 11 * u, height: 13 * u), cornerRadius: 4.5 * u)
        context.fill(knot, with: .linearGradient(
            Gradient(colors: [goldLight, goldMid]),
            startPoint: p(100, 177),
            endPoint: p(100, 191)
        ))
        context.stroke(knot, with: .color(Storybook.ink.opacity(0.84)), style: stroke(u, width: 1.85))
    }

    // 14. Leaf Hat (2-Layer Ghibli-inspired dewy lotus leaf cap)
    private static func drawLeafHat(
        layer: OutfitLayer,
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        u: CGFloat
    ) {
        let leafLight = Color(hex: 0xA8DF96)
        let leafMid = Color(hex: 0x69B46E)
        let leafDeep = Color(hex: 0x3D7E4E)
        let vein = Color(hex: 0xDAF4C4)

        context.drawLayer { ctx in
            let pivot = p(102, 52)
            ctx.translateBy(x: pivot.x, y: pivot.y)
            ctx.rotate(by: .degrees(5))
            ctx.translateBy(x: -pivot.x, y: -pivot.y)

            if layer == .back {
                let backRim = oval(100, 56, 60, 15, p: p, u: u)
                ctx.fill(backRim, with: .color(leafDeep))
                ctx.stroke(backRim, with: .color(Storybook.ink.opacity(0.76)), style: stroke(u, width: 1.8))
                return
            }

            // Organic scalloped lotus-leaf canopy perched on Dewy's head.
            var leaf = Path()
            leaf.move(to: p(38, 56))
            leaf.addCurve(to: p(100, 32), control1: p(42, 34), control2: p(72, 30))
            leaf.addCurve(to: p(162, 54), control1: p(128, 30), control2: p(158, 34))
            // Little natural botanical notch on right edge.
            leaf.addLine(to: p(146, 56))
            leaf.addLine(to: p(156, 62))
            leaf.addCurve(to: p(38, 56), control1: p(126, 72), control2: p(66, 72))
            leaf.closeSubpath()

            ctx.fill(leaf, with: .linearGradient(
                Gradient(colors: [leafLight, leafMid, leafDeep]),
                startPoint: p(66, 30),
                endPoint: p(142, 68)
            ))
            ctx.stroke(leaf, with: .color(Storybook.ink.opacity(0.8)), style: stroke(u, width: 1.9))

            // Delicate radiating botanical veins.
            let spokes: [(CGFloat, CGFloat)] = [(52, 54), (72, 60), (100, 62), (128, 58), (144, 48)]
            for end in spokes {
                var rib = Path()
                rib.move(to: p(100, 42))
                rib.addQuadCurve(to: p(end.0, end.1), control: p((100 + end.0) * 0.5, 48))
                ctx.stroke(rib, with: .color(vein.opacity(0.72)), style: stroke(u, width: 1.5))
            }

            // Charming curled stem rising from the center of the leaf.
            var stem = Path()
            stem.move(to: p(100, 42))
            stem.addCurve(to: p(114, 20), control1: p(98, 28), control2: p(106, 18))
            stem.addQuadCurve(to: p(120, 26), control: p(119, 20))
            ctx.stroke(stem, with: .color(leafDeep), style: stroke(u, width: 4.0))
            ctx.stroke(stem, with: .color(Storybook.ink.opacity(0.78)), style: stroke(u, width: 1.5))

            // One glistening painted dewdrop resting on the leaf slope.
            let drop = oval(74, 46, 5.2, 4.0, p: p, u: u)
            ctx.fill(drop, with: .color(Color(hex: 0xD2F6FA).opacity(0.92)))
            ctx.stroke(drop, with: .color(Storybook.ink.opacity(0.55)), style: stroke(u, width: 1.1))
            ctx.fill(oval(72.5, 44.8, 1.8, 1.3, p: p, u: u), with: .color(.white))
        }
    }
}
