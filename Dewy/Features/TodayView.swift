import SwiftUI

struct TodayView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme

    @State private var showPicker = false
    @State private var showPaywall = false
    @State private var bounce = 0
    @State private var celebrate = 0
    @State private var toast: DrinkEntry?
    @State private var toastTask: Task<Void, Never>?
    @State private var appeared = false

    private let quickKinds: [DrinkKind] = [.water, .tea, .coffee, .juice, .sparkling, .smoothie, .milk, .soda]

    var body: some View {
        ZStack {
            HeroBackdrop()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 22)
                        .floatIn(appeared, index: 0)
                    hero
                        .floatIn(appeared, index: 1)
                    sheet
                        .floatIn(appeared, index: 2)
                }
                .padding(.top, 6)
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
            if LaunchOptions.screenshot == "add" || LaunchOptions.screenshot == "paywall" {
                // Demo screenshots: present the sheet once the screen is on display.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.8))
                    if LaunchOptions.screenshot == "add" {
                        showPicker = true
                    } else {
                        showPaywall = true
                    }
                }
            }
            if LaunchOptions.screenshot == "celebrate" {
                // Demo recording: two drinks, the second one reaches the goal.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2.5))
                    add(.sparkling, amount: 500)
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
            VStack(alignment: .leading, spacing: 3) {
                CapsLabel(
                    text: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
                    color: theme.onHeroSoft,
                    size: 12
                )
                Text(store.profile.name.isEmpty ? greeting : "\(greeting), \(store.profile.name)")
                    .font(.dewy(27, .black))
                    .foregroundStyle(theme.onHero)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 12)
            StreakPill(days: store.currentStreak)
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 10) {
            ZStack {
                HaloRings(diameter: 330)
                MascotView(
                    progress: store.todayProgress,
                    mood: store.mood,
                    size: 196,
                    bounceTrigger: bounce,
                    bands: store.todayBands
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    bounce += 1
                    Haptics.tap()
                }
            }
            .frame(height: 290)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                SpeechBubble(text: store.mood.line())
                    .padding(.trailing, 20)
                    .padding(.top, 22)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(store.format(store.todayTotal, withUnit: false))
                    .font(.dewy(66, .black))
                    .foregroundStyle(theme.onHero)
                    .contentTransition(.numericText(value: store.displayValue(store.todayTotal)))
                Text(store.profile.unit.label)
                    .font(.dewy(24, .heavy))
                    .foregroundStyle(theme.onHeroSoft)
            }
            .shadow(color: theme.heroDeep.opacity(0.4), radius: 0, x: 0, y: 3)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.todayTotal)

            HStack(spacing: 10) {
                Text("\(Int((store.todayProgress * 100).rounded()))%")
                    .font(.dewy(15, .black))
                    .foregroundStyle(theme.heroDeep)
                    .contentTransition(.numericText())
                    .padding(.horizontal, 11)
                    .frame(height: 28)
                    .background(Color.white, in: Capsule())
                Text("of your \(store.format(store.goal)) goal")
                    .font(.dewy(16, .heavy))
                    .foregroundStyle(theme.onHero)
            }
            .padding(4)
            .padding(.trailing, 10)
            .background(Color.white.opacity(0.2), in: Capsule())
            .animation(.spring, value: store.todayTotal)

            DrinkStripe(bands: store.todayBands)
                .frame(width: 230, height: 10)
                .padding(.top, 6)
        }
        .padding(.bottom, 30)
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 26) {
            quickAdd
            logSection
            tipCard
        }
        .padding(.top, 26)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .canvasSheet()
    }

    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CapsLabel(text: "Quick add", color: theme.inkSoft, size: 13)
                Spacer()
                Button {
                    Haptics.tap()
                    showPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text("All drinks")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .black))
                    }
                    .font(.dewy(14, .heavy))
                    .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(quickKinds) { kind in
                        let locked = kind.isPremium && !purchases.isPremium
                        QuickDrinkButton(kind: kind, amount: store.format(kind.defaultAmount), isLocked: locked) {
                            if locked {
                                Haptics.warning()
                                showPaywall = true
                            } else {
                                add(kind, amount: kind.defaultAmount)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    // MARK: Log

    private var logSection: some View {
        let entries = Array(store.todayEntries.prefix(8))
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's sips", trailing: entries.isEmpty ? nil : "\(store.todayEntries.count) drinks")

            if entries.isEmpty {
                HStack(spacing: 14) {
                    MascotView(progress: 0, mood: .thirsty, size: 50, backdrop: .light, animated: false)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("No sips yet")
                            .font(.dewy(17, .heavy))
                            .foregroundStyle(theme.ink)
                        Text("Tap a cup above and watch Dewy fill up!")
                            .font(.dewy(14, .semibold))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
                .dewyCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        EntryRow(
                            entry: entry,
                            amount: store.format(entry.amount),
                            effective: store.format(entry.effective),
                            isFirst: index == 0,
                            isLast: index == entries.count - 1
                        )
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
                    }
                }
                .dewyCard(padding: 14)
            }
        }
        .padding(.horizontal, 20)
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Palette.sunshine)
                .frame(width: 44, height: 44)
                .background(Color(hex: 0x1E2340), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                CapsLabel(text: "Daily dew tip", color: Color(hex: 0x1E2340).opacity(0.6), size: 12)
                Text(HydrationTips.tip())
                    .font(.dewy(16, .heavy))
                    .foregroundStyle(Color(hex: 0x1E2340))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Palette.sunshine)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 90, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.28))
                        .rotationEffect(.degrees(-18))
                        .offset(x: 18, y: 22)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: Palette.sunshine.opacity(0.4), radius: 14, x: 0, y: 8)
        }
        .padding(.horizontal, 20)
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

