import SwiftUI
import UIKit

// MARK: - Clay surfaces
//
// Every surface in Dewy is "clay": a soft filled shape with
//   1. a bright inner highlight along the top edge (light from above),
//   2. a faint inner shade along the bottom edge (volume),
//   3. a warm colored drop shadow plus a tight contact shadow (it rests on the paper).
// Cards, buttons, chips and tiles all use the same recipe at different sizes.

/// The clay recipe as a reusable background.
struct ClaySurface<S: Shape>: View {
    var shape: S
    var fill: Color = .white
    /// Tints the drop shadow, e.g. a friend's color under their card.
    var glow: Color = Palette.shadow
    var elevation: CGFloat = 1

    var body: some View {
        shape
            .fill(fill)
            .overlay {
                // Volume: lighter at the top, a whisper darker at the bottom.
                shape.fill(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.55), location: 0),
                        .init(color: .white.opacity(0), location: 0.35),
                        .init(color: .black.opacity(0), location: 0.75),
                        .init(color: Color(hex: 0x6B4A3A).opacity(0.05), location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                ))
            }
            .overlay {
                // Inner highlight rim.
                shape.strokeBorderCompat(LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0)], startPoint: .top, endPoint: .center), lineWidth: 1.5)
            }
            .shadow(color: glow.opacity(0.22 * elevation), radius: 18 * elevation, x: 0, y: 10 * elevation)
            .shadow(color: Palette.shadow.opacity(0.10), radius: 1.5, x: 0, y: 1.5)
    }
}

private extension Shape {
    /// Strokes inside the shape's edge so the rim never spills out.
    func strokeBorderCompat<Style: ShapeStyle>(_ style: Style, lineWidth: CGFloat) -> some View {
        RimInsetShape(base: self, amount: lineWidth / 2).stroke(style, lineWidth: lineWidth)
    }
}

private struct RimInsetShape<Base: Shape>: Shape {
    var base: Base
    var amount: CGFloat
    func path(in rect: CGRect) -> Path { base.path(in: rect.insetBy(dx: amount, dy: amount)) }
}

/// A white clay card: the main content surface.
struct DewyCard: ViewModifier {
    @Environment(\.dewyTheme) private var theme
    var padding: CGFloat
    var radius: CGFloat
    var fill: Color?
    var glow: Color?

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                ClaySurface(shape: RoundedRectangle(cornerRadius: radius, style: .continuous), fill: fill ?? theme.card, glow: glow ?? Palette.shadow)
            }
    }
}

extension View {
    func dewyCard(padding: CGFloat = 18, radius: CGFloat = 28, fill: Color? = nil, glow: Color? = nil) -> some View {
        modifier(DewyCard(padding: padding, radius: radius, fill: fill, glow: glow))
    }

    /// Fades and lifts a view into place, staggered by `index`.
    func floatIn(_ visible: Bool, index: Int = 0) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 26)
            .scaleEffect(visible ? 1 : 0.96)
            .animation(.spring(response: 0.6, dampingFraction: 0.78).delay(Double(index) * 0.05), value: visible)
    }

    /// Places the view on a cream sheet with big rounded top corners
    /// that keeps going below the bottom edge, so overscrolling never reveals the scene.
    func canvasSheet(radius: CGFloat = 38) -> some View {
        modifier(CanvasSheet(radius: radius))
    }
}

private struct CanvasSheet: ViewModifier {
    @Environment(\.dewyTheme) private var theme
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(alignment: .top) {
                let shape = UnevenRoundedRectangle(topLeadingRadius: radius, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: radius, style: .continuous)
                shape
                    .fill(theme.canvas)
                    .overlay(alignment: .top) {
                        shape.stroke(LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.05)), lineWidth: 2)
                    }
                    .padding(.bottom, -1_200)
                    .shadow(color: Palette.shadow.opacity(0.16), radius: 24, x: 0, y: -8)
            }
    }
}

// MARK: - Labels

/// Small all-caps label with generous tracking.
struct CapsLabel: View {
    var text: String
    var color: Color
    var size: CGFloat = 12

    var body: some View {
        Text(text.uppercased())
            .font(.dewy(size, .heavy))
            .tracking(size * 0.12)
            .foregroundStyle(color)
    }
}

