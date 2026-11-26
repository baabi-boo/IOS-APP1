import SwiftUI
import UIKit

// MARK: - Cards

/// A solid white card with a soft shadow tinted by the world's sky: the main content surface.
struct DewyCard: ViewModifier {
    @Environment(\.dewyTheme) private var theme
    var padding: CGFloat
    var radius: CGFloat
    var fill: Color?

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .padding(padding)
            .background {
                shape
                    .fill(fill ?? theme.card)
                    .shadow(color: theme.shadow, radius: 16, x: 0, y: 8)
            }
    }
}

extension View {
    func dewyCard(padding: CGFloat = 18, radius: CGFloat = 28, fill: Color? = nil) -> some View {
        modifier(DewyCard(padding: padding, radius: radius, fill: fill))
    }

    /// Fades and lifts a view into place, staggered by `index`.
    func floatIn(_ visible: Bool, index: Int = 0) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 24)
            .scaleEffect(visible ? 1 : 0.97)
            .animation(.spring(response: 0.62, dampingFraction: 0.8).delay(Double(index) * 0.05), value: visible)
    }

    /// Places the view on a canvas-colored sheet with big rounded top corners
    /// that keeps going below the bottom edge, so overscrolling never reveals the scene.
    func canvasSheet(radius: CGFloat = 36) -> some View {
        modifier(CanvasSheet(radius: radius))
    }
}

private struct CanvasSheet: ViewModifier {
    @Environment(\.dewyTheme) private var theme
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(alignment: .top) {
                UnevenRoundedRectangle(topLeadingRadius: radius, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: radius, style: .continuous)
                    .fill(theme.canvas)
                    .padding(.bottom, -1_200)
                    .shadow(color: Color.black.opacity(theme.isDark ? 0.3 : 0.07), radius: 20, x: 0, y: -6)
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
                .font(.display(21))
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
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// The signature "candy" button: a solid face sitting on a darker lip.
/// Pressing pushes the face down onto the lip, like a real gummy key.
struct CandyButtonStyle: ButtonStyle {
    var fill: Color
    var lip: Color
    var shape: AnyShape = AnyShape(Capsule())
    var depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .background {
                shape.fill(fill)
                    .overlay(alignment: .top) {
                        // Candy shine across the top.
                        shape.fill(LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0)], startPoint: .top, endPoint: .center))
                    }
            }
            .offset(y: pressed ? depth * 0.8 : 0)
            .background {
                shape.fill(lip).offset(y: depth)
            }
            .padding(.bottom, depth)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: pressed)
    }
}

/// The big call to action: chunky display type on a candy capsule.
struct PrimaryButton: View {
    enum Style {
        /// The world's accent color.
        case accent
        /// White face for colored backgrounds.
        case light
        /// A custom fill, e.g. the selected drink's color.
        case tinted(Color, Color)
    }

    @Environment(\.dewyTheme) private var theme
    var title: String
    var systemImage: String?
    var style: Style = .accent
    var isLoading = false
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
            .font(.display(21))
            .foregroundStyle(colors.text)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Capsule())
        }
        .buttonStyle(CandyButtonStyle(fill: colors.fill, lip: colors.lip))
        .shadow(color: colors.lip.opacity(theme.isDark ? 0.3 : 0.28), radius: 14, x: 0, y: 10)
    }

    private var palette: (fill: Color, lip: Color, text: Color) {
        switch style {
        case .accent: (theme.accent, theme.accentDeep, theme.onAccent)
        case .light: (Color.white, Color(hex: 0xD9E4F2), theme.isDark ? Palette.ink : theme.accent)
        case .tinted(let fill, let lip): (fill, lip, .white)
        }
    }
}

/// A small round icon button. On colored areas it turns translucent white.
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
                .foregroundStyle(onHero ? Color.white : theme.ink)
                .frame(width: size, height: size)
                .background(onHero ? Color.white.opacity(0.24) : theme.well, in: Circle())
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
                if isLocked {
                    Image(systemName: "lock.fill").font(.system(size: 10, weight: .heavy))
                }
            }
            .font(.display(16))
            .foregroundStyle(isSelected ? (tint == nil ? theme.onAccent : .white) : theme.ink)
            .padding(.horizontal, 15)
            .frame(height: 40)
        }
        .buttonStyle(CandyButtonStyle(fill: isSelected ? selectedColor : theme.well, lip: lip, depth: 3))
    }

    private var lip: Color {
        if !isSelected {
            return theme.isDark ? Color.white.opacity(0.04) : Color(hex: 0xDCE0EC)
        }
        if let tintDeep { return tintDeep }
        if let tint { return tint.opacity(0.7) }
        return theme.accentDeep
    }
}

/// A rounded square holding an SF Symbol in a bold color, with a soft candy shine.
struct IconTile: View {
    var systemImage: String
    var color: Color
    var size: CGFloat = 38
    var filled = true

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.44, weight: .heavy))
            .foregroundStyle(filled ? Color.white : color)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(filled ? color : color.opacity(0.15))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                            .fill(LinearGradient(colors: [Color.white.opacity(filled ? 0.25 : 0), .clear], startPoint: .top, endPoint: .center))
                    }
            }
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

/// The drink illustration on its pale tile, used wherever a drink is listed.
struct DrinkBadge: View {
    var kind: DrinkKind
    var size: CGFloat = 44

    var body: some View {
        DrinkIcon(kind: kind, size: size * 0.86)
            .frame(width: size, height: size)
            .background(kind.light, in: RoundedRectangle(cornerRadius: size * 0.34, style: .continuous))
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
}
