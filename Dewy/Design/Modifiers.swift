import SwiftUI
import UIKit

// MARK: - Glass card

struct GlassCard: ViewModifier {
    @Environment(\.dewyTheme) private var theme
    var padding: CGFloat
    var radius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .padding(padding)
            .background {
                shape
                    .fill(theme.card)
                    .background(.ultraThinMaterial, in: shape)
                    .overlay(shape.strokeBorder(theme.cardStroke, lineWidth: 1))
                    .shadow(color: theme.shadow, radius: 20, x: 0, y: 10)
            }
    }
}

extension View {
    func glassCard(padding: CGFloat = 18, radius: CGFloat = 28) -> some View {
        modifier(GlassCard(padding: padding, radius: radius))
    }

    /// Fades and lifts a view into place, staggered by `index`.
    func floatIn(_ visible: Bool, index: Int = 0) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 18)
            .scaleEffect(visible ? 1 : 0.97)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.06), value: visible)
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
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Big pill-shaped call to action with a gradient and soft glow.
struct PrimaryButton: View {
    @Environment(\.dewyTheme) private var theme
    var title: String
    var systemImage: String?
    var isLoading = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                    if let systemImage {
                        Image(systemName: systemImage)
                    }
                }
            }
            .font(.dewy(18, .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(theme.accentGradient, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .shadow(color: theme.accent.opacity(0.4), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.96))
    }
}

/// A small round glass icon button.
struct CircleIconButton: View {
    @Environment(\.dewyTheme) private var theme
    var systemImage: String
    var size: CGFloat = 40
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(theme.ink)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(theme.cardStroke, lineWidth: 1))
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
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if isLocked {
                    Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                }
            }
            .font(.dewy(15, .semibold))
            .foregroundStyle(isSelected ? Color.white : theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background {
                if isSelected {
                    Capsule().fill(theme.accentGradient)
                        .shadow(color: theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    Capsule().fill(theme.card)
                        .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
                }
            }
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

// MARK: - Section header

struct SectionHeader: View {
    @Environment(\.dewyTheme) private var theme
    var title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.dewy(20, .bold))
                .foregroundStyle(theme.ink)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.dewy(14, .semibold))
                    .foregroundStyle(theme.inkSoft)
            }
        }
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
