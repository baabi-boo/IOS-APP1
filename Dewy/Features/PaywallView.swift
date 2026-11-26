import SwiftUI

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var selected: PurchaseManager.Plan = .yearly
    @State private var appeared = false
    @State private var celebrate = 0
    @State private var pulse = false

    private struct Feature: Identifiable {
        let icon: String
        let color: Color
        let title: String
        let detail: String
        var id: String { title }
    }

    private let features = [
        Feature(icon: "paintpalette.fill", color: Palette.grape, title: "4 bold themes", detail: "Peachy, Matcha, Lavender & Midnight"),
        Feature(icon: "cup.and.saucer.fill", color: Palette.tangerine, title: "Every drink", detail: "Smoothies, milk, soda, sparkling & more"),
        Feature(icon: "chart.bar.fill", color: Palette.sky, title: "30-day insights", detail: "See your monthly flow and rhythm"),
        Feature(icon: "bell.badge.fill", color: Palette.coral, title: "Custom reminders", detail: "Nudges every hour, 90 min or 3 hours"),
        Feature(icon: "heart.fill", color: Palette.berry, title: "Support a tiny indie app", detail: "Help Dewy keep growing")
    ]

    /// A rainbow of drinks shows off everything Dewy+ unlocks.
    private let rainbow: [LiquidBand] = [
        LiquidBand(color: DrinkKind.water.color, upTo: 0.2),
        LiquidBand(color: DrinkKind.juice.color, upTo: 0.38),
        LiquidBand(color: DrinkKind.tea.color, upTo: 0.55),
        LiquidBand(color: DrinkKind.smoothie.color, upTo: 0.73),
        LiquidBand(color: DrinkKind.sparkling.color, upTo: 0.92)
    ]

    var body: some View {
        ZStack {
            theme.hero.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    hero
                    VStack(spacing: 20) {
                        featureList
                        plans
                        cta
                        footer
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .padding(.bottom, 30)
                    .canvasSheet()
                }
            }
            .scrollIndicators(.hidden)

            ConfettiView(trigger: celebrate, origin: UnitPoint(x: 0.5, y: 0.2))
                .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            CircleIconButton(systemImage: "xmark", size: 38, onHero: true) { dismiss() }
                .padding(.trailing, 20)
                .padding(.top, 18)
        }
        .onAppear {
            appeared = true
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(0.8)) {
                pulse = true
            }
        }
        .alert("Hmm, something went wrong", isPresented: Binding(
            get: { purchases.errorMessage != nil },
            set: { if !$0 { purchases.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchases.errorMessage ?? "")
        }
    }

    // MARK: Sections

    private var hero: some View {
        VStack(spacing: 6) {
            MascotView(progress: 0.92, mood: .ecstatic, size: 138, accessory: .crown, bands: rainbow)
                .floatIn(appeared, index: 0)

            HStack(spacing: 0) {
                Text("Dewy")
                    .foregroundStyle(.white)
                Text("+")
                    .foregroundStyle(Palette.sunshine)
            }
            .font(.dewy(56, .black))
            .shadow(color: theme.heroDeep.opacity(0.5), radius: 0, x: 0, y: 4)
            .floatIn(appeared, index: 1)

            Text("Make every sip a little more magical")
                .font(.dewy(17, .heavy))
                .foregroundStyle(theme.onHeroSoft)
                .multilineTextAlignment(.center)
                .floatIn(appeared, index: 2)
        }
        .padding(.top, 58)
        .padding(.bottom, 36)
        .frame(maxWidth: .infinity)
        .background {
            HeroBackdrop(rays: true, rayCenter: UnitPoint(x: 0.5, y: 0.4))
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                HStack(spacing: 14) {
                    IconTile(systemImage: feature.icon, color: feature.color, size: 42)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(feature.title)
                            .font(.dewy(16, .heavy))
                            .foregroundStyle(theme.ink)
                        Text(feature.detail)
                            .font(.dewy(13, .semibold))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Palette.leafDeep, in: Circle())
                }
                .floatIn(appeared, index: index + 3)
            }
        }
        .dewyCard()
    }

    private var plans: some View {
        VStack(spacing: 10) {
            ForEach(Array(PurchaseManager.Plan.allCases.enumerated()), id: \.element.id) { index, plan in
                PlanCard(
                    plan: plan,
                    price: purchases.price(for: plan),
                    isSelected: selected == plan
                ) {
                    Haptics.select()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { selected = plan }
                }
                .floatIn(appeared, index: index + 8)
            }
        }
    }

    private var cta: some View {
        VStack(spacing: 10) {
            PrimaryButton(
                title: selected == .yearly ? "Start free trial" : "Unlock Dewy+",
                systemImage: "sparkles",
                isLoading: purchases.isPurchasing
            ) {
                Task { await buy() }
            }
            .scaleEffect(pulse ? 1.025 : 1)

            Text(selected == .lifetime ? "One-time purchase. Yours forever." : "Cancel anytime in Settings. No commitment.")
                .font(.dewy(12, .semibold))
                .foregroundStyle(theme.inkSoft)
        }
        .floatIn(appeared, index: 11)
    }

    private var footer: some View {
        HStack(spacing: 18) {
            Button("Restore") { Task { await purchases.restore() } }
            Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Link("Privacy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
        }
        .font(.dewy(13, .bold))
        .foregroundStyle(theme.inkSoft)
    }

    private func buy() async {
        let success = await purchases.purchase(selected)
        guard success else { return }
        celebrate += 1
        Haptics.success()
        try? await Task.sleep(for: .seconds(1.6))
        dismiss()
    }
}

private struct PlanCard: View {
    @Environment(\.dewyTheme) private var theme
    var plan: PurchaseManager.Plan
    var price: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? theme.accent : theme.inkSoft.opacity(0.35), lineWidth: 2.5)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(theme.accent, in: Circle())
                            .transition(.scale)
                    }
                }
                .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.dewy(18, .black))
                            .foregroundStyle(theme.ink)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.dewy(10, .black))
                                .tracking(0.6)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    plan == .yearly ? AnyShapeStyle(theme.accent) : AnyShapeStyle(Palette.flame),
                                    in: Capsule()
                                )
                        }
                    }
                    Text(plan.detail)
                        .font(.dewy(13, .semibold))
                        .foregroundStyle(theme.inkSoft)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price)
                        .font(.dewy(19, .black))
                        .foregroundStyle(theme.ink)
                    Text(plan.cadence)
                        .font(.dewy(12, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.card)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 3)
            }
            .shadow(color: isSelected ? theme.accent.opacity(0.25) : theme.shadow, radius: isSelected ? 14 : 8, x: 0, y: 6)
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }
}
