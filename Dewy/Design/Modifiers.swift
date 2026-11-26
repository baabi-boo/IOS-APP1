import SwiftUI
import UIKit

// MARK: - Cards

/// A solid, softly lifted card: the main content surface across the app.
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
                    .shadow(color: theme.shadow, radius: 18, x: 0, y: 8)
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
            .offset(y: visible ? 0 : 22)
            .scaleEffect(visible ? 1 : 0.96)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.06), value: visible)
    }

    /// Places the view on a canvas-colored sheet with big rounded top corners
    /// that keeps going below the bottom edge, so overscrolling never reveals the hero.
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
                UnevenRoundedRectangle(topLeadingRadius: radius, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: radius, style: .continuous)
                    .fill(theme.canvas)
                    .padding(.bottom, -1_200)
                    .shadow(color: Color.black.opacity(theme.isDark ? 0.3 : 0.08), radius: 20, x: 0, y: -6)
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
            .tracking(size * 0.1)
            .foregroundStyle(color)
    }
}

/// Section title with an optional trailing note.
struct SectionHeader: View {
    @Environment(\.dewyTheme) private var theme
    var title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            CapsLabel(text: title, color: theme.inkSoft, size: 13)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.dewy(13, .bold))
                    .foregroundStyle(theme.inkSoft)
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

/// The big pill-shaped call to action: chunky caps on a dark navy capsule.
struct PrimaryButton: View {
    enum Style {
        /// Dark navy capsule (yellow in the dark theme).
        case ink
        /// White capsule with hero-colored text, for use on colored backgrounds.
        case light
    }

    @Environment(\.dewyTheme) private var theme
    var title: String
    var systemImage: String?
    var style: Style = .ink
    var isLoading = false
    var action: () -> Void

    var body: some View {
        let background = style == .ink ? theme.cta : Color.white
        let foreground = style == .ink ? theme.onCta : theme.heroDeep
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(foreground)
                } else {
                    Text(title.uppercased())
                        .tracking(1.2)
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 17, weight: .heavy))
                    }
                }
            }
            .font(.dewy(18, .black))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(background, in: Capsule())
            .overlay(alignment: .top) {
                // A soft top highlight gives the flat pill a little candy shine.
                Capsule()
                    .fill(Color.white.opacity(style == .ink ? 0.08 : 0))
                    .frame(height: 30)
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
            }
            .shadow(color: background.opacity(theme.isDark ? 0.35 : 0.3), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.96))
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
                .background(onHero ? Color.white.opacity(0.22) : theme.well, in: Circle())
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
            .font(.dewy(15, .heavy))
            .foregroundStyle(isSelected ? Color.white : theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background {
                Capsule()
                    .fill(isSelected ? selectedColor : theme.well)
                    .shadow(color: isSelected ? selectedColor.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
            }
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// A rounded square holding an SF Symbol in a bold color.
struct IconTile: View {
    var systemImage: String
    var color: Color
    var size: CGFloat = 36
    var filled = true

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.44, weight: .heavy))
            .foregroundStyle(filled ? Color.white : color)
            .frame(width: size, height: size)
            .background(filled ? color : color.opacity(0.15), in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
    }
}

// MARK: - Haptics

@MainActor
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func splash() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.9)
    }

    static func select() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
