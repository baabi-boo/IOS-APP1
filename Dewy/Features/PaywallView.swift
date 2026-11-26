import SwiftUI

/// Dewy+ has its own identity in every world: a dreamy violet sky, purple candy and gold.
enum PlusPalette {
    static let violet = Color(hex: 0x8B5CF6)
    static let violetDeep = Color(hex: 0x6236D9)
    static let soft = Color(hex: 0xF1EAFF)
    static let gold = Color(hex: 0xFFD45C)
    static let sky = LinearGradient(stops: [
        .init(color: Color(hex: 0x6C55F5), location: 0),
        .init(color: Color(hex: 0xB46CF2), location: 0.45),
        .init(color: Color(hex: 0xFF9DB0), location: 0.8),
        .init(color: Color(hex: 0xFFD3A6), location: 1)
    ], startPoint: .top, endPoint: .bottom)
}

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var selected: PurchaseManager.Plan = .yearly
    @State private var appeared = false
    @State private var celebrate = 0
    @State private var pulse = false

    /// A rainbow of drinks shows off everything Dewy+ unlocks.
    private let rainbow: [LiquidBand] = [
        LiquidBand(color: DrinkKind.water.color, upTo: 0.2),
        LiquidBand(color: DrinkKind.juice.color, upTo: 0.38),
        LiquidBand(color: DrinkKind.matcha.color, upTo: 0.55),
        LiquidBand(color: DrinkKind.smoothie.color, upTo: 0.73),
        LiquidBand(color: DrinkKind.sparkling.color, upTo: 0.92)
    ]

    var body: some View {
        ZStack {
            theme.canvas.ignoresSafeArea()

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

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                CloudPuff()
                    .fill(LinearGradient(colors: [.white, Color(hex: 0xF3E6FF)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 230, height: 70)
                    .offset(y: 26)
                MascotView(progress: 0.92, mood: .ecstatic, size: 160, accessory: .crown, bands: rainbow, showsShadow: false)
            }
            .padding(.top, 34)
            .floatIn(appeared, index: 0)

            HStack(spacing: 0) {
                Text("Dewy")
                    .foregroundStyle(.white)
                Text("+")
                    .foregroundStyle(PlusPalette.gold)
            }
            .font(.display(62))
            .shadow(color: PlusPalette.violetDeep.opacity(0.35), radius: 0, x: 0, y: 4)
            .padding(.top, 12)
            .floatIn(appeared, index: 1)

            Text("Make every sip a little more magical")
                .font(.display(18, .medium))
                .foregroundStyle(Color.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .floatIn(appeared, index: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 34)
        .background(alignment: .top) {
            PlusSky()
                .padding(.top, -400)
                .padding(.bottom, -60)
        }
    }

    // MARK: Features

    private var featureList: some View {
        VStack(spacing: 16) {
            featureRow(title: "All 5 worlds", detail: "Sunset, Meadow, Dreamy & Midnight") {
                WorldOrb()
            }
            featureRow(title: "12 tasty drinks", detail: "Matcha, coconut, lemonade, cocoa & more") {
                DrinkBadge(kind: .coconut, size: 50)
            }
            featureRow(title: "30-day insights", detail: "Your monthly flow, rhythm and caffeine") {
                IconTile(systemImage: "chart.bar.fill", color: Palette.sky, size: 50)
            }
            featureRow(title: "Custom reminders", detail: "Every hour, 90 minutes or 3 hours") {
                IconTile(systemImage: "bell.badge.fill", color: Palette.coral, size: 50)
            }
            featureRow(title: "Support a tiny indie app", detail: "Help Dewy and friends keep growing") {
                IconTile(systemImage: "heart.fill", color: Palette.berry, size: 50)
            }
        }
        .dewyCard(padding: 18)
        .floatIn(appeared, index: 3)
    }

    private func featureRow<Icon: View>(title: String, detail: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 14) {
            icon()
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.display(18))
                    .foregroundStyle(theme.ink)
                Text(detail)
                    .font(.dewy(13, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Palette.mint, in: Circle())
        }
    }

    // MARK: Plans

    private var plans: some View {
        VStack(spacing: 12) {
            ForEach(PurchaseManager.Plan.allCases) { plan in
                PlanCard(plan: plan, price: purchases.price(for: plan), isSelected: selected == plan) {
                    Haptics.select()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { selected = plan }
                }
            }
        }
        .floatIn(appeared, index: 4)
    }

    private var cta: some View {
        VStack(spacing: 10) {
            PrimaryButton(
                title: selected == .yearly ? "Start my free trial" : "Unlock Dewy+",
                systemImage: "sparkles",
                style: .tinted(PlusPalette.violet, PlusPalette.violetDeep),
                isLoading: purchases.isPurchasing
            ) {
                Task { await buy() }
            }
            .scaleEffect(pulse ? 1.02 : 1)

            Text(selected == .lifetime ? "One-time purchase. Yours forever." : "Cancel anytime in Settings. No commitment.")
                .font(.dewy(12, .semibold))
                .foregroundStyle(theme.inkSoft)
        }
        .floatIn(appeared, index: 5)
    }

    private var footer: some View {
        HStack(spacing: 18) {
            Button("Restore") { Task { await purchases.restore() } }
            Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Link("Privacy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
        }
        .font(.display(14, .medium))
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
                        .strokeBorder(isSelected ? PlusPalette.violet : theme.inkSoft.opacity(0.35), lineWidth: 2.5)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(PlusPalette.violet, in: Circle())
                            .transition(.scale)
                    }
                }
                .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.display(19))
                            .foregroundStyle(theme.ink)
                        if let badge = plan.badge {
                            Text(badge.capitalized)
                                .font(.display(12))
                                .foregroundStyle(plan == .yearly ? Palette.ink : .white)
                                .padding(.horizontal, 9)
                                .frame(height: 22)
                                .background(
                                    plan == .yearly ? AnyShapeStyle(PlusPalette.gold) : AnyShapeStyle(Palette.flame),
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
                        .font(.display(20))
                        .foregroundStyle(theme.ink)
                    Text(plan.cadence)
                        .font(.dewy(12, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? (theme.isDark ? theme.card : PlusPalette.soft) : theme.card)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isSelected ? PlusPalette.violet : Color.clear, lineWidth: 3)
            }
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? PlusPalette.violetDeep : theme.line)
                    .offset(y: 4)
            }
            .padding(.bottom, 4)
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
    }
}

