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

/// A straight-sided mug body with a soft round bottom.
struct MugShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.width * 0.28
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
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

enum VesselStyle {
    case glass, mug, straw
}

/// A flat, colorful cup for a drink: a glass, a mug with a handle or a tumbler with a straw.
struct DrinkVessel: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var fill: Double = 0.72
    var width: CGFloat = 40
    var onHero = false
    var wavePhase: Double = 0.8

    private var height: CGFloat { width * 1.25 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch kind.vessel {
            case .glass:
                cup(TumblerShape(taper: 0.13), width: width, height: height)
            case .straw:
                Capsule()
                    .fill(kind.strawColor)
                    .frame(width: width * 0.1, height: height * 0.46)
                    .rotationEffect(.degrees(14))
                    .offset(x: width * 0.56, y: 0)
                cup(TumblerShape(taper: 0.13), width: width * 0.86, height: height * 0.8)
                    .offset(x: width * 0.07, y: height * 0.2)
            case .mug:
                Circle()
                    .strokeBorder(kind.color, lineWidth: width * 0.1)
                    .frame(width: width * 0.4, height: width * 0.4)
                    .offset(x: width * 0.6, y: height * 0.4)
                cup(MugShape(), width: width * 0.8, height: height * 0.74)
                    .offset(x: 0, y: height * 0.26)
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    private func cup<S: Shape>(_ shape: S, width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            shape.fill(onHero ? Color.white.opacity(0.35) : theme.well)
            WaveShape(level: fill, phase: wavePhase, amplitude: h * 0.035, frequency: 1)
                .fill(kind.color)
                .clipShape(shape)
            if kind == .sparkling {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: w * 0.1, height: w * 0.1)
                        .offset(x: w * (CGFloat(index) * 0.17 - 0.1), y: h * (0.32 - CGFloat(index % 2) * 0.16))
                }
            }
            Capsule()
                .fill(Color.white.opacity(0.5))
                .frame(width: w * 0.09, height: h * 0.36)
                .offset(x: -w * 0.24, y: -h * 0.04)
        }
        .frame(width: w, height: h)
    }
}
