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
        let emoji: String
        let title: String
        let detail: String
        var id: String { title }
    }

    private let features = [
        Feature(emoji: "🎨", title: "4 dreamy themes", detail: "Peachy, Matcha, Lavender & Midnight"),
        Feature(emoji: "🍓", title: "Every drink", detail: "Smoothies, milk, soda, sparkling & more"),
        Feature(emoji: "📈", title: "30-day insights", detail: "See your monthly flow and rhythm"),
        Feature(emoji: "🔔", title: "Custom reminders", detail: "Nudges every hour, 90 min or 3 hours"),
        Feature(emoji: "💙", title: "Support a tiny indie app", detail: "Help Dewy keep growing")
    ]

    var body: some View {
        ZStack {
            DreamyBackground()

            ScrollView {
                VStack(spacing: 22) {
                    hero
                    featureList
                    plans
                    cta
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)

            ConfettiView(trigger: celebrate, origin: UnitPoint(x: 0.5, y: 0.2))
                .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            CircleIconButton(systemImage: "xmark", size: 36) { dismiss() }
                .padding(.trailing, 20)
                .padding(.top, 14)
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
            MascotView(progress: 0.92, mood: .ecstatic, size: 132, accessory: .crown)
                .padding(.top, 30)
                .floatIn(appeared, index: 0)

            HStack(spacing: 0) {
                Text("Dewy")
                    .foregroundStyle(theme.ink)
                Text("+")
                    .foregroundStyle(theme.accentGradient)
            }
            .font(.dewy(46, .black))
            .shimmer()
            .floatIn(appeared, index: 1)

            Text("Make every sip a little more magical")
                .font(.dewy(17, .semibold))
                .foregroundStyle(theme.inkSoft)
                .multilineTextAlignment(.center)
                .floatIn(appeared, index: 2)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                HStack(spacing: 14) {
                    Text(feature.emoji)
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                        .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(feature.title)
                            .font(.dewy(16, .bold))
                            .foregroundStyle(theme.ink)
                        Text(feature.detail)
                            .font(.dewy(13, .medium))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.accent)
                }
                .floatIn(appeared, index: index + 3)
            }
        }
        .glassCard()
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
                title: selected == .yearly ? "Start 3-day free trial" : "Unlock Dewy+",
                systemImage: "sparkles",
                isLoading: purchases.isPurchasing
            ) {
                Task { await buy() }
            }
            .scaleEffect(pulse ? 1.025 : 1)

            Text(selected == .lifetime ? "One-time purchase. Yours forever." : "Cancel anytime in Settings. No commitment.")
                .font(.dewy(12, .medium))
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
        .font(.dewy(13, .semibold))
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
                        .strokeBorder(isSelected ? theme.accent : theme.inkSoft.opacity(0.35), lineWidth: 2)
                    if isSelected {
                        Circle()
                            .fill(theme.accentGradient)
                            .padding(5)
                            .transition(.scale)
                    }
                }
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.dewy(17, .heavy))
                            .foregroundStyle(theme.ink)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.dewy(10, .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    plan == .yearly ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(Palette.flame),
                                    in: Capsule()
                                )
                        }
                    }
                    Text(plan.detail)
                        .font(.dewy(13, .medium))
                        .foregroundStyle(theme.inkSoft)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price)
                        .font(.dewy(18, .heavy))
                        .foregroundStyle(theme.ink)
                    Text(plan.cadence)
                        .font(.dewy(12, .semibold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.card)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isSelected ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.cardStroke), lineWidth: isSelected ? 2.5 : 1)
            }
            .shadow(color: isSelected ? theme.accent.opacity(0.25) : theme.shadow, radius: isSelected ? 14 : 8, x: 0, y: 6)
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }
}
