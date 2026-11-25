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

enum MascotAccessory {
    case none, crown, sparkles
}

private struct Squish {
    var x: CGFloat = 1
    var y: CGFloat = 1
    var lift: CGFloat = 0
}

/// Dewy — a living droplet whose water level follows your progress.
struct MascotView: View {
    var progress: Double
    var mood: DewyMood
    var size: CGFloat = 220
    var bounceTrigger: Int = 0
    var accessory: MascotAccessory = .none

    @Environment(\.dewyTheme) private var theme
    @State private var level: Double = 0

    private var targetLevel: Double {
        let clamped = min(max(progress, 0), 1)
        return 0.07 + 0.86 * clamped + (progress >= 1 ? 0.03 : 0)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let bob = CGFloat(sin(t * 1.8))
            VStack(spacing: size * 0.05) {
                droplet(time: t)
                    .frame(width: size, height: size * 1.2)
                    .offset(y: bob * size * 0.025)
                    .rotationEffect(.degrees(sin(t * 0.9) * 2.2), anchor: .bottom)

                Ellipse()
                    .fill(theme.waterBottom.opacity(theme.isDark ? 0.35 : 0.2))
                    .frame(width: size * (0.56 - bob * 0.03), height: size * 0.07)
                    .blur(radius: size * 0.02)
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
            // Soft colored glow
            DropletShape()
                .fill(theme.waterBottom.opacity(0.35))
                .scaleEffect(0.9)
                .offset(y: size * 0.06)
                .blur(radius: size * 0.1)

            // Glass body
            DropletShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(theme.isDark ? 0.35 : 0.8), Color.white.opacity(theme.isDark ? 0.12 : 0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Water, waves and bubbles
            ZStack {
                WaveShape(level: level, phase: t * 1.6 + 1.7, amplitude: size * 0.024)
                    .fill(theme.waterTop.opacity(0.6))
                WaveShape(level: level, phase: t * 2.2, amplitude: size * 0.03)
                    .fill(theme.waterGradient)
                BubbleField(level: level, time: t)
            }
            .clipShape(DropletShape())

            // Glossy highlights
            Capsule()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.075, height: size * 0.2)
                .rotationEffect(.degrees(28))
                .offset(x: -size * 0.2, y: -size * 0.04)
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.045, height: size * 0.045)
                .offset(x: -size * 0.29, y: size * 0.1)

            // Rim
            DropletShape()
                .stroke(Color.white.opacity(0.95), lineWidth: max(2, size * 0.013))

            DewyFace(mood: mood, time: t)

            accessoryView(time: t)
        }
    }

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
            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0xFFB13D)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Color(hex: 0xFFB13D).opacity(0.5), radius: 8, x: 0, y: 4)
                .rotationEffect(.degrees(-12 + sin(t * 2) * 4))
                .offset(x: size * 0.02, y: -size * 0.6)
            sparkles(time: t)
        }
    }

    private func sparkles(time t: Double) -> some View {
        let spots: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (-0.48, -0.25, 0.13, 0),
            (0.47, -0.1, 0.1, 1.3),
            (0.4, -0.42, 0.07, 2.4),
            (-0.42, 0.3, 0.07, 3.1)
        ]
        return ZStack {
            ForEach(0..<spots.count, id: \.self) { index in
                let spot = spots[index]
                let pulse = 0.55 + 0.45 * sin(t * 3 + spot.3)
                Image(systemName: "sparkle")
                    .font(.system(size: size * spot.2, weight: .bold))
                    .foregroundStyle(index.isMultiple(of: 2) ? Palette.sunshine : Palette.blush)
                    .scaleEffect(pulse)
                    .opacity(0.4 + pulse * 0.6)
                    .offset(x: size * spot.0, y: size * spot.1)
            }
        }
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
            for index in 0..<12 {
                let seed = Double(index)
                let x0 = 0.22 + 0.56 * fract(sin(seed * 12.9898) * 43758.5453)
                let radius = size.width * (0.012 + 0.018 * fract(sin(seed * 78.233) * 12543.21))
                let speed = Double(size.height) * (0.06 + 0.08 * fract(sin(seed * 39.425) * 9631.7))
                let travel = (time * speed + seed * 97).truncatingRemainder(dividingBy: Double(column))
                let y = size.height - CGFloat(travel)
                guard y > surface + radius else { continue }
                let wobble = CGFloat(sin(time * 2.3 + seed)) * size.width * 0.012
                let x = size.width * CGFloat(x0) + wobble
                let fade = min(1, (y - surface) / (size.height * 0.12))
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.opacity = Double(fade)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.28)))
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.8)), lineWidth: 1.2)
            }
        }
        .allowsHitTesting(false)
    }

    private func fract(_ value: Double) -> Double {
        value - floor(value)
    }
}

