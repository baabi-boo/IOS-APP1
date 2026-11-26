import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme

    @State private var showPaywall = false
    @State private var confirmErase = false
    @State private var confirmClear = false
    @State private var permissionDenied = false
    @State private var appeared = false

    private struct ReminderInterval {
        let minutes: Int
        let label: String
    }

    private let intervals = [
        ReminderInterval(minutes: 60, label: "1h"),
        ReminderInterval(minutes: 90, label: "1.5h"),
        ReminderInterval(minutes: 120, label: "2h"),
        ReminderInterval(minutes: 180, label: "3h")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 6)
                    .padding(.bottom, 30)
                    .floatIn(appeared, index: 0)
                    .background(alignment: .top) {
                        SkyHeaderBackground(height: 300, sunY: 40)
                    }
                VStack(spacing: 18) {
                    if !purchases.isPremium {
                        premiumCard.floatIn(appeared, index: 1)
                    }
                    goalCard.floatIn(appeared, index: 2)
                    worldsCard.floatIn(appeared, index: 3)
                    remindersCard.floatIn(appeared, index: 4)
                    feelCard.floatIn(appeared, index: 5)
                    profileCard.floatIn(appeared, index: 6)
                    dataCard.floatIn(appeared, index: 7)
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 30)
                .canvasSheet()
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onAppear { appeared = true }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: reminderSignature) {
            ReminderScheduler.reschedule(for: store.profile)
        }
        .confirmationDialog("Clear today's log?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear today", role: .destructive) {
                withAnimation { store.clearToday() }
            }
        } message: {
            Text("Dewy will forget every drink you logged today.")
        }
        .confirmationDialog("Erase everything?", isPresented: $confirmErase, titleVisibility: .visible) {
            Button("Erase all data", role: .destructive) {
                store.eraseEverything()
            }
        } message: {
            Text("Your history, garden and settings will be removed. This can't be undone.")
        }
        .alert("Notifications are off", isPresented: $permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Allow notifications for Dewy in Settings so it can send gentle sip reminders.")
        }
    }

    private var reminderSignature: String {
        let p = store.profile
        return "\(p.remindersOn)-\(p.reminderInterval)-\(p.wakeMinutes)-\(p.sleepMinutes)"
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<UserProfile, Value>) -> Binding<Value> {
        Binding(
            get: { store.profile[keyPath: keyPath] },
            set: { store.profile[keyPath: keyPath] = $0 }
        )
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    CapsLabel(text: "Make it yours", color: theme.onHeroSoft, size: 12)
                    Text("Me")
                        .font(.display(34))
                        .foregroundStyle(.white)
                }
                Spacer()
                if purchases.isPremium {
                    HStack(spacing: 5) {
                        Image(systemName: "crown.fill").font(.system(size: 13, weight: .heavy))
                        Text("Dewy+")
                    }
                    .font(.display(16))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 13)
                    .frame(height: 36)
                    .background(Palette.gold, in: Capsule())
                }
            }

            HStack(spacing: 16) {
                MascotView(progress: store.todayProgress, mood: store.mood, size: 92, bands: store.todayBands, animated: false, showsShadow: false)
                    .frame(width: 110, height: 110)
                    .background(Color.white.opacity(0.22), in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 3))
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.profile.name.isEmpty ? "Friend of Dewy" : store.profile.name)
                        .font(.display(28))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 6) {
                        profilePill(symbol: "flame.fill", text: "\(store.currentStreak) days")
                        profilePill(symbol: "drop.fill", text: store.formatLiters(store.totalEffective))
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func profilePill(symbol: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 12, weight: .heavy))
            Text(text).font(.display(15))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 11)
        .frame(height: 32)
        .background(Color.white.opacity(0.22), in: Capsule())
    }

    // MARK: Premium

    private var premiumCard: some View {
        Button {
            Haptics.tap()
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                MascotView(progress: 1.0, mood: .ecstatic, size: 76, accessory: .crown, bands: Self.rainbow, backdrop: .tile, animated: false, showsShadow: false)
                    .frame(width: 80, height: 92)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 2) {
                        Text("Dewy")
                        Text("+").foregroundStyle(Color(hex: 0xFFE27A))
                    }
                    .font(.display(26))
                    .foregroundStyle(.white)
                    Text("Every world, every drink, 30-day insights and custom reminders.")
                        .font(.dewy(13.5, .bold))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.24), in: Circle())
            }
            .padding(16)
        }
        .buttonStyle(CandyButtonStyle(
            fill: Color(hex: 0x8B5CF6),
            lip: Color(hex: 0x6236D9),
            shape: AnyShape(RoundedRectangle(cornerRadius: 28, style: .continuous)),
            depth: 5
        ))
        .background {
            // A soft sunset glow behind the card.
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFF8FB1).opacity(0.5), Color(hex: 0x8B5CF6).opacity(0.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blur(radius: 18)
                .offset(y: 8)
        }
    }

    static let rainbow: [LiquidBand] = [
        LiquidBand(color: Color(hex: 0x4DB4FF), upTo: 0.24),
        LiquidBand(color: Color(hex: 0xFFAE3D), upTo: 0.44),
        LiquidBand(color: Color(hex: 0x8CCF63), upTo: 0.62),
        LiquidBand(color: Color(hex: 0xFF7DB0), upTo: 0.8),
        LiquidBand(color: Color(hex: 0x3FD3DE), upTo: 1)
    ]

    // MARK: Goal

    private var goalCard: some View {
        let recommended = store.profile.recommendedGoal
        return VStack(alignment: .leading, spacing: 14) {
            SettingsLabel(icon: "target", tint: theme.accent, title: "Daily goal", subtitle: "Based on your body & day")
            HStack {
                roundButton("minus") {
                    store.profile.dailyGoal = max(500, store.profile.dailyGoal - store.profile.unit.step)
                }
                Spacer()
                VStack(spacing: -2) {
                    Text(store.format(store.profile.dailyGoal, withUnit: false))
                        .font(.display(46))
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: store.profile.dailyGoal))
                    Text(store.profile.unit.label + " per day")
                        .font(.display(14, .medium))
                        .foregroundStyle(theme.inkSoft)
                }
                Spacer()
                roundButton("plus") {
                    store.profile.dailyGoal = min(6_000, store.profile.dailyGoal + store.profile.unit.step)
                }
            }
            if abs(recommended - store.profile.dailyGoal) >= 1 {
                Button {
                    Haptics.select()
                    withAnimation(.spring) { store.profile.dailyGoal = recommended }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Use recommended \(store.format(recommended))")
                    }
                    .font(.display(15))
                    .foregroundStyle(theme.link)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(theme.accentSoft, in: Capsule())
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
        .dewyCard()
    }

    private func roundButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(theme.onAccent)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(CandyButtonStyle(fill: theme.accent, lip: theme.accentDeep, shape: AnyShape(Circle()), depth: 4))
    }

    // MARK: Worlds

    private var worldsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsLabel(icon: "globe.americas.fill", tint: Color(hex: 0x2FB4F0), title: "Dewy's world", subtitle: theme.tagline)
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(AppTheme.allCases) { option in
                        let locked = option.isPremium && !purchases.isPremium
                        Button {
                            if locked {
                                Haptics.warning()
                                showPaywall = true
                            } else {
                                Haptics.select()
                                withAnimation(.smooth(duration: 0.5)) { store.profile.theme = option }
                            }
                        } label: {
                            WorldSwatch(world: option, isSelected: store.theme == option, isLocked: locked)
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
        .dewyCard()
    }

    // MARK: Reminders

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: Binding(
                get: { store.profile.remindersOn },
                set: { newValue in toggleReminders(newValue) }
            )) {
                SettingsLabel(icon: "bell.badge.fill", tint: Palette.coral, title: "Sip reminders",
                              subtitle: store.profile.remindersOn ? "Dewy will nudge you gently" : "Off")
            }
            .tint(theme.accent)

            if store.profile.remindersOn {
                VStack(alignment: .leading, spacing: 10) {
                    CapsLabel(text: "Remind me every", color: theme.inkSoft, size: 11)
                    HStack(spacing: 8) {
                        ForEach(intervals, id: \.minutes) { option in
                            let locked = option.minutes != 120 && !purchases.isPremium
                            ChipButton(title: option.label, isSelected: store.profile.reminderInterval == option.minutes, isLocked: locked) {
                                if locked {
                                    showPaywall = true
                                } else {
                                    Haptics.select()
                                    withAnimation(.spring) { store.profile.reminderInterval = option.minutes }
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Rectangle().fill(theme.line).frame(height: 1.5)

            timeRow(icon: "sun.max.fill", tint: Palette.tangerine, title: "Wake up", minutes: binding(\.wakeMinutes))
            timeRow(icon: "moon.stars.fill", tint: Palette.grape, title: "Bedtime", minutes: binding(\.sleepMinutes))
        }
        .dewyCard()
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: store.profile.remindersOn)
    }

    private func timeRow(icon: String, tint: Color, title: String, minutes: Binding<Int>) -> some View {
        HStack {
            SettingsLabel(icon: icon, tint: tint, title: title)
            Spacer()
            DatePicker(title, selection: minutes.timeOfDay, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(theme.accent)
        }
    }

    private func toggleReminders(_ isOn: Bool) {
        Haptics.select()
        guard isOn else {
            store.profile.remindersOn = false
            return
        }
        Task { @MainActor in
            let granted = await ReminderScheduler.requestPermission()
            if granted {
                store.profile.remindersOn = true
            } else {
                permissionDenied = true
            }
        }
    }

    // MARK: Feel

    private var feelCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: binding(\.soundsOn)) {
                SettingsLabel(icon: "speaker.wave.2.fill", tint: Color(hex: 0x22B8C9), title: "Sounds", subtitle: "Bloops, splashes and a goal chime")
            }
            .tint(theme.accent)
            Toggle(isOn: binding(\.hapticsOn)) {
                SettingsLabel(icon: "hand.tap.fill", tint: Color(hex: 0xFF8A4C), title: "Haptics", subtitle: "Feel every sip")
            }
            .tint(theme.accent)
            Rectangle().fill(theme.line).frame(height: 1.5)
            VStack(alignment: .leading, spacing: 10) {
                SettingsLabel(icon: "bolt.fill", tint: Color(hex: 0x9C6ADE), title: "Caffeine budget", subtitle: "Dewy keeps an eye on it for you")
                HStack(spacing: 8) {
                    ForEach([200.0, 300, 400], id: \.self) { limit in
                        ChipButton(title: "\(Int(limit)) mg", isSelected: store.profile.caffeineLimit == limit, tint: Color(hex: 0x9C6ADE), tintDeep: Color(hex: 0x7A48C0)) {
                            Haptics.select()
                            withAnimation(.spring) { store.profile.caffeineLimit = limit }
                        }
                    }
                }
            }
        }
        .dewyCard()
    }

    // MARK: Profile

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SettingsLabel(icon: "person.fill", tint: Palette.sky, title: "Name")
                Spacer()
                TextField("Your name", text: binding(\.name))
                    .multilineTextAlignment(.trailing)
                    .font(.display(17, .medium))
                    .foregroundStyle(theme.ink)
                    .submitLabel(.done)
                    .frame(maxWidth: 160)
            }
            Rectangle().fill(theme.line).frame(height: 1.5)
            HStack {
                SettingsLabel(icon: "ruler.fill", tint: Palette.mint, title: "Units")
                Spacer()
                HStack(spacing: 6) {
                    ForEach(VolumeUnit.allCases) { unit in
                        ChipButton(title: unit.label, isSelected: store.profile.unit == unit) {
                            Haptics.select()
                            withAnimation(.spring) { store.profile.unit = unit }
                        }
                    }
                }
            }
            Rectangle().fill(theme.line).frame(height: 1.5)
            HStack {
                SettingsLabel(icon: store.profile.activity.symbol, tint: store.profile.activity.tint, title: "Activity")
                Spacer()
                Menu {
                    Picker("Activity", selection: binding(\.activity)) {
                        ForEach(ActivityLevel.allCases) { level in
                            Label(level.title, systemImage: level.symbol).tag(level)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(store.profile.activity.title)
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 11, weight: .bold))
                    }
                    .font(.display(16, .medium))
                    .foregroundStyle(theme.ink)
                }
            }
        }
        .dewyCard()
    }

    // MARK: Data

    private var dataCard: some View {
        VStack(spacing: 0) {
            dataRow(icon: "arrow.counterclockwise", title: "Clear today's log", tint: Palette.sky) {
                confirmClear = true
            }
            Rectangle().fill(theme.line).frame(height: 1.5).padding(.vertical, 8)
            dataRow(icon: "arrow.clockwise", title: "Restore purchases", tint: Palette.grape) {
                Task { await purchases.restore() }
            }
            Rectangle().fill(theme.line).frame(height: 1.5).padding(.vertical, 8)
            dataRow(icon: "trash.fill", title: "Erase everything", tint: Palette.berry) {
                confirmErase = true
            }
        }
        .dewyCard()
    }

    private func dataRow(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconTile(systemImage: icon, color: tint, size: 36)
                Text(title)
                    .font(.display(17, .medium))
                    .foregroundStyle(tint == Palette.berry ? Palette.berry : theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(theme.inkSoft.opacity(0.6))
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            MascotView(progress: 0.6, mood: .happy, size: 56, backdrop: .light, animated: false, showsShadow: false)
            Text("Made with love for tiny sips")
                .font(.display(15, .medium))
                .foregroundStyle(theme.inkSoft)
            Text("Dewy 2.0")
                .font(.dewy(12, .bold))
                .foregroundStyle(theme.inkSoft.opacity(0.7))
        }
        .padding(.top, 8)
    }
}

