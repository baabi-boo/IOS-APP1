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

/// A slender six-pointed storybook starlet with delicate curved waists.
struct StarletShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = Double(rect.midX)
        let cy = Double(rect.midY)
        let outerR = Double(min(rect.width, rect.height)) * 0.5
        let innerR = outerR * 0.26
        let points = 6

        var path = Path()
        for i in 0..<(points * 2) {
            let angle = Double(i) * (Double.pi / Double(points)) - Double.pi / 2.0
            let isTip = i.isMultiple(of: 2)
            let rad = isTip ? outerR * (i % 4 == 0 ? 1.0 : 0.84) : innerR
            let pt = CGPoint(x: cx + cos(angle) * rad, y: cy + sin(angle) * rad)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// A tapered pressed botanical leaf with subtle organic curvature.
struct BotanicalLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let tip = CGPoint(x: rect.midX + w * 0.04, y: rect.minY)
        let base = CGPoint(x: rect.midX - w * 0.03, y: rect.maxY)

        var path = Path()
        path.move(to: base)
        path.addCurve(
            to: tip,
            control1: CGPoint(x: rect.minX - w * 0.06, y: rect.minY + h * 0.72),
            control2: CGPoint(x: rect.minX + w * 0.14, y: rect.minY + h * 0.22)
        )
        path.addCurve(
            to: base,
            control1: CGPoint(x: rect.maxX - w * 0.06, y: rect.minY + h * 0.28),
            control2: CGPoint(x: rect.maxX + w * 0.04, y: rect.minY + h * 0.76)
        )
        path.closeSubpath()
        return path
    }
}

/// An organic hand-cut gouache blossom petal with a soft cherry-blossom notch at its crown.
struct BlossomPetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let base = CGPoint(x: rect.midX, y: rect.maxY)
        let notch = CGPoint(x: rect.midX, y: rect.minY + h * 0.16)
        let leftCrown = CGPoint(x: rect.minX + w * 0.24, y: rect.minY + h * 0.04)
        let rightCrown = CGPoint(x: rect.maxX - w * 0.24, y: rect.minY + h * 0.04)

        var path = Path()
        path.move(to: base)
        path.addCurve(
            to: leftCrown,
            control1: CGPoint(x: rect.minX + w * 0.04, y: rect.minY + h * 0.72),
            control2: CGPoint(x: rect.minX - w * 0.04, y: rect.minY + h * 0.20)
        )
        path.addQuadCurve(
            to: notch,
            control: CGPoint(x: rect.minX + w * 0.40, y: rect.minY)
        )
        path.addQuadCurve(
            to: rightCrown,
            control: CGPoint(x: rect.maxX - w * 0.40, y: rect.minY)
        )
        path.addCurve(
            to: base,
            control1: CGPoint(x: rect.maxX + w * 0.04, y: rect.minY + h * 0.20),
            control2: CGPoint(x: rect.maxX - w * 0.04, y: rect.minY + h * 0.72)
        )
        path.closeSubpath()
        return path
    }
}

/// A glistening plump botanical water bead / teardrop.
struct TeardropBeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let apex = CGPoint(x: rect.midX, y: rect.minY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)

        var path = Path()
        path.move(to: apex)
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.64),
            control1: CGPoint(x: rect.midX + w * 0.22, y: rect.minY + h * 0.22),
            control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.44)
        )
        path.addCurve(
            to: bottom,
            control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.88),
            control2: CGPoint(x: rect.midX + w * 0.28, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + h * 0.64),
            control1: CGPoint(x: rect.midX - w * 0.28, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.88)
        )
        path.addCurve(
            to: apex,
            control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.44),
            control2: CGPoint(x: rect.midX - w * 0.22, y: rect.minY + h * 0.22)
        )
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
