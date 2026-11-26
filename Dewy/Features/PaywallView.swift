import SwiftUI

/// Compatibility palette tokens retained for older views if referenced.
enum PlusPalette {
    static let violet = Palette.lilac
    static let violetDeep = Color(hex: 0x5E4E96)
    static let soft = Palette.lilacSoft
    static let gold = Palette.butter
    static let sky = LinearGradient(stops: [
        .init(color: Color(hex: 0x7D6BB5), location: 0),
        .init(color: Color(hex: 0xB39CD8), location: 0.45),
        .init(color: Color(hex: 0xE8B4C4), location: 0.8),
        .init(color: Color(hex: 0xF7D7C2), location: 1)
    ], startPoint: .top, endPoint: .bottom)
}

/// The Dewy+ paywall: live animated celestial pavilion panorama with crowned Dewy and
/// premium live FriendView companions, editorial cotton-paper perks, and tactile plan cards.
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
            let heroHeight = max(proxy.size.height * 0.36, 294)
            ZStack {
                theme.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        stage(height: heroHeight)
                        titleBlock
                            .floatIn(appeared, index: 1)
                        VStack(spacing: 20) {
                            plans.floatIn(appeared, index: 2)
                            perksCard.floatIn(appeared, index: 3)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    stickyBottomBar
                        .floatIn(appeared, index: 4)
                }

                ConfettiView(trigger: celebrate, origin: UnitPoint(x: 0.5, y: 0.25))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            CircleIconButton(systemImage: "xmark", size: 36, onHero: true) { dismiss() }
                .accessibilityLabel("Close")
                .padding(.trailing, 20)
                .padding(.top, 16)
        }
        .onAppear {
            appeared = true
            guard isLive else { return }
            bob = true
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.8)) {
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
            LilyPad(width: 158, animated: isLive)

            companion(.octopus, size: 52, x: -84, y: -116, delay: 0.9)
            companion(.unicorn, size: 68, x: -116, y: -20, delay: 0)
            companion(.dino, size: 68, x: 116, y: -20, delay: 0.45)

            MascotView(
                progress: 0.92,
                mood: .ecstatic,
                size: 138,
                outfits: [.crown],
                sparkles: true,
                bands: rainbow,
                animated: isLive,
                showsShadow: false
            )
            .liveMeniscusGlow(strength: 0.14)
            .padding(.bottom, 16)
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .bottom)
        .background(alignment: .bottom) {
            heroPanorama(height: height + 180)
        }
        .floatIn(appeared, index: 0)
        .accessibilityHidden(true)
    }

    private func heroPanorama(height: CGFloat) -> some View {
        PaywallPanoramaView(animated: isLive)
            .frame(height: height)
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    stops: [
                        .init(color: theme.canvas.opacity(0), location: 0),
                        .init(color: theme.canvas.opacity(0.68), location: 0.56),
                        .init(color: theme.canvas, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: height * 0.28)
            }
    }

    private func companion(_ friend: Friend, size: CGFloat, x: CGFloat, y: CGFloat, delay: Double) -> some View {
        FriendView(friend: friend, size: size, animated: isLive)
            .offset(y: bob ? -4 : 3)
            .animation(
                isLive ? Animation.easeInOut(duration: 1.6 + delay * 0.4).repeatForever(autoreverses: true).delay(delay) : nil,
                value: bob
            )
            .offset(x: x, y: y)
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ClayIcon(glyph: .crown, size: 38)
                Text("Dewy+")
                    .font(.display(40, .bold))
                    .tracking(-0.6)
                    .foregroundStyle(theme.ink)
            }
            Text("Unlock every companion, sanctuary and wardrobe piece — and turn every sip into a tiny ritual.")
                .font(.editorialItalic(16))
                .foregroundStyle(theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 30)
        }
        .padding(.top, 2)
    }

    // MARK: Perks

    private let perks: [PaywallPerk] = [
        PaywallPerk(art: .friend(.unicorn), tint: Palette.lilacSoft, title: "Exclusive friends, worlds & outfits", detail: "Stella, Sprout, Inky, four new worlds and the full wardrobe"),
        PaywallPerk(art: .glyph(.drop), tint: Palette.coralSoft, title: "2× Dew Drops for every goal", detail: "Fill your sanctuary fund twice as fast"),
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
                        .frame(height: 1)
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
        VStack(spacing: 14) {
            ForEach(PurchaseManager.Plan.allCases) { plan in
                PaywallPlanCard(plan: plan, price: price(for: plan), isSelected: selected == plan) {
                    Haptics.select()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { selected = plan }
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

    private var stickyBottomBar: some View {
        VStack(spacing: 9) {
            PrimaryButton(
                title: selected == .yearly ? "Start free trial" : "Continue",
                style: .accent,
                isLoading: purchases.isPurchasing,
                height: 54
            ) {
                Task { await buy() }
            }
            .scaleEffect(pulse ? 1.015 : 1)

            Text(ctaNote)
                .font(.dewy(12, .bold))
                .foregroundStyle(theme.inkSoft)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            HStack(spacing: 8) {
                Button("Restore purchases") {
                    Haptics.tap()
                    Task { await purchases.restore() }
                }
                .buttonStyle(.plain)
                Text("·")
                Text("Cancel anytime")
                Text("·")
                Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Text("·")
                Link("Privacy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
            }
            .font(.dewy(11, .semibold))
            .foregroundStyle(theme.inkSoft)
            .tint(theme.inkSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background {
            VStack(spacing: 0) {
                Rectangle().fill(theme.line).frame(height: 1)
                theme.canvas.opacity(0.96)
            }
            .ignoresSafeArea(edges: .bottom)
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
        let iconShape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        HStack(spacing: 14) {
            icon
                .frame(width: 46, height: 46)
                .background {
                    iconShape
                        .fill(perk.tint)
                        .overlay(iconShape.stroke(Ink.hairline, lineWidth: 1))
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.title)
                    .font(.dewy(15.5, .semibold))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(perk.detail)
                    .font(.dewy(12.5, .medium))
                    .foregroundStyle(theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(theme.accentDeep)
                .frame(width: 24, height: 24)
                .background(theme.accentSoft, in: Circle())
                .overlay(Circle().stroke(theme.accent.opacity(0.22), lineWidth: 0.75))
        }
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private var icon: some View {
        switch perk.art {
        case .friend(let friend):
            FriendView(friend: friend, size: 38, animated: false)
        case .glyph(let glyph):
            ClayIcon(glyph: glyph, size: 30)
        case .drink(let kind):
            DrinkIcon(kind: kind, size: 34)
        case .symbol(let name, let color):
            Image(systemName: name)
                .font(.system(size: 19, weight: .semibold))
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

    private let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                checkmark
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title)
                        .font(.display(19, .semibold))
                        .foregroundStyle(theme.ink)
                    Text(plan.detail)
                        .font(.dewy(12.5, .bold))
                        .foregroundStyle(plan == .yearly ? Palette.coralDeep : theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price)
                        .font(.display(20, .bold))
                        .monospacedDigit()
                        .foregroundStyle(theme.ink)
                    Text(plan.cadence)
                        .font(.dewy(11.5, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 17)
            .background {
                PaperSurface(
                    shape: shape,
                    fill: isSelected ? Palette.aquaSoft.blended(with: Palette.paper, by: 0.62) : Palette.paper,
                    tint: isSelected ? Palette.aqua : Palette.shadow,
                    elevation: isSelected ? 0.95 : 0.55
                )
            }
            .overlay {
                shape.strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 2.2)
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
                .strokeBorder(isSelected ? theme.accent : theme.inkFaint, lineWidth: 2)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Palette.paper)
                    .frame(width: 24, height: 24)
                    .background(theme.accent, in: Circle())
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 24, height: 24)
    }

    private func badgeView(_ text: String) -> some View {
        let isYearly = plan == .yearly
        return Text(text.uppercased())
            .font(.dewy(10, .bold))
            .tracking(0.8)
            .foregroundStyle(Palette.paper)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(
                isYearly ? AnyShapeStyle(Palette.coral) : AnyShapeStyle(Palette.gold),
                in: Capsule()
            )
            .overlay(Capsule().stroke((isYearly ? Palette.coralDeep : Color(hex: 0x7A5110)).opacity(0.35), lineWidth: 0.75))
            .shadow(color: Palette.shadow.opacity(0.18), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Decorations

/// A soft cloud silhouette helper.
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
