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

/// Little extras Dewy and friends can wear.
enum MascotAccessory {
    case none, sparkles, crown, sunglasses, sprout, bow, hearts, snowflakes, nightcap, flame, star
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

// MARK: - Geometry

/// Dewy is drawn in a 200×220 design box (the same numbers as the SVG sources in `design/`).
/// The canvas adds a 10-point margin around it for the arms, accessories and shadow.
enum DewyGeometry {
    /// Width and height of the canvas in design units.
    static let canvas = CGSize(width: 220, height: 250)
    /// Bottom and top of the body, where the liquid goes from empty to full.
    static let bodyBottom: CGFloat = 216
    static let bodyTop: CGFloat = 10

    /// The chubby droplet with its little flick at the tip.
    static func body(_ p: (CGFloat, CGFloat) -> CGPoint) -> Path {
        var path = Path()
        path.move(to: p(92, 30))
        path.addCurve(to: p(120, 10), control1: p(96, 18), control2: p(106, 10))
        path.addCurve(to: p(114, 36), control1: p(114, 16), control2: p(110, 24))
        path.addCurve(to: p(168, 100), control1: p(124, 58), control2: p(154, 72))
        path.addCurve(to: p(168, 184), control1: p(182, 124), control2: p(182, 162))
        path.addCurve(to: p(100, 216), control1: p(152, 208), control2: p(128, 216))
        path.addCurve(to: p(32, 184), control1: p(72, 216), control2: p(48, 208))
        path.addCurve(to: p(32, 98), control1: p(18, 162), control2: p(18, 122))
        path.addCurve(to: p(92, 30), control1: p(48, 68), control2: p(84, 52))
        path.closeSubpath()
        return path
    }
}

/// Dewy's silhouette, stretched to fill a rect. Handy for progress glyphs and clipping.
struct DewyShape: Shape {
    func path(in rect: CGRect) -> Path {
        DewyGeometry.body { x, y in
            CGPoint(x: rect.minX + (x - 18) / 164 * rect.width, y: rect.minY + (y - 10) / 206 * rect.height)
        }
    }
}

// MARK: - Mascot

private struct Squish {
    var x: CGFloat = 1
    var y: CGFloat = 1
    var lift: CGFloat = 0
}

/// Dewy — a glassy droplet buddy that fills up with a layer for every drink.
struct MascotView: View {
    var progress: Double
    var mood: DewyMood
    /// Width of the whole figure in points.
    var size: CGFloat = 220
    var bounceTrigger: Int = 0
    var accessory: MascotAccessory = .none
    /// Layers to stack, oldest first. Empty means a single layer of `liquid`.
    var bands: [LiquidBand] = []
    var liquid: Color?
    var backdrop: MascotBackdrop = .color
    /// Set to `false` for small decorative mascots to save rendering work.
    var animated = true
    var showsShadow = true

