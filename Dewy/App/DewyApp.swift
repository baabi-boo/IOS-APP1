import SwiftUI

@main
struct DewyApp: App {
    @State private var store = HydrationStore()
    @State private var purchases = PurchaseManager()
    @State private var router = AppRouter()

    init() {
        FontRegistry.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(purchases)
                .environment(router)
        }
    }
}

struct RootView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.scenePhase) private var scenePhase
    @State private var motion = MotionManager()

    var body: some View {
        ZStack {
            if store.hasOnboarded {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            } else {
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.smooth(duration: 0.6), value: store.hasOnboarded)
        .environment(\.dewyTheme, store.theme)
        .environment(\.dewySlosh, motion.slosh)
        .preferredColorScheme(.light)
        .tint(store.theme.accent)
        .task {
            await purchases.start()
        }
        .task {
            // Demo mode: tell the screenshot script once launch animations have settled.
            guard LaunchOptions.isDemo else { return }
            try? await Task.sleep(for: .seconds(3.5))
            let marker = FileManager.default.temporaryDirectory.appendingPathComponent("dewy-ready")
            try? Data().write(to: marker)
        }
        .onAppear {
            applyFeedbackSettings()
            installHooks()
            store.notePremium(purchases.isPremium)
            store.settleDemoBalance()
            motion.start()
        }
        .onChange(of: purchases.isPremium) {
            store.notePremium(purchases.isPremium)
        }
        .onChange(of: store.profile) {
            applyFeedbackSettings()
            store.save()
            LiveActivityManager.sync(store)
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background:
                store.save()
                motion.stop()
            case .active:
                store.reloadFromDisk()
                motion.start()
            default: break
            }
        }
    }

    private func applyFeedbackSettings() {
        Haptics.isEnabled = store.profile.hapticsOn
        SoundFX.isEnabled = store.profile.soundsOn
    }

    /// Mirrors drinks into Apple Health and the Live Activity, from the app and from the Lock Screen.
    private func installHooks() {
        HydrationStore.onAdd = { entry, store in
            if store.profile.healthSyncOn { HealthSync.write(entry) }
            LiveActivityManager.sync(store)
        }
        HydrationStore.onDelete = { entry, store in
            if store.profile.healthSyncOn { HealthSync.delete(entry) }
            LiveActivityManager.sync(store)
        }
        let store = store
        QuickSipHooks.onLogged = { entry, data in
            if data.profile.healthSyncOn { HealthSync.write(entry) }
            LiveActivityManager.sync(data: data, enabled: data.profile.liveActivityOn)
            store.reloadFromDisk()
        }
    }
}

// MARK: - Routing

/// A drink picked in the drink sheet, waiting for the Today screen to pour it into Dewy.
struct QueuedDrink: Equatable {
    var id = UUID()
    var kind: DrinkKind
    var amount: Double
}

/// App-wide navigation state, so the tab bar's add button works from every tab.
@MainActor
@Observable
final class AppRouter {
    var tab: AppTab = .initial
    var showAddDrink = false
    var showMe = false
    var showPaywall = false
    var queuedDrink: QueuedDrink?

    /// Sends a drink to the Today screen, switching tabs so you can watch Dewy fill up.
    func log(_ kind: DrinkKind, amount: Double) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            tab = .today
        }
        queuedDrink = QueuedDrink(kind: kind, amount: amount)
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case today, journey, friends, insights

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .journey: "Journey"
        case .friends: "Friends"
        case .insights: "Insights"
        }
    }

    var icon: String {
        switch self {
        case .today: "drop.fill"
        case .journey: "map.fill"
        case .friends: "heart.fill"
        case .insights: "chart.bar.fill"
        }
    }

    static var initial: AppTab {
        switch LaunchOptions.screenshot {
        case "insights": .insights
        case "journey", "garden", "challenges", "badges": .journey
        case "friends", "wardrobe", "places", "decor": .friends
        default: .today
        }
    }
}

// MARK: - Main tabs

struct MainTabView: View {
    @Environment(\.dewyTheme) private var theme
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        ZStack {
            theme.canvas.ignoresSafeArea()

            Group {
                switch router.tab {
                case .today: TodayView()
                case .journey: JourneyView()
                case .friends: FriendsView()
                case .insights: InsightsView()
                }
            }
            .id(router.tab)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 16)).combined(with: .scale(scale: 0.985)),
                removal: .opacity
            ))

            // Content fades out softly behind the floating tab bar.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(
                    stops: [
                        .init(color: theme.canvas.opacity(0), location: 0),
                        .init(color: theme.canvas.opacity(0.92), location: 0.5),
                        .init(color: theme.canvas, location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 140)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar()
                .padding(.horizontal, 18)
                .padding(.bottom, 2)
        }
        .sheet(isPresented: $router.showAddDrink) {
            DrinkPickerSheet { kind, amount in
                router.log(kind, amount: amount)
            }
        }
        .sheet(isPresented: $router.showMe) {
            SettingsView()
        }
        .sheet(isPresented: $router.showPaywall) {
            PaywallView()
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                switch LaunchOptions.screenshot {
                case "add": router.showAddDrink = true
                case "settings", "me", "widgets": router.showMe = true
                case "paywall": router.showPaywall = true
                default: break
                }
            }
        }
    }
}

/// The floating clay tab bar, with a puffy aqua "+" in the middle for logging a drink.
struct FloatingTabBar: View {
    @Environment(\.dewyTheme) private var theme
    @Environment(AppRouter.self) private var router
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.today)
            tabButton(.journey)
            addButton
            tabButton(.friends)
            tabButton(.insights)
        }
        .padding(.horizontal, 8)
        .frame(height: 72)
        .background {
            ClaySurface(shape: RoundedRectangle(cornerRadius: 30, style: .continuous), fill: .white, glow: Palette.shadow, elevation: 1)
        }
    }

    private func tabButton(_ item: AppTab) -> some View {
        let isSelected = router.tab == item
        return Button {
            guard !isSelected else { return }
            Haptics.select()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                router.tab = item
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.system(size: 19, weight: .heavy))
                    .symbolEffect(.bounce, value: isSelected)
                    .frame(width: 50, height: 32)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(LinearGradient(colors: [Palette.aquaSoft, Color(hex: 0xC9ECFA)], startPoint: .top, endPoint: .bottom))
                                .overlay(Capsule().stroke(.white, lineWidth: 1.2))
                                .matchedGeometryEffect(id: "tab", in: namespace)
                        }
                    }
                    .foregroundStyle(isSelected ? Palette.aquaDeep : theme.inkFaint)
                Text(item.title)
                    .font(.dewy(10.5, .heavy))
                    .foregroundStyle(isSelected ? theme.ink : theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.86))
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var addButton: some View {
        Button {
            Haptics.tap()
            SoundFX.play(.pop, volume: 0.35)
            router.showAddDrink = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: Palette.aquaDeep.opacity(0.5), radius: 0, x: 0, y: 1.5)
                .frame(width: 62, height: 58)
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(CandyButtonStyle(fill: theme.accent, lip: theme.accentDeep, shape: AnyShape(RoundedRectangle(cornerRadius: 22, style: .continuous)), depth: 5))
        .shadow(color: theme.accent.opacity(0.4), radius: 12, x: 0, y: 8)
        .offset(y: -14)
        .frame(width: 76)
        .accessibilityLabel("Add a drink")
    }
}
