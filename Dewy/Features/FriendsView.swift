import SwiftUI

/// The Friends tab: Dewy's storybook dressing pavilion. Spend earned Dew Drops on live animated
/// pond companions, handcrafted outfits, illustrated worlds and shore decorations.
struct FriendsView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(AppRouter.self) private var router
    @Environment(\.dewyTheme) private var theme

    enum Shelf: String, CaseIterable {
        case friends, wardrobe, places, decor

        var title: String {
            switch self {
            case .friends: "Friends"
            case .wardrobe: "Wardrobe"
            case .places: "Worlds"
            case .decor: "Decor"
            }
        }

        static var initial: Shelf {
            switch LaunchOptions.screenshot {
            case "wardrobe": .wardrobe
            case "places": .places
            case "decor": .decor
            default: .friends
            }
        }
    }

    @State private var shelf: Shelf = .initial
    @State private var appeared = false
    @State private var bounce = 0
    @State private var confetti = 0
    @State private var detail: ShopItem?

    private let headerHeight: CGFloat = 88
    private let stageHeight: CGFloat = 236
    private let mascotSize: CGFloat = 152
    private let padWidth: CGFloat = 132
    private var mascotHeight: CGFloat { mascotSize * DewyGeometry.canvas.height / DewyGeometry.canvas.width }
    private var padTop: CGFloat { mascotHeight * 0.925 - padWidth * 0.232 }
    private var horizonY: CGFloat { headerHeight + 100 }
    private var phase: SkyPhase { theme.phase() }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                sheet
                    .floatIn(appeared, index: 2)
            }
        }
        .scrollIndicators(.hidden)
        .overlay {
            ConfettiView(trigger: confetti, origin: UnitPoint(x: 0.5, y: 0.25))
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .sheet(item: $detail) { item in
            ShopItemSheet(item: item) { bought in
                detail = nil
                if bought {
                    bounce += 1
                    confetti += 1
                }
            }
            .preferredColorScheme(.light)
            .presentationDetents([.height(item.isOutfit ? 560 : 520)])
            .presentationCornerRadius(34)
            .presentationBackground(theme.canvas)
        }
        .onAppear { appeared = true }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 0) {
            header
                .frame(height: headerHeight, alignment: .top)
                .padding(.horizontal, 20)
                .floatIn(appeared, index: 0)
            stage
                .frame(height: stageHeight, alignment: .top)
                .floatIn(appeared, index: 1)
        }
        .padding(.top, 4)
        .padding(.bottom, 24)
        .background(alignment: .top) {
            GeometryReader { proxy in
                let bgHeight = proxy.size.height + 68
                VStack(spacing: 0) {
                    theme.sky[0]
                        .frame(height: 600)
                    ClayWorld(
                        horizon: horizonY,
                        decor: store.placedDecor,
                        interactive: true,
                        showsLandmark: true,
                        headerSafeTop: 148
                    )
                    .frame(width: proxy.size.width, height: bgHeight)
                }
                .frame(width: proxy.size.width, height: bgHeight, alignment: .bottom)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: "Dressing pavilion", color: theme.onHeroSoft, size: 11)
                Text("Dewy & Friends")
                    .font(.display(30, .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(theme.onHero)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Spacer(minLength: 8)
            CountPill(glyph: .drop, value: store.dropBalance, tint: Palette.coral)
                .accessibilityLabel("\(store.dropBalance) Dew Drops")
        }
    }

    private var stage: some View {
        ZStack(alignment: .top) {
            LilyPad(width: padWidth, rippleTrigger: bounce)
                .offset(y: padTop)

            ForEach(Array(store.companions.prefix(2).enumerated()), id: \.element) { index, friend in
                StageFriendPad(
                    friend: friend,
                    index: index,
                    cheerTrigger: bounce,
                    isNight: phase.isNight
                )
                .offset(x: index == 0 ? -116 : 116, y: padTop - 22)
                .transition(.scale(scale: 0.45).combined(with: .opacity))
            }

            MascotView(
                progress: store.todayProgress,
                mood: store.mood,
                size: mascotSize,
                bounceTrigger: bounce,
                outfits: store.outfits,
                sparkles: true,
                bands: store.todayBands,
                isNight: phase.isNight
            )
            .liveMeniscusGlow(strength: 0.13)
            .contentShape(Rectangle())
            .onTapGesture {
                bounce += 1
                Haptics.tap()
                SoundFX.play(.pop, volume: 0.3)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: store.companions)
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: store.outfits)
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            StorySegmented(items: Shelf.allCases, selection: $shelf, title: \.title)
                .padding(.horizontal, 20)

            Group {
                switch shelf {
                case .friends: friendsShelf
                case .wardrobe: wardrobeShelf
                case .places: placesShelf
                case .decor: decorShelf
                }
            }
            .transition(.opacity.combined(with: .offset(y: 10)))
            .id(shelf)

            earnNote
                .padding(.horizontal, 20)
        }
        .padding(.top, 24)
        .padding(.bottom, 128)
        .frame(maxWidth: .infinity)
        .canvasSheet()
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: shelf)
    }

    private func shelfNote(_ text: String) -> some View {
        Text(text)
            .font(.editorialItalic(14.5))
            .foregroundStyle(theme.inkSoft)
            .padding(.horizontal, 24)
    }

    // MARK: Friends

    private var friendsShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            shelfNote("Invite up to two pond companions to keep Dewy company.")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(Friend.allCases) { friend in
                    let owned = store.owns(friend)
                    Button {
                        tap(.friend(friend))
                    } label: {
                        FriendCard(
                            friend: friend,
                            owned: owned,
                            isCompanion: store.isCompanion(friend),
                            locked: friend.isPremium && !purchases.isPremium && !owned,
                            affordable: store.canAfford(friend.price)
                        )
                    }
                    .buttonStyle(SquishyButtonStyle(scale: 0.96))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Wardrobe

    private var wardrobeShelf: some View {
        VStack(alignment: .leading, spacing: 18) {
            shelfNote("Tap to dress Dewy. Complete challenges to win heirloom pieces.")
            ForEach(OutfitSlot.allCases) { slot in
                VStack(alignment: .leading, spacing: 10) {
                    CapsLabel(text: slot.title, color: theme.inkSoft, size: 11)
                        .padding(.horizontal, 24)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(Outfit.allCases.filter { $0.slot == slot }) { outfit in
                            let owned = store.owns(outfit)
                            Button {
                                tap(.outfit(outfit))
                            } label: {
                                AtelierItemCard(
                                    title: outfit.name,
                                    tint: outfit.tint,
                                    price: outfit.price,
                                    owned: owned,
                                    active: store.isWearing(outfit),
                                    activeLabel: "Wearing",
                                    idleLabel: "Wear",
                                    locked: outfit.isPremium && !purchases.isPremium && !owned,
                                    affordable: store.canAfford(outfit.price)
                                ) {
                                    OutfitArtView(outfit: outfit, size: 68)
                                }
                            }
                            .buttonStyle(SquishyButtonStyle(scale: 0.95))
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: Decor

    private var decorShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            shelfNote("Arrange up to three keepsakes along Dewy's pond shore.")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Decor.allCases) { decor in
                    let owned = store.owns(decor)
                    Button {
                        tap(.decor(decor))
                    } label: {
                        AtelierItemCard(
                            title: decor.name,
                            tint: decor.tint,
                            price: decor.price,
                            owned: owned,
                            active: store.isPlaced(decor),
                            activeLabel: "Placed",
                            idleLabel: "Place",
                            locked: decor.isPremium && !purchases.isPremium && !owned,
                            affordable: store.canAfford(decor.price)
                        ) {
                            ArtImage(name: decor.imageName, fallback: "sparkles", tint: decor.tint, size: 66)
                        }
                    }
                    .buttonStyle(SquishyButtonStyle(scale: 0.95))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Worlds

    private var placesShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            shelfNote("Choose Dewy's sanctuary. Each world shifts through dawn, day, dusk and starlight.")
            VStack(spacing: 14) {
                ForEach(AppTheme.allCases) { option in
                    let locked = option.isPremium && !purchases.isPremium
                    Button {
                        if locked {
                            Haptics.warning()
                            router.showPaywall = true
                        } else if store.profile.theme != option {
                            Haptics.select()
                            withAnimation(.smooth(duration: 0.5)) { store.profile.theme = option }
                            store.save()
                        }
                    } label: {
                        WorldCard(world: option, selected: store.profile.theme == option, locked: locked)
                    }
                    .buttonStyle(SquishyButtonStyle(scale: 0.97))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Earn note

    private var earnNote: some View {
        let breakdown = store.dropBreakdown
        return HStack(alignment: .top, spacing: 14) {
            ClayIcon(glyph: .drop, size: 42)
            VStack(alignment: .leading, spacing: 4) {
                Text("Drops are earned, never sold")
                    .font(.display(17, .semibold))
                    .foregroundStyle(theme.ink)
                Text("+\(DropRules.perSip) a sip, +\(DropRules.perBeat) a story moment, +\(store.goalReward) for your goal and a streak bonus. You've earned \(breakdown.total) so far.")
                    .font(.dewy(13, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dewyCard(padding: 16, fill: Palette.coralSoft.blended(with: Palette.paper, by: 0.42), glow: Palette.coral)
    }

    // MARK: Actions

    private func tap(_ item: ShopItem) {
        switch item {
        case .friend(let friend) where store.owns(friend):
            Haptics.select()
            bounce += 1
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { store.toggleCompanion(friend) }
        case .outfit(let outfit) where store.owns(outfit):
            Haptics.select()
            bounce += 1
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { store.toggleWear(outfit) }
        case .decor(let decor) where store.owns(decor):
            Haptics.select()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { store.togglePlaced(decor) }
        default:
            if item.isPremium && !purchases.isPremium {
                Haptics.warning()
                router.showPaywall = true
            } else {
                Haptics.tap()
                detail = item
            }
        }
    }
}

// MARK: - Shop item

/// Anything that can be unlocked with earned Dew Drops.
enum ShopItem: Identifiable, Hashable {
    case friend(Friend)
    case outfit(Outfit)
    case decor(Decor)

    var id: String {
        switch self {
        case .friend(let f): "friend-\(f.rawValue)"
        case .outfit(let o): "outfit-\(o.rawValue)"
        case .decor(let d): "decor-\(d.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .friend(let f): f.name
        case .outfit(let o): o.name
        case .decor(let d): d.name
        }
    }

    var subtitle: String {
        switch self {
        case .friend(let f): f.species
        case .outfit(let o): o.slot == .head ? "Hat" : (o.slot == .face ? "Glasses" : "Neckwear")
        case .decor(let d): d.floats ? "Floats on the pond" : (d.flies ? "Drifts in the sky" : "Rests along the shore")
        }
    }

    var blurb: String {
        switch self {
        case .friend(let f): f.bio
        case .outfit: "Dewy wears it on the Today screen, in widgets and on your share postcards."
        case .decor: "Appears around Dewy's sanctuary on the Today screen."
        }
    }

    var price: Int {
        switch self {
        case .friend(let f): f.price
        case .outfit(let o): o.price
        case .decor(let d): d.price
        }
    }

    var tint: Color {
        switch self {
        case .friend(let f): f.tint
        case .outfit(let o): o.tint
        case .decor(let d): d.tint
        }
    }

    var isPremium: Bool {
        switch self {
        case .friend(let f): f.isPremium
        case .outfit(let o): o.isPremium
        case .decor(let d): d.isPremium
        }
    }

    var isOutfit: Bool {
        if case .outfit = self { return true }
        return false
    }
}

// MARK: - Cards

private struct FriendCard: View {
    @Environment(\.dewyTheme) private var theme
    var friend: Friend
    var owned: Bool
    var isCompanion: Bool
    var locked: Bool
    var affordable: Bool

    private var deepTint: Color {
        friend.tint.blended(with: Ink.primary, by: 0.34)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [friend.tint.opacity(0.32), friend.tint.opacity(0.08)],
                            center: .center,
                            startRadius: 6,
                            endRadius: 54
                        )
                    )
                    .overlay(Circle().stroke(Ink.hairline, lineWidth: 1))
                    .frame(width: 98, height: 98)

                FriendView(friend: friend, size: 88, animated: true)
                    .saturation(owned || !locked ? 1 : 0.35)
                    .opacity(owned ? 1 : 0.92)
            }
            .frame(height: 104)
            .overlay(alignment: .topTrailing) {
                if friend.isPremium { PlusBadge().offset(x: 8, y: -4) }
            }

            VStack(spacing: 2) {
                Text(friend.name)
                    .font(.display(19, .semibold))
                    .foregroundStyle(theme.ink)
                Text(friend.species)
                    .font(.dewy(11.5, .bold))
                    .foregroundStyle(theme.inkSoft)
            }

            status
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background {
            PaperSurface(
                shape: shape,
                fill: isCompanion ? friend.tint.blended(with: Palette.paper, by: 0.84) : Palette.paper,
                tint: owned ? friend.tint : Palette.shadow,
                elevation: isCompanion ? 0.95 : 0.65
            )
        }
        .overlay {
            if isCompanion {
                shape.stroke(deepTint.opacity(0.65), lineWidth: 2)
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        if owned {
            HStack(spacing: 4) {
                Image(systemName: isCompanion ? "heart.fill" : "plus")
                    .font(.system(size: 10, weight: .bold))
                Text(isCompanion ? "With Dewy" : "Invite")
                    .font(.dewy(12.5, .bold))
            }
            .foregroundStyle(isCompanion ? Palette.paper : deepTint)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(isCompanion ? deepTint : friend.tint.opacity(0.18), in: Capsule())
            .overlay(Capsule().stroke(deepTint.opacity(isCompanion ? 0 : 0.25), lineWidth: 1))
        } else if locked {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill").font(.system(size: 9.5, weight: .bold))
                Text("Dewy+").font(.dewy(12.5, .bold))
            }
            .foregroundStyle(Palette.butterDeep)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(Palette.butterSoft, in: Capsule())
            .overlay(Capsule().stroke(Palette.butterDeep.opacity(0.24), lineWidth: 1))
        } else {
            PriceTag(price: friend.price, affordable: affordable)
        }
    }
}

/// Cotton-paper atelier card shared cleanly by live OutfitArtView pieces and handcrafted Decor art.
private struct AtelierItemCard<Artwork: View>: View {
    @Environment(\.dewyTheme) private var theme
    var title: String
    var tint: Color
    var price: Int
    var owned: Bool
    var active: Bool
    var activeLabel: String
    var idleLabel: String
    var locked: Bool
    var affordable: Bool
    @ViewBuilder var artwork: () -> Artwork

    private var deepTint: Color {
        tint.blended(with: Ink.primary, by: 0.36)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(tint.opacity(active ? 0.26 : 0.14))
                    .overlay(Circle().stroke(Ink.hairline, lineWidth: 1))
                    .frame(width: 68, height: 68)
                artwork()
            }
            .frame(height: 74)

            Text(title)
                .font(.display(13, .semibold))
                .foregroundStyle(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            status
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background {
            PaperSurface(
                shape: shape,
                fill: active ? tint.blended(with: Palette.paper, by: 0.84) : Palette.paper,
                tint: active ? tint : Palette.shadow,
                elevation: active ? 0.9 : 0.55
            )
        }
        .overlay {
            if active {
                shape.stroke(deepTint.opacity(0.65), lineWidth: 2)
            }
        }
        .overlay(alignment: .topTrailing) {
            if active {
                Image(systemName: "checkmark")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(Palette.paper)
                    .frame(width: 21, height: 21)
                    .background(Circle().fill(deepTint))
                    .overlay(Circle().stroke(Palette.paper, lineWidth: 1.5))
                    .offset(x: 4, y: -4)
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        if owned {
            Text(active ? activeLabel : idleLabel)
                .font(.dewy(12, .bold))
                .foregroundStyle(active ? deepTint : theme.inkSoft)
                .frame(height: 26)
        } else if locked {
            HStack(spacing: 3) {
                Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold))
                Text("Dewy+").font(.dewy(11.5, .bold))
            }
            .foregroundStyle(Palette.butterDeep)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(Palette.butterSoft, in: Capsule())
            .overlay(Capsule().stroke(Palette.butterDeep.opacity(0.24), lineWidth: 1))
        } else {
            PriceTag(price: price, affordable: affordable)
        }
    }
}

/// Rich multi-layer miniature world preview card showcasing each sanctuary's distinct atmosphere.
private struct WorldCard: View {
    @Environment(\.dewyTheme) private var theme
    var world: AppTheme
    var selected: Bool
    var locked: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        let isNight = world.phase().isNight

        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                ClayWorld(horizon: 76, animated: false, showsLandmark: true)
                    .environment(\.dewyTheme, world)

                ZStack(alignment: .bottom) {
                    LilyPad(width: 52, animated: false)
                        .environment(\.dewyTheme, world)
                        .offset(y: 7)
                    MascotView(
                        progress: 0.72,
                        mood: .happy,
                        size: 46,
                        animated: false,
                        showsShadow: false,
                        isNight: isNight
                    )
                    .environment(\.dewyTheme, world)
                }
                .padding(.bottom, 10)
            }
            .frame(height: 126)
            .clipped()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(world.displayName)
                            .font(.display(19, .semibold))
                            .foregroundStyle(theme.ink)
                        if world.isPremium { PlusBadge() }
                    }
                    Text(world.tagline)
                        .font(.dewy(12.5, .semibold))
                        .foregroundStyle(theme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.paper)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Palette.aqua))
                        .overlay(Circle().stroke(Palette.aquaDeep.opacity(0.35), lineWidth: 1))
                } else if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.butterDeep)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Palette.butterSoft))
                        .overlay(Circle().stroke(Palette.butterDeep.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Palette.paper)
        }
        .clipShape(shape)
        .background {
            PaperSurface(
                shape: shape,
                fill: Palette.paper,
                tint: selected ? world.tint : Palette.shadow,
                elevation: selected ? 1.0 : 0.65
            )
        }
        .overlay {
            shape.stroke(selected ? Palette.aqua : Ink.hairline, lineWidth: selected ? 2.2 : 1)
        }
    }
}

