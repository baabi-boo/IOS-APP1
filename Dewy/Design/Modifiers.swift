import SwiftUI
import UIKit

// MARK: - Tactile Cotton-Paper Surfaces
//
// Dewy's surfaces feel like heavyweight 300gsm cotton rag card stock resting on warm paper:
//   1. matte unbleached cotton fill with a whisper of natural directional warmth,
//   2. crisp 1pt top-edge light catch and subtle warm archival ink hairline border,
//   3. tight contact shadow plus a clean, airy ambient lift — never glossy plastic.

/// Heavyweight cotton-paper surface with an archival ink hairline and crisp elevation.
struct PaperSurface<S: Shape>: View {
    var shape: S
    var fill: Color = Palette.paper
    /// Subtle tint for the ambient elevation shadow.
    var tint: Color = Palette.shadow
    var elevation: CGFloat = 1
    var bordered: Bool = true

    var body: some View {
        let clampedElevation = max(elevation, 0)
        shape
            .fill(fill)
            .paperGrain(0.020)
            .overlay {
                shape.fill(paperWarmth)
            }
            .overlay {
                shape.strokeBorderCompat(topBevel, lineWidth: 1)
            }
            .overlay {
                if bordered {
                    shape.strokeBorderCompat(Ink.hairline, lineWidth: 1)
                }
            }
            .shadow(
                color: tint.opacity(0.11 * clampedElevation),
                radius: 12 * clampedElevation,
                x: 0,
                y: 6 * clampedElevation
            )
            .shadow(
                color: Palette.shadow.opacity(0.08 * min(clampedElevation, 1.2)),
                radius: 1.5,
                x: 0,
                y: 1
            )
    }

    private var paperWarmth: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.white.opacity(0.35), location: 0),
                .init(color: Color.clear, location: 0.42),
                .init(color: Palette.shadow.opacity(0.025), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topBevel: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.65), Color.white.opacity(0)],
            startPoint: .top,
            endPoint: .init(x: 0.5, y: 0.35)
        )
    }
}

/// Compatibility wrapper forwarding `ClaySurface` call sites onto tactile `PaperSurface`.
struct ClaySurface<S: Shape>: View {
    var shape: S
    var fill: Color = Palette.paper
    /// Tints the soft ambient elevation shadow.
    var glow: Color = Palette.shadow
    var elevation: CGFloat = 1

    var body: some View {
        PaperSurface(shape: shape, fill: fill, tint: glow, elevation: elevation)
    }
}

private extension Shape {
    /// Strokes inside the shape's edge so hairlines never bleed outside clipped bounds.
    func strokeBorderCompat<Style: ShapeStyle>(_ style: Style, lineWidth: CGFloat) -> some View {
        RimInsetShape(base: self, amount: lineWidth / 2).stroke(style, lineWidth: lineWidth)
    }
}

private struct RimInsetShape<Base: Shape>: Shape {
    var base: Base
    var amount: CGFloat
    func path(in rect: CGRect) -> Path { base.path(in: rect.insetBy(dx: amount, dy: amount)) }
}

/// A tactile cotton-paper card: the primary editorial content container.
struct DewyCard: ViewModifier {
    @Environment(\.dewyTheme) private var theme
    var padding: CGFloat
    var radius: CGFloat
    var fill: Color?
    var glow: Color?
    var elevation: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                PaperSurface(
                    shape: RoundedRectangle(cornerRadius: radius, style: .continuous),
                    fill: fill ?? theme.card,
                    tint: glow ?? Palette.shadow,
                    elevation: elevation
                )
            }
    }
}

extension View {
    func dewyCard(padding: CGFloat = 18, radius: CGFloat = 24, fill: Color? = nil, glow: Color? = nil) -> some View {
        modifier(DewyCard(padding: padding, radius: radius, fill: fill, glow: glow))
    }

    func paperCard(
        padding: CGFloat = 18,
        radius: CGFloat = 24,
        fill: Color? = nil,
        tint: Color? = nil,
        elevation: CGFloat = 1
    ) -> some View {
        modifier(DewyCard(padding: padding, radius: radius, fill: fill, glow: tint, elevation: elevation))
    }

    /// Fades and lifts a view into place, staggered by `index`.
    func floatIn(_ visible: Bool, index: Int = 0) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 22)
            .scaleEffect(visible ? 1 : 0.97)
            .animation(.spring(response: 0.56, dampingFraction: 0.82).delay(Double(index) * 0.045), value: visible)
    }

    /// Places content on a warm cotton-paper sheet with refined rounded top corners
    /// extending far below the bottom edge so overscrolling stays seamless.
    func canvasSheet(radius: CGFloat = 34) -> some View {
        modifier(CanvasSheet(radius: radius))
    }
}

