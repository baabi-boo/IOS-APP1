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
        case .thirsty: ["I'm a little dry…", "A sip would be lovely 🥺", "Psst… water?"]
        case .okay: ["Off to a good start!", "Keep the sips coming ✨", "Feeling fresher!"]
        case .happy: ["Ahh, so refreshing!", "You're glowing today 💙", "Almost there!"]
        case .ecstatic: ["Goal smashed! 🎉", "I'm overflowing with joy!", "Best. Day. Ever."]
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
    case none, crown, sparkles, sunglasses, leaf, heart, snowflake, star, moon, flame
}

/// What Dewy is standing on: the hero color field, a colored tile, or a light card.
enum MascotBackdrop {
    case color, tile, light
}

/// One colored layer of liquid inside Dewy. Each drink you log stacks a new layer.
struct LiquidBand: Hashable {
    var color: Color
    /// Where this layer ends, as a cumulative fraction of the daily goal.
    var upTo: Double
}

private struct Squish {
    var x: CGFloat = 1
    var y: CGFloat = 1
    var lift: CGFloat = 0
}

/// Dewy — a living droplet that fills up with a layer for every drink.
struct MascotView: View {
    var progress: Double
    var mood: DewyMood
    var size: CGFloat = 220
    var bounceTrigger: Int = 0
    var accessory: MascotAccessory = .none
    /// Layers to stack, oldest first. Empty means a single layer of `liquid`.
    var bands: [LiquidBand] = []
    var liquid: Color?
    var backdrop: MascotBackdrop = .color
    /// Set to `false` for small decorative mascots to save rendering work.
    var animated = true

    @Environment(\.dewyTheme) private var theme
    @State private var level: Double = 0

    /// Overflowing days squeeze every layer into a full droplet.
    private var overflowScale: Double { max(progress, 1) }

    private func visualLevel(_ fraction: Double) -> Double {
        0.06 + 0.9 * min(max(fraction / overflowScale, 0), 1)
    }

    private var targetLevel: Double { visualLevel(progress) }

    private var resolvedBands: [LiquidBand] {
        guard !bands.isEmpty else {
            return [LiquidBand(color: liquid ?? theme.water, upTo: targetLevel)]
        }
        return bands.map { LiquidBand(color: $0.color, upTo: visualLevel($0.upTo)) }
    }

    private var groundShadow: Color {
        switch backdrop {
        case .color: theme.heroDeep.opacity(0.45)
        case .tile: Color.black.opacity(0.18)
        case .light: theme.ink.opacity(0.08)
        }
    }

    private var bodyShadow: Color {
        switch backdrop {
        case .color: theme.heroDeep.opacity(0.35)
        case .tile: Color.black.opacity(0.15)
        case .light: Color.clear
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !animated)) { timeline in
            let t = animated ? timeline.date.timeIntervalSinceReferenceDate : 0.6
            let bob = CGFloat(sin(t * 1.8))
            VStack(spacing: size * 0.05) {
                droplet(time: t)
                    .frame(width: size, height: size * 1.2)
                    .offset(y: bob * size * 0.025)
                    .rotationEffect(.degrees(sin(t * 0.9) * 2.2), anchor: .bottom)

                Ellipse()
                    .fill(groundShadow)
                    .frame(width: size * (0.56 - bob * 0.03), height: size * 0.07)
                    .blur(radius: size * 0.012)
            }
        }
        .frame(width: size, height: size * 1.32)
        .keyframeAnimator(initialValue: Squish(), trigger: bounceTrigger) { content, value in
            content
                .scaleEffect(x: value.x, y: value.y, anchor: .bottom)
                .offset(y: value.lift)
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                CubicKeyframe(1.12, duration: 0.12)
                SpringKeyframe(0.94, duration: 0.2)
                SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
            }
            KeyframeTrack(\.y) {
                CubicKeyframe(0.88, duration: 0.12)
                SpringKeyframe(1.08, duration: 0.2)
                SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
            }
            KeyframeTrack(\.lift) {
                CubicKeyframe(0, duration: 0.12)
                SpringKeyframe(-size * 0.1, duration: 0.2)
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
        .accessibilityElement()
        .accessibilityLabel("Dewy is \(mood.rawValue), \(Int(progress * 100)) percent of today's goal")
    }

