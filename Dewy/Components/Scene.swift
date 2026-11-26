import SwiftUI

private func fract(_ value: Double) -> Double { value - floor(value) }

/// Deterministic pseudo-random number in 0..<1 for a seed.
private func noise(_ seed: Double, _ salt: Double) -> Double {
    fract(sin(seed * 12.9898 + salt * 78.233) * 43758.5453)
}

// MARK: - World scene

/// The living backdrop of every screen: the world's sky, its sun or moon, drifting clouds,
/// and the water at the horizon, with a few details that are unique to each world.
struct WorldScene: View {
    /// Distance of the horizon from the top of the view, in points. Pass a value larger
    /// than the view to show only sky.
    var horizon: CGFloat
    /// Where the sun (or moon) sits, as a fraction of the width, measured from the top.
    var sunPosition = CGPoint(x: 0.84, y: 120)
    var animated = true

    @Environment(\.dewyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                theme.skyGradient

                // Sun glow
                RadialGradient(
                    stops: [
                        .init(color: theme.sunGlow.opacity(theme.isDark ? 0.5 : 0.95), location: 0),
                        .init(color: theme.sunGlow.opacity(theme.isDark ? 0.18 : 0.45), location: 0.2),
                        .init(color: theme.sunGlow.opacity(0), location: 1)
                    ],
                    center: UnitPoint(x: sunPosition.x, y: sunPosition.y / max(size.height, 1)),
                    startRadius: 0,
                    endRadius: 260
                )

                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated || reduceMotion)) { timeline in
                    let t = animated && !reduceMotion ? timeline.date.timeIntervalSinceReferenceDate : 40
                    Canvas { context, canvasSize in
                        draw(in: &context, size: canvasSize, time: t)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Drawing

    private func draw(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let w = size.width
        let sun = CGPoint(x: w * sunPosition.x, y: sunPosition.y)

        if theme.isDark {
            drawStars(in: &context, size: size, time: t)
            drawMoon(in: &context, center: sun)
        } else {
            drawRays(in: &context, center: sun, time: t)
        }

        if theme == .peach {
            // A big, soft setting sun sinking into the sea.
            let r: CGFloat = 70
            let center = CGPoint(x: w * 0.68, y: horizon + 8)
            context.fill(Path(ellipseIn: CGRect(x: center.x - r * 1.9, y: center.y - r * 1.9, width: r * 3.8, height: r * 3.8)),
                         with: .radialGradient(Gradient(colors: [Color(hex: 0xFFE7A8).opacity(0.7), Color(hex: 0xFFE7A8).opacity(0)]), center: center, startRadius: r * 0.8, endRadius: r * 1.9))
            context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                         with: .linearGradient(Gradient(colors: [Color(hex: 0xFFF3C4), Color(hex: 0xFFC37A)]), startPoint: CGPoint(x: center.x, y: center.y - r), endPoint: CGPoint(x: center.x, y: center.y + r)))
        }

        drawClouds(in: &context, size: size, time: t, far: true)

        if theme == .matcha {
            drawHills(in: &context, size: size)
        }

        guard horizon < size.height else {
            drawClouds(in: &context, size: size, time: t, far: false)
            drawSparkles(in: &context, size: size, time: t)
            return
        }

        if theme == .lagoon {
            drawIsland(in: &context, at: CGPoint(x: w * 0.12, y: horizon + 2))
        }
        if theme == .lavender {
            drawCloudBank(in: &context, size: size)
        }

        drawSea(in: &context, size: size, time: t)
        drawClouds(in: &context, size: size, time: t, far: false)
        drawSparkles(in: &context, size: size, time: t)
    }

    private func drawRays(in context: inout GraphicsContext, center: CGPoint, time t: Double) {
        let spin = t * 0.04
        context.drawLayer { layer in
            layer.opacity = 0.16
            for index in 0..<10 {
                let angle = Double(index) / 10 * .pi * 2 + spin
                var ray = Path()
                ray.move(to: center)
                ray.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle - 0.09)) * 420, y: center.y + CGFloat(sin(angle - 0.09)) * 420))
                ray.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle + 0.09)) * 420, y: center.y + CGFloat(sin(angle + 0.09)) * 420))
                ray.closeSubpath()
                layer.fill(ray, with: .radialGradient(Gradient(colors: [.white, .white.opacity(0)]), center: center, startRadius: 20, endRadius: 380))
            }
        }
    }

    private func drawMoon(in context: inout GraphicsContext, center: CGPoint) {
        let r: CGFloat = 30
        context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                     with: .linearGradient(Gradient(colors: [Color(hex: 0xFFF6D8), Color(hex: 0xFFE08A)]), startPoint: CGPoint(x: center.x - r, y: center.y - r), endPoint: CGPoint(x: center.x + r, y: center.y + r)))
        for (dx, dy, cr) in [(CGFloat(-9), CGFloat(-6), CGFloat(6)), (10, 8, 4.5), (6, -12, 3)] {
            context.fill(Path(ellipseIn: CGRect(x: center.x + dx - cr, y: center.y + dy - cr, width: cr * 2, height: cr * 2)), with: .color(Color(hex: 0xF2C96B).opacity(0.6)))
        }
    }

    private func drawStars(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let limit = min(horizon, size.height) - 20
        for index in 0..<46 {
            let seed = Double(index)
            let x = CGFloat(noise(seed, 1)) * size.width
            let y = CGFloat(noise(seed, 2)) * max(limit, 0)
            let twinkle = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * (1 + noise(seed, 3) * 2) + seed))
            let r = CGFloat(0.8 + noise(seed, 4) * 1.6)
            context.opacity = twinkle
            context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white))
        }
        context.opacity = 1
    }

    // MARK: Clouds

    private func cloudPath(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
            path.addEllipse(in: CGRect(x: rect.minX + cx * w - r * h, y: rect.minY + cy * h - r * h, width: r * 2 * h, height: r * 2 * h))
        }
        circle(0.26, 0.64, 0.36)
        circle(0.5, 0.44, 0.44)
        circle(0.74, 0.6, 0.34)
        path.addRoundedRect(in: CGRect(x: rect.minX + 0.08 * w, y: rect.minY + 0.5 * h, width: 0.84 * w, height: 0.5 * h), cornerSize: CGSize(width: 0.25 * h, height: 0.25 * h))
        return path
    }

    private func drawClouds(in context: inout GraphicsContext, size: CGSize, time t: Double, far: Bool) {
        // (y as a fraction of the horizon, width, speed, phase)
        let clouds: [(CGFloat, CGFloat, Double, Double)] = far
            ? [(0.42, 150, 3.2, 0.1), (0.62, 120, 2.4, 0.55), (0.2, 96, 2.0, 0.8)]
            : [(0.3, 128, 6.0, 0.35), (0.78, 160, 4.6, 0.02)]
        let span = size.width + 260
        let skyHeight = min(horizon, size.height)
        for cloud in clouds {
            let travel = (t * cloud.2 + cloud.3 * Double(span)).truncatingRemainder(dividingBy: Double(span))
            let x = CGFloat(travel) - 160
            let width = cloud.1
            let height = width * 0.42
            let y = skyHeight * cloud.0 - height
            let rect = CGRect(x: x, y: y, width: width, height: height)
            let path = cloudPath(in: rect)
            context.opacity = far ? (theme.isDark ? 0.14 : 0.5) : (theme.isDark ? 0.22 : 0.96)
            context.fill(path, with: .linearGradient(
                Gradient(colors: [.white, theme.cloudShade]),
                startPoint: CGPoint(x: rect.midX, y: rect.minY), endPoint: CGPoint(x: rect.midX, y: rect.maxY)
            ))
        }
        context.opacity = 1
    }

    private func drawCloudBank(in context: inout GraphicsContext, size: CGSize) {
        let y = horizon
        for (x, width) in [(CGFloat(-40), CGFloat(170)), (size.width * 0.32, 150), (size.width * 0.66, 190)] {
            let rect = CGRect(x: x, y: y - width * 0.36, width: width, height: width * 0.42)
            context.fill(cloudPath(in: rect), with: .color(Color(hex: 0xFFEFFA).opacity(0.85)))
        }
    }

    // MARK: Land and sea

    private func drawHills(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let base = min(horizon, size.height)
        var back = Path()
        back.move(to: CGPoint(x: 0, y: base + 4))
        back.addCurve(to: CGPoint(x: w * 0.55, y: base - 40), control1: CGPoint(x: w * 0.15, y: base - 70), control2: CGPoint(x: w * 0.38, y: base - 70))
        back.addCurve(to: CGPoint(x: w, y: base - 20), control1: CGPoint(x: w * 0.72, y: base - 14), control2: CGPoint(x: w * 0.86, y: base - 52))
        back.addLine(to: CGPoint(x: w, y: base + 4))
        back.closeSubpath()
        context.fill(back, with: .color(Color(hex: 0x9BE3B0)))
        var front = Path()
        front.move(to: CGPoint(x: 0, y: base - 10))
        front.addCurve(to: CGPoint(x: w, y: base - 4), control1: CGPoint(x: w * 0.3, y: base - 46), control2: CGPoint(x: w * 0.7, y: base + 18))
        front.addLine(to: CGPoint(x: w, y: base + 4))
        front.addLine(to: CGPoint(x: 0, y: base + 4))
        front.closeSubpath()
        context.fill(front, with: .color(Color(hex: 0x6FD08F)))
        // Little round trees on the back hill.
        for (fx, scale) in [(CGFloat(0.2), CGFloat(1)), (0.27, 0.75), (0.82, 0.9)] {
            let x = w * fx
            let y = base - (fx < 0.5 ? 50 : 38)
            context.fill(Path(CGRect(x: x - 2, y: y, width: 4, height: 14 * scale)), with: .color(Color(hex: 0x8A6A4E)))
            context.fill(Path(ellipseIn: CGRect(x: x - 11 * scale, y: y - 18 * scale, width: 22 * scale, height: 24 * scale)), with: .color(Color(hex: 0x3FB874)))
        }
    }

    private func drawIsland(in context: inout GraphicsContext, at point: CGPoint) {
        var island = Path()
        island.move(to: CGPoint(x: point.x - 52, y: point.y))
        island.addCurve(to: CGPoint(x: point.x + 56, y: point.y), control1: CGPoint(x: point.x - 30, y: point.y - 24), control2: CGPoint(x: point.x + 30, y: point.y - 26))
        island.closeSubpath()
        context.fill(island, with: .color(Color(hex: 0x6ED3B8)))
        // Palm tree
        var trunk = Path()
        trunk.move(to: CGPoint(x: point.x + 6, y: point.y - 14))
        trunk.addQuadCurve(to: CGPoint(x: point.x + 16, y: point.y - 50), control: CGPoint(x: point.x + 4, y: point.y - 34))
        context.stroke(trunk, with: .color(Color(hex: 0x4FA88F)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        let top = CGPoint(x: point.x + 16, y: point.y - 50)
        for angle in [-150.0, -110.0, -60.0, -20.0, 20.0] {
            let rad = angle * .pi / 180
            var leaf = Path()
            leaf.move(to: top)
            let tip = CGPoint(x: top.x + CGFloat(cos(rad)) * 22, y: top.y + CGFloat(sin(rad)) * 14 + 8)
            leaf.addQuadCurve(to: tip, control: CGPoint(x: top.x + CGFloat(cos(rad)) * 12, y: top.y + CGFloat(sin(rad)) * 14 - 6))
            context.stroke(leaf, with: .color(Color(hex: 0x4FA88F)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }

    private func drawSea(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let w = size.width
        let top = horizon
        var sea = Path()
        sea.move(to: CGPoint(x: 0, y: top))
        var x: CGFloat = 0
        while x <= w + 8 {
            sea.addLine(to: CGPoint(x: x, y: top + 2.5 * CGFloat(sin(Double(x / w) * .pi * 3 + t * 0.6))))
            x += 8
        }
        sea.addLine(to: CGPoint(x: w, y: size.height))
        sea.addLine(to: CGPoint(x: 0, y: size.height))
        sea.closeSubpath()
        context.fill(sea, with: .linearGradient(Gradient(colors: theme.sea), startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: size.height)))

        // Bright glint where water meets sky.
        var glint = Path()
        x = 0
        glint.move(to: CGPoint(x: 0, y: top + 2.5 * CGFloat(sin(t * 0.6))))
        while x <= w + 8 {
            glint.addLine(to: CGPoint(x: x, y: top + 2.5 * CGFloat(sin(Double(x / w) * .pi * 3 + t * 0.6))))
            x += 8
        }
        context.stroke(glint, with: .color(theme.seaGlint.opacity(0.9)), lineWidth: 5)

        // Reflection of the sun or moon.
        if theme == .peach || theme.isDark {
            let cx = theme == .peach ? w * 0.68 : w * sunPosition.x
            for row in 0..<6 {
                let y = top + 14 + CGFloat(row) * 15
                let half = CGFloat(46 - row * 6) * (0.85 + 0.15 * CGFloat(sin(t * 1.4 + Double(row))))
                var stripe = Path()
                stripe.move(to: CGPoint(x: cx - half, y: y))
                stripe.addLine(to: CGPoint(x: cx + half, y: y))
                context.stroke(stripe, with: .color(Color(hex: 0xFFF1C4).opacity(0.55 - Double(row) * 0.07)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
        }

        // Little dashes of light drifting on the water.
        let depth = size.height - top
        for index in 0..<9 {
            let seed = Double(index)
            let fy = noise(seed, 7)
            let y = top + 22 + CGFloat(fy) * max(depth - 40, 0)
            let speed = 4 + noise(seed, 8) * 6
            let span = Double(w + 80)
            let px = (noise(seed, 9) * span + t * speed).truncatingRemainder(dividingBy: span) - 40
            let length = CGFloat(14 + noise(seed, 10) * 22)
            var dash = Path()
            dash.move(to: CGPoint(x: CGFloat(px), y: y))
            dash.addLine(to: CGPoint(x: CGFloat(px) + length, y: y))
            context.opacity = 0.25 + 0.3 * (0.5 + 0.5 * sin(t * 1.3 + seed))
            context.stroke(dash, with: .color(.white), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        context.opacity = 1
    }

    private func drawSparkles(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let skyHeight = min(horizon, size.height)
        let spots: [(CGFloat, CGFloat, CGFloat, Double)] = [(0.12, 0.3, 18, 0), (0.9, 0.62, 12, 1.4), (0.08, 0.7, 10, 2.6), (0.6, 0.16, 9, 3.3)]
        for spot in spots {
            let pulse = 0.5 + 0.5 * sin(t * 2.2 + spot.3)
            let s = spot.2 * CGFloat(0.6 + 0.4 * pulse)
            let center = CGPoint(x: size.width * spot.0, y: skyHeight * spot.1)
            context.opacity = 0.45 + 0.5 * pulse
            context.fill(SparkleShape().path(in: CGRect(x: center.x - s / 2, y: center.y - s / 2, width: s, height: s)), with: .color(.white))
        }
        context.opacity = 1
    }
}

// MARK: - Lily pad

/// The lily pad Dewy stands on, with ripples that spread whenever a drink lands.
struct LilyPad: View {
    var width: CGFloat
    var rippleTrigger: Int = 0
    var animated = true

    @Environment(\.dewyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var splashes: [Date] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: (!animated || reduceMotion) && splashes.isEmpty)) { timeline in
            let now = timeline.date
            let t = animated && !reduceMotion ? now.timeIntervalSinceReferenceDate : 0
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let rx = width / 2
                let ry = rx * 0.2

                func ring(_ scale: CGFloat, opacity: Double, line: CGFloat = 2.5) {
                    let rect = CGRect(x: center.x - rx * scale, y: center.y - ry * scale, width: rx * 2 * scale, height: ry * 2 * scale)
                    context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)), lineWidth: line)
                }

                // Resting ripples breathe gently.
                let breathe = CGFloat(sin(t * 1.3)) * 0.03
                ring(1.32 + breathe, opacity: 0.45)
                ring(1.8 + breathe * 1.5, opacity: 0.25)

                // Splash ripples spread out and fade.
                for start in splashes {
                    let age = now.timeIntervalSince(start)
                    guard age >= 0, age < 1.8 else { continue }
                    let progress = age / 1.8
                    ring(1.1 + CGFloat(progress) * 1.5, opacity: 0.85 * (1 - progress), line: 3.5)
                    if age > 0.25 {
                        let p2 = (age - 0.25) / 1.55
                        ring(1.05 + CGFloat(p2) * 1.1, opacity: 0.6 * (1 - p2), line: 2.5)
                    }
                }

                // Shadow in the water
                context.fill(Path(ellipseIn: CGRect(x: center.x - rx, y: center.y - ry + 3, width: rx * 2, height: ry * 2)), with: .color(Color(hex: 0x0B4D7A).opacity(0.22)))

                // The pad, with its little notch.
                var pad = Path(ellipseIn: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
                var notch = Path()
                notch.move(to: center)
                notch.addLine(to: CGPoint(x: center.x + rx * 0.5, y: center.y - ry * 1.2))
                notch.addLine(to: CGPoint(x: center.x + rx * 0.05, y: center.y - ry * 1.2))
                notch.closeSubpath()
                pad = pad.subtracting(notch)
                context.fill(pad, with: .color(theme.pad))
                let inner = Path(ellipseIn: CGRect(x: center.x - rx * 0.86, y: center.y - ry * 0.95, width: rx * 1.72, height: ry * 1.6)).subtracting(notch)
                context.fill(inner, with: .color(theme.padLight))

                // A tiny lotus at the edge.
                let lotus = CGPoint(x: center.x - rx * 0.82, y: center.y + ry * 0.1)
                for angle in [-70.0, -35.0, 0.0, 35.0, 70.0] {
                    var petal = Path(ellipseIn: CGRect(x: -4, y: -12, width: 8, height: 13))
                    petal = petal.applying(CGAffineTransform(rotationAngle: CGFloat(angle * .pi / 180)))
                        .applying(CGAffineTransform(translationX: lotus.x, y: lotus.y))
                    context.fill(petal, with: .color(abs(angle) > 40 ? Color(hex: 0xFF9CC2) : Color(hex: 0xFFC2DA)))
                }
                context.fill(Path(ellipseIn: CGRect(x: lotus.x - 3.5, y: lotus.y - 5, width: 7, height: 6)), with: .color(Palette.sunshine))
            }
        }
        .frame(width: width * 1.9, height: width * 0.5)
        .onChange(of: rippleTrigger) {
            splashes = splashes.filter { Date.now.timeIntervalSince($0) < 2 } + [Date.now]
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Sky header

/// The world's sky behind the top of a screen. It keeps going upward in the sky's top color,
/// so the status bar area and overscrolling always show sky.
struct SkyHeaderBackground: View {
    var height: CGFloat
    /// Horizon measured from the top of the header; `nil` shows only sky.
    var horizon: CGFloat?
    var sunY: CGFloat = 70

    @Environment(\.dewyTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            theme.sky[0].frame(height: 800)
            WorldScene(horizon: horizon ?? height + 1_000, sunPosition: CGPoint(x: 0.86, y: sunY))
                .frame(height: height)
        }
        .frame(height: height, alignment: .bottom)
        .allowsHitTesting(false)
    }
}
