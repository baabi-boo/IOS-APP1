import SwiftUI

struct TodayView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme

    @State private var showPicker = LaunchOptions.screenshot == "add"
    @State private var showPaywall = LaunchOptions.screenshot == "paywall"
    @State private var bounce = 0
    @State private var celebrate = 0
    @State private var toast: DrinkEntry?
    @State private var toastTask: Task<Void, Never>?
    @State private var appeared = false

    private struct QuickServing {
        let title: String
        let amount: Double
        let fill: Double
    }

    private let quickServings: [QuickServing] = [
        QuickServing(title: "Sip", amount: 150, fill: 0.35),
        QuickServing(title: "Glass", amount: 250, fill: 0.6),
        QuickServing(title: "Bottle", amount: 500, fill: 0.9)
    ]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 22) {
                    header.floatIn(appeared, index: 0)
                    hero.floatIn(appeared, index: 1)
                    quickAdd.floatIn(appeared, index: 2)
                    logSection.floatIn(appeared, index: 3)
                    tipCard.floatIn(appeared, index: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            ConfettiView(trigger: celebrate)
                .ignoresSafeArea()
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastView(entry: toast, label: store.format(toast.amount)) {
                    undo(toast)
                }
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
            }
        }
        .sheet(isPresented: $showPicker) {
            DrinkPickerSheet { kind, amount in
                add(kind, amount: amount)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            appeared = true
            if LaunchOptions.screenshot == "celebrate" {
                // Demo recording: two sips, the second one reaches the goal.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2.5))
                    add(.water, amount: 500)
                    try? await Task.sleep(for: .seconds(3))
                    add(.water, amount: 500)
                }
            }
        }
    }

    // MARK: Header

    private var greeting: String {
        let hour = LaunchOptions.isDemo ? 14 : Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello, night owl"
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased())
                    .font(.dewy(13, .bold))
                    .tracking(1.2)
                    .foregroundStyle(theme.inkSoft)
                Text(store.profile.name.isEmpty ? greeting : "\(greeting), \(store.profile.name)")
                    .font(.dewy(26, .heavy))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 12)
            StreakPill(days: store.currentStreak)
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                MascotView(progress: store.todayProgress, mood: store.mood, size: 196, bounceTrigger: bounce)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        bounce += 1
                        Haptics.tap()
                    }

                SpeechBubble(text: store.mood.line())
                    .offset(x: -2, y: 6)
            }
            .padding(.top, 4)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(store.format(store.todayTotal, withUnit: false))
                    .font(.dewy(54, .heavy))
                    .foregroundStyle(theme.ink)
                    .contentTransition(.numericText(value: store.displayValue(store.todayTotal)))
                Text(store.profile.unit.label)
                    .font(.dewy(22, .bold))
                    .foregroundStyle(theme.inkSoft)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.todayTotal)

            Text("of \(store.format(store.goal)) · \(Int((store.todayProgress * 100).rounded()))%")
                .font(.dewy(16, .semibold))
                .foregroundStyle(theme.inkSoft)
                .contentTransition(.numericText())
                .animation(.spring, value: store.todayTotal)

            ProgressCapsule(progress: store.todayProgress)
                .frame(height: 12)
                .padding(.horizontal, 40)
                .padding(.top, 10)
        }
    }

    // MARK: Quick add

    private var quickAdd: some View {
        HStack(spacing: 12) {
            ForEach(quickServings, id: \.title) { serving in
                Button {
                    add(.water, amount: serving.amount)
                } label: {
                    VStack(spacing: 8) {
                        CupGlyph(fill: serving.fill, width: 26, height: 32)
                        VStack(spacing: 1) {
                            Text(store.format(serving.amount))
                                .font(.dewy(15, .bold))
                                .foregroundStyle(theme.ink)
                            Text(serving.title)
                                .font(.dewy(12, .semibold))
                                .foregroundStyle(theme.inkSoft)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard(padding: 14, radius: 24)
                }
                .buttonStyle(SquishyButtonStyle())
            }

            Button {
                Haptics.tap()
                showPicker = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .heavy))
                        .frame(height: 32)
                    Text("More")
                        .font(.dewy(13, .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 66)
                .padding(.vertical, 14)
                .frame(maxHeight: .infinity)
                .background(theme.accentGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.35)))
                .shadow(color: theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(SquishyButtonStyle())
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Log

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's sips", trailing: store.todayEntries.isEmpty ? nil : "\(store.todayEntries.count) drinks")

            if store.todayEntries.isEmpty {
                HStack(spacing: 14) {
                    Text("🫗").font(.system(size: 34))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("No sips yet")
                            .font(.dewy(17, .bold))
                            .foregroundStyle(theme.ink)
                        Text("Tap a glass above and watch Dewy fill up!")
                            .font(.dewy(14, .medium))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
                .glassCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.todayEntries.prefix(8).enumerated()), id: \.element.id) { index, entry in
                        EntryRow(entry: entry, amount: store.format(entry.amount), effective: store.format(entry.effective))
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation(.spring) { store.delete(entry) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            ))
                        if index < min(store.todayEntries.count, 8) - 1 {
                            Divider().overlay(theme.inkSoft.opacity(0.15)).padding(.leading, 62)
                        }
                    }
                }
                .glassCard(padding: 14)
            }
        }
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Palette.sunshine)
                .frame(width: 44, height: 44)
                .background(Palette.sunshine.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily dew tip")
                    .font(.dewy(15, .bold))
                    .foregroundStyle(theme.ink)
                Text(HydrationTips.tip())
                    .font(.dewy(14, .medium))
                    .foregroundStyle(theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .glassCard()
    }

    // MARK: Actions

    private func add(_ kind: DrinkKind, amount: Double) {
        let wasBelowGoal = store.todayProgress < 1
        var entry: DrinkEntry?
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            entry = store.add(kind, amount: amount)
        }
        bounce += 1
        Haptics.splash()
        if wasBelowGoal && store.todayProgress >= 1 {
            celebrate += 1
            Haptics.success()
        }
        guard let entry else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            toast = entry
        }
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) { toast = nil }
        }
    }

    private func undo(_ entry: DrinkEntry) {
        toastTask?.cancel()
        Haptics.tap()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            store.delete(entry)
            toast = nil
        }
    }
}

