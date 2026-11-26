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
    @State private var appeared = LaunchOptions.freezesMotion

    private let presets: [Double] = [150, 250, 330, 500]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 11), count: 4)
    private let range: ClosedRange<Double> = 50...1_000

    private var isLocked: Bool { kind.isPremium && !purchases.isPremium }

    /// Deep, readable gouache pigment for controls & CTA so light drinks never look muddy.
    private var activeFill: Color { kind.deep }
    private var activeLip: Color { kind.deep.blended(with: Ink.primary, by: 0.30) }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                    .floatIn(appeared, index: 0)
                hero
                    .floatIn(appeared, index: 1)
                amountCard
                    .floatIn(appeared, index: 2)
                drinksGrid
                    .floatIn(appeared, index: 3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(theme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground(theme.canvas)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .preferredColorScheme(.light)
        }
        .onAppear {
            if !appeared {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.05))
                    appeared = true
                }
            }
        }
    }

    // MARK: Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: "Every sip counts", color: theme.inkSoft, size: 10.5)
                Text("Add a drink")
                    .font(.display(32, .bold))
                    .tracking(-0.4)
                    .foregroundStyle(theme.ink)
            }
            Spacer()
            CircleIconButton(systemImage: "xmark") { dismiss() }
        }
    }

    private var footer: some View {
        PrimaryButton(
            title: isLocked ? "Unlock \(kind.name)" : "Pour it in",
            systemImage: isLocked ? "lock.fill" : "drop.fill",
            style: .tinted(activeFill, activeLip)
        ) {
            if isLocked {
                Haptics.tap()
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
            LinearGradient(
                stops: [
                    .init(color: theme.canvas.opacity(0), location: 0),
                    .init(color: theme.canvas, location: 0.24),
                    .init(color: theme.canvas, location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .animation(.smooth(duration: 0.28), value: kind)
    }

    // MARK: Tasting Card Hero

    private var hero: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                heroArt
                heroText
                Spacer(minLength: 0)
            }
            factRow
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background { heroBackground }
        .overlay(alignment: .topTrailing) {
            if isLocked {
                PlusBadge()
                    .padding(14)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: kind)
    }

    private var heroArt: some View {
        ZStack {
            Circle()
                .fill(kind.light.blended(with: Palette.paper, by: 0.18))
                .overlay(Circle().stroke(kind.deep.opacity(0.16), lineWidth: 1))
                .frame(width: 112, height: 112)

            Ellipse()
                .fill(Palette.shadow.opacity(0.14))
                .frame(width: 72, height: 12)
                .blur(radius: 4)
                .offset(y: 48)

            DrinkIcon(kind: kind, size: 116)
                .id(kind)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
                .keyframeAnimator(initialValue: 1.0, trigger: pop) { content, scale in
                    content.scaleEffect(scale, anchor: .bottom)
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(0.90, duration: 0.1)
                        SpringKeyframe(1.06, duration: 0.18)
                        SpringKeyframe(1.0, duration: 0.36, spring: .bouncy)
                    }
                }
        }
        .frame(width: 128, height: 132)
    }

    private var heroText: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(kind.name)
                .font(.display(21, .semibold))
                .foregroundStyle(kind.deep)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(store.format(amount, withUnit: false))
                    .font(.display(48, .bold))
                    .tracking(-0.8)
                    .foregroundStyle(theme.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: amount))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(store.profile.unit.label)
                    .font(.display(19, .medium))
                    .foregroundStyle(theme.inkSoft)
            }
            .animation(.snappy, value: amount)

            Text(kind.blurb)
                .font(.editorialItalic(14))
                .foregroundStyle(theme.inkSoft)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var factRow: some View {
        HStack(spacing: 6) {
            PickerFactChip(text: "\(Int(kind.hydration * 100))% hydrating", tint: kind.deep)
            PickerFactChip(text: "counts \(store.format(amount * kind.hydration))", tint: kind.deep)
            if kind.caffeinePerML > 0 {
                PickerFactChip(text: "\(Int((amount * kind.caffeinePerML).rounded())) mg caffeine", tint: Palette.lilac)
            }
            Spacer(minLength: 0)
        }
    }

    private var heroBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return PaperSurface(shape: shape, fill: Palette.paper, tint: kind.color, elevation: 0.8)
            .overlay {
                LinearGradient(
                    colors: [kind.light.opacity(0.62), kind.light.opacity(0.14), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(shape)
                .allowsHitTesting(false)
            }
    }

    // MARK: Amount

    private var amountCard: some View {
        VStack(spacing: 16) {
            HStack {
                SectionHeader(title: "How much?")
                Spacer()
            }
            HStack(spacing: 12) {
                stepButton("minus") { step(-1) }
                AmountSlider(
                    value: $amount,
                    range: range,
                    step: store.profile.unit == .ml ? 10 : VolumeUnit.mlPerOunce,
                    tint: activeFill,
                    lip: activeLip
                )
                stepButton("plus") { step(1) }
            }
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    ChipButton(
                        title: store.format(preset),
                        isSelected: abs(amount - preset) < 1,
                        tint: activeFill,
                        tintDeep: activeLip
                    ) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { amount = preset }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .dewyCard(padding: 18)
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.paper)
                .frame(width: 42, height: 42)
        }
        .buttonStyle(StampButtonStyle(fill: activeFill, lip: activeLip, shape: AnyShape(Circle()), depth: 3))
        .accessibilityLabel(icon == "plus" ? "More" : "Less")
    }

    private func step(_ direction: Double) {
        Haptics.select()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            amount = min(max(amount + direction * store.profile.unit.step, range.lowerBound), range.upperBound)
        }
    }

    // MARK: Drinks

    private var drinksGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Drinks",
                trailing: purchases.isPremium ? "\(DrinkKind.allCases.count) drinks" : "4 free · \(DrinkKind.allCases.count - 4) Dewy+"
            )
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DrinkKind.allCases) { option in
                    DrinkChoiceTile(
                        kind: option,
                        isSelected: option == kind,
                        isLocked: option.isPremium && !purchases.isPremium
                    ) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
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

private struct PickerFactChip: View {
    var text: String
    var tint: Color

    var body: some View {
        Text(text)
            .font(.dewy(11.5, .bold))
            .monospacedDigit()
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(Palette.paper, in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.24), lineWidth: 1))
    }
}