/// Section title in the display face with an optional trailing note or action.
struct SectionHeader: View {
    @Environment(\.dewyTheme) private var theme
    var title: String
    var trailing: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.display(22))
                .foregroundStyle(theme.ink)
            Spacer()
            if let trailing {
                if let action {
                    Button(action: action) {
                        HStack(spacing: 3) {
                            Text(trailing)
                            Image(systemName: "chevron.right").font(.system(size: 11, weight: .heavy))
                        }
                        .font(.dewy(14, .heavy))
                        .foregroundStyle(theme.link)
                    }
                    .buttonStyle(SquishyButtonStyle())
                } else {
                    Text(trailing)
                        .font(.dewy(13, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Buttons

/// A bouncy, jelly-like press effect used across the app.
struct SquishyButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

/// The signature puffy clay button: a rounded face with a glossy top, sitting on a deeper lip.
/// Pressing squashes it onto the lip, like a gummy key.
struct CandyButtonStyle: ButtonStyle {
    var fill: Color
    var lip: Color
    var shape: AnyShape = AnyShape(Capsule())
    var depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .background {
                shape.fill(LinearGradient(colors: [fill.blended(with: .white, by: 0.18), fill], startPoint: .top, endPoint: .bottom))
                    .overlay {
                        // Glossy pill of light across the top.
                        GeometryReader { proxy in
                            Capsule()
                                .fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                                .frame(width: proxy.size.width * 0.78, height: max(proxy.size.height * 0.34, 4))
                                .offset(x: proxy.size.width * 0.11, y: proxy.size.height * 0.08)
                        }
                        .clipShape(shape)
                    }
                    .overlay {
                        shape.stroke(.white.opacity(0.35), lineWidth: 1)
                    }
            }
            .scaleEffect(x: pressed ? 1.02 : 1, y: pressed ? 0.96 : 1, anchor: .bottom)
            .offset(y: pressed ? depth * 0.8 : 0)
            .background {
                shape.fill(lip).offset(y: depth)
            }
            .padding(.bottom, depth)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: pressed)
    }
}

/// The big call to action: chunky display type on a puffy clay capsule.
struct PrimaryButton: View {
    enum Style {
        /// Aqua: "do this".
        case accent
        /// White face for colored backgrounds.
        case light
        /// Coral: rewards and spending drops.
        case reward
        /// A custom fill, e.g. the selected drink's color.
        case tinted(Color, Color)
    }

    @Environment(\.dewyTheme) private var theme
    var title: String
    var systemImage: String?
    var style: Style = .accent
    var isLoading = false
    var height: CGFloat = 60
    var action: () -> Void

    var body: some View {
        let colors = palette
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(colors.text)
                } else {
                    Text(title)
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .heavy))
                    }
                }
            }
            .font(.display(height > 54 ? 21 : 18))
            .foregroundStyle(colors.text)
            .shadow(color: colors.lip.opacity(0.35), radius: 0, x: 0, y: 1)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .contentShape(Capsule())
        }
        .buttonStyle(CandyButtonStyle(fill: colors.fill, lip: colors.lip))
        .shadow(color: colors.lip.opacity(0.3), radius: 16, x: 0, y: 10)
    }

    private var palette: (fill: Color, lip: Color, text: Color) {
        switch style {
        case .accent: (theme.accent, theme.accentDeep, .white)
        case .light: (Color.white, Color(hex: 0xEADBD0), theme.ink)
        case .reward: (Palette.coral, Palette.coralDeep, .white)
        case .tinted(let fill, let lip): (fill, lip, .white)
        }
    }
}

/// A small round clay icon button.
struct CircleIconButton: View {
    @Environment(\.dewyTheme) private var theme
    var systemImage: String
    var size: CGFloat = 40
    var onHero = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .heavy))
                .foregroundStyle(theme.ink)
                .frame(width: size, height: size)
                .background {
                    ClaySurface(shape: Circle(), fill: onHero ? .white.opacity(0.85) : .white, elevation: 0.5)
                }
                .contentShape(Circle())
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// A selectable capsule chip.
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
                    Image(systemName: "lock.fill").font(.system(size: 10, weight: .heavy))
                }
            }
            .font(.display(16))
            .foregroundStyle(isSelected ? .white : theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 40)
        }
        .buttonStyle(CandyButtonStyle(fill: isSelected ? selectedColor : .white, lip: lip, depth: 3))
    }

    private var lip: Color {
        if !isSelected { return Color(hex: 0xEEDFD3) }
        if let tintDeep { return tintDeep }
        if let tint { return tint.blended(with: .black, by: 0.18) }
        return theme.accentDeep
    }
}