/// Live animated companion perched on a miniature botanical lily pad beside Dewy on stage.
private struct StageFriendPad: View {
    var friend: Friend
    var index: Int
    var cheerTrigger: Int
    var isNight: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LilyPad(width: 76, rippleTrigger: cheerTrigger)
                .offset(y: 12)
            FriendView(
                friend: friend,
                size: 72,
                animated: true,
                celebrateTrigger: cheerTrigger,
                isNight: isNight,
                phaseOffset: Double(index) * 1.9
            )
            .scaleEffect(x: index == 0 ? 1 : -1, y: 1)
            .offset(y: -4)
        }
        .frame(width: 92, height: 82, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

// MARK: - Detail sheet

private struct ShopItemSheet: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.dewyTheme) private var theme
    var item: ShopItem
    var onClose: (Bool) -> Void

    @State private var pop = false
    @State private var shake = 0
    @State private var previewHop = 0

    var body: some View {
        let balance = store.dropBalance
        let affordable = balance >= item.price

        VStack(spacing: 14) {
            Capsule().fill(Ink.faint.opacity(0.5)).frame(width: 38, height: 4.5).padding(.top, 10)

            preview
                .frame(height: item.isOutfit ? 210 : 186)
                .scaleEffect(pop ? 1 : 0.74)
                .modifier(ShakeEffect(shakes: CGFloat(shake)))

            VStack(spacing: 5) {
                CapsLabel(text: item.subtitle, color: item.tint.blended(with: Ink.primary, by: 0.36), size: 10.5)
                Text(item.title)
                    .font(.display(28, .bold))
                    .foregroundStyle(theme.ink)
                Text(item.blurb)
                    .font(.editorialItalic(16))
                    .foregroundStyle(theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                PrimaryButton(
                    title: item.price == 0 ? "Adopt for free" : "Get for \(item.price) drops",
                    style: affordable ? .reward : .light,
                    height: 56
                ) {
                    buy()
                }
                Text(affordable ? "You have \(balance) drops" : "\(item.price - balance) more drops to go. Keep sipping!")
                    .font(.dewy(13, .bold))
                    .foregroundStyle(theme.inkSoft)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .onAppear {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.66)) { pop = true }
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item {
        case .friend(let friend):
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [friend.tint.opacity(0.32), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 112
                        )
                    )
                    .frame(width: 224, height: 224)
                FriendView(friend: friend, size: 156, animated: true, celebrateTrigger: previewHop)
                    .onTapGesture {
                        previewHop += 1
                        Haptics.tap()
                    }
            }
        case .outfit(let outfit):
            let worn = store.outfits.filter { $0.slot != outfit.slot } + [outfit]
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [outfit.tint.opacity(0.32), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 115
                        )
                    )
                    .frame(width: 230, height: 230)
                MascotView(
                    progress: store.todayProgress,
                    mood: .happy,
                    size: 168,
                    outfits: worn,
                    sparkles: true,
                    bands: store.todayBands,
                    showsShadow: false
                )
                .liveMeniscusGlow(strength: 0.14)
            }
        case .decor(let decor):
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [decor.tint.opacity(0.34), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 112
                        )
                    )
                    .frame(width: 224, height: 224)
                ArtImage(name: decor.imageName, fallback: "sparkles", tint: decor.tint, size: 146)
            }
        }
    }

    private func buy() {
        let bought: Bool
        switch item {
        case .friend(let f): bought = store.buy(f)
        case .outfit(let o): bought = store.buy(o)
        case .decor(let d): bought = store.buy(d)
        }
        if bought {
            Haptics.success()
            SoundFX.play(.goal, volume: 0.5)
            onClose(true)
        } else {
            Haptics.warning()
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
        }
    }
}

/// Subtle horizontal shake when balance is too low to unlock an item.
private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 4), y: 0))
    }
}
