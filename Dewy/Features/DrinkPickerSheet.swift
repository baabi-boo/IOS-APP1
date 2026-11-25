import SwiftUI

struct DrinkPickerSheet: View {
    var onAdd: (DrinkKind, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme

    @State private var kind: DrinkKind = LaunchOptions.screenshot == "add" ? .tea : .water
    @State private var amount: Double = LaunchOptions.screenshot == "add" ? 330 : 250
    @State private var showPaywall = false

    private let presets: [Double] = [150, 250, 330, 500]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ZStack {
            DreamyBackground()

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add a drink")
                            .font(.dewy(26, .heavy))
                            .foregroundStyle(theme.ink)
                        Text("Every sip makes Dewy happier")
                            .font(.dewy(14, .medium))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Spacer()
                    CircleIconButton(systemImage: "xmark") { dismiss() }
                }
                .padding(.top, 8)

                preview
                amountControls
                drinkGrid

                Spacer(minLength: 0)

                PrimaryButton(title: "Add \(store.format(amount))", systemImage: "drop.fill") {
                    onAdd(kind, amount)
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(36)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: Sections

    private var preview: some View {
        HStack(spacing: 22) {
            DrinkCup(kind: kind, fill: min(amount / 650, 1))
                .frame(width: 104, height: 132)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: amount)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: kind)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(store.format(amount, withUnit: false))
                        .font(.dewy(48, .heavy))
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: amount))
                    Text(store.profile.unit.label)
                        .font(.dewy(20, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
                .animation(.snappy, value: amount)

                Label("\(kind.name) · \(Int(kind.hydration * 100))% hydrating", systemImage: "drop.halffull")
                    .font(.dewy(14, .semibold))
                    .foregroundStyle(kind.color)
                    .contentTransition(.interpolate)

                Text("Counts as \(store.format(amount * kind.hydration))")
                    .font(.dewy(13, .medium))
                    .foregroundStyle(theme.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .glassCard()
    }

    private var amountControls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                stepButton("minus") { amount = max(50, amount - store.profile.unit.step) }
                Slider(value: $amount, in: 50...1_000, step: 10)
                    .tint(kind.color)
                stepButton("plus") { amount = min(1_000, amount + store.profile.unit.step) }
            }
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    ChipButton(title: store.format(preset), isSelected: abs(amount - preset) < 1) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { amount = preset }
                    }
                }
            }
        }
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(theme.ink)
                .frame(width: 38, height: 38)
                .background(theme.card, in: Circle())
                .overlay(Circle().strokeBorder(theme.cardStroke, lineWidth: 1))
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private var drinkGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(DrinkKind.allCases) { option in
                let locked = option.isPremium && !purchases.isPremium
                DrinkTile(kind: option, isSelected: option == kind, isLocked: locked) {
                    if locked {
                        Haptics.warning()
                        showPaywall = true
                    } else {
                        Haptics.select()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                            kind = option
                            amount = option.defaultAmount
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Pieces

struct DrinkTile: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var isSelected: Bool
    var isLocked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(kind.emoji)
                    .font(.system(size: 28))
                    .frame(width: 58, height: 58)
                    .background(kind.color.opacity(isSelected ? 0.3 : 0.16), in: Circle())
                    .overlay(Circle().strokeBorder(isSelected ? kind.color : .clear, lineWidth: 2.5))
                    .overlay(alignment: .topTrailing) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(theme.accentGradient, in: Circle())
                                .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                                .offset(x: 3, y: -3)
                        }
                    }
                    .scaleEffect(isSelected ? 1.08 : 1)
                Text(kind.name)
                    .font(.dewy(13, isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? theme.ink : theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(theme.cardStroke))
                        .shadow(color: kind.color.opacity(0.25), radius: 10, x: 0, y: 5)
                }
            }
            .opacity(isLocked ? 0.75 : 1)
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// A large animated glass showing the selected drink and amount.
struct DrinkCup: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var fill: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                TumblerShape(taper: 0.12)
                    .fill(Color.white.opacity(theme.isDark ? 0.14 : 0.65))
                ZStack {
                    WaveShape(level: 0.08 + fill * 0.84, phase: t * 1.8 + 1.4, amplitude: 4, frequency: 1)
                        .fill(kind.color.opacity(0.45))
                    WaveShape(level: 0.08 + fill * 0.84, phase: t * 2.4, amplitude: 5, frequency: 1)
                        .fill(LinearGradient(colors: [kind.color.opacity(0.65), kind.color], startPoint: .top, endPoint: .bottom))
                }
                .clipShape(TumblerShape(taper: 0.12))

                // Gloss
                Capsule()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 7, height: 56)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -30, y: -10)

                TumblerShape(taper: 0.12)
                    .stroke(Color.white, lineWidth: 3)

                Text(kind.emoji)
                    .font(.system(size: 30))
                    .offset(y: CGFloat(8 + sin(t * 2) * 3))
                    .id(kind)
                    .transition(.scale.combined(with: .opacity))
            }
            .shadow(color: kind.color.opacity(0.3), radius: 14, x: 0, y: 8)
        }
    }
}
