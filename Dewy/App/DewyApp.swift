import SwiftUI

@main
struct DewyApp: App {
    @State private var store = HydrationStore()
    @State private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(purchases)
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
        .onChange(of: store.profile) {
            store.save()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                store.save()
            }
        }
    }
}

// MARK: - Tabs

enum AppTab: String, CaseIterable, Identifiable {
    case today, insights, garden, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .insights: "Insights"
        case .garden: "Garden"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .today: "drop.fill"
        case .insights: "chart.bar.fill"
        case .garden: "leaf.fill"
        case .settings: "gearshape.fill"
        }
    }

    static var initial: AppTab {
        switch LaunchOptions.screenshot {
        case "insights": .insights
        case "garden": .garden
        case "settings": .settings
        default: .today
        }
    }
}

struct MainTabView: View {
    @Environment(\.dewyTheme) private var theme
    @State private var tab: AppTab = .initial

    var body: some View {
        ZStack {
            theme.canvas.ignoresSafeArea()

            Group {
                switch tab {
                case .today: TodayView()
                case .insights: InsightsView()
                case .garden: GardenView()
                case .settings: SettingsView()
                }
            }
            .id(tab)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 14)),
                removal: .opacity
            ))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(selection: $tab)
                .padding(.horizontal, 22)
                .padding(.bottom, 6)
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.dewyTheme) private var theme
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { item in
                let isSelected = item == selection
                Button {
                    guard !isSelected else { return }
                    Haptics.select()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                        selection = item
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: .heavy))
                            .symbolEffect(.bounce, value: isSelected)
                        if isSelected {
                            Text(item.title)
                                .font(.dewy(15, .heavy))
                                .lineLimit(1)
                                .fixedSize()
                                .transition(.opacity.combined(with: .scale(scale: 0.6, anchor: .leading)))
                        }
                    }
                    .foregroundStyle(isSelected ? Color.white : theme.inkSoft)
                    .frame(maxWidth: isSelected ? .infinity : 56)
                    .frame(height: 52)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(theme.isDark ? theme.heroLight : theme.hero)
                                .shadow(color: theme.hero.opacity(0.45), radius: 10, x: 0, y: 5)
                                .matchedGeometryEffect(id: "pill", in: namespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.9))
                .accessibilityLabel(item.title)
            }
        }
        .padding(6)
        .background(theme.card, in: Capsule())
        .shadow(color: Color.black.opacity(theme.isDark ? 0.4 : 0.12), radius: 22, x: 0, y: 10)
    }
}
