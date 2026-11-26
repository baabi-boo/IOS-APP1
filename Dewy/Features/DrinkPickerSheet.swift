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
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    private let range: ClosedRange<Double> = 50...1_000

    private var isLocked: Bool { kind.isPremium && !purchases.isPremium }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(theme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(38)
        .presentationBackground(theme.canvas)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
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
                CapsLabel(text: "Every sip counts", color: theme.inkSoft, size: 11)
                Text("Add a drink")
                    .font(.display(34))
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
            style: .tinted(kind.color, kind.deep)
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
        .padding(.top, 14)
        .padding(.bottom, 6)
        .background {
            LinearGradient(colors: [theme.canvas.opacity(0), theme.canvas, theme.canvas], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
        .animation(.smooth(duration: 0.3), value: kind)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
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
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: kind)
    }

    private var heroArt: some View {
        ZStack {
            // Clay glow in the drink's color.
            Circle()
                .fill(RadialGradient(colors: [kind.color.opacity(0.42), kind.color.opacity(0)], center: .center, startRadius: 4, endRadius: 78))
                .frame(width: 156, height: 156)
            Circle()
                .fill(LinearGradient(colors: [Color.white.opacity(0.85), kind.light.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                .frame(width: 104, height: 104)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .shadow(color: kind.deep.opacity(0.18), radius: 10, x: 0, y: 6)
            Ellipse()
                .fill(kind.deep.opacity(0.2))
                .frame(width: 84, height: 14)
                .blur(radius: 5)
                .offset(y: 60)
            DrinkIcon(kind: kind, size: 130)
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
        }
        .frame(width: 140, height: 150)
    }

    private var heroText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(kind.name)
                .font(.display(22))
                .foregroundStyle(kind.deep)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(store.format(amount, withUnit: false))
                    .font(.display(52))
                    .foregroundStyle(theme.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: amount))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(store.profile.unit.label)
                    .font(.display(20))
                    .foregroundStyle(theme.inkSoft)
            }
            .animation(.snappy, value: amount)
            Text(kind.blurb)
                .font(.dewy(14, .semibold))
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
                PickerFactChip(text: "\(Int((amount * kind.caffeinePerML).rounded())) mg caffeine", tint: Color(hex: 0x8A6BC9))
            }
            Spacer(minLength: 0)
        }
    }

    private var heroBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)
        return ClaySurface(shape: shape, fill: kind.light.blended(with: .white, by: 0.25), glow: kind.color)
            .overlay {
                // A soft wash of the drink color with a couple of clay bubbles.
                ZStack {
                    LinearGradient(colors: [Color.white.opacity(0), kind.color.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Circle()
                        .fill(kind.color.opacity(0.16))
                        .frame(width: 150, height: 150)
                        .offset(x: 140, y: -70)
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 34, height: 34)
                        .offset(x: 70, y: -62)
                    Circle()
                        .fill(kind.color.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .offset(x: -150, y: 80)
                }
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
        .dewyCard(padding: 18)
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(CandyButtonStyle(fill: kind.color, lip: kind.deep, shape: AnyShape(Circle()), depth: 4))
        .accessibilityLabel(icon == "plus" ? "More" : "Less")
    }

    private func step(_ direction: Double) {
        Haptics.select()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            amount = min(max(amount + direction * store.profile.unit.step, range.lowerBound), range.upperBound)
        }
    }

    // MARK: Drinks

    private var drinksGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Drinks", trailing: purchases.isPremium ? "\(DrinkKind.allCases.count) drinks" : "4 free · \(DrinkKind.allCases.count - 4) with Dewy+")
            LazyVGrid(columns: columns, spacing: 14) {
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

private struct PickerFactChip: View {
    var text: String
    var tint: Color

    var body: some View {
        Text(text)
            .font(.dewy(12, .heavy))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background {
                ClaySurface(shape: Capsule(), fill: .white, glow: tint, elevation: 0.35)
            }
    }
}

/// One drink in the grid: a white clay tile that lifts and takes a drink-colored rim when selected.
struct DrinkChoiceTile: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var isSelected: Bool
    var isLocked: Bool
    var action: () -> Void

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 22, style: .continuous) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(kind.light)
                        .frame(width: 48, height: 48)
                        .offset(y: 4)
                    DrinkIcon(kind: kind, size: 52)
                }
                .frame(height: 56)
                Text(kind.name)
                    .font(.display(13))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 94)
            .background {
                ClaySurface(shape: shape, fill: .white, glow: isSelected ? kind.color : Palette.shadow, elevation: isSelected ? 0.95 : 0.55)
            }
            .overlay {
                shape.strokeBorder(isSelected ? kind.color : Color.clear, lineWidth: 2.5)
            }
            .overlay(alignment: .topTrailing) { cornerBadge }
            .offset(y: isSelected ? -3 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
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
                .scaleEffect(0.78, anchor: .topTrailing)
                .offset(x: 6, y: -7)
        } else if isSelected {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(kind.color, in: Circle())
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                .shadow(color: kind.deep.opacity(0.3), radius: 3, x: 0, y: 2)
                .offset(x: 5, y: -5)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

/// A puffy clay slider: a recessed track, a glossy candy fill in the drink color and a big white clay thumb.
struct AmountSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var tint: Color
    var lip: Color
    var unitName = "milliliters"

    @Environment(\.dewyTheme) private var theme
    @State private var isDragging = false

    private var trackHeight: CGFloat { 18 }
    private var thumb: CGFloat { 36 }

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
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .frame(height: 46)
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
            .fill(theme.well.shadow(.inner(color: Palette.shadow.opacity(0.28), radius: 2, x: 0, y: 1.5)))
            .overlay(Capsule().stroke(Color(hex: 0xEADBCD).opacity(0.7), lineWidth: 1))
            .frame(height: trackHeight)
    }

    private func fill(width: CGFloat) -> some View {
        Capsule()
            .fill(LinearGradient(colors: [tint.blended(with: .white, by: 0.22), tint], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .frame(height: 5)
                    .padding(.horizontal, 6)
                    .padding(.top, 3)
            }
            .frame(width: width, height: trackHeight)
            .shadow(color: lip.opacity(0.25), radius: 4, x: 0, y: 2)
    }

    private var thumbView: some View {
        ZStack {
            ClaySurface(shape: Circle(), fill: .white, glow: lip, elevation: isDragging ? 0.9 : 0.6)
            Circle()
                .fill(LinearGradient(colors: [tint.blended(with: .white, by: 0.2), tint], startPoint: .top, endPoint: .bottom))
                .frame(width: 14, height: 14)
                .overlay(alignment: .top) {
                    Circle().fill(Color.white.opacity(0.5)).frame(width: 6, height: 4).padding(.top, 2)
                }
        }
        .frame(width: thumb, height: thumb)
        .scaleEffect(isDragging ? 1.14 : 1)
    }
}