// MARK: - Pieces

struct SettingsLabel: View {
    @Environment(\.dewyTheme) private var theme
    var icon: String
    var tint: Color
    var title: String
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemImage: icon, color: tint, size: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.display(17))
                    .foregroundStyle(theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.dewy(12.5, .semibold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
        }
    }
}

/// A tiny postcard of a world: its sky, its water and a little Dewy.
struct WorldSwatch: View {
    @Environment(\.dewyTheme) private var current
    var world: AppTheme
    var isSelected: Bool
    var isLocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                world.skyGradient
                RadialGradient(colors: [world.sunGlow.opacity(0.9), world.sunGlow.opacity(0)], center: UnitPoint(x: 0.8, y: 0.15), startRadius: 0, endRadius: 50)
                VStack(spacing: 0) {
                    Rectangle().fill(world.seaGlint).frame(height: 3)
                    world.seaGradient
                }
                .frame(height: 34)
                DewyShape()
                    .fill(Color.white)
                    .frame(width: 26, height: 33)
                    .overlay {
                        DewyShape()
                            .fill(world.water)
                            .mask(alignment: .bottom) { Rectangle().frame(height: 18) }
                    }
                    .padding(.bottom, 16)
            }
            .frame(width: 72, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(isSelected ? current.ink : Color.clear, lineWidth: 3)
                    .padding(-4)
            }
            .overlay(alignment: .topTrailing) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Palette.ink.opacity(0.75), in: Circle())
                        .padding(5)
                }
            }
            .shadow(color: world.sky[0].opacity(0.3), radius: 8, x: 0, y: 5)
            Text(world.displayName)
                .font(.display(14, isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? current.ink : current.inkSoft)
        }
        .padding(.top, 4)
    }
}

// MARK: - Time binding

extension Binding where Value == Int {
    /// Bridges "minutes after midnight" to a `Date` for `DatePicker`.
    var timeOfDay: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(bySettingHour: wrappedValue / 60 % 24, minute: wrappedValue % 60, second: 0, of: .now) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }
}
