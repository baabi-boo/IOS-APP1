import SwiftUI

/// The Friends tab: Dewy's dressing room. Spend Dew Drops on friends who hang out by the pond,
/// outfits to wear, worlds to live in and decorations for the shore.
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

    private let headerHeight: CGFloat = 96
    private let stageHeight: CGFloat = 236
    private let mascotSize: CGFloat = 150
    private let padWidth: CGFloat = 128
    private var mascotHeight: CGFloat { mascotSize * DewyGeometry.canvas.height / DewyGeometry.canvas.width }
    private var padTop: CGFloat { mascotHeight * 0.925 - padWidth * 0.232 }
    private var sceneHeight: CGFloat { headerHeight + stageHeight + 80 }
    private var horizonY: CGFloat { headerHeight + 96 }
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
            .presentationDetents([.height(item.isOutfit ? 560 : 520)])
            .presentationCornerRadius(38)
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
        .padding(.top, 6)
        .padding(.bottom, 26)
        .background(alignment: .top) {
            VStack(spacing: 0) {
                phase.sky[0].frame(height: 800)
                ClayWorld(horizon: horizonY, decor: store.placedDecor, interactive: true, showsLandmark: true)
                    .frame(height: sceneHeight)
            }
            .frame(height: sceneHeight, alignment: .bottom)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: "Dressing room", color: phase.onSkySoft, size: 11.5)
                Text("Dewy & Friends")
                    .font(.display(30))
                    .foregroundStyle(phase.onSky)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
                StageFriend(friend: friend, index: index)
                    .offset(x: index == 0 ? -118 : 118, y: padTop - 22)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }

            MascotView(
                progress: store.todayProgress,
                mood: store.mood,
                size: mascotSize,
                bounceTrigger: bounce,
                outfits: store.outfits,
                sparkles: true,
                bands: store.todayBands
            )
            .contentShape(Rectangle())
            .onTapGesture {
                bounce += 1
                Haptics.tap()
                SoundFX.play(.pop, volume: 0.3)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: store.companions)
        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: store.outfits)
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            ClaySegmented(items: Shelf.allCases, selection: $shelf, title: \.title)
                .padding(.horizontal, 20)

            Group {
                switch shelf {
                case .friends: friendsShelf
                case .wardrobe: wardrobeShelf
                case .places: placesShelf
                case .decor: decorShelf
                }
            }
            .transition(.opacity.combined(with: .offset(y: 12)))
            .id(shelf)

            earnNote
                .padding(.horizontal, 20)
        }
        .padding(.top, 24)
        .padding(.bottom, 130)
        .frame(maxWidth: .infinity)
        .canvasSheet()
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: shelf)
    }

    private var shelfNoteColor: Color { theme.inkSoft }

    private func shelfNote(_ text: String) -> some View {
        Text(text)
            .font(.dewy(14, .semibold))
            .foregroundStyle(shelfNoteColor)
            .padding(.horizontal, 24)
    }

    // MARK: Friends

    private var friendsShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            shelfNote("Pick up to two friends to hang out with Dewy.")
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
                    .buttonStyle(SquishyButtonStyle(scale: 0.95))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Wardrobe

    private var wardrobeShelf: some View {
        VStack(alignment: .leading, spacing: 18) {
            shelfNote("Tap to wear. Finish challenges to win the rarest pieces.")
            ForEach(OutfitSlot.allCases) { slot in
                VStack(alignment: .leading, spacing: 10) {
                    CapsLabel(text: slot.title, color: theme.inkSoft, size: 11.5)
                        .padding(.horizontal, 24)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(Outfit.allCases.filter { $0.slot == slot }) { outfit in
                            let owned = store.owns(outfit)
                            Button {
                                tap(.outfit(outfit))
                            } label: {
                                ItemCard(
                                    imageName: outfit.imageName,
                                    title: outfit.name,
                                    tint: outfit.tint,
                                    price: outfit.price,
                                    owned: owned,
                                    active: store.isWearing(outfit),
                                    activeLabel: "Wearing",
                                    idleLabel: "Wear",
                                    locked: outfit.isPremium && !purchases.isPremium && !owned,
                                    affordable: store.canAfford(outfit.price),
                                    reward: ChallengeKind.allCases.first { $0.reward == outfit }.map { _ in "Challenge prize" }
                                )
                            }
                            .buttonStyle(SquishyButtonStyle(scale: 0.94))
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
            shelfNote("Place up to three things around the pond.")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Decor.allCases) { decor in
                    let owned = store.owns(decor)
                    Button {
                        tap(.decor(decor))
                    } label: {
                        ItemCard(
                            imageName: decor.imageName,
                            title: decor.name,
                            tint: decor.tint,
                            price: decor.price,
                            owned: owned,
                            active: store.isPlaced(decor),
                            activeLabel: "Placed",
                            idleLabel: "Place",
                            locked: decor.isPremium && !purchases.isPremium && !owned,
                            affordable: store.canAfford(decor.price),
                            reward: nil
                        )
                    }
                    .buttonStyle(SquishyButtonStyle(scale: 0.94))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Worlds

    private var placesShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            shelfNote("Where Dewy lives. The sky follows your time of day.")
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
            ClayIcon(glyph: .drop, size: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text("Drops are earned, never sold")
                    .font(.display(17))
                    .foregroundStyle(theme.ink)
                Text("+\(DropRules.perSip) a sip, +\(DropRules.perBeat) a story moment, +\(store.goalReward) for your goal and a streak bonus. You've earned \(breakdown.total) so far.")
                    .font(.dewy(13.5, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dewyCard(padding: 16, fill: Palette.coralSoft.blended(with: .white, by: 0.4), glow: Palette.coral)
    }

    // MARK: Actions

    private func tap(_ item: ShopItem) {
        switch item {
        case .friend(let friend) where store.owns(friend):
            Haptics.select()
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

/// Anything that can be bought with Dew Drops.
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

    var imageName: String {
        switch self {
        case .friend(let f): f.imageName
        case .outfit(let o): o.imageName
        case .decor(let d): d.imageName
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
        case .decor(let d): d.floats ? "Floats on the pond" : (d.flies ? "Drifts in the sky" : "Sits on the shore")
        }
    }

    var blurb: String {
        switch self {
        case .friend(let f): f.bio
        case .outfit: "Dewy wears it on the Today screen, in widgets and on your share cards."
        case .decor: "Shows up around Dewy's pond on the Today screen."
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

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [friend.tint.opacity(0.5), friend.tint.opacity(0.12)], center: .center, startRadius: 4, endRadius: 64))
                    .frame(width: 112, height: 112)
                ArtImage(name: friend.imageName, fallback: "pawprint.fill", tint: friend.tint, size: 118)
                    .saturation(owned || !locked ? 1 : 0.4)
                    .opacity(owned ? 1 : 0.92)
            }
            .frame(height: 118)
            .overlay(alignment: .topTrailing) {
                if friend.isPremium { PlusBadge().offset(x: 6, y: -4) }
            }
            VStack(spacing: 1) {
                Text(friend.name)
                    .font(.display(19))
                    .foregroundStyle(theme.ink)
                Text(friend.species)
                    .font(.dewy(12.5, .bold))
                    .foregroundStyle(theme.inkSoft)
            }
            status
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .background {
            ClaySurface(
                shape: RoundedRectangle(cornerRadius: 30, style: .continuous),
                fill: isCompanion ? friend.tint.blended(with: .white, by: 0.78) : .white,
                glow: owned ? friend.tint : Palette.shadow,
                elevation: isCompanion ? 1.1 : 0.8
            )
        }
        .overlay {
            if isCompanion {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(friend.tint, lineWidth: 2.5)
            }
        }
    }

    @ViewBuilder private var status: some View {
        if owned {
            HStack(spacing: 4) {
                Image(systemName: isCompanion ? "heart.fill" : "plus")
                    .font(.system(size: 11, weight: .black))
                Text(isCompanion ? "With Dewy" : "Invite")
                    .font(.display(13.5))
            }
            .foregroundStyle(isCompanion ? .white : friend.tint.blended(with: .black, by: 0.35))
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(isCompanion ? friend.tint.blended(with: .black, by: 0.08) : friend.tint.opacity(0.2), in: Capsule())
        } else if locked {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill").font(.system(size: 10, weight: .heavy))
                Text("Dewy+").font(.display(13.5))
            }
            .foregroundStyle(Palette.butterDeep)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(Palette.butterSoft, in: Capsule())
        } else {
            PriceTag(price: friend.price, affordable: affordable)
        }
    }
}

private struct ItemCard: View {
    @Environment(\.dewyTheme) private var theme
    var imageName: String
    var title: String
    var tint: Color
    var price: Int
    var owned: Bool
    var active: Bool
    var activeLabel: String
    var idleLabel: String
    var locked: Bool
    var affordable: Bool
    var reward: String?

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(tint.opacity(active ? 0.42 : 0.2))
                    .frame(width: 70, height: 70)
                ArtImage(name: imageName, fallback: "sparkles", tint: tint, size: 72)
            }
            .frame(height: 76)
            Text(title)
                .font(.display(13))
                .foregroundStyle(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            status
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background {
            ClaySurface(
                shape: RoundedRectangle(cornerRadius: 24, style: .continuous),
                fill: active ? tint.blended(with: .white, by: 0.8) : .white,
                glow: active ? tint : Palette.shadow,
                elevation: active ? 1 : 0.6
            )
        }
        .overlay {
            if active {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(tint, lineWidth: 2.5)
            }
        }
        .overlay(alignment: .topTrailing) {
            if active {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(tint.blended(with: .black, by: 0.1)))
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: 4, y: -4)
            }
        }
    }

    @ViewBuilder private var status: some View {
        if owned {
            Text(active ? activeLabel : idleLabel)
                .font(.display(12.5))
                .foregroundStyle(active ? tint.blended(with: .black, by: 0.4) : theme.inkSoft)
                .frame(height: 26)
        } else if locked {
            HStack(spacing: 3) {
                Image(systemName: "lock.fill").font(.system(size: 9, weight: .heavy))
                Text("Dewy+").font(.display(12.5))
            }
            .foregroundStyle(Palette.butterDeep)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(Palette.butterSoft, in: Capsule())
        } else {
            PriceTag(price: price, affordable: affordable)
        }
    }
}

private struct WorldCard: View {
    @Environment(\.dewyTheme) private var theme
    var world: AppTheme
    var selected: Bool
    var locked: Bool

    var body: some View {
        VStack(spacing: 0) {
            // A live, still preview of the world in its own sky.
            ClayWorld(horizon: 78, animated: false)
                .environment(\.dewyTheme, world)
                .frame(height: 118)
                .overlay(alignment: .bottom) {
                    MascotView(progress: 0.7, mood: .happy, size: 44, animated: false, showsShadow: false)
                        .offset(y: -10)
                }
                .clipped()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(world.displayName)
                            .font(.display(19))
                            .foregroundStyle(theme.ink)
                        if world.isPremium { PlusBadge() }
                    }
                    Text(world.tagline)
                        .font(.dewy(13, .semibold))
                        .foregroundStyle(theme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .top, endPoint: .bottom)))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(color: Palette.aqua.opacity(0.4), radius: 6, x: 0, y: 3)
                } else if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Palette.butterDeep)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Palette.butterSoft))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .background {
            ClaySurface(shape: RoundedRectangle(cornerRadius: 28, style: .continuous), fill: .white, glow: selected ? world.tint : Palette.shadow, elevation: selected ? 1.1 : 0.7)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(selected ? Palette.aqua : .white, lineWidth: selected ? 3 : 2)
        }
    }
}

