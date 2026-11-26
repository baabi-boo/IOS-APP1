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

    /// The chubby jelly droplet with a playful curl at the tip.
    static func body(_ p: (CGFloat, CGFloat) -> CGPoint) -> Path {
        var path = Path()
        path.move(to: p(88, 36))
        path.addCurve(to: p(124, 6), control1: p(92, 18), control2: p(106, 4))
        path.addCurve(to: p(113, 38), control1: p(117, 13), control2: p(111, 24))
        path.addCurve(to: p(170, 110), control1: p(128, 62), control2: p(162, 80))
        path.addCurve(to: p(160, 196), control1: p(182, 140), control2: p(180, 176))
        path.addCurve(to: p(100, 218), control1: p(144, 212), control2: p(124, 218))
        path.addCurve(to: p(40, 196), control1: p(76, 218), control2: p(56, 212))
        path.addCurve(to: p(30, 110), control1: p(20, 176), control2: p(18, 140))
        path.addCurve(to: p(88, 36), control1: p(38, 80), control2: p(72, 60))
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
    func path(in rect: CGRect) -> Path {
        let u = rect.width / DewyGeometry.canvas.width
        return DewyGeometry.body { x, y in CGPoint(x: rect.minX + (x + 10) * u, y: rect.minY + (y + 10) * u) }
    }
}

// MARK: - Mascot

private struct Squish {
    var x: CGFloat = 1
    var y: CGFloat = 1
    var lift: CGFloat = 0
}

/// Dewy — a translucent aqua jelly droplet that fills up with a layer for every drink.
///
/// Built in layers so only what moves is redrawn each frame: the jelly material and its
/// highlights are static views, while the liquid, limbs and face are small canvases.
struct MascotView: View {
    var progress: Double
    var mood: DewyMood
    /// Width of the whole figure in points.
    var size: CGFloat = 220
    var bounceTrigger: Int = 0
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