    @ViewBuilder
    private func droplet(time t: Double) -> some View {
        ZStack {
            // Body
            DropletShape()
                .fill(backdrop == .light ? theme.well : Color.white)
                .shadow(color: bodyShadow, radius: size * 0.05, x: 0, y: size * 0.035)

            // Stacked drink layers and rising bubbles
            ZStack {
                LiquidLayers(level: level, bands: resolvedBands, time: t, amplitude: size * 0.028)
                BubbleField(level: level, time: t)
            }
            .clipShape(DropletShape())

            // Gentle shading on the right gives the flat body some roundness.
            DropletShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0), Color(hex: 0x1E2340).opacity(0.07)],
                        startPoint: UnitPoint(x: 0.45, y: 0.3),
                        endPoint: .bottomTrailing
                    )
                )

            // Glossy highlights
            Capsule()
                .fill(Color.white.opacity(0.75))
                .frame(width: size * 0.075, height: size * 0.2)
                .rotationEffect(.degrees(28))
                .offset(x: -size * 0.2, y: -size * 0.04)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.045, height: size * 0.045)
                .offset(x: -size * 0.29, y: size * 0.1)

            if backdrop == .light {
                DropletShape()
                    .stroke(theme.ink.opacity(theme.isDark ? 0.18 : 0.06), lineWidth: max(1.5, size * 0.01))
            }

            DewyFace(mood: mood, time: t)

            accessoryView(time: t)
        }
    }

    // MARK: Accessories

    @ViewBuilder
    private func accessoryView(time t: Double) -> some View {
        switch accessory {
        case .none:
            if mood == .ecstatic {
                sparkles(time: t)
            }
        case .sparkles:
            sparkles(time: t)
        case .crown:
            symbol("crown.fill", style: Palette.gold, scale: 0.2, x: 0.02, y: -0.6, angle: -12 + sin(t * 2) * 4)
            sparkles(time: t)
        case .sunglasses:
            symbol("sunglasses.fill", style: Color(hex: 0x1E2340), scale: 0.27, x: 0, y: 0.13, angle: -3)
        case .leaf:
            symbol("leaf.fill", style: Palette.leaf, scale: 0.17, x: 0.08, y: -0.6, angle: 18 + sin(t * 2.4) * 8)
        case .heart:
            symbol("heart.fill", style: Palette.berry, scale: 0.15, x: 0.37, y: -0.3, angle: 14 + sin(t * 3) * 6)
            symbol("heart.fill", style: Palette.blush, scale: 0.09, x: 0.48, y: -0.5, angle: -10)
        case .snowflake:
            symbol("snowflake", style: Palette.sky, scale: 0.16, x: -0.36, y: -0.34, angle: t * 20)
            symbol("snowflake", style: Color(hex: 0x9BE3FF), scale: 0.09, x: 0.42, y: -0.18, angle: -t * 30)
        case .star:
            symbol("star.fill", style: Palette.gold, scale: 0.19, x: 0.02, y: -0.64, angle: sin(t * 2) * 12)
        case .moon:
            symbol("moon.stars.fill", style: Palette.sunshine, scale: 0.18, x: 0.36, y: -0.36, angle: -8 + sin(t * 1.5) * 6)
        case .flame:
            symbol("flame.fill", style: Palette.flame, scale: 0.19, x: 0.01, y: -0.66, angle: sin(t * 6) * 5)
        }
    }

    private func symbol(_ name: String, style: some ShapeStyle, scale: CGFloat, x: CGFloat, y: CGFloat, angle: Double) -> some View {
        Image(systemName: name)
            .font(.system(size: size * scale, weight: .bold))
            .foregroundStyle(style)
            .shadow(color: Color.black.opacity(0.14), radius: size * 0.015, x: 0, y: size * 0.012)
            .rotationEffect(.degrees(angle))
            .offset(x: size * x, y: size * y)
    }

    private func sparkles(time t: Double) -> some View {
        let spots: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (-0.5, -0.25, 0.13, 0),
            (0.48, -0.1, 0.1, 1.3),
            (0.4, -0.44, 0.07, 2.4),
            (-0.44, 0.3, 0.07, 3.1)
        ]
        return ZStack {
            ForEach(0..<spots.count, id: \.self) { index in
                let spot = spots[index]
                let pulse = 0.55 + 0.45 * sin(t * 3 + spot.3)
                SparkleShape()
                    .fill(index.isMultiple(of: 2) ? Palette.sunshine : Color.white)
                    .frame(width: size * spot.2, height: size * spot.2)
                    .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    .scaleEffect(pulse)
                    .opacity(0.5 + pulse * 0.5)
                    .offset(x: size * spot.0, y: size * spot.1)
            }
        }
    }
}

// MARK: - Liquid layers

