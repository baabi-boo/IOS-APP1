import SwiftUI

struct DrinkPickerSheet: View {
    var onAdd: (DrinkKind, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme

    @State private var kind: DrinkKind = LaunchOptions.screenshot == "add" ? .coffee : .water
    @State private var amount: Double = 250
    @State private var showPaywall = false
    @State private var pop = 0

    private let presets: [Double] = [150, 250, 350, 500]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    private let range: ClosedRange<Double> = 50...1_000

    private var isLocked: Bool { kind.isPremium && !purchases.isPremium }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                preview
                amountCard
                drinksGrid
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(theme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryButton(
                title: isLocked ? "Unlock \(kind.name)" : "Add \(store.format(amount))",
                systemImage: isLocked ? "lock.fill" : "drop.fill",
                style: .tinted(kind.color, kind.deep)
            ) {
                if isLocked {
                    showPaywall = true
                } else {
                    onAdd(kind, amount)
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 6)
            .background {
                LinearGradient(colors: [theme.canvas.opacity(0), theme.canvas, theme.canvas], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            .animation(.smooth(duration: 0.3), value: kind)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(36)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: "Every sip counts", color: theme.inkSoft, size: 11)
                Text("Add a drink")
                    .font(.display(30))
                    .foregroundStyle(theme.ink)
            }
            Spacer()
            CircleIconButton(systemImage: "xmark") { dismiss() }
        }
    }

    private var preview: some View {
        HStack(spacing: 14) {
            DrinkIcon(kind: kind, size: 124)
                .id(kind)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .keyframeAnimator(initialValue: 1.0, trigger: pop) { content, scale in
                    content.scaleEffect(scale, anchor: .bottom)
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(0.88, duration: 0.1)
                        SpringKeyframe(1.08, duration: 0.18)
                        SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
                    }
                }
                .frame(width: 124, height: 130)

            VStack(alignment: .leading, spacing: 4) {
                Text(kind.name)
                    .font(.display(20))
                    .foregroundStyle(kind.deep)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(store.format(amount, withUnit: false))
                        .font(.display(52))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(value: amount))
                    Text(store.profile.unit.label)
                        .font(.display(20))
                        .foregroundStyle(Palette.ink.opacity(0.55))
                }
                .animation(.snappy, value: amount)
                Text(kind.blurb)
                    .font(.dewy(13, .semibold))
                    .foregroundStyle(Palette.ink.opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(kind.light)
                .overlay(alignment: .topTrailing) {
                    // Soft bubbles in the drink's color.
                    ZStack {
                        Circle().fill(kind.color.opacity(0.18)).frame(width: 90).offset(x: 26, y: -30)
                        Circle().fill(kind.color.opacity(0.14)).frame(width: 34).offset(x: -60, y: 8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 6) {
                FactChip(text: "\(Int(kind.hydration * 100))% hydrating", tint: kind.deep)
                FactChip(text: "counts \(store.format(amount * kind.hydration))", tint: kind.deep)
                if kind.caffeinePerML > 0 {
                    FactChip(text: "\(Int((amount * kind.caffeinePerML).rounded())) mg caffeine", tint: Color(hex: 0x8A5BD6))
                }
            }
            .offset(y: 15)
        }
        .padding(.bottom, 14)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: kind)
    }

    private var amountCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                stepButton("minus") { step(-1) }
                AmountSlider(value: $amount, range: range, step: store.profile.unit == .ml ? 10 : VolumeUnit.mlPerOunce, tint: kind.color, lip: kind.deep)
                stepButton("plus") { step(1) }
            }
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    ChipButton(title: store.format(preset), isSelected: abs(amount - preset) < 1, tint: kind.color, tintDeep: kind.deep) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { amount = preset }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .dewyCard(padding: 16)
        .padding(.top, 4)
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(CandyButtonStyle(fill: kind.color, lip: kind.deep, shape: AnyShape(Circle()), depth: 4))
    }

    private func step(_ direction: Double) {
        Haptics.select()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            amount = min(max(amount + direction * store.profile.unit.step, range.lowerBound), range.upperBound)
        }
    }

    private var drinksGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Drinks", trailing: purchases.isPremium ? "\(DrinkKind.allCases.count) drinks" : "4 free · \(DrinkKind.allCases.count - 4) with Dewy+")
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(DrinkKind.allCases) { option in
                    DrinkChoiceTile(
                        kind: option,
                        isSelected: option == kind,
                        isLocked: option.isPremium && !purchases.isPremium
                    ) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            kind = option
                            amount = option.defaultAmount
                        }
                        pop += 1
                    }
                }
            }
        }
    }
}

// MARK: - Pieces

private struct FactChip: View {
    var text: String
    var tint: Color

    var body: some View {
        Text(text)
            .font(.dewy(12, .heavy))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Color.white, in: Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            .lineLimit(1)
    }
}

/// One drink in the grid.
struct DrinkChoiceTile: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var isSelected: Bool
    var isLocked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                DrinkIcon(kind: kind, size: 52)
                Text(kind.name)
                    .font(.display(13))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .background(kind.light, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(isSelected ? kind.color : Color.clear, lineWidth: 3)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(kind.color, in: Circle())
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                        .offset(x: 5, y: -5)
                        .transition(.scale.combined(with: .opacity))
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Palette.ink.opacity(0.7), in: Circle())
                        .padding(6)
                }
            }
            .scaleEffect(isSelected ? 1.04 : 1)
            .shadow(color: isSelected ? kind.color.opacity(0.35) : .clear, radius: 10, x: 0, y: 6)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(isLocked ? "\(kind.name), Dewy+ only" : kind.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A chunky slider: a candy track filled with the drink color and a big white thumb.
struct AmountSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var tint: Color
    var lip: Color
    var unitName = "milliliters"

    @Environment(\.dewyTheme) private var theme
    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let thumb: CGFloat = 32
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let x = thumb / 2 + CGFloat(fraction) * (width - thumb)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.well)
                    .frame(height: 14)
                Capsule()
                    .fill(tint)
                    .frame(width: max(x, 14), height: 14)
                Circle()
                    .fill(Color.white)
                    .frame(width: thumb, height: thumb)
                    .overlay(Circle().strokeBorder(tint, lineWidth: 4))
                    .shadow(color: lip.opacity(0.35), radius: isDragging ? 10 : 5, x: 0, y: 3)
                    .scaleEffect(isDragging ? 1.15 : 1)
                    .offset(x: x - thumb / 2)
            }
            .frame(height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let raw = Double((gesture.location.x - thumb / 2) / (width - thumb))
                        let clamped = min(max(raw, 0), 1)
                        let newValue = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
                        let stepped = (newValue / step).rounded() * step
                        let final = min(max(stepped, range.lowerBound), range.upperBound)
                        if abs(final - value) >= step * 0.5 {
                            Haptics.select()
                        }
                        value = final
                    }
                    .onEnded { _ in isDragging = false }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .frame(height: 44)
        .accessibilityElement()
        .accessibilityLabel("Amount")
        .accessibilityValue("\(Int(value)) \(unitName)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + step * 5, range.upperBound)
            case .decrement: value = max(value - step * 5, range.lowerBound)
            @unknown default: break
            }
        }
    }
}