/// A friend bobbing on a little lily pad beside Dewy.
private struct StageFriend: View {
    var friend: Friend
    var index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let live = !reduceMotion && !LaunchOptions.freezesMotion
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !live)) { timeline in
            let t = live ? timeline.date.timeIntervalSinceReferenceDate : 0
            let bob = CGFloat(sin(t * 1.6 + Double(index) * 1.7)) * 3
            VStack(spacing: -16) {
                ArtImage(name: friend.imageName, fallback: "pawprint.fill", tint: friend.tint, size: 70)
                    .scaleEffect(x: index == 0 ? 1 : -1, y: 1)
                    .offset(y: bob)
                    .zIndex(1)
                if Art.exists("prop-lilypad") {
                    Image("prop-lilypad")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                }
            }
        }
        .frame(width: 92)
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

    var body: some View {
        let balance = store.dropBalance
        let affordable = balance >= item.price
        VStack(spacing: 14) {
            Capsule().fill(Ink.faint.opacity(0.5)).frame(width: 40, height: 5).padding(.top, 10)
            preview
                .frame(height: item.isOutfit ? 210 : 180)
                .scaleEffect(pop ? 1 : 0.7)
                .modifier(ShakeEffect(shakes: CGFloat(shake)))
            VStack(spacing: 4) {
                CapsLabel(text: item.subtitle, color: item.tint.blended(with: .black, by: 0.35), size: 11)
                Text(item.title)
                    .font(.display(28, .bold))
                    .foregroundStyle(theme.ink)
                Text(item.blurb)
                    .font(.dewy(15.5, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 28)
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                PrimaryButton(title: item.price == 0 ? "Adopt for free" : "Get for \(item.price) drops", style: affordable ? .reward : .light, height: 58) {
                    buy()
                }
                Text(affordable ? "You have \(balance) drops" : "\(item.price - balance) more drops to go. Keep sipping!")
                    .font(.dewy(13.5, .bold))
                    .foregroundStyle(theme.inkSoft)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) { pop = true }
        }
    }

    @ViewBuilder private var preview: some View {
        switch item {
        case .outfit(let outfit):
            // Try it on before buying.
            let worn = store.outfits.filter { $0.slot != outfit.slot } + [outfit]
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [outfit.tint.opacity(0.4), .clear], center: .center, startRadius: 10, endRadius: 120))
                    .frame(width: 240, height: 240)
                MascotView(progress: store.todayProgress, mood: .happy, size: 170, outfits: worn, sparkles: true, bands: store.todayBands, showsShadow: false)
            }
        default:
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [item.tint.opacity(0.45), .clear], center: .center, startRadius: 10, endRadius: 120))
                    .frame(width: 240, height: 240)
                ArtImage(name: item.imageName, fallback: "sparkles", tint: item.tint, size: 170)
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

/// A quick side-to-side wobble for "not enough drops".
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
