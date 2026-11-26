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
        .preferredColorScheme(store.theme.colorScheme)
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
        .onAppear(perform: applyFeedbackSettings)
        .onChange(of: store.profile) {
            applyFeedbackSettings()
            store.save()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                store.save()
            }
        }
    }

    private func applyFeedbackSettings() {
        Haptics.isEnabled = store.profile.hapticsOn
        SoundFX.isEnabled = store.profile.soundsOn
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
    case today, insights, garden, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .insights: "Insights"
        case .garden: "Garden"
        case .settings: "Me"
        }
    }

    var icon: String {
        switch self {
        case .today: "drop.fill"
        case .insights: "chart.bar.fill"
        case .garden: "leaf.fill"
        case .settings: "person.fill"
        }
    }

    static var initial: AppTab {
        switch LaunchOptions.screenshot {
        case "insights": .insights
        case "garden", "challenges": .garden
        case "settings": .settings
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
                case .insights: InsightsView()
                case .garden: GardenView()
                case .settings: SettingsView()
                }
            }
            .id(router.tab)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 14)),
                removal: .opacity
            ))

            // Paint the status bar in the sky's top color, so the white clock stays
            // readable when light content scrolls up underneath it.
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    theme.sky[0].frame(height: proxy.safeAreaInsets.top)
                    Spacer(minLength: 0)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar()
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
        }
        .sheet(isPresented: $router.showAddDrink) {
            DrinkPickerSheet { kind, amount in
                router.log(kind, amount: amount)
            }
        }
        .onAppear {
            guard LaunchOptions.screenshot == "add" else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                router.showAddDrink = true
            }
        }
    }
}

/// The floating tab bar, with a raised candy "+" in the middle for logging a drink.
struct FloatingTabBar: View {
    @Environment(\.dewyTheme) private var theme
    @Environment(AppRouter.self) private var router
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.today)
            tabButton(.insights)
            addButton
            tabButton(.garden)
            tabButton(.settings)
        }
        .padding(.horizontal, 8)
        .frame(height: 68)
        .background {
            Capsule()
                .fill(theme.card)
                .shadow(color: theme.isDark ? Color.black.opacity(0.45) : theme.sky[0].opacity(0.16), radius: 22, x: 0, y: 10)
        }
    }

    private func tabButton(_ item: AppTab) -> some View {
        let isSelected = router.tab == item
        return Button {
            guard !isSelected else { return }
            Haptics.select()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                router.tab = item
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.system(size: 19, weight: .heavy))
                    .symbolEffect(.bounce, value: isSelected)
                    .frame(width: 46, height: 30)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(theme.accentSoft)
                                .matchedGeometryEffect(id: "tab", in: namespace)
                        }
                    }
                    .foregroundStyle(isSelected ? theme.link : theme.inkSoft.opacity(0.75))
                Text(item.title)
                    .font(.dewy(10.5, .heavy))
                    .foregroundStyle(isSelected ? theme.ink : theme.inkSoft.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.88))
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
                .foregroundStyle(theme.onAccent)
                .frame(width: 60, height: 60)
                .contentShape(Circle())
        }
        .buttonStyle(CandyButtonStyle(fill: theme.accent, lip: theme.accentDeep, shape: AnyShape(Circle()), depth: 5))
        .background {
            Circle()
                .fill(theme.card)
                .frame(width: 74, height: 74)
                .offset(y: 2)
        }
        .shadow(color: theme.accent.opacity(0.4), radius: 12, x: 0, y: 8)
        .offset(y: -18)
        .frame(width: 76)
        .accessibilityLabel("Add a drink")
    }
}