private struct CanvasSheet: ViewModifier {
    @Environment(\.dewyTheme) private var theme
    var radius: CGFloat

    func body(content: Content) -> some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: radius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: radius,
            style: .continuous
        )
        content
            .background(alignment: .top) {
                shape
                    .fill(theme.canvas)
                    .paperGrain(0.026)
                    .overlay(alignment: .top) {
                        shape.stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.75), Color.white.opacity(0)],
                                startPoint: .top,
                                endPoint: .init(x: 0.5, y: 0.04)
                            ),
                            lineWidth: 1.5
                        )
                    }
                    .overlay(alignment: .top) {
                        shape.stroke(
                            LinearGradient(
                                colors: [Ink.hairline, Ink.hairline.opacity(0)],
                                startPoint: .top,
                                endPoint: .init(x: 0.5, y: 0.06)
                            ),
                            lineWidth: 0.75
                        )
                    }
                    .padding(.bottom, -260)
                    .shadow(color: Palette.shadow.opacity(0.12), radius: 18, x: 0, y: -6)
            }
    }
}

// MARK: - Editorial Labels

/// Finely tracked archival small-caps kicker label.
struct CapsLabel: View {
    var text: String
    var color: Color
    var size: CGFloat = 11.5

    var body: some View {
        Text(text.uppercased())
            .font(.dewy(size, .bold))
            .tracking(size * 0.14)
            .foregroundStyle(color)
    }
}

