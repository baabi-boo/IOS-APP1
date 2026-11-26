import SwiftUI

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