    @Environment(\.dewyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var level: Double = 0
    @State private var waveStart: Date?

    private var height: CGFloat { size * DewyGeometry.canvas.height / DewyGeometry.canvas.width }

    /// Overflowing days squeeze every layer into a full droplet.
    private var overflowScale: Double { max(progress, 1) }

    private func visualLevel(_ fraction: Double) -> Double {
        0.05 + 0.86 * min(max(fraction / overflowScale, 0), 1)
    }

    private var targetLevel: Double { visualLevel(progress) }

    private var resolvedBands: [LiquidBand] {
        guard !bands.isEmpty else {
            return [LiquidBand(color: liquid ?? theme.water, upTo: targetLevel)]
        }
        return bands.map { LiquidBand(color: $0.color, upTo: visualLevel($0.upTo)) }
    }

    private var isLive: Bool { animated && !reduceMotion }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isLive)) { timeline in
            let now = timeline.date
            let t = isLive ? now.timeIntervalSinceReferenceDate : 0.6
            let wave = waveAmount(at: now)
            MascotCanvas(
                level: animated ? level : targetLevel,
                bands: resolvedBands,
                mood: mood,
                time: t,
                accessory: accessory,
                backdrop: backdrop,
                wave: wave,
                blinks: isLive && (!LaunchOptions.isDemo || LaunchOptions.screenshot == "celebrate"),
                showsShadow: showsShadow
            )
            .frame(width: size, height: height)
            .scaleEffect(x: 1 - CGFloat(sin(t * 2.2)) * 0.008, y: 1 + CGFloat(sin(t * 2.2)) * 0.014, anchor: .bottom)
        }
        .frame(width: size, height: height)
        .keyframeAnimator(initialValue: Squish(), trigger: bounceTrigger) { content, value in
            content
                .scaleEffect(x: value.x, y: value.y, anchor: .bottom)
                .offset(y: value.lift)
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                CubicKeyframe(1.12, duration: 0.12)
                SpringKeyframe(0.95, duration: 0.2)
                SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
            }
            KeyframeTrack(\.y) {
                CubicKeyframe(0.88, duration: 0.12)
                SpringKeyframe(1.07, duration: 0.2)
                SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
            }
            KeyframeTrack(\.lift) {
                CubicKeyframe(0, duration: 0.12)
                SpringKeyframe(-size * 0.08, duration: 0.2)
                SpringKeyframe(0, duration: 0.5, spring: .bouncy)
            }
        }
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

// MARK: - Drawing

/// Draws the whole character in one Canvas. Animatable on `level`, so a spring can pour
/// a new layer in while the `TimelineView` keeps the surface rolling.
private struct MascotCanvas: View, Animatable {
    var level: Double
    var bands: [LiquidBand]
    var mood: DewyMood
    var time: Double
    var accessory: MascotAccessory
    var backdrop: MascotBackdrop
    var wave: Double
    var blinks: Bool
    var showsShadow: Bool

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    private static let ink = Color(hex: 0x2A2350)