/// Draws the stacked drink layers. Animatable on `level`, so a spring can pour
/// a new layer in while the `TimelineView` keeps the surface rolling.
private struct LiquidLayers: View, Animatable {
    var level: Double
    var bands: [LiquidBand]
    var time: Double
    var amplitude: CGFloat

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    var body: some View {
        Canvas { context, size in
            guard !bands.isEmpty else { return }
            let rect = CGRect(origin: .zero, size: size)
            let surfaceIndex = bands.firstIndex { $0.upTo >= level - 0.0005 } ?? (bands.count - 1)
            let lineWidth = max(1, size.width * 0.012)

            // A paler back wave behind the surface adds depth.
            let backWave = WavePath.make(in: rect, level: level, phase: time * 1.6 + 1.7, amplitude: amplitude * 0.85)
            context.fill(backWave, with: .color(bands[surfaceIndex].color.opacity(0.4)))

            for index in stride(from: surfaceIndex, through: 0, by: -1) {
                let isSurface = index == surfaceIndex
                let top = isSurface ? level : bands[index].upTo
                guard top > 0.001 else { continue }
                let amp = isSurface ? amplitude : amplitude * 0.4
                let phase = isSurface ? time * 2.2 : time * 0.7 + Double(index) * 1.9
                let layer = WavePath.make(in: rect, level: top, phase: phase, amplitude: amp)
                context.fill(layer, with: .color(bands[index].color))
                let edge = WavePath.line(in: rect, level: top, phase: phase, amplitude: amp)
                context.stroke(edge, with: .color(Color.white.opacity(isSurface ? 0.45 : 0.28)), lineWidth: lineWidth)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Bubbles

/// Little bubbles rising through the water. Animatable so they follow the springy water level.
private struct BubbleField: View, Animatable {
    var level: Double
    var time: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let surface = size.height * (1 - CGFloat(level))
            let column = size.height - surface
            guard column > 12 else { return }
            for index in 0..<10 {
                let seed = Double(index)
                let x0 = 0.22 + 0.56 * fract(sin(seed * 12.9898) * 43758.5453)
                let radius = size.width * (0.012 + 0.016 * fract(sin(seed * 78.233) * 12543.21))
                let speed = Double(size.height) * (0.06 + 0.08 * fract(sin(seed * 39.425) * 9631.7))
                let travel = (time * speed + seed * 97).truncatingRemainder(dividingBy: Double(column))
                let y = size.height - CGFloat(travel)
                guard y > surface + radius else { continue }
                let wobble = CGFloat(sin(time * 2.3 + seed)) * size.width * 0.012
                let x = size.width * CGFloat(x0) + wobble
                let fade = min(1, (y - surface) / (size.height * 0.12))
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.opacity = Double(fade)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.3)))
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.85)), lineWidth: 1.2)
            }
        }
        .allowsHitTesting(false)
    }

    private func fract(_ value: Double) -> Double {
        value - floor(value)
    }
}

// MARK: - Face

/// Dewy's face. Every feature gets a thin white outline so it stays readable on any drink color.
private struct DewyFace: View {
    var mood: DewyMood
    var time: Double

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let eyeY = h * 0.615
            let eyeDX = w * 0.15
            let ink = Color(hex: 0x1E2340)
            let halo = Color.white
            let haloWidth = w * 0.022

            // Blink every few seconds (but never in a still screenshot).
            let cycle = time.truncatingRemainder(dividingBy: 4.2)
            let blinks = !LaunchOptions.isDemo || LaunchOptions.screenshot == "celebrate"
            let blink: CGFloat = blinks && cycle < 0.16 ? CGFloat(abs(cycle - 0.08) / 0.08) : 1
            let openness = max(0.08, blink)