// MARK: - Decorations

/// The violet Dewy+ sky with sun rays, drifting clouds and sparkles.
private struct PlusSky: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PlusPalette.sky
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || LaunchOptions.freezesMotion)) { timeline in
                let t = reduceMotion || LaunchOptions.freezesMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height - 290)
                    context.drawLayer { layer in
                        layer.opacity = 0.18
                        for index in 0..<14 {
                            let angle = Double(index) / 14 * .pi * 2 + t * 0.05
                            var ray = Path()
                            ray.move(to: center)
                            ray.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle - 0.08)) * 600, y: center.y + CGFloat(sin(angle - 0.08)) * 600))
                            ray.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle + 0.08)) * 600, y: center.y + CGFloat(sin(angle + 0.08)) * 600))
                            ray.closeSubpath()
                            layer.fill(ray, with: .color(.white))
                        }
                    }
                    context.fill(Path(ellipseIn: CGRect(x: center.x - 170, y: center.y - 170, width: 340, height: 340)),
                                 with: .radialGradient(Gradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0)]), center: center, startRadius: 0, endRadius: 170))
                    let spots: [(CGFloat, CGFloat, CGFloat, Double)] = [(0.12, -360, 18, 0), (0.86, -420, 14, 1.2), (0.2, -180, 12, 2.1), (0.84, -150, 16, 3)]
                    for spot in spots {
                        let pulse = 0.5 + 0.5 * sin(t * 2.4 + spot.3)
                        let s = spot.2 * CGFloat(0.6 + 0.4 * pulse)
                        let point = CGPoint(x: size.width * spot.0, y: size.height + spot.1)
                        context.opacity = 0.5 + 0.5 * pulse
                        context.fill(SparkleShape().path(in: CGRect(x: point.x - s / 2, y: point.y - s / 2, width: s, height: s)), with: .color(.white))
                    }
                    context.opacity = 1
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// A fluffy cloud for Dewy to stand on.
struct CloudPuff: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
            path.addEllipse(in: CGRect(x: rect.minX + cx * w - r * h, y: rect.minY + cy * h - r * h, width: r * 2 * h, height: r * 2 * h))
        }
        circle(0.22, 0.6, 0.4)
        circle(0.42, 0.42, 0.5)
        circle(0.62, 0.45, 0.46)
        circle(0.8, 0.62, 0.36)
        path.addRoundedRect(in: CGRect(x: rect.minX + 0.08 * w, y: rect.minY + 0.5 * h, width: 0.84 * w, height: 0.5 * h), cornerSize: CGSize(width: 0.25 * h, height: 0.25 * h))
        return path
    }
}

/// Five little world colors swirled into one orb.
private struct WorldOrb: View {
    var body: some View {
        ZStack {
            ForEach(Array(AppTheme.allCases.enumerated()), id: \.offset) { index, world in
                Circle()
                    .trim(from: CGFloat(index) / 5, to: CGFloat(index + 1) / 5)
                    .stroke(world.sky[1], lineWidth: 25)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 25, height: 25)
            Circle().strokeBorder(Color.white, lineWidth: 3).frame(width: 50, height: 50)
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