    @Environment(\.dewyTheme) private var theme
    @Environment(\.dewySlosh) private var slosh
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var level: Double = 0
    @State private var waveStart: Date?

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
                    figure(time: isLive ? now.timeIntervalSinceReferenceDate : 0.6, wave: waveAmount(at: now))
                }
            } else {
                // Decorative and widget mascots are a single still frame: no timeline at all.
                figure(time: 0.6, wave: 0)
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
        .accessibilityElement()
        .accessibilityLabel("Dewy is \(mood.rawValue), \(Int(progress * 100)) percent of today's goal")
    }

    private func figure(time t: Double, wave: Double) -> some View {
        let u = size / DewyGeometry.canvas.width
        let tilt = isLive ? (slosh?.angle ?? 0) : 0
        let chop = isLive ? (slosh?.energy ?? 0) : 0
        let twinkles = sparkles || mood == .ecstatic
        return ZStack(alignment: .topLeading) {
            if showsShadow {
                Ellipse()
                    .fill(Color(hex: 0x2E6E86).opacity(backdrop == .light ? 0.12 : 0.2))
                    .frame(width: (112 - CGFloat(sin(t * 2.2)) * 4) * u, height: 14 * u)
                    .blur(radius: 4 * u)
                    .position(x: 110 * u, y: 236 * u)
            }

            MascotLimbs(time: t, wave: wave, onLight: backdrop == .light)

            JellyBack(u: u, onLight: backdrop == .light)

            MascotLiquid(level: animated ? level : targetLevel, bands: resolvedBands, time: t, tilt: tilt, chop: chop + wave * 0.6)
                .clipShape(DewyCanvasShape())

            JellyFront(u: u)

            MascotFace(mood: mood, time: t, blinks: isLive && (!LaunchOptions.isDemo || LaunchOptions.screenshot == "celebrate"), hidesEyes: outfits.contains(.sunglasses))

            ForEach(outfits) { outfit in
                OutfitImage(outfit: outfit, u: u)
            }

            if twinkles {
                MascotSparkles(time: t)
            }
        }
        .frame(width: size, height: height, alignment: .topLeading)
        .scaleEffect(x: breath(t, by: -0.01), y: breath(t, by: 0.016), anchor: .bottom)
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
                    CubicKeyframe(1.14, duration: 0.12)
                    SpringKeyframe(0.94, duration: 0.2)
                    SpringKeyframe(1.0, duration: 0.55, spring: .bouncy)
                }
                KeyframeTrack(\.y) {
                    CubicKeyframe(0.86, duration: 0.12)
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

// MARK: - Jelly material

private enum Jelly {
    static let core = Color(hex: 0xE6FCFC)
    static let mid = Color(hex: 0xADEDF1)
    static let edge = Color(hex: 0x6CD1DE)
    static let deep = Color(hex: 0x37A9C2)
    static let limbTop = Color(hex: 0xCBF5F6)
    static let limbBottom = Color(hex: 0x7DD6E2)
}

/// The jelly body behind the liquid: a translucent aqua with a lit core.
private struct JellyBack: View {
    var u: CGFloat
    var onLight: Bool

    var body: some View {
        DewyCanvasShape()
            .fill(RadialGradient(
                stops: [
                    .init(color: Jelly.core, location: 0),
                    .init(color: Jelly.mid, location: 0.55),
                    .init(color: Jelly.edge, location: 1)
                ],
                center: UnitPoint(x: 0.4, y: 0.42),
                startRadius: 0,
                endRadius: 118 * u
            ))
            .opacity(0.94)
            .overlay {
                if onLight {
                    DewyCanvasShape().stroke(Jelly.deep.opacity(0.25), lineWidth: 1.5 * u)
                }
            }
    }
}

/// Everything that makes the jelly read as a soft 3D object, drawn over the liquid:
/// a blurred inner rim, light passing through the bottom, a big soft highlight and crisp glints.
private struct JellyFront: View {
    var u: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Thick wall: a blurred inner rim in deeper aqua.
            DewyCanvasShape()
                .stroke(Jelly.deep.opacity(0.55), lineWidth: 14 * u)
                .blur(radius: 7 * u)
                .clipShape(DewyCanvasShape())

            // Light scattering out through the bottom of the jelly.
            Ellipse()
                .fill(Color.white.opacity(0.38))
                .frame(width: 90 * u, height: 26 * u)
                .blur(radius: 9 * u)
                .position(x: 110 * u, y: 212 * u)
                .clipShape(DewyCanvasShape())

            // Big soft highlight, upper left.
            Ellipse()
                .fill(Color.white.opacity(0.6))
                .frame(width: 34 * u, height: 64 * u)
                .rotationEffect(.degrees(28))
                .blur(radius: 6 * u)
                .position(x: 66 * u, y: 104 * u)
                .clipShape(DewyCanvasShape())

            // Crisp glints.
            Canvas { context, size in
                let s = size.width / DewyGeometry.canvas.width
                func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: (x + 10) * s, y: (y + 10) * s) }
                var gloss = Path()
                gloss.move(to: p(48, 120))
                gloss.addCurve(to: p(84, 62), control1: p(50, 98), control2: p(64, 76))
                context.stroke(gloss, with: .color(.white.opacity(0.92)), style: StrokeStyle(lineWidth: 7 * s, lineCap: .round))
                context.fill(Path(ellipseIn: CGRect(x: p(41, 134).x, y: p(41, 134).y, width: 7 * s, height: 7 * s)), with: .color(.white.opacity(0.9)))
                // Shine on the curl.
                var curl = Path()
                curl.move(to: p(100, 26))
                curl.addQuadCurve(to: p(116, 12), control: p(104, 16))
                context.stroke(curl, with: .color(.white.opacity(0.85)), style: StrokeStyle(lineWidth: 3.5 * s, lineCap: .round))
                // Rim light on the right.
                var rim = Path()
                rim.move(to: p(158, 104))
                rim.addCurve(to: p(158, 184), control1: p(174, 128), control2: p(174, 164))
                context.stroke(rim, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 3 * s, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Limbs

/// Little jelly feet and arms. The right arm waves after a tap.
private struct MascotLimbs: View {
    var time: Double
    var wave: Double
    var onLight: Bool

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: (x + 10) * u, y: (y + 10) * u) }
            let fill = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Jelly.limbTop, Jelly.limbBottom]),
                startPoint: p(0, 120), endPoint: p(0, 230)
            )

            // Feet
            for x in [CGFloat(76), 124] {
                let foot = Path(ellipseIn: CGRect(x: p(x - 17, 204).x, y: p(x - 17, 204).y, width: 34 * u, height: 20 * u))
                context.fill(foot, with: fill)
                context.fill(Path(ellipseIn: CGRect(x: p(x - 9, 207).x, y: p(x - 9, 207).y, width: 10 * u, height: 5 * u)), with: .color(.white.opacity(0.7)))
            }

            // Arms
            let sway: Double = sin(time * 1.6) * 0.06
            let degree: Double = .pi / 180
            context.fill(arm(center: p(28, 150), radians: 30 * degree + sway, u: u), with: fill)
            let w = CGFloat(wave)
            let rest = p(172, 150)
            let up = p(182, 112)
            let center = CGPoint(x: rest.x + (up.x - rest.x) * w, y: rest.y + (up.y - rest.y) * w)
            let flap: Double = 56 + sin(time * 16) * 14
            context.fill(arm(center: center, radians: (flap * wave - 30) * degree - sway, u: u), with: fill)
        }
        .allowsHitTesting(false)
    }

    private func arm(center: CGPoint, radians: Double, u: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: -12 * u, y: -17 * u, width: 24 * u, height: 34 * u))
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .applying(CGAffineTransform(translationX: center.x, y: center.y))
    }
}