// MARK: - Pieces

struct StreakPill: View {
    @Environment(\.dewyTheme) private var theme
    var days: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.flame)
                .symbolEffect(.bounce, value: days)
            Text("\(days)")
                .font(.dewy(17, .heavy))
                .foregroundStyle(theme.ink)
                .contentTransition(.numericText(value: Double(days)))
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(.ultraThinMaterial, in: Capsule())
        .background(theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
        .accessibilityLabel("\(days) day streak")
    }
}

struct SpeechBubble: View {
    @Environment(\.dewyTheme) private var theme
    var text: String

    var body: some View {
        Text(text)
            .font(.dewy(13, .bold))
            .foregroundStyle(theme.ink)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 120)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.isDark ? Color.white.opacity(0.14) : Color.white.opacity(0.92))
                    .overlay(alignment: .bottomLeading) {
                        Circle()
                            .fill(theme.isDark ? Color.white.opacity(0.14) : Color.white.opacity(0.92))
                            .frame(width: 12, height: 12)
                            .offset(x: 6, y: 9)
                    }
                    .shadow(color: theme.shadow, radius: 10, x: 0, y: 5)
            }
            .rotationEffect(.degrees(3))
            .id(text)
            .transition(.scale.combined(with: .opacity))
    }
}

struct ProgressCapsule: View {
    @Environment(\.dewyTheme) private var theme
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.inkSoft.opacity(0.14))
                Capsule()
                    .fill(LinearGradient(colors: [theme.waterTop, theme.waterBottom], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(proxy.size.height, proxy.size.width * min(progress, 1)))
                    .overlay(alignment: .trailing) {
                        Circle()
                            .fill(.white)
                            .frame(width: proxy.size.height * 0.5, height: proxy.size.height * 0.5)
                            .padding(.trailing, proxy.size.height * 0.25)
                    }
                    .shadow(color: theme.waterBottom.opacity(0.35), radius: 6, x: 0, y: 3)
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
    }
}

struct EntryRow: View {
    @Environment(\.dewyTheme) private var theme
    var entry: DrinkEntry
    var amount: String
    var effective: String

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.kind.emoji)
                .font(.system(size: 24))
                .frame(width: 46, height: 46)
                .background(entry.kind.color.opacity(0.2), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind.name)
                    .font(.dewy(16, .bold))
                    .foregroundStyle(theme.ink)
                Text(entry.date.formatted(date: .omitted, time: .shortened))
                    .font(.dewy(13, .medium))
                    .foregroundStyle(theme.inkSoft)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(amount)")
                    .font(.dewy(16, .heavy))
                    .foregroundStyle(entry.kind.color)
                if entry.kind.hydration < 1 {
                    Text("≈ \(effective) hydration")
                        .font(.dewy(11, .medium))
                        .foregroundStyle(theme.inkSoft)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct ToastView: View {
    @Environment(\.dewyTheme) private var theme
    var entry: DrinkEntry
    var label: String
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(entry.kind.emoji)
            Text("Added \(label) \(entry.kind.name.lowercased())")
                .font(.dewy(15, .bold))
                .foregroundStyle(theme.ink)
            Button("Undo", action: onUndo)
                .font(.dewy(15, .heavy))
                .foregroundStyle(theme.accent)
        }
        .padding(.horizontal, 18)
        .frame(height: 46)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
        .shadow(color: theme.shadow, radius: 14, x: 0, y: 8)
    }
}