// MARK: - Face

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
            let ink = Color(hex: 0x27304F)

            // Blink every few seconds.
            let cycle = time.truncatingRemainder(dividingBy: 4.2)
            let blink: CGFloat = cycle < 0.16 ? CGFloat(abs(cycle - 0.08) / 0.08) : 1
            let openness = max(0.08, blink)

            // Rosy cheeks
            for side in [-1.0, 1.0] {
                let rect = CGRect(
                    x: cx + CGFloat(side) * w * 0.265 - w * 0.065,
                    y: eyeY + h * 0.04,
                    width: w * 0.13,
                    height: w * 0.075
                )
                context.fill(Path(ellipseIn: rect), with: .color(Palette.blush.opacity(0.6)))
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
                    context.stroke(arc, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.026, lineCap: .round))
                case .thirsty:
                    let eh = w * 0.075 * openness
                    let rect = CGRect(x: ex - w * 0.04, y: eyeY - eh / 2 + w * 0.01, width: w * 0.08, height: eh)
                    context.fill(Path(ellipseIn: rect), with: .color(ink))
                    // Worried brows
                    var brow = Path()
                    brow.move(to: CGPoint(x: ex - CGFloat(side) * w * 0.05, y: eyeY - w * 0.055))
                    brow.addLine(to: CGPoint(x: ex + CGFloat(side) * w * 0.035, y: eyeY - w * 0.075))
                    context.stroke(brow, with: .color(ink.opacity(0.8)), style: StrokeStyle(lineWidth: w * 0.016, lineCap: .round))
                case .okay, .happy:
                    let eh = w * 0.11 * openness
                    let rect = CGRect(x: ex - w * 0.0425, y: eyeY - eh / 2, width: w * 0.085, height: eh)
                    context.fill(Path(ellipseIn: rect), with: .color(ink))
                    if openness > 0.6 {
                        let shine = CGRect(x: ex - w * 0.022, y: eyeY - eh * 0.36, width: w * 0.03, height: w * 0.03)
                        context.fill(Path(ellipseIn: shine), with: .color(.white))
                        let shine2 = CGRect(x: ex + w * 0.008, y: eyeY + eh * 0.12, width: w * 0.014, height: w * 0.014)
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
                context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.02, lineCap: .round))

                // A tiny sweat drop
                let drop = CGRect(x: cx + w * 0.25, y: eyeY - w * 0.14, width: w * 0.06, height: w * 0.075)
                context.fill(DropletShape().path(in: drop), with: .color(Palette.sky))
                context.stroke(DropletShape().path(in: drop), with: .color(.white), lineWidth: 1.5)
            case .okay:
                var mouth = Path()
                mouth.move(to: CGPoint(x: cx - w * 0.055, y: my - w * 0.005))
                mouth.addQuadCurve(to: CGPoint(x: cx + w * 0.055, y: my - w * 0.005), control: CGPoint(x: cx, y: my + w * 0.055))
                context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
            case .happy, .ecstatic:
                let half = mood == .ecstatic ? w * 0.085 : w * 0.068
                let depth = mood == .ecstatic ? w * 0.13 : w * 0.1
                var mouth = Path()
                mouth.move(to: CGPoint(x: cx - half, y: my - w * 0.01))
                mouth.addQuadCurve(to: CGPoint(x: cx + half, y: my - w * 0.01), control: CGPoint(x: cx, y: my - w * 0.022))
                mouth.addQuadCurve(to: CGPoint(x: cx - half, y: my - w * 0.01), control: CGPoint(x: cx, y: my + depth))
                mouth.closeSubpath()
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