/// Editorial New York serif section header with an optional trailing note or action.
struct SectionHeader: View {
    @Environment(\.dewyTheme) private var theme
    var title: String
    var trailing: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.display(23, .semibold))
                .tracking(-0.3)
                .foregroundStyle(theme.ink)
            Spacer()
            if let trailing {
                if let action {
                    Button(action: action) {
                        HStack(spacing: 3) {
                            Text(trailing)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10.5, weight: .bold))
                        }
                        .font(.dewy(13.5, .bold))
                        .foregroundStyle(theme.link)
                    }
                    .buttonStyle(SquishyButtonStyle())
                } else {
                    Text(trailing)
                        .font(.dewy(13, .semibold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Tactile Letterpress Stamp Buttons

/// A crisp, responsive tactile press scale used across icon and text controls.
struct SquishyButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.015 : 0)
            .animation(.spring(response: 0.24, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

/// Matte hand-mixed gouache letterpress stamp button: clean pigment face, fine paper bevel,
/// crisp ink-tinted edge, and a solid tactile shadow lip that compresses physically on press.
struct StampButtonStyle: ButtonStyle {
    var fill: Color
    var lip: Color
    var shape: AnyShape = AnyShape(Capsule())
    var depth: CGFloat = 3.5

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let faceGradient = LinearGradient(
            colors: [
                fill.blended(with: .white, by: 0.05),
                fill.blended(with: .black, by: 0.03)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        configuration.label
            .background {
                shape
                    .fill(faceGradient)
                    .overlay {
                        shape.stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.28), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                    }
                    .overlay {
                        shape.stroke(lip.opacity(0.42), lineWidth: 1)
                    }
            }
            .scaleEffect(pressed ? 0.988 : 1, anchor: .bottom)
            .offset(y: pressed ? depth * 0.82 : 0)
            .background {
                shape
                    .fill(lip)
                    .offset(y: depth)
            }
            .padding(.bottom, depth)
            .animation(.spring(response: 0.2, dampingFraction: 0.66), value: pressed)
    }
}

/// Compatibility button style forwarding legacy `CandyButtonStyle` sites to matte `StampButtonStyle`.
struct CandyButtonStyle: ButtonStyle {
    var fill: Color
    var lip: Color
    var shape: AnyShape = AnyShape(Capsule())
    var depth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        StampButtonStyle(fill: fill, lip: lip, shape: shape, depth: min(depth, 4))
            .makeBody(configuration: configuration)
    }
}

/// Primary editorial call-to-action button: New York serif label on a matte gouache stamp.
struct PrimaryButton: View {
    enum Style {
        /// Cerulean spring water: primary action.
        case accent
        /// Cotton rag paper face for tinted or scenic backdrops.
        case light
        /// Terracotta coral: rewards and Dew Drops.
        case reward
        /// Custom gouache fill + letterpress lip, e.g. the selected drink.
        case tinted(Color, Color)
    }

    @Environment(\.dewyTheme) private var theme
    var title: String
    var systemImage: String?
    var style: Style = .accent
    var isLoading = false
    var height: CGFloat = 58
    var action: () -> Void

    var body: some View {
        let colors = palette
        Button(action: action) {
            HStack(spacing: 9) {
                if isLoading {
                    ProgressView().tint(colors.text)
                } else {
                    Text(title)
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .font(.display(height > 54 ? 20 : 17.5, .semibold))
            .foregroundStyle(colors.text)
            .shadow(color: colors.textShadow, radius: 0, x: 0, y: 0.75)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .contentShape(Capsule())
        }
        .buttonStyle(StampButtonStyle(fill: colors.fill, lip: colors.lip, depth: 3.5))
        .shadow(color: colors.lip.opacity(0.18), radius: 10, x: 0, y: 6)
    }

    private var palette: (fill: Color, lip: Color, text: Color, textShadow: Color) {
        switch style {
        case .accent:
            return (theme.accent, theme.accentDeep, Palette.paper, theme.accentDeep.opacity(0.28))
        case .light:
            return (Palette.paper, Color(hex: 0xDDD0BF), theme.ink, .clear)
        case .reward:
            return (Palette.coral, Palette.coralDeep, Palette.paper, Palette.coralDeep.opacity(0.28))
        case .tinted(let fill, let lip):
            return (fill, lip, Palette.paper, lip.opacity(0.28))
        }
    }
}

/// Circular cotton-paper icon button with crisp ink hairline.
struct CircleIconButton: View {
    @Environment(\.dewyTheme) private var theme
    var systemImage: String
    var size: CGFloat = 40
    var onHero = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.37, weight: .semibold))
                .foregroundStyle(theme.ink)
                .frame(width: size, height: size)
                .background {
                    PaperSurface(
                        shape: Circle(),
                        fill: onHero ? Palette.paper.opacity(0.92) : Palette.paper,
                        elevation: 0.45
                    )
                }
                .contentShape(Circle())
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// Tactile selectable editorial capsule chip.
struct ChipButton: View {
    @Environment(\.dewyTheme) private var theme
    var title: String
    var isSelected: Bool
    var isLocked = false
    var tint: Color?
    var tintDeep: Color?
    var action: () -> Void

    var body: some View {
        let selectedColor = tint ?? theme.accent
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .font(.dewy(14.5, .bold))
            .monospacedDigit()
            .foregroundStyle(isSelected ? Palette.paper : theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 38)
        }
        .buttonStyle(StampButtonStyle(fill: isSelected ? selectedColor : Palette.paper, lip: lip, depth: 2.5))
    }

    private var lip: Color {
        if !isSelected { return Color(hex: 0xDDD0BF) }
        if let tintDeep { return tintDeep }
        if let tint { return tint.blended(with: .black, by: 0.22) }
        return theme.accentDeep
    }
}

/// Sunken cotton-linen segmented control with a matte gouache sliding capsule.
struct ClaySegmented<Item: Hashable>: View {
    @Environment(\.dewyTheme) private var theme
    var items: [Item]
    @Binding var selection: Item
    var title: (Item) -> String
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isSelected = item == selection
                Button {
                    guard !isSelected else { return }
                    Haptics.select()
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.8)) { selection = item }
                } label: {
                    Text(title(item))
                        .font(.dewy(14, .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .foregroundStyle(isSelected ? Palette.paper : theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.accent.blended(with: .white, by: 0.05), theme.accent],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(Capsule().stroke(theme.accentDeep.opacity(0.32), lineWidth: 1))
                                    .shadow(color: theme.accentDeep.opacity(0.22), radius: 6, x: 0, y: 3)
                                    .matchedGeometryEffect(id: "thumb", in: namespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.96))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(theme.well)
                .overlay(Capsule().stroke(Ink.hairline, lineWidth: 1))
        }
    }
}

/// Editorial alias for the tactile segmented control.
typealias StorySegmented = ClaySegmented

/// Matte botanical-ink badge tile holding an SF Symbol.
struct IconTile: View {
    var systemImage: String
    var color: Color
    var size: CGFloat = 38
    var filled = true

    var body: some View {
        let corner = size * 0.30
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        Image(systemName: systemImage)
            .font(.system(size: size * 0.43, weight: .semibold))
            .foregroundStyle(filled ? Palette.paper : color.blended(with: Ink.primary, by: 0.22))
            .frame(width: size, height: size)
            .background {
                shape
                    .fill(filled ? filledWash : softWash)
                    .overlay {
                        shape.stroke(
                            filled ? color.blended(with: Ink.primary, by: 0.28).opacity(0.35) : color.opacity(0.24),
                            lineWidth: 1
                        )
                    }
            }
    }

    private var filledWash: LinearGradient {
        LinearGradient(
            colors: [color.blended(with: .white, by: 0.06), color.blended(with: .black, by: 0.06)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var softWash: LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.13), color.opacity(0.19)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Illustrated Art & Hand-Inked Storybook Glyphs

/// Asset-catalog illustration with a matte ink-tile fallback if missing.
struct ArtImage: View {
    var name: String
    var fallback: String = "sparkles"
    var tint: Color = Palette.aqua
    var size: CGFloat

    var body: some View {
        Group {
            if Art.exists(name) {
                Image(name)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                IconTile(systemImage: fallback, color: tint, size: size * 0.8)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Storybook ink-and-gouache glyphs drawn crisply at any size.
enum ClayGlyph: String {
    case drop, flame, gift, crown, bell, heart, star, map, chest, cup

    var imageName: String { "icon-\(rawValue)" }

    var fallback: String {
        switch self {
        case .drop: "drop.fill"
        case .flame: "flame.fill"
        case .gift: "gift.fill"
        case .crown: "crown.fill"
        case .bell: "bell.fill"
        case .heart: "heart.fill"
        case .star: "star.fill"
        case .map: "map.fill"
        case .chest: "shippingbox.fill"
        case .cup: "cup.and.saucer.fill"
        }
    }

    var tint: Color {
        switch self {
        case .drop: Palette.coral
        case .flame: Palette.butterDeep
        case .gift: Palette.pink
        case .crown: Palette.butter
        case .bell: Palette.butter
        case .heart: Palette.pink
        case .star: Palette.butter
        case .map: Palette.mint
        case .chest: Palette.peach
        case .cup: Palette.aqua
        }
    }
}

/// Crisp vector hand-inked storybook gouache mini-icon rendered natively via SwiftUI Canvas.
struct ClayIcon: View {
    var glyph: ClayGlyph
    var size: CGFloat = 22

    var body: some View {
        StorybookGlyphCanvas(glyph: glyph)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

private struct StorybookGlyphCanvas: View {
    var glyph: ClayGlyph

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            let box = CGRect(origin: origin, size: CGSize(width: side, height: side))
            let line = max(1.05, side * 0.064)
            let style = StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round)

            switch glyph {
            case .drop: drawDrop(&context, in: box, stroke: style)
            case .flame: drawFlame(&context, in: box, stroke: style)
            case .gift: drawGift(&context, in: box, stroke: style)
            case .crown: drawCrown(&context, in: box, stroke: style)
            case .bell: drawBell(&context, in: box, stroke: style)
            case .heart: drawHeart(&context, in: box, stroke: style)
            case .star: drawStar(&context, in: box, stroke: style)
            case .map: drawMap(&context, in: box, stroke: style)
            case .chest: drawChest(&context, in: box, stroke: style)
            case .cup: drawCup(&context, in: box, stroke: style)
            }
        }
    }

    private func pt(_ x: CGFloat, _ y: CGFloat, in r: CGRect) -> CGPoint {
        CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height)
    }

    private func fillWash(_ ctx: inout GraphicsContext, path: Path, top: Color, bottom: Color, in r: CGRect) {
        let grad = Gradient(colors: [top, bottom])
        ctx.fill(path, with: .linearGradient(grad, startPoint: CGPoint(x: r.midX, y: r.minY), endPoint: CGPoint(x: r.midX, y: r.maxY)))
    }

    private func drawDrop(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        var p = Path()
        p.move(to: pt(0.50, 0.09, in: r))
        p.addCurve(to: pt(0.83, 0.61, in: r), control1: pt(0.65, 0.28, in: r), control2: pt(0.83, 0.44, in: r))
        p.addCurve(to: pt(0.50, 0.91, in: r), control1: pt(0.83, 0.79, in: r), control2: pt(0.68, 0.91, in: r))
        p.addCurve(to: pt(0.17, 0.61, in: r), control1: pt(0.32, 0.91, in: r), control2: pt(0.17, 0.79, in: r))
        p.addCurve(to: pt(0.50, 0.09, in: r), control1: pt(0.17, 0.44, in: r), control2: pt(0.35, 0.28, in: r))
        p.closeSubpath()

        let pearlGrad = Gradient(stops: [
            .init(color: Color(hex: 0xFFB89A), location: 0.0),
            .init(color: Color(hex: 0xF27E63), location: 0.52),
            .init(color: Color(hex: 0xD45842), location: 1.0)
        ])
        ctx.fill(
            p,
            with: .linearGradient(
                pearlGrad,
                startPoint: CGPoint(x: r.minX + r.width * 0.35, y: r.minY + r.height * 0.10),
                endPoint: CGPoint(x: r.minX + r.width * 0.65, y: r.maxY)
            )
        )
        ctx.stroke(p, with: .color(Ink.primary), style: stroke)

        var glint = Path()
        glint.move(to: pt(0.36, 0.45, in: r))
        glint.addQuadCurve(to: pt(0.35, 0.66, in: r), control: pt(0.29, 0.56, in: r))
        ctx.stroke(
            glint,
            with: .color(Color(hex: 0xFFF9F0).opacity(0.92)),
            style: StrokeStyle(lineWidth: stroke.lineWidth * 0.95, lineCap: .round)
        )
        let pearlDot = CGRect(
            x: r.minX + r.width * 0.37,
            y: r.minY + r.height * 0.33,
            width: r.width * 0.08,
            height: r.height * 0.08
        )
        ctx.fill(Path(ellipseIn: pearlDot), with: .color(Color(hex: 0xFFFBF5).opacity(0.92)))
    }

    private func drawFlame(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        var outer = Path()
        outer.move(to: pt(0.54, 0.08, in: r))
        outer.addCurve(to: pt(0.84, 0.60, in: r), control1: pt(0.70, 0.24, in: r), control2: pt(0.86, 0.42, in: r))
        outer.addCurve(to: pt(0.50, 0.92, in: r), control1: pt(0.82, 0.80, in: r), control2: pt(0.68, 0.92, in: r))
        outer.addCurve(to: pt(0.16, 0.60, in: r), control1: pt(0.30, 0.92, in: r), control2: pt(0.16, 0.78, in: r))
        outer.addCurve(to: pt(0.36, 0.34, in: r), control1: pt(0.16, 0.46, in: r), control2: pt(0.26, 0.39, in: r))
        outer.addCurve(to: pt(0.54, 0.08, in: r), control1: pt(0.36, 0.22, in: r), control2: pt(0.45, 0.14, in: r))
        outer.closeSubpath()

        fillWash(&ctx, path: outer, top: Color(hex: 0xE8AD3A), bottom: Palette.coral, in: r)
        ctx.stroke(outer, with: .color(Ink.primary), style: stroke)

        var inner = Path()
        inner.move(to: pt(0.50, 0.48, in: r))
        inner.addCurve(to: pt(0.65, 0.72, in: r), control1: pt(0.60, 0.56, in: r), control2: pt(0.66, 0.64, in: r))
        inner.addCurve(to: pt(0.50, 0.85, in: r), control1: pt(0.64, 0.80, in: r), control2: pt(0.58, 0.85, in: r))
        inner.addCurve(to: pt(0.35, 0.72, in: r), control1: pt(0.42, 0.85, in: r), control2: pt(0.36, 0.80, in: r))
        inner.addCurve(to: pt(0.50, 0.48, in: r), control1: pt(0.34, 0.64, in: r), control2: pt(0.40, 0.56, in: r))
        inner.closeSubpath()
        ctx.fill(inner, with: .color(Palette.butterSoft))
    }

    private func drawGift(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        let bodyRect = CGRect(x: r.minX + r.width * 0.17, y: r.minY + r.height * 0.42, width: r.width * 0.66, height: r.height * 0.46)
        let lidRect = CGRect(x: r.minX + r.width * 0.12, y: r.minY + r.height * 0.28, width: r.width * 0.76, height: r.height * 0.16)
        let body = Path(roundedRect: bodyRect, cornerRadius: r.width * 0.08)
        let lid = Path(roundedRect: lidRect, cornerRadius: r.width * 0.06)

        fillWash(&ctx, path: body, top: Palette.pinkSoft, bottom: Palette.pink.opacity(0.65), in: r)
        fillWash(&ctx, path: lid, top: Palette.pink, bottom: Palette.berry, in: r)

        let ribbonRect = CGRect(x: r.minX + r.width * 0.43, y: r.minY + r.height * 0.28, width: r.width * 0.14, height: r.height * 0.60)
        ctx.fill(Path(ribbonRect), with: .color(Palette.butter))

        var bow = Path()
        bow.move(to: pt(0.50, 0.28, in: r))
        bow.addCurve(to: pt(0.28, 0.16, in: r), control1: pt(0.40, 0.12, in: r), control2: pt(0.26, 0.10, in: r))
        bow.addQuadCurve(to: pt(0.50, 0.28, in: r), control: pt(0.30, 0.28, in: r))
        bow.addCurve(to: pt(0.72, 0.16, in: r), control1: pt(0.60, 0.12, in: r), control2: pt(0.74, 0.10, in: r))
        bow.addQuadCurve(to: pt(0.50, 0.28, in: r), control: pt(0.70, 0.28, in: r))

        ctx.fill(bow, with: .color(Palette.butter))
        ctx.stroke(body, with: .color(Ink.primary), style: stroke)
        ctx.stroke(lid, with: .color(Ink.primary), style: stroke)
        ctx.stroke(bow, with: .color(Ink.primary), style: stroke)
    }

    private func drawCrown(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        var p = Path()
        p.move(to: pt(0.16, 0.78, in: r))
        p.addLine(to: pt(0.12, 0.34, in: r))
        p.addLine(to: pt(0.34, 0.50, in: r))
        p.addLine(to: pt(0.50, 0.22, in: r))
        p.addLine(to: pt(0.66, 0.50, in: r))
        p.addLine(to: pt(0.88, 0.34, in: r))
        p.addLine(to: pt(0.84, 0.78, in: r))
        p.closeSubpath()

        fillWash(&ctx, path: p, top: Color(hex: 0xE6B14A), bottom: Palette.butterDeep, in: r)
        ctx.stroke(p, with: .color(Ink.primary), style: stroke)

        let jewel = CGRect(x: r.minX + r.width * 0.44, y: r.minY + r.height * 0.56, width: r.width * 0.12, height: r.height * 0.12)
        ctx.fill(Path(ellipseIn: jewel), with: .color(Palette.coral))
    }

    private func drawBell(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        let clapper = CGRect(x: r.minX + r.width * 0.41, y: r.minY + r.height * 0.75, width: r.width * 0.18, height: r.height * 0.15)
        ctx.fill(Path(ellipseIn: clapper), with: .color(Palette.butterDeep))
        ctx.stroke(Path(ellipseIn: clapper), with: .color(Ink.primary), style: stroke)

        var bell = Path()
        bell.move(to: pt(0.50, 0.14, in: r))
        bell.addCurve(to: pt(0.76, 0.48, in: r), control1: pt(0.68, 0.14, in: r), control2: pt(0.76, 0.28, in: r))
        bell.addLine(to: pt(0.84, 0.72, in: r))
        bell.addQuadCurve(to: pt(0.80, 0.78, in: r), control: pt(0.85, 0.78, in: r))
        bell.addLine(to: pt(0.20, 0.78, in: r))
        bell.addQuadCurve(to: pt(0.16, 0.72, in: r), control: pt(0.15, 0.78, in: r))
        bell.addLine(to: pt(0.24, 0.48, in: r))
        bell.addCurve(to: pt(0.50, 0.14, in: r), control1: pt(0.24, 0.28, in: r), control2: pt(0.32, 0.14, in: r))
        bell.closeSubpath()

        fillWash(&ctx, path: bell, top: Color(hex: 0xE7B248), bottom: Palette.butterDeep, in: r)
        ctx.stroke(bell, with: .color(Ink.primary), style: stroke)
    }

    private func drawHeart(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        var p = Path()
        p.move(to: pt(0.50, 0.86, in: r))
        p.addCurve(to: pt(0.12, 0.40, in: r), control1: pt(0.24, 0.68, in: r), control2: pt(0.12, 0.55, in: r))
        p.addCurve(to: pt(0.50, 0.30, in: r), control1: pt(0.12, 0.18, in: r), control2: pt(0.38, 0.12, in: r))
        p.addCurve(to: pt(0.88, 0.40, in: r), control1: pt(0.62, 0.12, in: r), control2: pt(0.88, 0.18, in: r))
        p.addCurve(to: pt(0.50, 0.86, in: r), control1: pt(0.88, 0.55, in: r), control2: pt(0.76, 0.68, in: r))
        p.closeSubpath()

        fillWash(&ctx, path: p, top: Color(hex: 0xE488A6), bottom: Palette.berry, in: r)
        ctx.stroke(p, with: .color(Ink.primary), style: stroke)

        let dot = CGRect(x: r.minX + r.width * 0.25, y: r.minY + r.height * 0.29, width: r.width * 0.11, height: r.height * 0.11)
        ctx.fill(Path(ellipseIn: dot), with: .color(Palette.paper.opacity(0.85)))
    }

    private func drawStar(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        let center = CGPoint(x: r.midX, y: r.midY + r.height * 0.02)
        let outerR = r.width * 0.40
        let innerR = r.width * 0.19
        var p = Path()
        for i in 0..<10 {
            let angle = (Double(i) * .pi / 5.0) - (.pi / 2.0)
            let rad = i.isMultiple(of: 2) ? outerR : innerR
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * rad, y: center.y + CGFloat(sin(angle)) * rad)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        p.closeSubpath()

        fillWash(&ctx, path: p, top: Color(hex: 0xECC057), bottom: Palette.butterDeep, in: r)
        ctx.stroke(p, with: .color(Ink.primary), style: stroke)
    }

    private func drawMap(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        var left = Path()
        left.move(to: pt(0.12, 0.24, in: r))
        left.addLine(to: pt(0.37, 0.16, in: r))
        left.addLine(to: pt(0.37, 0.78, in: r))
        left.addLine(to: pt(0.12, 0.86, in: r))
        left.closeSubpath()

        var mid = Path()
        mid.move(to: pt(0.37, 0.16, in: r))
        mid.addLine(to: pt(0.63, 0.24, in: r))
        mid.addLine(to: pt(0.63, 0.86, in: r))
        mid.addLine(to: pt(0.37, 0.78, in: r))
        mid.closeSubpath()

        var right = Path()
        right.move(to: pt(0.63, 0.24, in: r))
        right.addLine(to: pt(0.88, 0.16, in: r))
        right.addLine(to: pt(0.88, 0.78, in: r))
        right.addLine(to: pt(0.63, 0.86, in: r))
        right.closeSubpath()

        ctx.fill(left, with: .color(Palette.mintSoft))
        ctx.fill(mid, with: .color(Palette.cream))
        ctx.fill(right, with: .color(Palette.mint.opacity(0.45)))

        var trail = Path()
        trail.move(to: pt(0.24, 0.62, in: r))
        trail.addQuadCurve(to: pt(0.52, 0.48, in: r), control: pt(0.38, 0.36, in: r))
        trail.addQuadCurve(to: pt(0.75, 0.56, in: r), control: pt(0.64, 0.62, in: r))
        ctx.stroke(trail, with: .color(Palette.coral), style: StrokeStyle(lineWidth: stroke.lineWidth * 0.9, lineCap: .round, dash: [r.width * 0.06, r.width * 0.06]))

        ctx.stroke(left, with: .color(Ink.primary), style: stroke)
        ctx.stroke(mid, with: .color(Ink.primary), style: stroke)
        ctx.stroke(right, with: .color(Ink.primary), style: stroke)
    }

    private func drawChest(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        let baseRect = CGRect(x: r.minX + r.width * 0.14, y: r.minY + r.height * 0.46, width: r.width * 0.72, height: r.height * 0.40)
        let base = Path(roundedRect: baseRect, cornerRadius: r.width * 0.08)

        var lid = Path()
        lid.move(to: pt(0.12, 0.46, in: r))
        lid.addCurve(to: pt(0.50, 0.18, in: r), control1: pt(0.14, 0.24, in: r), control2: pt(0.30, 0.18, in: r))
        lid.addCurve(to: pt(0.88, 0.46, in: r), control1: pt(0.70, 0.18, in: r), control2: pt(0.86, 0.24, in: r))
        lid.closeSubpath()

        fillWash(&ctx, path: base, top: Color(hex: 0xC68C64), bottom: Palette.soil, in: r)
        fillWash(&ctx, path: lid, top: Color(hex: 0xDA9F76), bottom: Color(hex: 0xAE744F), in: r)

        let strapLeft = Path(CGRect(x: r.minX + r.width * 0.26, y: r.minY + r.height * 0.22, width: r.width * 0.09, height: r.height * 0.64))
        let strapRight = Path(CGRect(x: r.minX + r.width * 0.65, y: r.minY + r.height * 0.22, width: r.width * 0.09, height: r.height * 0.64))
        ctx.fill(strapLeft, with: .color(Palette.butter))
        ctx.fill(strapRight, with: .color(Palette.butter))

        ctx.stroke(base, with: .color(Ink.primary), style: stroke)
        ctx.stroke(lid, with: .color(Ink.primary), style: stroke)

        let clasp = Path(roundedRect: CGRect(x: r.minX + r.width * 0.42, y: r.minY + r.height * 0.40, width: r.width * 0.16, height: r.height * 0.18), cornerRadius: r.width * 0.04)
        ctx.fill(clasp, with: .color(Color(hex: 0xECC057)))
        ctx.stroke(clasp, with: .color(Ink.primary), style: stroke)
    }

    private func drawCup(_ ctx: inout GraphicsContext, in r: CGRect, stroke: StrokeStyle) {
        var handle = Path()
        handle.move(to: pt(0.73, 0.45, in: r))
        handle.addCurve(to: pt(0.72, 0.71, in: r), control1: pt(0.92, 0.44, in: r), control2: pt(0.92, 0.71, in: r))
        ctx.stroke(handle, with: .color(Ink.primary), style: stroke)

        var cup = Path()
        cup.move(to: pt(0.17, 0.38, in: r))
        cup.addLine(to: pt(0.74, 0.38, in: r))
        cup.addLine(to: pt(0.71, 0.69, in: r))
        cup.addCurve(to: pt(0.455, 0.86, in: r), control1: pt(0.70, 0.80, in: r), control2: pt(0.59, 0.86, in: r))
        cup.addCurve(to: pt(0.20, 0.69, in: r), control1: pt(0.32, 0.86, in: r), control2: pt(0.21, 0.80, in: r))
        cup.closeSubpath()

        fillWash(&ctx, path: cup, top: Color(hex: 0xFAF3E8), bottom: Color(hex: 0xE5D6C3), in: r)
        let teaRim = Path(ellipseIn: CGRect(
            x: r.minX + r.width * 0.19,
            y: r.minY + r.height * 0.33,
            width: r.width * 0.53,
            height: r.height * 0.10
        ))
        ctx.fill(teaRim, with: .color(Palette.aquaLight.opacity(0.85)))
        ctx.stroke(cup, with: .color(Ink.primary), style: stroke)
        ctx.stroke(teaRim, with: .color(Ink.primary), style: StrokeStyle(lineWidth: stroke.lineWidth * 0.8, lineCap: .round))

        var steam = Path()
        steam.move(to: pt(0.38, 0.27, in: r))
        steam.addQuadCurve(to: pt(0.42, 0.13, in: r), control: pt(0.33, 0.20, in: r))
        steam.move(to: pt(0.54, 0.27, in: r))
        steam.addQuadCurve(to: pt(0.58, 0.13, in: r), control: pt(0.49, 0.20, in: r))
        ctx.stroke(steam, with: .color(Palette.aqua), style: StrokeStyle(lineWidth: stroke.lineWidth * 0.82, lineCap: .round))
    }
}

// MARK: - Pills & Badges

/// A cotton-paper capsule showing a tabular count beside a hand-inked storybook glyph.
struct CountPill: View {
    @Environment(\.dewyTheme) private var theme
    var glyph: ClayGlyph
    var value: Int
    var tint: Color
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            ClayIcon(glyph: glyph, size: compact ? 18 : 21)
            Text(value.formatted(.number))
                .font(.dewy(compact ? 14 : 15.5, .bold))
                .foregroundStyle(theme.ink)
                .contentTransition(.numericText(value: Double(value)))
                .monospacedDigit()
        }
        .padding(.leading, compact ? 7 : 8)
        .padding(.trailing, compact ? 11 : 13)
        .frame(height: compact ? 32 : 36)
        .background {
            PaperSurface(shape: Capsule(), fill: Palette.paper, tint: tint, elevation: 0.45)
        }
    }
}

/// An archival Dew Drops price tag.
struct PriceTag: View {
    var price: Int
    var affordable = true

    var body: some View {
        HStack(spacing: 4) {
            ClayIcon(glyph: .drop, size: 15)
            Text("\(price)")
                .font(.dewy(13.5, .bold))
                .monospacedDigit()
                .foregroundStyle(affordable ? Palette.coralDeep : Ink.soft)
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .frame(height: 26)
        .background(affordable ? Palette.coralSoft : Palette.creamDeep, in: Capsule())
        .overlay(
            Capsule().stroke(
                affordable ? Palette.coral.opacity(0.26) : Ink.hairline,
                lineWidth: 1
            )
        )
    }
}

/// Editorial antique-brass Dewy+ foil badge.
struct PlusBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 9, weight: .bold))
            Text("PLUS")
                .font(.dewy(9.5, .bold))
                .tracking(0.8)
        }
        .foregroundStyle(Palette.paper)
        .padding(.horizontal, 8)
        .frame(height: 21)
        .background(Palette.gold, in: Capsule())
        .overlay(Capsule().stroke(Color(hex: 0x7A5110).opacity(0.35), lineWidth: 0.75))
        .shadow(color: Palette.butterDeep.opacity(0.22), radius: 3, x: 0, y: 1.5)
    }
}

