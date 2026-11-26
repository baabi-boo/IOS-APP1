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
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        ZStack {
            HeroBackdrop(top: kind.color, bottom: kind.color)
                .overlay(LinearGradient(colors: [Color.white.opacity(0.1), Color.black.opacity(0.12)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
                .animation(.smooth(duration: 0.5), value: kind)

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 22)
                        .padding(.top, 24)
                    preview
                        .padding(.horizontal, 22)
                        .padding(.vertical, 22)
                    panel
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PrimaryButton(title: "Add \(store.format(amount))", systemImage: "drop.fill") {
                    onAdd(kind, amount)
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .background {
                    LinearGradient(colors: [theme.canvas.opacity(0), theme.canvas, theme.canvas], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(38)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: "Every sip counts", color: theme.onHeroSoft, size: 12)
                Text("Add a drink")
                    .font(.dewy(30, .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            CircleIconButton(systemImage: "xmark", onHero: true) { dismiss() }
        }
    }

    private var preview: some View {
        HStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 150, height: 150)
                Circle()
                    .fill(Color.white)
                    .frame(width: 124, height: 124)
                    .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    DrinkVessel(
                        kind: kind,
                        fill: 0.12 + min(amount / 650, 1) * 0.78,
                        width: 62,
                        wavePhase: timeline.date.timeIntervalSinceReferenceDate * 2.4
                    )
                }
                .frame(width: 62, height: 78)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: amount)
                .id(kind)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: kind)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(store.format(amount, withUnit: false))
                        .font(.dewy(56, .black))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: amount))
                    Text(store.profile.unit.label)
                        .font(.dewy(22, .heavy))
                        .foregroundStyle(theme.onHeroSoft)
                }
                .animation(.snappy, value: amount)
                .shadow(color: Color.black.opacity(0.12), radius: 0, x: 0, y: 3)

                CapsLabel(text: "\(kind.name) · \(Int(kind.hydration * 100))% hydrating", color: .white, size: 12)

                Text("Counts as \(store.format(amount * kind.hydration))")
                    .font(.dewy(14, .bold))
                    .foregroundStyle(theme.onHeroSoft)
            }
            Spacer(minLength: 0)
        }
    }

    private var panel: some View {
        VStack(spacing: 22) {
            amountControls
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Drinks", trailing: purchases.isPremium ? nil : "4 free · 4 with Dewy+")
                drinkGrid
            }
            afterCard
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 16)
        .canvasSheet()
    }

    private var amountControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                stepButton("minus") { amount = max(50, amount - store.profile.unit.step) }
                Slider(value: $amount, in: 50...1_000, step: 10)
                    .tint(kind.color)
                stepButton("plus") { amount = min(1_000, amount + store.profile.unit.step) }
            }
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    ChipButton(title: store.format(preset), isSelected: abs(amount - preset) < 1, tint: kind.color) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { amount = preset }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .dewyCard()
    }

    /// Shows what today's progress will look like once this drink is logged.
    private var afterCard: some View {
        let added = amount * kind.hydration
        let after = store.todayTotal + added
        let progress = after / store.goal
        let bands = store.todayBands + [LiquidBand(color: kind.color, upTo: progress)]
        return HStack(spacing: 14) {
            MascotView(progress: progress, mood: DewyMood(progress: progress), size: 50, bands: bands, backdrop: .light, animated: false)
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    CapsLabel(text: "After this drink", color: theme.inkSoft, size: 11)
                    Spacer()
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.dewy(16, .black))
                        .foregroundStyle(kind.color)
                        .contentTransition(.numericText(value: progress))
                }
                Text("\(store.format(after)) of \(store.format(store.goal))")
                    .font(.dewy(17, .heavy))
                    .foregroundStyle(theme.ink)
                    .contentTransition(.numericText(value: after))
                DrinkStripe(bands: bands, track: theme.well)
                    .frame(height: 10)
            }
        }
        .dewyCard(padding: 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: after)
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(kind.color, in: Circle())
                .shadow(color: kind.color.opacity(0.4), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.85))
    }

    private var drinkGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
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
            VStack(spacing: 8) {
                DrinkVessel(kind: kind, fill: 0.72, width: 32)
                    .frame(height: 42)
                    .scaleEffect(isSelected ? 1.1 : 1)
                Text(kind.name.uppercased())
                    .font(.dewy(10, .black))
                    .tracking(0.4)
                    .foregroundStyle(isSelected ? kind.color : theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(isSelected ? kind.color : Color.clear, lineWidth: 3)
                    }
                    .shadow(color: isSelected ? kind.color.opacity(0.3) : theme.shadow, radius: isSelected ? 12 : 8, x: 0, y: 5)
            }
            .overlay(alignment: .topTrailing) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Color(hex: 0x1E2340), in: Circle())
                        .overlay(Circle().strokeBorder(theme.card, lineWidth: 2))
                        .offset(x: 3, y: -3)
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(kind.color, in: Circle())
                        .overlay(Circle().strokeBorder(theme.card, lineWidth: 2))
                        .offset(x: 4, y: -4)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .opacity(isLocked ? 0.75 : 1)
        }
        .buttonStyle(SquishyButtonStyle())
    }
}