// MARK: - Liquid

/// The layered drinks inside Dewy. Animatable on `level`, so a spring pours a new layer in
/// while the timeline keeps the surface rolling. The surface leans with `tilt`.
private struct MascotLiquid: View, Animatable {
    var level: Double
    var bands: [LiquidBand]
    var time: Double
    var tilt: Double
    var chop: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: (x + 10) * u, y: (y + 10) * u) }
            drawLiquid(in: &context, p: p, u: u)
            drawBubbles(in: &context, p: p, u: u)
        }
        .allowsHitTesting(false)
    }

    private var slope: CGFloat { CGFloat(max(min(tan(tilt), 0.7), -0.7)) }

    private func surfaceY(level: Double, x: CGFloat, amplitude: CGFloat, phase: Double, leans: Bool) -> CGFloat {
        let base = DewyGeometry.bodyBottom - CGFloat(level) * (DewyGeometry.bodyBottom - DewyGeometry.bodyTop)
        let lean = leans ? (x - 100) * slope : 0
        return base + lean + amplitude * CGFloat(sin(Double(x / 200) * .pi * 2.4 + phase))
    }

    private func wavePath(level: Double, amplitude: CGFloat, phase: Double, leans: Bool, p: (CGFloat, CGFloat) -> CGPoint, closed: Bool) -> Path {
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
        let amp = CGFloat(4.5 + chop * 7)

        // A paler back wave behind the surface adds depth.
        context.fill(
            wavePath(level: level + 0.012, amplitude: amp * 0.9, phase: time * 1.7 + 2.4, leans: true, p: p, closed: true),
            with: .color(bands[surface].color.blended(with: .white, by: 0.45).opacity(0.75))
        )

        for index in stride(from: surface, through: 0, by: -1) {
            let isSurface = index == surface
            let top = isSurface ? level : bands[index].upTo
            guard top > 0.001 else { continue }
            let amplitude: CGFloat = isSurface ? amp : 2.2
            let phase = isSurface ? time * 2.3 + 0.4 : time * 0.6 + Double(index) * 1.9
            let color = bands[index].color
            let fillPath = wavePath(level: top, amplitude: amplitude, phase: phase, leans: isSurface, p: p, closed: true)
            context.fill(fillPath, with: .linearGradient(
                Gradient(colors: [color.blended(with: .white, by: 0.2), color]),
                startPoint: p(0, surfaceY(level: top, x: 100, amplitude: 0, phase: 0, leans: false)),
                endPoint: p(0, 220)
            ))
            // A creamy light band along each layer's top, like the clay mockups.
            context.stroke(
                wavePath(level: top - 0.012, amplitude: amplitude, phase: phase, leans: isSurface, p: p, closed: false),
                with: .color(color.blended(with: .white, by: 0.55).opacity(0.9)),
                lineWidth: (isSurface ? 6 : 3.5) * u
            )
            context.stroke(
                wavePath(level: top, amplitude: amplitude, phase: phase, leans: isSurface, p: p, closed: false),
                with: .color(.white.opacity(isSurface ? 0.8 : 0.45)),
                lineWidth: 1.6 * u
            )
        }
    }

    private func drawBubbles(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let surface = DewyGeometry.bodyBottom - CGFloat(level) * (DewyGeometry.bodyBottom - DewyGeometry.bodyTop)
        let column = Double(DewyGeometry.bodyBottom - surface)
        guard column > 14 else { return }
        for index in 0..<7 {
            let seed = Double(index)
            let x0 = 56 + 88 * fract(sin(seed * 12.9898) * 43758.5453)
            let radius = 2 + 2.4 * fract(sin(seed * 78.233) * 12543.21)
            let speed = 12 + 16 * fract(sin(seed * 39.425) * 9631.7)
            let travel = (time * speed + seed * 97).truncatingRemainder(dividingBy: column)
            let y = Double(DewyGeometry.bodyBottom) - travel
            guard y > Double(surface) + radius + 6 else { continue }
            let x = x0 + sin(time * 2.3 + seed) * 2.5
            let fade = min(1, (y - Double(surface)) / 20)
            let center = p(CGFloat(x), CGFloat(y))
            let rect = CGRect(x: center.x - CGFloat(radius) * u, y: center.y - CGFloat(radius) * u, width: CGFloat(radius * 2) * u, height: CGFloat(radius * 2) * u)
            context.opacity = fade
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.35)))
            context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.9)), lineWidth: 1 * u)
            context.opacity = 1
        }
    }

    private func fract(_ value: Double) -> Double { value - floor(value) }
}

