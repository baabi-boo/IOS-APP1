import SwiftUI

/// Legacy Dewy+ colors. The clay paywall uses the shared palette (aqua, coral, butter),
/// but these stay available for any view that still references them.
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

/// The Dewy+ paywall: a cinematic clay scene with Dewy and the premium friends,
/// a perks card, three plan cards and one big aqua call to action.
struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selected: PurchaseManager.Plan = .yearly
    @State private var appeared = false
    @State private var celebrate = 0
    @State private var pulse = false
    @State private var bob = false

    /// A rainbow of drinks shows off everything Dewy+ unlocks.
    private let rainbow: [LiquidBand] = [
        LiquidBand(color: DrinkKind.water.color, upTo: 0.2),
        LiquidBand(color: DrinkKind.juice.color, upTo: 0.38),
        LiquidBand(color: DrinkKind.matcha.color, upTo: 0.55),
        LiquidBand(color: DrinkKind.smoothie.color, upTo: 0.73),
        LiquidBand(color: DrinkKind.sparkling.color, upTo: 0.92)
    ]

    private var isLive: Bool { !LaunchOptions.freezesMotion && !reduceMotion }

    var body: some View {
        GeometryReader { proxy in
            let heroHeight = max(proxy.size.height * 0.45, 330)
            ZStack {
                theme.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        stage(height: heroHeight)
                        titleBlock
                            .floatIn(appeared, index: 1)
                        VStack(spacing: 24) {
                            perksCard.floatIn(appeared, index: 2)
                            plans.floatIn(appeared, index: 3)
                            cta.floatIn(appeared, index: 4)
                            footer
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 34)
                    }
                }
                .scrollIndicators(.hidden)

                ConfettiView(trigger: celebrate, origin: UnitPoint(x: 0.5, y: 0.25))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            CircleIconButton(systemImage: "xmark", size: 38, onHero: true) { dismiss() }
                .accessibilityLabel("Close")
                .padding(.trailing, 20)
                .padding(.top, 18)
        }
        .onAppear {
            appeared = true
            guard isLive else { return }
            bob = true
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

    private func stage(height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            LilyPad(width: 170, animated: isLive)

            friendView(.octopus, size: 58, x: -104, y: -168, delay: 0.9)
            friendView(.unicorn, size: 72, x: -124, y: -26, delay: 0)
            friendView(.dino, size: 72, x: 124, y: -26, delay: 0.45)

            MascotView(
                progress: 0.92,
                mood: .ecstatic,
                size: 150,
                outfits: [.crown],
                sparkles: true,
                bands: rainbow,
                animated: isLive,
                showsShadow: false
            )
            .padding(.bottom, 18)
        }
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .bottom)
        .background(alignment: .bottom) {
            // Extends above the top so pulling down keeps showing the scene.
            heroImage(height: height + 180)
        }
        .floatIn(appeared, index: 0)
        .accessibilityHidden(true)
    }

    private func heroImage(height: CGFloat) -> some View {
        Color.clear
            .frame(height: height)
            .overlay {
                Image("hero-paywall")
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(stops: [
                    .init(color: theme.canvas.opacity(0), location: 0),
                    .init(color: theme.canvas.opacity(0.65), location: 0.55),
                    .init(color: theme.canvas, location: 1)
                ], startPoint: .top, endPoint: .bottom)
                .frame(height: height * 0.3)
            }
    }

    private func friendView(_ friend: Friend, size: CGFloat, x: CGFloat, y: CGFloat, delay: Double) -> some View {
        ArtImage(name: friend.imageName, size: size)
            .background(alignment: .bottom) {
                Ellipse()
                    .fill(Palette.shadow.opacity(0.18))
                    .frame(width: size * 0.62, height: size * 0.12)
                    .blur(radius: 2)
                    .offset(y: size * 0.04)
            }
            .offset(y: bob ? -5 : 3)
            .animation(isLive ? Animation.easeInOut(duration: 1.5 + delay * 0.4).repeatForever(autoreverses: true).delay(delay) : nil, value: bob)
            .offset(x: x, y: y)
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ClayIcon(glyph: .crown, size: 40)
                Text("Dewy+")
                    .font(.display(40))
                    .foregroundStyle(theme.ink)
            }
            Text("Unlock every friend, world and outfit, and make every sip a little more magical.")
                .font(.dewy(16, .medium))
                .foregroundStyle(theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
        }
        .padding(.top, 2)
    }

    // MARK: Perks

    private let perks: [PaywallPerk] = [
        PaywallPerk(art: .friend(.unicorn), tint: Palette.lilacSoft, title: "Exclusive friends, worlds & outfits", detail: "Stella, Sprout, Inky, four new worlds and the full wardrobe"),
        PaywallPerk(art: .glyph(.drop), tint: Palette.coralSoft, title: "2× Dew Drops for every goal", detail: "Fill your shop fund twice as fast"),
        PaywallPerk(art: .glyph(.map), tint: Palette.mintSoft, title: "The full adventure archive", detail: "Revisit every chapter of Dewy's journey"),
        PaywallPerk(art: .symbol("chart.bar.fill", Palette.aqua), tint: Palette.aquaSoft, title: "30-day & yearly insights", detail: "Your rhythm, streaks and caffeine over time"),
        PaywallPerk(art: .glyph(.heart), tint: Palette.pinkSoft, title: "Apple Health history", detail: "Bring your past days in from Health"),
        PaywallPerk(art: .glyph(.bell), tint: Palette.butterSoft, title: "Custom reminders", detail: "Every hour, 90 minutes or 3 hours"),
        PaywallPerk(art: .drink(.matcha), tint: Palette.peachSoft, title: "Every drink type", detail: "Matcha, coconut, cocoa, lemonade and more")
    ]

    private var perksCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(perks.enumerated()), id: \.offset) { index, perk in
                if index > 0 {
                    Rectangle()
                        .fill(theme.line)
                        .frame(height: 1.5)
                        .padding(.leading, 62)
                }
                PaywallPerkRow(perk: perk)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .dewyCard(padding: 0)
    }

    // MARK: Plans

    private func price(for plan: PurchaseManager.Plan) -> String {
        LaunchOptions.isDemo ? plan.fallbackPrice : purchases.price(for: plan)
    }

    private var plans: some View {
        VStack(spacing: 16) {
            ForEach(PurchaseManager.Plan.allCases) { plan in
                PaywallPlanCard(plan: plan, price: price(for: plan), isSelected: selected == plan) {
                    Haptics.select()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { selected = plan }
                }
            }
        }
        .padding(.top, 6)
    }

    private var ctaNote: String {
        switch selected {
        case .yearly: "3 days free, then \(price(for: .yearly)) per year."
        case .monthly: "\(price(for: .monthly)) per month."
        case .lifetime: "One-time purchase. Yours forever."
        }
    }

    private var cta: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: selected == .yearly ? "Start free trial" : "Continue",
                style: .accent,
                isLoading: purchases.isPurchasing
            ) {
                Task { await buy() }
            }
            .scaleEffect(pulse ? 1.02 : 1)

            Text(ctaNote)
                .font(.dewy(13, .semibold))
                .foregroundStyle(theme.inkSoft)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Button("Restore purchases") {
                    Haptics.tap()
                    Task { await purchases.restore() }
                }
                .buttonStyle(.plain)
                Text("·")
                Text("Cancel anytime")
            }
            .font(.dewy(13, .semibold))
            .foregroundStyle(theme.inkSoft)

            HStack(spacing: 18) {
                Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("Privacy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
            }
            .font(.dewy(12, .semibold))
            .foregroundStyle(theme.inkSoft)
            .tint(theme.inkSoft)
        }
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

