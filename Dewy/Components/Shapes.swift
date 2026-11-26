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

/// Builds a sine-wave surface that fills `rect` from the bottom up to `level`.
enum WavePath {
    static func make(in rect: CGRect, level: Double, phase: Double, amplitude: CGFloat, frequency: Double = 1.25) -> Path {
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

    /// Just the wavy surface line of `make(in:level:phase:amplitude:frequency:)`.
    static func line(in rect: CGRect, level: Double, phase: Double, amplitude: CGFloat, frequency: Double = 1.25) -> Path {
        var path = Path()
        let clamped = min(max(level, 0), 1.05)
        let baseline = rect.maxY - rect.height * CGFloat(clamped)
        let step: CGFloat = 3
        var x = rect.minX
        var first = true
        while x <= rect.maxX + step {
            let relative = Double((x - rect.minX) / max(rect.width, 1))
            let point = CGPoint(x: x, y: baseline + amplitude * CGFloat(sin(relative * .pi * 2 * frequency + phase)))
            if first {
                path.move(to: point)
                first = false
            } else {
                path.addLine(to: point)
            }
            x += step
        }
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
        WavePath.make(in: rect, level: level, phase: phase, amplitude: amplitude, frequency: frequency)
    }
}

/// A rectangle whose top edge rolls like a gentle wave.
struct WaveEdgeShape: Shape {
    var amplitude: CGFloat = 9
    var waves: Double = 1.5
    var phase: Double = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        var x = rect.minX
        let step: CGFloat = 4
        while x <= rect.maxX + step {
            let relative = Double((x - rect.minX) / max(rect.width, 1))
            let y = rect.minY + amplitude + amplitude * CGFloat(sin(relative * .pi * 2 * waves + phase))
            path.addLine(to: CGPoint(x: min(x, rect.maxX), y: y))
            x += step
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
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

/// A four-pointed twinkle.
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let k = r * 0.22
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: c.y - r))
        path.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + k, y: c.y - k))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + k, y: c.y + k))
        path.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - k, y: c.y + k))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - k, y: c.y - k))
        path.closeSubpath()
        return path
    }
}

/// A smooth rolling hill. Heights are fractions of the rect, measured from the top.
struct HillShape: Shape {
    var left: CGFloat
    var peakX: CGFloat
    var peakY: CGFloat
    var right: CGFloat

    /// The hill's surface height (fraction of the rect from the top) at `x` (0...1).
    func surface(_ x: CGFloat) -> CGFloat {
        if x <= peakX {
            let t = peakX > 0 ? x / peakX : 1
            return left + (peakY - left) * (1 - cos(.pi * t)) / 2
        }
        let t = (x - peakX) / max(1 - peakX, 0.0001)
        return peakY + (right - peakY) * (1 - cos(.pi * t)) / 2
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        let steps = 60
        for index in 0...steps {
            let x = CGFloat(index) / CGFloat(steps)
            path.addLine(to: CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * surface(x)))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Drink vessels

/// Legacy name for the illustrated drink, kept so older call sites keep working.
struct DrinkVessel: View {
    var kind: DrinkKind
    var fill: Double = 0.72
    var width: CGFloat = 40
    var onHero = false
    var wavePhase: Double = 0.8

    var body: some View {
        DrinkIcon(kind: kind, size: width * 1.25)
    }
}