// MARK: - Face

/// Big glossy eyes with sparkle highlights, blurred blush and a tiny mouth.
private struct MascotFace: View {
    var mood: DewyMood
    var time: Double
    var blinks: Bool
    var hidesEyes: Bool

    private static let ink = Color(hex: 0x2B1F36)
    private static let inkTop = Color(hex: 0x15101C)
    private static let inkBottom = Color(hex: 0x4B3A5C)

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: (x + 10) * u, y: (y + 10) * u) }
            func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: (cx - rx + 10) * u, y: (cy - ry + 10) * u, width: rx * 2 * u, height: ry * 2 * u))
            }

            // Blush, softly blurred.
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 3.2 * u))
                layer.fill(ellipse(55, 156, 14, 8.5), with: .color(Color(hex: 0xFF8FB3).opacity(0.62)))
                layer.fill(ellipse(145, 156, 14, 8.5), with: .color(Color(hex: 0xFF8FB3).opacity(0.62)))
            }

            let ey: CGFloat = 134
            let eyes: [CGFloat] = [76, 124]
            let cycle = time.truncatingRemainder(dividingBy: 4.6)
            let openness: CGFloat = blinks && cycle < 0.16 ? max(0.08, CGFloat(abs(cycle - 0.08) / 0.08)) : 1

            if !hidesEyes {
                for ex in eyes {
                    switch mood {
                    case .ecstatic:
                        // Happy closed eyes: ^ ^
                        var arc = Path()
                        arc.move(to: p(ex - 11, ey + 4))
                        arc.addQuadCurve(to: p(ex + 11, ey + 4), control: p(ex, ey - 12))
                        context.stroke(arc, with: .color(Self.ink), style: StrokeStyle(lineWidth: 5.5 * u, lineCap: .round))
                    case .thirsty:
                        drawEye(in: &context, center: CGPoint(x: ex, y: ey + 3), rx: 10.5, ry: 11.5 * openness, u: u, ellipse: ellipse, sparkle: false)
                    case .okay, .happy:
                        drawEye(in: &context, center: CGPoint(x: ex, y: ey), rx: 12.5, ry: 15.5 * openness, u: u, ellipse: ellipse, sparkle: true)
                    }
                }
            }

            if mood == .thirsty {
                // Worried brows and a tiny sweat drop.
                for (outer, inner) in [(CGFloat(64), CGFloat(84)), (136, 116)] {
                    var brow = Path()
                    brow.move(to: p(outer, 116))
                    brow.addLine(to: p(inner, 111))
                    context.stroke(brow, with: .color(Self.ink.opacity(0.85)), style: StrokeStyle(lineWidth: 3.6 * u, lineCap: .round))
                }
                let drop = DewyShape().path(in: CGRect(x: p(150, 96).x, y: p(150, 96).y, width: 11 * u, height: 15 * u))
                context.fill(drop, with: .color(Color(hex: 0x9EE2F5)))
                context.fill(Path(ellipseIn: CGRect(x: p(152.5, 104).x, y: p(152.5, 104).y, width: 3 * u, height: 4 * u)), with: .color(.white))
            }

            // Mouth
            switch mood {
            case .thirsty:
                var mouth = Path()
                mouth.move(to: p(94, 160))
                mouth.addQuadCurve(to: p(106, 160), control: p(100, 154))
                context.stroke(mouth, with: .color(Self.ink), style: StrokeStyle(lineWidth: 3.6 * u, lineCap: .round))
            case .okay:
                // A little cat smile: w
                var mouth = Path()
                mouth.move(to: p(91, 153))
                mouth.addQuadCurve(to: p(100, 155), control: p(95, 160))
                mouth.addQuadCurve(to: p(109, 153), control: p(105, 160))
                context.stroke(mouth, with: .color(Self.ink), style: StrokeStyle(lineWidth: 3.6 * u, lineCap: .round, lineJoin: .round))
            case .happy, .ecstatic:
                let half: CGFloat = mood == .ecstatic ? 10 : 7.5
                let depth: CGFloat = mood == .ecstatic ? 15 : 10
                var mouth = Path()
                mouth.move(to: p(100 - half, 151))
                mouth.addQuadCurve(to: p(100 + half, 151), control: p(100, 149))
                mouth.addQuadCurve(to: p(100, 151 + depth), control: p(100 + half - 0.5, 151 + depth))
                mouth.addQuadCurve(to: p(100 - half, 151), control: p(100 - half + 0.5, 151 + depth))
                mouth.closeSubpath()
                context.fill(mouth, with: .color(Color(hex: 0x6A2B4E)))
                context.drawLayer { layer in
                    layer.clip(to: mouth)
                    layer.fill(ellipse(100, 151 + depth * 0.9, half * 0.7, depth * 0.36), with: .color(Color(hex: 0xFF8FAE)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawEye(
        in context: inout GraphicsContext,
        center: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        u: CGFloat,
        ellipse: (CGFloat, CGFloat, CGFloat, CGFloat) -> Path,
        sparkle: Bool
    ) {
        let eye = ellipse(center.x, center.y, rx, ry)
        let top = CGPoint(x: (center.x + 10) * u, y: (center.y - ry + 10) * u)
        let bottom = CGPoint(x: (center.x + 10) * u, y: (center.y + ry + 10) * u)
        context.fill(eye, with: .linearGradient(Gradient(colors: [Self.inkTop, Self.inkBottom]), startPoint: top, endPoint: bottom))
        guard ry > rx * 0.55 else { return }
        // Glossy reflection along the bottom.
        context.drawLayer { layer in
            layer.clip(to: eye)
            layer.fill(ellipse(center.x + 1, center.y + ry * 0.75, rx * 0.8, ry * 0.4), with: .color(Color(hex: 0x8A74A0).opacity(0.55)))
        }
        // Big catchlight, a small one, and a twinkle.
        context.fill(ellipse(center.x - rx * 0.32, center.y - ry * 0.38, rx * 0.42, ry * 0.36), with: .color(.white))
        context.fill(ellipse(center.x + rx * 0.38, center.y + ry * 0.36, rx * 0.17, rx * 0.17), with: .color(.white.opacity(0.95)))
        if sparkle {
            let s = rx * 0.62 * u
            let c = CGPoint(x: (center.x + rx * 0.42 + 10) * u, y: (center.y - ry * 0.46 + 10) * u)
            context.fill(SparkleShape().path(in: CGRect(x: c.x - s / 2, y: c.y - s / 2, width: s, height: s)), with: .color(.white))
        }
    }
}

// MARK: - Outfits

/// One wardrobe item placed on Dewy from its design-box placement.
private struct OutfitImage: View {
    var outfit: Outfit
    var u: CGFloat

    var body: some View {
        if Art.exists(outfit.imageName) {
            let placement = outfit.placement
            Image(outfit.imageName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: placement.width * u)
                .rotationEffect(.degrees(placement.rotation))
                .shadow(color: Color(hex: 0x2E6E86).opacity(0.18), radius: 3 * u, x: 0, y: 2 * u)
                .position(x: (placement.x + 10) * u, y: (placement.y + 10) * u)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Sparkles

private struct MascotSparkles: View {
    var time: Double

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            let spots: [(CGFloat, CGFloat, CGFloat, Double)] = [(-4, 70, 24, 0), (198, 90, 20, 1.3), (186, 30, 14, 2.4), (6, 178, 14, 3.1)]
            for (index, spot) in spots.enumerated() {
                let pulse = 0.55 + 0.45 * sin(time * 3 + spot.3)
                let s = spot.2 * u * CGFloat(pulse)
                let c = CGPoint(x: (spot.0 + 10) * u, y: (spot.1 + 10) * u)
                context.opacity = 0.55 + pulse * 0.45
                context.fill(SparkleShape().path(in: CGRect(x: c.x - s / 2, y: c.y - s / 2, width: s, height: s)), with: .color(index.isMultiple(of: 2) ? Palette.butter : .white))
                context.opacity = 1
            }
        }
        .allowsHitTesting(false)
    }
}
