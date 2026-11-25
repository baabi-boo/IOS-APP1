import SwiftUI

/// Dewy's chubby droplet silhouette.
struct DropletShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var path = Path()
        path.move(to: point(0.5, 0))
        path.addCurve(to: point(0.97, 0.633), control1: point(0.58, 0.133), control2: point(0.97, 0.35))
        path.addCurve(to: point(0.5, 1), control1: point(0.97, 0.85), control2: point(0.76, 1))
        path.addCurve(to: point(0.03, 0.633), control1: point(0.24, 1), control2: point(0.03, 0.85))
        path.addCurve(to: point(0.5, 0), control1: point(0.03, 0.35), control2: point(0.42, 0.133))
        path.closeSubpath()
        return path
    }
}

/// A sine wave filling a rect from the bottom up to `level`.
/// Only `level` is animatable so a running `TimelineView` can drive `phase` every frame
/// while a spring smoothly animates the water level.
struct WaveShape: Shape {
    var level: Double
    var phase: Double
    var amplitude: CGFloat
    var frequency: Double = 1.25

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clamped = min(max(level, 0), 1.05)
        let baseline = rect.maxY - rect.height * CGFloat(clamped)
        let step: CGFloat = 3
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        var x = rect.minX
        while x <= rect.maxX + step {
            let relative = Double((x - rect.minX) / max(rect.width, 1))
            let y = baseline + amplitude * CGFloat(sin(relative * .pi * 2 * frequency + phase))
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A friendly tapered tumbler glass.
struct TumblerShape: Shape {
    var taper: CGFloat = 0.14

    func path(in rect: CGRect) -> Path {
        let inset = rect.width * taper
        let radius = rect.width * 0.16
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - inset - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX - inset - radius * 0.1, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + inset + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + inset, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX + inset + radius * 0.1, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

/// A rounded heart, used for sparkles and confetti.
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + h * 0.3),
            control1: CGPoint(x: rect.midX - w * 0.1, y: rect.maxY - h * 0.15),
            control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.6)
        )
        path.addArc(
            center: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + h * 0.28),
            radius: w * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: rect.minX + w * 0.75, y: rect.minY + h * 0.28),
            radius: w * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.6),
            control2: CGPoint(x: rect.midX + w * 0.1, y: rect.maxY - h * 0.15)
        )
        path.closeSubpath()
        return path
    }
}

/// A tiny cup glyph that shows how full a serving is.
struct CupGlyph: View {
    @Environment(\.dewyTheme) private var theme
    var fill: Double
    var tint: Color?
    var width: CGFloat = 26
    var height: CGFloat = 32

    var body: some View {
        let water = tint.map { LinearGradient(colors: [$0.opacity(0.7), $0], startPoint: .top, endPoint: .bottom) } ?? theme.waterGradient
        ZStack {
            TumblerShape()
                .fill(Color.white.opacity(theme.isDark ? 0.15 : 0.7))
            WaveShape(level: fill, phase: 0.8, amplitude: 1.5, frequency: 1)
                .fill(water)
                .clipShape(TumblerShape())
            TumblerShape()
                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
        }
        .frame(width: width, height: height)
    }
}