/// Tactile cotton-paper drink tile with handcrafted watercolor vessel art.
struct DrinkChoiceTile: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var isSelected: Bool
    var isLocked: Bool
    var action: () -> Void

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(kind.light)
                        .overlay(Circle().stroke(kind.deep.opacity(0.14), lineWidth: 0.75))
                        .frame(width: 48, height: 48)
                        .offset(y: 3)
                    DrinkIcon(kind: kind, size: 50)
                }
                .frame(height: 54)

                Text(kind.name)
                    .font(.display(12.5, .semibold))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background {
                PaperSurface(
                    shape: shape,
                    fill: isSelected ? kind.light.blended(with: Palette.paper, by: 0.55) : Palette.paper,
                    tint: isSelected ? kind.deep : Palette.shadow,
                    elevation: isSelected ? 0.85 : 0.5
                )
            }
            .overlay {
                shape.strokeBorder(isSelected ? kind.deep : Color.clear, lineWidth: 2)
            }
            .overlay(alignment: .topTrailing) { cornerBadge }
            .offset(y: isSelected ? -2 : 0)
            .animation(.spring(response: 0.34, dampingFraction: 0.76), value: isSelected)
            .contentShape(shape)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(isLocked ? "\(kind.name), Dewy+ only" : kind.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var cornerBadge: some View {
        if isLocked {
            PlusBadge()
                .scaleEffect(0.76, anchor: .topTrailing)
                .offset(x: 5, y: -6)
        } else if isSelected {
            Image(systemName: "checkmark")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(Palette.paper)
                .frame(width: 20, height: 20)
                .background(kind.deep, in: Circle())
                .overlay(Circle().strokeBorder(Palette.paper, lineWidth: 1.5))
                .offset(x: 4, y: -4)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

/// Matte tactile cotton-paper slider with recessed linen track and letterpress thumb.
struct AmountSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var tint: Color
    var lip: Color
    var unitName = "milliliters"

    @Environment(\.dewyTheme) private var theme
    @State private var isDragging = false

    private var trackHeight: CGFloat { 14 }
    private var thumb: CGFloat { 32 }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let span = max(range.upperBound - range.lowerBound, 0.0001)
            let fraction = min(max((value - range.lowerBound) / span, 0), 1)
            let x = thumb / 2 + CGFloat(fraction) * max(width - thumb, 1)
            ZStack(alignment: .leading) {
                track
                fill(width: max(x, trackHeight))
                thumbView
                    .offset(x: x - thumb / 2)
            }
            .frame(height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let raw = Double((gesture.location.x - thumb / 2) / max(width - thumb, 1))
                        let clamped = min(max(raw, 0), 1)
                        let newValue = range.lowerBound + clamped * span
                        let stepped = (newValue / step).rounded() * step
                        let final = min(max(stepped, range.lowerBound), range.upperBound)
                        if abs(final - value) >= step * 0.5 {
                            Haptics.select()
                        }
                        value = final
                    }
                    .onEnded { _ in isDragging = false }
            )
            .animation(.spring(response: 0.28, dampingFraction: 0.74), value: isDragging)
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

    private var track: some View {
        Capsule()
            .fill(theme.well)
            .overlay(Capsule().stroke(Ink.hairlineStrong, lineWidth: 1))
            .frame(height: trackHeight)
    }

    private func fill(width: CGFloat) -> some View {
        Capsule()
            .fill(tint)
            .overlay(Capsule().stroke(lip.opacity(0.35), lineWidth: 0.75))
            .frame(width: width, height: trackHeight)
    }

    private var thumbView: some View {
        ZStack {
            PaperSurface(shape: Circle(), fill: Palette.paper, tint: lip, elevation: isDragging ? 0.95 : 0.65)
            Circle()
                .fill(tint)
                .frame(width: 11, height: 11)
        }
        .frame(width: thumb, height: thumb)
        .scaleEffect(isDragging ? 1.12 : 1)
    }
}