/// Compact editorial badge pill for chapter kickers, status tags and story markers.
struct StoryBadge: View {
    var text: String
    var systemImage: String?
    var tint: Color = Palette.aquaDeep
    var soft: Color = Palette.aquaSoft

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.dewy(11.5, .bold))
                .tracking(0.2)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(soft, in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.20), lineWidth: 1))
    }
}

// MARK: - Drinks

/// The illustrated drink from the asset catalog.
struct DrinkIcon: View {
    var kind: DrinkKind
    var size: CGFloat = 48

    var body: some View {
        Image(kind.imageName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// The drink illustration resting on a matte watercolor tile with a crisp ink hairline.
struct DrinkBadge: View {
    var kind: DrinkKind
    var size: CGFloat = 44

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
        DrinkIcon(kind: kind, size: size * 0.78)
            .frame(width: size, height: size)
            .background {
                shape
                    .fill(
                        LinearGradient(
                            colors: [kind.light.blended(with: Palette.paper, by: 0.32), kind.light],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        shape.stroke(kind.deep.opacity(0.14), lineWidth: 1)
                    }
            }
    }
}

// MARK: - Haptics

@MainActor
enum Haptics {
    /// Mirrors the user's setting.
    static var isEnabled = true

    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func splash() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.9)
    }

    static func select() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// A light rhythmic tick, e.g. while the drop counter rolls up.
    static func tick() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
    }
}