            // Rosy cheeks
            for side in [-1.0, 1.0] {
                let rect = CGRect(
                    x: cx + CGFloat(side) * w * 0.265 - w * 0.065,
                    y: eyeY + h * 0.04,
                    width: w * 0.13,
                    height: w * 0.075
                )
                context.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xFF7FA8).opacity(0.7)))
            }

            // Eyes
            for side in [-1.0, 1.0] {
                let ex = cx + CGFloat(side) * eyeDX
                switch mood {
                case .ecstatic:
                    var arc = Path()
                    arc.move(to: CGPoint(x: ex - w * 0.045, y: eyeY + w * 0.015))
                    arc.addQuadCurve(
                        to: CGPoint(x: ex + w * 0.045, y: eyeY + w * 0.015),
                        control: CGPoint(x: ex, y: eyeY - w * 0.05)
                    )
                    context.stroke(arc, with: .color(halo), style: StrokeStyle(lineWidth: w * 0.026 + haloWidth, lineCap: .round))
                    context.stroke(arc, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.026, lineCap: .round))
                case .thirsty:
                    let eh = w * 0.075 * openness
                    let rect = CGRect(x: ex - w * 0.04, y: eyeY - eh / 2 + w * 0.01, width: w * 0.08, height: eh)
                    context.fill(Path(ellipseIn: rect.insetBy(dx: -haloWidth / 2, dy: -haloWidth / 2)), with: .color(halo))
                    context.fill(Path(ellipseIn: rect), with: .color(ink))
                    // Worried brows
                    var brow = Path()
                    brow.move(to: CGPoint(x: ex - CGFloat(side) * w * 0.05, y: eyeY - w * 0.055))
                    brow.addLine(to: CGPoint(x: ex + CGFloat(side) * w * 0.035, y: eyeY - w * 0.075))
                    context.stroke(brow, with: .color(halo), style: StrokeStyle(lineWidth: w * 0.016 + haloWidth, lineCap: .round))
                    context.stroke(brow, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.016, lineCap: .round))
                case .okay, .happy:
                    let eh = w * 0.115 * openness
                    let rect = CGRect(x: ex - w * 0.045, y: eyeY - eh / 2, width: w * 0.09, height: eh)
                    context.fill(Path(ellipseIn: rect.insetBy(dx: -haloWidth / 2, dy: -haloWidth / 2)), with: .color(halo))
                    context.fill(Path(ellipseIn: rect), with: .color(ink))
                    if openness > 0.6 {
                        let shine = CGRect(x: ex - w * 0.024, y: eyeY - eh * 0.36, width: w * 0.032, height: w * 0.032)
                        context.fill(Path(ellipseIn: shine), with: .color(.white))
                        let shine2 = CGRect(x: ex + w * 0.008, y: eyeY + eh * 0.12, width: w * 0.015, height: w * 0.015)
                        context.fill(Path(ellipseIn: shine2), with: .color(.white.opacity(0.9)))
                    }
                }
            }

            // Mouth
            let my = eyeY + h * 0.075
            switch mood {
            case .thirsty:
                var mouth = Path()
                mouth.move(to: CGPoint(x: cx - w * 0.045, y: my + w * 0.012))
                mouth.addQuadCurve(to: CGPoint(x: cx + w * 0.045, y: my + w * 0.012), control: CGPoint(x: cx, y: my - w * 0.03))
                context.stroke(mouth, with: .color(halo), style: StrokeStyle(lineWidth: w * 0.02 + haloWidth, lineCap: .round))
                context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.02, lineCap: .round))

                // A tiny sweat drop
                let drop = CGRect(x: cx + w * 0.25, y: eyeY - w * 0.14, width: w * 0.06, height: w * 0.075)
                context.fill(DropletShape().path(in: drop), with: .color(Color(hex: 0x2FB4FF)))
                context.stroke(DropletShape().path(in: drop), with: .color(.white), lineWidth: 1.5)
            case .okay:
                var mouth = Path()
                mouth.move(to: CGPoint(x: cx - w * 0.055, y: my - w * 0.005))
                mouth.addQuadCurve(to: CGPoint(x: cx + w * 0.055, y: my - w * 0.005), control: CGPoint(x: cx, y: my + w * 0.055))
                context.stroke(mouth, with: .color(halo), style: StrokeStyle(lineWidth: w * 0.022 + haloWidth, lineCap: .round))
                context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
            case .happy, .ecstatic:
                let half = mood == .ecstatic ? w * 0.085 : w * 0.068
                let depth = mood == .ecstatic ? w * 0.13 : w * 0.1
                var mouth = Path()
                mouth.move(to: CGPoint(x: cx - half, y: my - w * 0.01))
                mouth.addQuadCurve(to: CGPoint(x: cx + half, y: my - w * 0.01), control: CGPoint(x: cx, y: my - w * 0.022))
                mouth.addQuadCurve(to: CGPoint(x: cx - half, y: my - w * 0.01), control: CGPoint(x: cx, y: my + depth))
                mouth.closeSubpath()
                context.stroke(mouth, with: .color(halo), style: StrokeStyle(lineWidth: haloWidth, lineJoin: .round))
                context.fill(mouth, with: .color(Color(hex: 0x5B2740)))
                context.drawLayer { layer in
                    layer.clip(to: mouth)
                    let tongue = CGRect(x: cx - half * 0.6, y: my + depth * 0.22, width: half * 1.2, height: depth * 0.6)
                    layer.fill(Path(ellipseIn: tongue), with: .color(Color(hex: 0xFF7E9D)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