// MARK: - Perks

private struct PaywallPerk {
    enum Art {
        case friend(Friend)
        case glyph(ClayGlyph)
        case drink(DrinkKind)
        case symbol(String, Color)
    }

    var art: Art
    var tint: Color
    var title: String
    var detail: String
}

private struct PaywallPerkRow: View {
    @Environment(\.dewyTheme) private var theme
    var perk: PaywallPerk

    var body: some View {
        HStack(spacing: 14) {
            icon
                .frame(width: 48, height: 48)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [perk.tint.blended(with: .white, by: 0.35), perk.tint], startPoint: .top, endPoint: .bottom))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .top, endPoint: .center), lineWidth: 1.2)
                        }
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.title)
                    .font(.dewy(16, .semibold))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(perk.detail)
                    .font(.dewy(13, .medium))
                    .foregroundStyle(theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(theme.accentDeep)
                .frame(width: 24, height: 24)
                .background(theme.accentSoft, in: Circle())
        }
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private var icon: some View {
        switch perk.art {
        case .friend(let friend):
            ArtImage(name: friend.imageName, size: 40)
        case .glyph(let glyph):
            ClayIcon(glyph: glyph, size: 32)
        case .drink(let kind):
            DrinkIcon(kind: kind, size: 36)
        case .symbol(let name, let color):
            Image(systemName: name)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Plans

private struct PaywallPlanCard: View {
    @Environment(\.dewyTheme) private var theme
    var plan: PurchaseManager.Plan
    var price: String
    var isSelected: Bool
    var action: () -> Void

    private let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                checkmark
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title)
                        .font(.display(19))
                        .foregroundStyle(theme.ink)
                    Text(plan.detail)
                        .font(.dewy(13, .semibold))
                        .foregroundStyle(plan == .yearly ? Palette.coralDeep : theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price)
                        .font(.display(20))
                        .foregroundStyle(theme.ink)
                    Text(plan.cadence)
                        .font(.dewy(12, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background {
                ClaySurface(
                    shape: shape,
                    fill: isSelected ? Color(hex: 0xF2FAFE) : .white,
                    glow: isSelected ? Palette.aqua : Palette.shadow,
                    elevation: isSelected ? 1 : 0.6
                )
            }
            .overlay {
                shape.strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 2.5)
            }
            .overlay(alignment: .topTrailing) {
                if let badge = plan.badge {
                    badgeView(badge)
                        .offset(x: -16, y: -11)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.97))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var checkmark: some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? theme.accent : theme.inkFaint, lineWidth: 2.5)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(theme.accent, in: Circle())
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 26, height: 26)
    }

    private func badgeView(_ text: String) -> some View {
        let isYearly = plan == .yearly
        return Text(text)
            .font(.dewy(11, .black))
            .tracking(0.6)
            .foregroundStyle(isYearly ? Color.white : theme.ink)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(isYearly ? Palette.coral : Palette.butter, in: Capsule())
            .shadow(color: (isYearly ? Palette.coralDeep : Palette.butterDeep).opacity(0.35), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Decorations

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
