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
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @State private var motion = MotionManager()

    /// True whenever the active screen displays a deep twilight or night sky beneath the status bar.
    private var usesLightStatusBar: Bool {
        guard store.hasOnboarded else { return false }
        if router.tab == .journey {
            return store.todayChapter == .grove || store.todayChapter == .lake
        }
        return store.theme.prefersLightStatusBar && (router.tab == .today || router.tab == .friends)
    }

    var body: some View {
        ZStack {
            if store.hasOnboarded {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
            } else {
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.smooth(duration: 0.55), value: store.hasOnboarded)
        .environment(\.dewyTheme, store.theme)
        .environment(\.dewySlosh, motion.slosh)
        // Pin all cotton-paper chrome and controls to warm light mode while letting the
        // window's status bar switch cleanly to crisp white over twilight/night skies.
        .environment(\.colorScheme, .light)
        .preferredColorScheme(usesLightStatusBar ? .dark : .light)
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

/// App-wide navigation state, so the dock's add stamp works from every tab.
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

    var inactiveIcon: String {
        switch self {
        case .today: "drop"
        case .journey: "map"
        case .friends: "heart"
        case .insights: "chart.bar"
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
                insertion: .opacity.combined(with: .offset(y: 12)).combined(with: .scale(scale: 0.99)),
                removal: .opacity
            ))

            // Subtle airy paper mist tucked strictly behind the dock.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(
                    stops: [
                        .init(color: theme.canvas.opacity(0), location: 0),
                        .init(color: theme.canvas.opacity(0.84), location: 0.62),
                        .init(color: theme.canvas, location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 56)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar()
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
        }
        .sheet(isPresented: $router.showAddDrink) {
            DrinkPickerSheet { kind, amount in
                router.log(kind, amount: amount)
            }
            .preferredColorScheme(.light)
        }
        .sheet(isPresented: $router.showMe) {
            SettingsView()
                .preferredColorScheme(.light)
        }
        .sheet(isPresented: $router.showPaywall) {
            PaywallView()
                .preferredColorScheme(.light)
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

/// Tactile cotton-paper floating storybook dock with a nested circular cerulean stamp "+" button.
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
        .frame(height: 62)
        .background {
            PaperSurface(shape: Capsule(), fill: Palette.paper, tint: Palette.shadow, elevation: 0.9)
        }
    }

    private func tabButton(_ item: AppTab) -> some View {
        let isSelected = router.tab == item
        return Button {
            guard !isSelected else { return }
            Haptics.select()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                router.tab = item
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? item.icon : item.inactiveIcon)
                    .font(.system(size: 17.5, weight: isSelected ? .bold : .medium))
                    .symbolEffect(.bounce, value: isSelected)
                    .frame(width: 44, height: 28)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Palette.aquaSoft)
                                .overlay(Capsule().stroke(Palette.aqua.opacity(0.22), lineWidth: 1))
                                .matchedGeometryEffect(id: "tab", in: namespace)
                        }
                    }
                    .foregroundStyle(isSelected ? Palette.aquaDeep : theme.inkSoft.opacity(0.82))
                Text(item.title)
                    .font(.dewy(10, isSelected ? .bold : .semibold))
                    .tracking(0.15)
                    .foregroundStyle(isSelected ? theme.ink : theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.9))
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var addButton: some View {
        ZStack {
            Circle()
                .fill(Palette.paper)
                .overlay(Circle().stroke(Ink.hairline, lineWidth: 1))
                .frame(width: 52, height: 52)

            Button {
                Haptics.tap()
                SoundFX.play(.pop, volume: 0.35)
                router.showAddDrink = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Palette.paper)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(
                StampButtonStyle(
                    fill: theme.accent,
                    lip: theme.accentDeep,
                    shape: AnyShape(Circle()),
                    depth: 2.5
                )
            )
            .shadow(color: theme.accentDeep.opacity(0.24), radius: 6, x: 0, y: 3)
            .offset(y: 0.5)
        }
        .frame(width: 60)
        .accessibilityLabel("Add a drink")
    }
}