    var body: some View {
        Canvas { context, size in
            let u = size.width / DewyGeometry.canvas.width
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: (x + 10) * u, y: (y + 10) * u) }
            func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: (cx - rx + 10) * u, y: (cy - ry + 10) * u, width: rx * 2 * u, height: ry * 2 * u))
            }

            let onLight = backdrop == .light
            let limb = onLight ? Color(hex: 0xCDE8FF) : Color(hex: 0xF6FBFF)
            let limbShade = onLight ? Color(hex: 0xA5D3FA) : Color(hex: 0xD3E9FA)
            let glassTint = onLight ? Color(hex: 0xE6F1FB) : Color(hex: 0xEAF6FF)

            // Ground shadow
            if showsShadow {
                let bob = CGFloat(sin(time * 2.2))
                context.fill(
                    ellipse(100, 228, 58 - bob * 2, 8),
                    with: .color(onLight ? Self.ink.opacity(0.08) : Color(hex: 0x0B3B7A).opacity(0.16))
                )
            }

            // Feet
            context.fill(ellipse(78, 214, 17, 9), with: .color(limbShade))
            context.fill(ellipse(122, 214, 17, 9), with: .color(limbShade))

            // Arms: the right one waves after a tap.
            let sway = sin(time * 1.6) * 0.05
            let leftArm = armPath(center: p(26, 150), radians: 28 * .pi / 180 + sway, u: u)
            context.fill(leftArm, with: .color(limb))
            let w = CGFloat(wave)
            let rightCenter = CGPoint(x: p(174, 150).x + (p(182, 116).x - p(174, 150).x) * w,
                                      y: p(174, 150).y + (p(182, 116).y - p(174, 150).y) * w)
            let rightAngle = (-28 + (54 + sin(time * 16) * 14) * Double(w)) * .pi / 180 - sway
            context.fill(armPath(center: rightCenter, radians: rightAngle, u: u), with: .color(limb))

            // Glass body
            let body = DewyGeometry.body(p)
            context.fill(body, with: .linearGradient(
                Gradient(colors: [.white, glassTint]),
                startPoint: p(100, 10), endPoint: p(100, 216)
            ))

            // Liquid, bubbles and shading live inside the glass.
            context.drawLayer { layer in
                layer.clip(to: body)
                drawLiquid(in: &layer, p: p)
                drawBubbles(in: &layer, p: p, u: u)
                layer.fill(body, with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color(hex: 0x1D2A6B).opacity(0), location: 0.55),
                        .init(color: Color(hex: 0x1D2A6B).opacity(0.2), location: 1)
                    ]),
                    center: p(80, 92), startRadius: 0, endRadius: 150 * u
                ))
                var rim = Path()
                rim.move(to: p(150, 86))
                rim.addCurve(to: p(156, 186), control1: p(172, 112), control2: p(176, 156))
                layer.stroke(rim, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 5 * u, lineCap: .round))
            }

            if onLight {
                context.stroke(body, with: .color(Self.ink.opacity(0.08)), lineWidth: 2 * u)
            }

            // Gloss
            var gloss = Path()
            gloss.move(to: p(58, 92))
            gloss.addCurve(to: p(92, 52), control1: p(66, 76), control2: p(80, 62))
            context.stroke(gloss, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 9 * u, lineCap: .round))
            context.fill(ellipse(48, 112, 4.5, 4.5), with: .color(.white.opacity(0.9)))

            drawFace(in: &context, p: p, ellipse: ellipse, u: u)
            drawAccessory(in: &context, p: p, ellipse: ellipse, u: u)
        }
        .allowsHitTesting(false)
    }

    private func armPath(center: CGPoint, radians: Double, u: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: -11 * u, y: -15 * u, width: 22 * u, height: 30 * u))
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .applying(CGAffineTransform(translationX: center.x, y: center.y))
    }

    // MARK: Liquid

    private func wavePath(level: Double, amplitude: CGFloat, phase: Double, p: (CGFloat, CGFloat) -> CGPoint, closed: Bool) -> Path {
        let base = DewyGeometry.bodyBottom - CGFloat(level) * (DewyGeometry.bodyBottom - DewyGeometry.bodyTop)
        var path = Path()
        var x: CGFloat = 0
        var first = true
        if closed {
            path.move(to: p(0, 240))
            first = false
        }
        while x <= 200 {
            let y = base + amplitude * CGFloat(sin(Double(x / 200) * .pi * 2.5 + phase))
            if first {
                path.move(to: p(x, y))
                first = false
            } else {
                path.addLine(to: p(x, y))
            }
            x += 4
        }
        if closed {
            path.addLine(to: p(200, 240))
            path.closeSubpath()
        }
        return path
    }

    private func drawLiquid(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint) {
        guard !bands.isEmpty else { return }
        let surface = bands.firstIndex { $0.upTo >= level - 0.0005 } ?? (bands.count - 1)
        let u = p(1, 0).x - p(0, 0).x

        // A paler back wave behind the surface adds depth.
        context.fill(
            wavePath(level: level, amplitude: 4.5, phase: time * 1.7 + 2.4, p: p, closed: true),
            with: .color(bands[surface].color.opacity(0.45))
        )

        for index in stride(from: surface, through: 0, by: -1) {
            let isSurface = index == surface
            let top = isSurface ? level : bands[index].upTo
            guard top > 0.001 else { continue }
            let amplitude: CGFloat = isSurface ? 5 : 2.2
            let phase = isSurface ? time * 2.3 + 0.4 : time * 0.6 + Double(index) * 1.9
            context.fill(wavePath(level: top, amplitude: amplitude, phase: phase, p: p, closed: true), with: .color(bands[index].color))
            context.stroke(
                wavePath(level: top, amplitude: amplitude, phase: phase, p: p, closed: false),
                with: .color(.white.opacity(isSurface ? 0.55 : 0.35)),
                lineWidth: 2.4 * u
            )
        }
    }

    private func drawBubbles(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let surface = DewyGeometry.bodyBottom - CGFloat(level) * (DewyGeometry.bodyBottom - DewyGeometry.bodyTop)
        let column = Double(DewyGeometry.bodyBottom - surface)
        guard column > 14 else { return }
        for index in 0..<8 {
            let seed = Double(index)
            let x0 = 52 + 96 * fract(sin(seed * 12.9898) * 43758.5453)
            let radius = 2.2 + 2.6 * fract(sin(seed * 78.233) * 12543.21)
            let speed = 14 + 18 * fract(sin(seed * 39.425) * 9631.7)
            let travel = (time * speed + seed * 97).truncatingRemainder(dividingBy: column)
            let y = Double(DewyGeometry.bodyBottom) - travel
            guard y > Double(surface) + radius + 2 else { continue }
            let x = x0 + sin(time * 2.3 + seed) * 2.5
            let fade = min(1, (y - Double(surface)) / 20)
            let center = p(CGFloat(x), CGFloat(y))
            let rect = CGRect(x: center.x - CGFloat(radius) * u, y: center.y - CGFloat(radius) * u, width: CGFloat(radius * 2) * u, height: CGFloat(radius * 2) * u)
            context.opacity = fade
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.28)))
            context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.85)), lineWidth: 1.1 * u)
            context.opacity = 1
        }
    }

    private func fract(_ value: Double) -> Double { value - floor(value) }

    // MARK: Face

    private func drawFace(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        ellipse: (CGFloat, CGFloat, CGFloat, CGFloat) -> Path,
        u: CGFloat
    ) {
        let ink = Self.ink
        let ey: CGFloat = 136
        let eyes: [CGFloat] = [75, 125]

        // Blink every few seconds.
        let cycle = time.truncatingRemainder(dividingBy: 4.4)
        let openness: CGFloat = blinks && cycle < 0.16 ? max(0.1, CGFloat(abs(cycle - 0.08) / 0.08)) : 1

        // Rosy cheeks
        context.fill(ellipse(56, 154, 12, 7.5), with: .color(Palette.cheek.opacity(0.6)))
        context.fill(ellipse(144, 154, 12, 7.5), with: .color(Palette.cheek.opacity(0.6)))

        if accessory != .sunglasses {
            for ex in eyes {
                switch mood {
                case .ecstatic:
                    var arc = Path()
                    arc.move(to: p(ex - 11, ey + 3))
                    arc.addQuadCurve(to: p(ex + 11, ey + 3), control: p(ex, ey - 13))
                    context.stroke(arc, with: .color(ink), style: StrokeStyle(lineWidth: 6.5 * u, lineCap: .round))
                case .thirsty:
                    context.fill(ellipse(ex, ey + 3, 10.5, 10 * openness), with: .color(ink))
                    if openness > 0.6 {
                        context.fill(ellipse(ex - 3.5, ey - 1, 3.8, 3.8), with: .color(.white))
                    }
                case .okay, .happy:
                    context.fill(ellipse(ex, ey, 11.5, 14.5 * openness), with: .color(ink))
                    if openness > 0.6 {
                        context.fill(ellipse(ex - 4, ey - 6, 5, 5), with: .color(.white))
                        context.fill(ellipse(ex + 4, ey + 6, 2.2, 2.2), with: .color(.white))
                    }
                }
            }
        }

        if mood == .thirsty {
            // Worried brows and a tiny sweat drop.
            for (outer, inner) in [(CGFloat(63), CGFloat(84)), (137, 116)] {
                var brow = Path()
                brow.move(to: p(outer, 119))
                brow.addLine(to: p(inner, 113))
                context.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: 4 * u, lineCap: .round))
            }
            let drop = DewyShape().path(in: CGRect(x: p(150, 100).x, y: p(150, 100).y, width: 11 * u, height: 14 * u))
            context.fill(drop, with: .color(Color(hex: 0x7FD0FF)))
        }

        // Mouth
        switch mood {
        case .thirsty:
            var mouth = Path()
            mouth.move(to: p(93, 158))
            mouth.addQuadCurve(to: p(107, 158), control: p(100, 151))
            context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: 4 * u, lineCap: .round))
        case .okay:
            var mouth = Path()
            mouth.move(to: p(92, 151))
            mouth.addQuadCurve(to: p(108, 151), control: p(100, 160))
            context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: 4.2 * u, lineCap: .round))
        case .happy, .ecstatic:
            let half: CGFloat = mood == .ecstatic ? 10 : 7
            let depth: CGFloat = mood == .ecstatic ? 18 : 12
            var mouth = Path()
            mouth.move(to: p(100 - half, 150))
            mouth.addQuadCurve(to: p(100 + half, 150), control: p(100, 149))
            mouth.addQuadCurve(to: p(100, 150 + depth), control: p(100 + half - 1, 150 + depth))
            mouth.addQuadCurve(to: p(100 - half, 150), control: p(100 - half + 1, 150 + depth))
            mouth.closeSubpath()
            context.fill(mouth, with: .color(Color(hex: 0x5A1F45)))
            context.drawLayer { layer in
                layer.clip(to: mouth)
                layer.fill(ellipse(100, 150 + depth * 0.82, half * 0.64, depth * 0.3), with: .color(Color(hex: 0xFF7E9D)))
            }
        }
    }

    // MARK: Accessories

    private func drawAccessory(
        in context: inout GraphicsContext,
        p: (CGFloat, CGFloat) -> CGPoint,
        ellipse: (CGFloat, CGFloat, CGFloat, CGFloat) -> Path,
        u: CGFloat
    ) {
        /// Runs `draw` in a local coordinate space centered on a design point.
        func local(_ x: CGFloat, _ y: CGFloat, rotation: Double = 0, scale: CGFloat = 1, _ draw: (inout GraphicsContext, (CGFloat, CGFloat) -> CGPoint) -> Void) {
            var layer = context
            layer.translateBy(x: p(x, y).x, y: p(x, y).y)
            layer.rotate(by: .degrees(rotation))
            layer.scaleBy(x: scale, y: scale)
            draw(&layer) { lx, ly in CGPoint(x: lx * u, y: ly * u) }
        }
        func polygon(_ points: [(CGFloat, CGFloat)], _ q: (CGFloat, CGFloat) -> CGPoint) -> Path {
            var path = Path()
            path.addLines(points.map { q($0.0, $0.1) })
            path.closeSubpath()
            return path
        }

        switch accessory {
        case .none:
            if mood == .ecstatic { drawSparkles(in: &context, p: p, u: u) }

        case .sparkles:
            drawSparkles(in: &context, p: p, u: u)

        case .crown:
            local(148, 62, rotation: 18 + sin(time * 2) * 3, scale: 1.25) { layer, q in
                let crown = polygon([(-23, 12), (-24, -8), (-11, 3), (0, -15), (11, 3), (24, -8), (23, 12)], q)
                layer.fill(crown, with: .color(Color(hex: 0xFFC93D)))
                layer.stroke(crown, with: .color(Color(hex: 0xFFC93D)), style: StrokeStyle(lineWidth: 4 * u, lineJoin: .round))
                layer.fill(Path(roundedRect: CGRect(origin: q(-24, 6), size: CGSize(width: 48 * u, height: 9 * u)), cornerRadius: 4 * u), with: .color(Color(hex: 0xF29A1B)))
                for (x, y, r, c) in [(CGFloat(0), CGFloat(-15), CGFloat(4), Color(hex: 0xFF6FA5)), (-24, -8, 3.4, .white), (24, -8, 3.4, .white), (0, 10.5, 3, Color(hex: 0x4DB4FF))] {
                    layer.fill(Path(ellipseIn: CGRect(x: (x - r) * u, y: (y - r) * u, width: r * 2 * u, height: r * 2 * u)), with: .color(c))
                }
            }
            drawSparkles(in: &context, p: p, u: u)

        case .sunglasses:
            let ink = Self.ink
            for x in [CGFloat(57), 105] {
                context.fill(Path(roundedRect: CGRect(origin: p(x, 123), size: CGSize(width: 38 * u, height: 27 * u)), cornerRadius: 10 * u), with: .color(ink))
                var shine = Path()
                shine.move(to: p(x + 7, 144))
                shine.addLine(to: p(x + 19, 128))
                shine.move(to: p(x + 13, 146))
                shine.addLine(to: p(x + 25, 130))
                context.stroke(shine, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 3.5 * u, lineCap: .round))
            }
            context.fill(Path(roundedRect: CGRect(origin: p(92, 129), size: CGSize(width: 16 * u, height: 5 * u)), cornerRadius: 2.5 * u), with: .color(ink))

        case .sprout:
            var stem = Path()
            stem.move(to: p(118, 16))
            stem.addCurve(to: p(124, -8), control1: p(118, 6), control2: p(120, -2))
            context.stroke(stem, with: .color(Color(hex: 0x4CAF50)), style: StrokeStyle(lineWidth: 4 * u, lineCap: .round))
            local(124, -7, rotation: sin(time * 2.4) * 6) { layer, q in
                var left = Path()
                left.move(to: q(-1, 1))
                left.addCurve(to: q(-28, -3), control1: q(-8, -11), control2: q(-22, -11))
                left.addCurve(to: q(-1, 1), control1: q(-20, 5), control2: q(-8, 5))
                layer.fill(left, with: .color(Color(hex: 0x6CCB5F)))
                var right = Path()
                right.move(to: q(0, -1))
                right.addCurve(to: q(28, -9), control1: q(6, -15), control2: q(22, -17))
                right.addCurve(to: q(0, -1), control1: q(22, 1), control2: q(8, 3))
                layer.fill(right, with: .color(Color(hex: 0x8EDB6E)))
            }

        case .bow:
            local(148, 70, rotation: 16) { layer, q in
                let pink = Color(hex: 0xFF6FA5)
                let deep = Color(hex: 0xE24F8A)
                for side in [CGFloat(-1), 1] {
                    var lobe = Path()
                    lobe.move(to: q(0, 0))
                    lobe.addCurve(to: q(26 * side, -2), control1: q(8 * side, -14), control2: q(26 * side, -16))
                    lobe.addCurve(to: q(0, 0), control1: q(26 * side, 12), control2: q(8 * side, 10))
                    layer.fill(lobe, with: .color(pink))
                    let tail = polygon([(3 * side, 2), (9 * side, 18), (3 * side, 15), (0, 20), (-2 * side, 3)], q)
                    layer.fill(tail, with: .color(deep))
                }
                layer.fill(Path(ellipseIn: CGRect(x: -6.5 * u, y: -6.5 * u, width: 13 * u, height: 13 * u)), with: .color(deep))
            }

        case .hearts:
            let float = CGFloat(sin(time * 2)) * 3
            drawHeart(in: &context, center: p(172, 84 + float), size: 22 * u, color: Color(hex: 0xFF5C8A))
            drawHeart(in: &context, center: p(36, 76 - float), size: 13 * u, color: Color(hex: 0xFF8FB1))

        case .snowflakes:
            for (x, y, s, speed) in [(CGFloat(30), CGFloat(70), CGFloat(20), 25.0), (170, 60, 14, -35), (178, 120, 10, 40)] {
                local(x, y, rotation: time * speed) { layer, q in
                    var flake = Path()
                    for index in 0..<3 {
                        let angle = Double(index) * .pi / 3
                        let dx = CGFloat(cos(angle)) * s / 2
                        let dy = CGFloat(sin(angle)) * s / 2
                        flake.move(to: q(-dx, -dy))
                        flake.addLine(to: q(dx, dy))
                    }
                    layer.stroke(flake, with: .color(.white), style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
                }
            }

        case .nightcap:
            var cap = Path()
            cap.move(to: p(78, 60))
            cap.addCurve(to: p(140, 12), control1: p(82, 26), control2: p(112, 4))
            cap.addCurve(to: p(174, 70), control1: p(158, 18), control2: p(170, 40))
            cap.addCurve(to: p(150, 56), control1: p(164, 56), control2: p(156, 50))
            cap.addCurve(to: p(78, 60), control1: p(130, 68), control2: p(100, 70))
            cap.closeSubpath()
            context.fill(cap, with: .color(Color(hex: 0x5B6CFF)))
            var band = Path()
            band.move(to: p(78, 60))
            band.addCurve(to: p(152, 58), control1: p(100, 72), control2: p(132, 70))
            context.stroke(band, with: .color(.white), style: StrokeStyle(lineWidth: 11 * u, lineCap: .round))
            context.fill(ellipse(174, 74, 10, 10), with: .color(.white))
            drawStar(in: &context, center: p(98, 34), radius: 5 * u, color: Color(hex: 0xFFE27A))
            drawStar(in: &context, center: p(132, 37), radius: 3.6 * u, color: Color(hex: 0xFFE27A))

        case .flame:
            let flicker = CGFloat(sin(time * 9)) * 0.06
            local(120, 0, rotation: sin(time * 6) * 4, scale: 1 + flicker) { layer, q in
                var outer = Path()
                outer.move(to: q(0, -26))
                outer.addCurve(to: q(17, 8), control1: q(8, -12), control2: q(20, -6))
                outer.addCurve(to: q(-6, 22), control1: q(15, 20), control2: q(4, 25))
                outer.addCurve(to: q(-16, -2), control1: q(-18, 19), control2: q(-22, 8))
                outer.addCurve(to: q(-7, 5), control1: q(-14, 5), control2: q(-10, 7))
                outer.addCurve(to: q(0, -26), control1: q(-10, -6), control2: q(-6, -16))
                outer.closeSubpath()
                layer.fill(outer, with: .color(Color(hex: 0xFF7A3D)))
                var inner = Path()
                inner.move(to: q(-1, -6))
                inner.addCurve(to: q(8, 11), control1: q(3, 1), control2: q(9, 4))
                inner.addCurve(to: q(-4, 18), control1: q(7, 17), control2: q(1, 19))
                inner.addCurve(to: q(-8, 5), control1: q(-10, 16), control2: q(-11, 10))
                inner.addCurve(to: q(-1, -6), control1: q(-6, 8), control2: q(-3, 2))
                inner.closeSubpath()
                layer.fill(inner, with: .color(Color(hex: 0xFFD23F)))
            }

        case .star:
            drawStar(in: &context, center: p(150, 40), radius: 16 * u, color: Color(hex: 0xFFC93D))
        }
    }

    private func drawSparkles(in context: inout GraphicsContext, p: (CGFloat, CGFloat) -> CGPoint, u: CGFloat) {
        let spots: [(CGFloat, CGFloat, CGFloat, Double)] = [(-2, 70, 26, 0), (196, 92, 20, 1.3), (184, 34, 14, 2.4), (8, 176, 14, 3.1)]
        for (index, spot) in spots.enumerated() {
            let pulse = 0.55 + 0.45 * sin(time * 3 + spot.3)
            let s = spot.2 * u * CGFloat(pulse)
            let rect = CGRect(x: p(spot.0, spot.1).x - s / 2, y: p(spot.0, spot.1).y - s / 2, width: s, height: s)
            context.opacity = 0.5 + pulse * 0.5
            context.fill(SparkleShape().path(in: rect), with: .color(index.isMultiple(of: 2) ? Palette.sunshine : .white))
            context.opacity = 1
        }
    }

    private func drawHeart(in context: inout GraphicsContext, center: CGPoint, size: CGFloat, color: Color) {
        let rect = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
        context.fill(HeartShape().path(in: rect), with: .color(color))
    }

    private func drawStar(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        var star = Path()
        for index in 0..<10 {
            let r = index.isMultiple(of: 2) ? radius : radius * 0.48
            let angle = Double(index) * .pi / 5 - .pi / 2
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * r, y: center.y + CGFloat(sin(angle)) * r)
            if index == 0 { star.move(to: point) } else { star.addLine(to: point) }
        }
        star.closeSubpath()
        context.fill(star, with: .color(color))
        context.stroke(star, with: .color(color), style: StrokeStyle(lineWidth: radius * 0.22, lineJoin: .round))
    }
}