/// A cup button in the quick-add row: one tap logs the drink's usual serving.
struct QuickDrinkButton: View {
    @Environment(\.dewyTheme) private var theme
    var kind: DrinkKind
    var amount: String
    var isLocked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                DrinkVessel(kind: kind, fill: 0.74, width: 36)
                    .frame(height: 46)
                VStack(spacing: 1) {
                    Text(kind.name.uppercased())
                        .font(.dewy(11, .black))
                        .tracking(0.6)
                        .foregroundStyle(theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(amount)
                        .font(.dewy(13, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            .frame(width: 80)
            .padding(.vertical, 14)
            .background(theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: theme.shadow, radius: 12, x: 0, y: 6)
            .overlay(alignment: .topTrailing) {
                Image(systemName: isLocked ? "lock.fill" : "plus")
                    .font(.system(size: isLocked ? 9 : 11, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(isLocked ? Color(hex: 0x1E2340) : kind.color, in: Circle())
                    .overlay(Circle().strokeBorder(theme.card, lineWidth: 2.5))
                    .offset(x: 4, y: -4)
            }
            .opacity(isLocked ? 0.8 : 1)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("Add \(amount) of \(kind.name)")
    }
}

/// A slim capsule striped with today's drink colors.
struct DrinkStripe: View {
    var bands: [LiquidBand]
    var track: Color = Color.white.opacity(0.24)

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let total = max(bands.last?.upTo ?? 0, 1)
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                HStack(spacing: 2) {
                    ForEach(Array(bands.enumerated()), id: \.offset) { index, band in
                        let previous = index == 0 ? 0 : bands[index - 1].upTo
                        Rectangle()
                            .fill(band.color)
                            .frame(width: max(2, width * CGFloat((band.upTo - previous) / total) - 2))
                    }
                }
                .clipShape(Capsule())
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: bands.count)
    }
}

struct StreakPill: View {
    @Environment(\.dewyTheme) private var theme
    var days: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.flame)
                .symbolEffect(.bounce, value: days)
            Text("\(days)")
                .font(.dewy(18, .black))
                .foregroundStyle(Color(hex: 0x1E2340))
                .contentTransition(.numericText(value: Double(days)))
        }
        .padding(.horizontal, 15)
        .frame(height: 42)
        .background(Color.white, in: Capsule())
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
        .accessibilityLabel("\(days) day streak")
    }
}

struct SpeechBubble: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.dewy(13, .heavy))
            .foregroundStyle(Color(hex: 0x1E2340))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 112)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .overlay(alignment: .bottomLeading) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .offset(x: 6, y: 9)
                    }
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
            }
            .rotationEffect(.degrees(4))
            .id(text)
            .transition(.scale.combined(with: .opacity))
    }
}

struct ProgressCapsule: View {
    @Environment(\.dewyTheme) private var theme
    var progress: Double
    var tint: Color?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.well)
                Capsule()
                    .fill(tint ?? theme.accent)
                    .frame(width: max(proxy.size.height, proxy.size.width * min(max(progress, 0), 1)))
                    .overlay(alignment: .trailing) {
                        Circle()
                            .fill(.white)
                            .frame(width: proxy.size.height * 0.45, height: proxy.size.height * 0.45)
                            .padding(.trailing, proxy.size.height * 0.28)
                    }
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
    var isFirst: Bool
    var isLast: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.date.formatted(date: .omitted, time: .shortened))
                .font(.dewy(13, .heavy))
                .foregroundStyle(theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 62, alignment: .trailing)

            ZStack {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(isFirst ? Color.clear : theme.line)
                        .frame(width: 3)
                    Rectangle()
                        .fill(isLast ? Color.clear : theme.line)
                        .frame(width: 3)
                }
                Circle()
                    .fill(entry.kind.color)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().strokeBorder(theme.card, lineWidth: 3))
            }
            .frame(width: 16)

            DrinkVessel(kind: entry.kind, fill: 0.72, width: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.kind.name)
                    .font(.dewy(16, .heavy))
                    .foregroundStyle(theme.ink)
                if entry.kind.hydration < 1 {
                    Text("≈ \(effective) hydration")
                        .font(.dewy(11, .semibold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            Spacer(minLength: 4)
            Text("+\(amount)")
                .font(.dewy(15, .black))
                .foregroundStyle(entry.kind.color)
        }
        .frame(height: 60)
        .contentShape(Rectangle())
    }
}

struct ToastView: View {
    var entry: DrinkEntry
    var label: String
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(entry.kind.color)
                .frame(width: 12, height: 12)
            Text("Added \(label) \(entry.kind.name.lowercased())")
                .font(.dewy(15, .heavy))
                .foregroundStyle(.white)
            Button(action: onUndo) {
                Text("UNDO")
                    .font(.dewy(14, .black))
                    .tracking(0.8)
                    .foregroundStyle(Palette.sunshine)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 48)
        .background(Color(hex: 0x1E2340), in: Capsule())
        .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 8)
    }
}