/// A clay segmented control, with a puffy aqua thumb that springs between options.
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { selection = item }
                } label: {
                    Text(title(item))
                        .font(.display(15))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(isSelected ? .white : theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(LinearGradient(colors: [Palette.aquaLight, theme.accent], startPoint: .top, endPoint: .bottom))
                                    .overlay(alignment: .top) {
                                        Capsule().fill(.white.opacity(0.35)).frame(height: 10).padding(.horizontal, 14).padding(.top, 4)
                                    }
                                    .shadow(color: theme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
                                    .matchedGeometryEffect(id: "thumb", in: namespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.95))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background {
            Capsule().fill(theme.well)
                .overlay(Capsule().stroke(Color(hex: 0xEADBCD).opacity(0.7), lineWidth: 1))
        }
    }
}

/// A rounded square holding an SF Symbol in a pastel clay tile.
struct IconTile: View {
    var systemImage: String
    var color: Color
    var size: CGFloat = 38
    var filled = true

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.44, weight: .heavy))
            .foregroundStyle(filled ? Color.white : color.blended(with: .black, by: 0.15))
            .shadow(color: color.blended(with: .black, by: 0.3).opacity(filled ? 0.3 : 0), radius: 0, x: 0, y: 1)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                    .fill(filled
                          ? LinearGradient(colors: [color.blended(with: .white, by: 0.2), color], startPoint: .top, endPoint: .bottom)
                          : LinearGradient(colors: [color.opacity(0.16), color.opacity(0.22)], startPoint: .top, endPoint: .bottom))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                            .stroke(LinearGradient(colors: [.white.opacity(filled ? 0.6 : 0.8), .clear], startPoint: .top, endPoint: .center), lineWidth: 1.2)
                    }
            }
    }
}

// MARK: - Art

/// A clay illustration from the asset catalog, falling back to an SF Symbol tile
/// if the art is missing so a screen never shows an empty square.
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

/// The little clay icons (drop, flame, gift…) drawn at text sizes.
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

struct ClayIcon: View {
    var glyph: ClayGlyph
    var size: CGFloat = 22

    var body: some View {
        Group {
            if Art.exists(glyph.imageName) {
                Image(glyph.imageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: glyph.fallback)
                    .font(.system(size: size * 0.82, weight: .heavy))
                    .foregroundStyle(glyph.tint)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A clay capsule showing a count next to a clay icon, e.g. the Dew Drops balance or the streak.
struct CountPill: View {
    @Environment(\.dewyTheme) private var theme
    var glyph: ClayGlyph
    var value: Int
    var tint: Color
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            ClayIcon(glyph: glyph, size: compact ? 20 : 24)
            Text(value.formatted(.number))
                .font(.display(compact ? 15 : 17))
                .foregroundStyle(theme.ink)
                .contentTransition(.numericText(value: Double(value)))
                .monospacedDigit()
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .frame(height: compact ? 32 : 38)
        .background {
            ClaySurface(shape: Capsule(), fill: .white, glow: tint, elevation: 0.55)
        }
    }
}

/// A coral price tag in Dew Drops, or a lock for Dewy+ items.
struct PriceTag: View {
    var price: Int
    var affordable = true

    var body: some View {
        HStack(spacing: 3) {
            ClayIcon(glyph: .drop, size: 16)
            Text("\(price)")
                .font(.display(14))
                .foregroundStyle(affordable ? Palette.coralDeep : Ink.soft)
        }
        .padding(.leading, 5)
        .padding(.trailing, 9)
        .frame(height: 26)
        .background(affordable ? Palette.coralSoft : Color(hex: 0xF4ECE6), in: Capsule())
    }
}

/// The Dewy+ crown badge.
struct PlusBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill").font(.system(size: 10, weight: .black))
            Text("PLUS").font(.dewy(10, .black)).tracking(0.6)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Palette.gold, in: Capsule())
        .shadow(color: Palette.butterDeep.opacity(0.35), radius: 4, x: 0, y: 2)
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

/// The drink illustration on its pale clay tile, used wherever a drink is listed.
struct DrinkBadge: View {
    var kind: DrinkKind
    var size: CGFloat = 44

    var body: some View {
        DrinkIcon(kind: kind, size: size * 0.8)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                    .fill(LinearGradient(colors: [kind.light.blended(with: .white, by: 0.3), kind.light], startPoint: .top, endPoint: .bottom))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                            .stroke(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center), lineWidth: 1.2)
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
