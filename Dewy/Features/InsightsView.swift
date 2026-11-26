import SwiftUI
import Charts

/// Insights: a cream canvas with one hero card (this week at a glance), then clean clay cards
/// for the chart, the streak calendar, the drink mix, the sip rhythm, caffeine and Apple Health.
struct InsightsView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(AppRouter.self) private var router
    @Environment(\.dewyTheme) private var theme

    @State private var range: InsightsRange = .week
    @State private var appeared = false
    @State private var selectedDate: Date?
    @Namespace private var rangeNamespace

    private static let milestones = [3, 7, 14, 30, 60, 100, 180, 365]

    private var isPremium: Bool { store.isPremium || purchases.isPremium }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                    .floatIn(appeared, index: 0)
                heroCard
                    .floatIn(appeared, index: 1)
                trendSection
                    .floatIn(appeared, index: 2)
                statsSection
                    .floatIn(appeared, index: 3)
                calendarSection
                    .floatIn(appeared, index: 4)
                breakdownSection
                    .floatIn(appeared, index: 5)
                rhythmSection
                    .floatIn(appeared, index: 6)
                caffeineSection
                    .floatIn(appeared, index: 7)
                healthCard
                    .floatIn(appeared, index: 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background(theme.canvas.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05)) {
                appeared = true
            }
        }
        .onChange(of: range) {
            selectedDate = nil
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: "Your flow", color: theme.inkSoft, size: 12)
                Text("Insights")
                    .font(.display(34))
                    .foregroundStyle(theme.ink)
            }
            Spacer(minLength: 8)
            totalPill
        }
    }

    private var totalPill: some View {
        HStack(spacing: 6) {
            DewyShape()
                .fill(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .top, endPoint: .bottom))
                .frame(width: 14, height: 18)
            Text(store.formatLiters(store.totalEffective))
                .font(.display(16))
                .foregroundStyle(theme.ink)
                .monospacedDigit()
        }
        .padding(.leading, 11)
        .padding(.trailing, 14)
        .frame(height: 36)
        .background {
            ClaySurface(shape: Capsule(), fill: .white, glow: Palette.aqua, elevation: 0.55)
        }
        .padding(.bottom, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(store.formatLiters(store.totalEffective)) sipped in total")
    }

    // MARK: Hero

    private var nextMilestone: Int {
        Self.milestones.first { $0 > store.currentStreak } ?? (store.currentStreak + 30)
    }

    private var heroCard: some View {
        let average = store.average(days: 7)
        let hitRate = store.hitRate(days: 7)
        let hitPercent = Int((hitRate * 100).rounded())
        let ratio = average / store.goal
        let ratioPercent = Int((ratio * 100).rounded())
        let current = store.currentStreak
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    CapsLabel(text: "This week", color: theme.inkSoft, size: 11)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(store.format(average, withUnit: false))
                            .font(.display(44))
                            .foregroundStyle(theme.ink)
                            .contentTransition(.numericText(value: store.displayValue(average)))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(store.profile.unit.label)
                            .font(.display(18))
                            .foregroundStyle(theme.inkSoft)
                    }
                    Text("a day on average · \(ratioPercent)% of goal")
                        .font(.dewy(14, .semibold))
                        .foregroundStyle(theme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                heroMascot(ratio: ratio, sparkles: hitRate >= 0.7)
            }

            HStack(spacing: 10) {
                InsightsHeroStat(
                    glyph: .star,
                    value: "\(hitPercent)%",
                    label: "Goal hit rate",
                    tint: Palette.aquaSoft
                )
                InsightsHeroStat(
                    glyph: .flame,
                    value: store.bestStreak == 1 ? "1 day" : "\(store.bestStreak) days",
                    label: current > 0 ? "Best · now \(current)" : "Best streak",
                    tint: Palette.butterSoft
                )
            }

            InsightsWeekDroplets(days: store.weekProgress())

            if current > 0 {
                HStack(spacing: 6) {
                    ClayIcon(glyph: .flame, size: 16)
                    Text("\(nextMilestone - current) more goal days to a \(nextMilestone)-day streak")
                        .font(.dewy(13, .bold))
                        .foregroundStyle(theme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .dewyCard(padding: 20)
    }

    private func heroMascot(ratio: Double, sparkles: Bool) -> some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Palette.aquaSoft, Palette.aquaSoft.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 56
                    )
                )
                .frame(width: 112, height: 30)
                .offset(y: 6)
            MascotView(
                progress: max(ratio, 0.12),
                mood: DewyMood(progress: ratio),
                size: 92,
                outfits: store.outfits,
                sparkles: sparkles,
                backdrop: .light,
                animated: false
            )
        }
        .frame(width: 112)
    }

    // MARK: Range + chart

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            rangePicker
            chartCard
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 4) {
            ForEach(InsightsRange.allCases) { option in
                rangeButton(option)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(theme.well)
                .overlay(Capsule().stroke(Color(hex: 0xEADBCD).opacity(0.7), lineWidth: 1))
        }
    }

    private func rangeButton(_ option: InsightsRange) -> some View {
        let locked = option.isPremium && !isPremium
        let isSelected = option == range
        return Button {
            select(option)
        } label: {
            HStack(spacing: 5) {
                Text(option.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .heavy))
                }
            }
            .font(.display(15))
            .foregroundStyle(isSelected ? Color.white : theme.inkSoft)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background {
                if isSelected {
                    rangeThumb
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(SquishyButtonStyle(scale: 0.95))
        .accessibilityLabel(locked ? "\(option.title), Dewy+" : option.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var rangeThumb: some View {
        Capsule()
            .fill(LinearGradient(colors: [Palette.aquaLight, theme.accent], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(height: 10)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
            }
            .shadow(color: theme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
            .matchedGeometryEffect(id: "range-thumb", in: rangeNamespace)
    }

    private func select(_ option: InsightsRange) {
        if option.isPremium && !isPremium {
            Haptics.warning()
            router.showPaywall = true
            return
        }
        guard option != range else { return }
        Haptics.select()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            range = option
        }
    }

    /// Bars for the current range: one per day, or one per month (daily average) for the year.
    private var bars: [InsightsBar] {
        let goal = store.goal
        switch range {
        case .week, .month:
            let totals = store.dailyTotals(days: range.days)
            let lastIndex = totals.count - 1
            return totals.enumerated().map { index, day in
                InsightsBar(date: day.date, amount: day.amount, met: day.amount >= goal, isCurrent: index == lastIndex)
            }
        case .year:
            return monthlyBars
        }
    }

    private var monthlyBars: [InsightsBar] {
        let calendar = Calendar.current
        let totals = store.totalsByDay()
        let goal = store.goal
        let today = calendar.startOfDay(for: .now)
        guard let thisMonth = calendar.dateInterval(of: .month, for: today)?.start else { return [] }
        var result: [InsightsBar] = []
        for offset in (0..<12).reversed() {
            guard let start = calendar.date(byAdding: .month, value: -offset, to: thisMonth),
                  let end = calendar.date(byAdding: .month, value: 1, to: start) else { continue }
            let values: [Double] = totals
                .filter { $0.key >= start && $0.key < end && $0.value > 0 }
                .map { $0.value }
            let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
            result.append(InsightsBar(date: start, amount: average, met: average >= goal, isCurrent: offset == 0))
        }
        return result
    }

    private func selectedBar(in data: [InsightsBar]) -> InsightsBar? {
        guard let selectedDate else { return nil }
        let calendar = Calendar.current
        let component: Calendar.Component = range == .year ? .month : .day
        return data.first { calendar.isDate($0.date, equalTo: selectedDate, toGranularity: component) }
    }

    private var chartCard: some View {
        let data = bars
        let goal = store.goal
        let highest = data.map(\.amount).max() ?? 0
        let maxValue = max(goal * 1.25, highest * 1.08)
        let selected = selectedBar(in: data)
        let average = store.average(days: range.days)
        return VStack(alignment: .leading, spacing: 16) {
            chartHeader(selected: selected, average: average, goal: goal)
            InsightsBarChart(
                bars: data,
                goal: goal,
                maxValue: maxValue,
                range: range,
                appeared: appeared,
                selectedDate: $selectedDate
            )
            .frame(height: 190)
            chartLegend
        }
        .dewyCard(padding: 20)
    }

    private func chartHeader(selected: InsightsBar?, average: Double, goal: Double) -> some View {
        let value = selected?.amount ?? average
        let label = selected.map { selectedLabel(for: $0.date) } ?? "Daily average"
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: label, color: theme.inkSoft, size: 11)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(store.format(value, withUnit: false))
                        .font(.display(34))
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: store.displayValue(value)))
                    Text(store.profile.unit.label)
                        .font(.display(16))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                Capsule()
                    .fill(Palette.coral)
                    .frame(width: 12, height: 3)
                Text("Goal \(store.format(goal))")
                    .font(.display(13))
                    .foregroundStyle(Palette.coralDeep)
                    .lineLimit(1)
            }
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(Palette.coralSoft, in: Capsule())
        }
    }

    private func selectedLabel(for date: Date) -> String {
        if range == .year {
            return date.formatted(.dateTime.month(.wide)) + " · avg"
        }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private var chartLegend: some View {
        HStack(spacing: 14) {
            legendItem(color: Palette.aqua, title: "Goal met")
            legendItem(color: Palette.lilac, title: "Under goal")
            legendItem(color: Palette.peach, title: range == .year ? "This month" : "Today")
            Spacer(minLength: 0)
        }
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.dewy(12, .bold))
                .foregroundStyle(theme.inkSoft)
                .lineLimit(1)
        }
    }

    // MARK: Stats

    private var statsSection: some View {
        let days = range.days
        let calendar = Calendar.current
        let totals = store.dailyTotals(days: days)
        let shares = store.breakdown(days: days)
        let favorite = shares.first?.kind
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: .now)) ?? .now
        let logged = store.entries.filter { $0.date >= start }.count
        let sipped = totals.reduce(0) { $0 + $1.amount }
        let goalDays = totals.filter { $0.amount >= store.goal }.count
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "At a glance", trailing: range.caption)
            LazyVGrid(columns: columns, spacing: 12) {
                InsightsStatTile(value: store.formatLiters(sipped), label: "Sipped") {
                    IconTile(systemImage: "drop.fill", color: Palette.aqua, size: 36)
                }
                InsightsStatTile(value: "\(goalDays)/\(totals.count)", label: "Goal days") {
                    ClayIcon(glyph: .star, size: 34)
                }
                InsightsStatTile(value: "\(logged)", label: "Drinks logged") {
                    ClayIcon(glyph: .cup, size: 34)
                }
                InsightsStatTile(value: favorite?.name ?? "None yet", label: "Favorite drink") {
                    DrinkIcon(kind: favorite ?? .water, size: 38)
                }
            }
        }
    }

    // MARK: Calendar

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Streak calendar", trailing: "Best \(store.bestStreak)")
            calendarCard
        }
    }

    private var calendarCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let monthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
        let dayCount = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let leading = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        let totals = store.totalsByDay()
        let goal = store.goal

        var cells: [InsightsCalendarCell] = Array(repeating: InsightsCalendarCell(), count: leading)
        var run = -1
        var previousMet = false
        var goalDays = 0
        for day in 1...dayCount {
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
            let amount = totals[date] ?? 0
            let isFuture = date > today
            let met = !isFuture && amount >= goal
            if met {
                goalDays += 1
                if !previousMet { run += 1 }
            }
            previousMet = met
            cells.append(InsightsCalendarCell(day: day, met: met, isFuture: isFuture, isToday: date == today, run: met ? run : nil, partial: amount / goal))
        }
        while cells.count % 7 != 0 { cells.append(InsightsCalendarCell()) }
        let rows = cells.count / 7

        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let weekdays = Array(symbols[first...] + symbols[..<first])

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(today.formatted(.dateTime.month(.wide)))
                    .font(.display(24))
                    .foregroundStyle(theme.ink)
                Spacer()
                HStack(spacing: 4) {
                    ClayIcon(glyph: .flame, size: 18)
                    Text(goalDays == 1 ? "1 goal day" : "\(goalDays) goal days")
                        .font(.display(14))
                        .foregroundStyle(Palette.butterDeep.blended(with: Ink.primary, by: 0.35))
                }
                .padding(.leading, 8)
                .padding(.trailing, 12)
                .frame(height: 30)
                .background(Palette.butterSoft, in: Capsule())
            }
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.display(13))
                        .foregroundStyle(theme.inkSoft)
                        .frame(maxWidth: .infinity)
                }
            }
            VStack(spacing: 8) {
                ForEach(0..<rows, id: \.self) { row in
                    InsightsCalendarWeekRow(cells: Array(cells[(row * 7)..<(row * 7 + 7)]))
                }
            }
        }
        .dewyCard(padding: 20)
    }

    // MARK: Breakdown

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "What you drink", trailing: range.caption)
            breakdownCard
        }
    }

    @ViewBuilder
    private var breakdownCard: some View {
        let shares = store.breakdown(days: range.days)
        if shares.isEmpty {
            HStack(spacing: 14) {
                DrinkBadge(kind: .water, size: 56)
                Text("Log a few drinks and your mix shows up here.")
                    .font(.dewy(15, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .dewyCard(padding: 20)
        } else {
            HStack(spacing: 18) {
                breakdownDonut(shares: shares)
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(shares.prefix(5)) { share in
                        breakdownRow(share)
                    }
                }
            }
            .dewyCard(padding: 20)
        }
    }

    private func breakdownDonut(shares: [KindShare]) -> some View {
        let top = shares.first
        let topPercent: Int = Int(((top?.share ?? 0) * 100).rounded())
        return ZStack {
            Circle()
                .stroke(theme.well, lineWidth: 26)
                .padding(13)
            Chart(shares) { share in
                SectorMark(
                    angle: .value("Amount", appeared ? share.amount : 0.0001),
                    innerRadius: .ratio(0.62),
                    angularInset: 2.5
                )
                .cornerRadius(8)
                .foregroundStyle(share.kind.color)
            }
            .chartLegend(.hidden)
            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: appeared)
            VStack(spacing: 0) {
                DrinkIcon(kind: top?.kind ?? .water, size: 44)
                Text("\(topPercent)%")
                    .font(.display(17))
                    .foregroundStyle(theme.ink)
            }
        }
        .frame(width: 136, height: 136)
    }

    private func breakdownRow(_ share: KindShare) -> some View {
        HStack(spacing: 8) {
            DrinkBadge(kind: share.kind, size: 28)
            Text(share.kind.name)
                .font(.display(15))
                .foregroundStyle(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            Text("\(Int((share.share * 100).rounded()))%")
                .font(.display(14))
                .foregroundStyle(theme.inkSoft)
                .monospacedDigit()
        }
    }

    // MARK: Rhythm

    private var rhythmSection: some View {
        let rhythm = store.hourlyRhythm(days: range.days)
        let peak = rhythm.max { $0.value < $1.value }?.key ?? 9
        let peakLabel = Calendar.current.date(bySettingHour: peak, minute: 0, second: 0, of: .now)?
            .formatted(date: .omitted, time: .shortened) ?? ""
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Sip rhythm", trailing: rhythm.isEmpty ? nil : "Peak · \(peakLabel)")
            InsightsRhythmChart(rhythm: rhythm, peak: peak, appeared: appeared)
                .frame(height: 104)
                .dewyCard(padding: 20)
        }
    }

    // MARK: Caffeine

    private var caffeineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Caffeine", trailing: nil)
            caffeineCard
        }
    }

    private var caffeineCard: some View {
        let today = store.todayCaffeine
        let limit = max(store.profile.caffeineLimit, 1)
        let average = store.averageCaffeine(days: range.days)
        let over = today >= limit
        let fillColors: [Color] = over ? [Palette.coral.blended(with: .white, by: 0.25), Palette.coral] : [Palette.peach, DrinkKind.coffee.color]
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                DrinkBadge(kind: .coffee, size: 46)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Today")
                        .font(.display(19))
                        .foregroundStyle(theme.ink)
                    Text("Avg \(Int(average.rounded())) mg a day")
                        .font(.dewy(13, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(today.rounded()))")
                        .font(.display(30))
                        .foregroundStyle(theme.ink)
                    Text("mg")
                        .font(.display(15))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(theme.well)
                        Capsule()
                            .fill(LinearGradient(colors: fillColors, startPoint: .leading, endPoint: .trailing))
                            .overlay(alignment: .top) {
                                Capsule()
                                    .fill(Color.white.opacity(0.35))
                                    .frame(height: 4)
                                    .padding(.horizontal, 6)
                                    .padding(.top, 2)
                            }
                            .frame(width: max(14, proxy.size.width * CGFloat(min(today / limit, 1))))
                            .scaleEffect(x: appeared ? 1 : 0, anchor: .leading)
                    }
                }
                .frame(height: 14)
                HStack {
                    Text(over ? "Over today's budget, maybe water next?" : "\(Int((limit - today).rounded())) mg left in today's budget")
                    Spacer()
                    Text("\(Int(limit)) mg")
                }
                .font(.dewy(12, .bold))
                .foregroundStyle(theme.inkSoft)
            }
        }
        .dewyCard(padding: 20)
    }

    // MARK: Apple Health

    private var healthCard: some View {
        let isOn = store.profile.healthSyncOn
        return HStack(alignment: .center, spacing: 14) {
            ClayIcon(glyph: .heart, size: 34)
                .frame(width: 56, height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.pinkSoft.blended(with: .white, by: 0.3), Palette.pinkSoft], startPoint: .top, endPoint: .bottom))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center), lineWidth: 1.2)
                        }
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(isOn ? "Syncing with Apple Health" : "Apple Health")
                    .font(.display(18))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(isOn ? "Every sip lands in the Health app too." : "Send every sip to Health and keep your water in one place.")
                    .font(.dewy(13, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)
                    .background(Palette.mint, in: Circle())
                    .accessibilityLabel("On")
            } else {
                ChipButton(title: "Turn on", isSelected: true) {
                    Haptics.tap()
                    router.showMe = true
                }
                .fixedSize()
            }
        }
        .dewyCard(padding: 18)
    }
}

// MARK: - Range

private enum InsightsRange: String, CaseIterable, Identifiable {
    case week, month, year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "7 days"
        case .month: return "30 days"
        case .year: return "Year"
        }
    }

    var caption: String {
        switch self {
        case .week: return "Last 7 days"
        case .month: return "Last 30 days"
        case .year: return "Last 12 months"
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }

    /// 30 days and the year are part of Dewy+.
    var isPremium: Bool { self != .week }
}

// MARK: - Bar chart

private struct InsightsBar: Identifiable {
    var date: Date
    var amount: Double
    var met: Bool
    /// Today (or this month, for the year view): still in progress.
    var isCurrent: Bool
    var id: Date { date }
}

/// Pastel rounded bars, aqua when the goal was met, lilac when not, peach for today,
/// with a dashed coral goal line. Drag across it to read a single day.
private struct InsightsBarChart: View {
    @Environment(\.dewyTheme) private var theme
    var bars: [InsightsBar]
    var goal: Double
    var maxValue: Double
    var range: InsightsRange
    var appeared: Bool
    @Binding var selectedDate: Date?

    private var unit: Calendar.Component { range == .year ? .month : .day }
    private var radius: CGFloat { range == .month ? 4 : 9 }
    private var barWidth: MarkDimension { .ratio(range == .month ? 0.7 : 0.58) }

    var body: some View {
        Chart {
            ForEach(bars) { bar in
                BarMark(
                    x: .value("Date", bar.date, unit: unit),
                    y: .value("Amount", appeared ? max(bar.amount, maxValue * 0.02) : 0),
                    width: barWidth
                )
                .cornerRadius(radius, style: .continuous)
                .foregroundStyle(fill(for: bar))
                .opacity(isDimmed(bar) ? 0.4 : 1)
            }
            RuleMark(y: .value("Goal", goal))
                .foregroundStyle(Palette.coral)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6]))
        }
        .chartYScale(domain: 0...maxValue)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: axisValues) { value in
                AxisValueLabel(centered: true) {
                    if let date = value.as(Date.self) {
                        Text(axisLabel(for: date))
                            .font(.display(12))
                            .foregroundStyle(theme.inkSoft)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDate)
        .animation(.spring(response: 0.75, dampingFraction: 0.8), value: appeared)
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: range)
    }

    private var axisValues: AxisMarkValues {
        switch range {
        case .week: return .stride(by: .day)
        case .month: return .stride(by: .day, count: 7)
        case .year: return .stride(by: .month)
        }
    }

    private func axisLabel(for date: Date) -> String {
        switch range {
        case .week: return date.formatted(.dateTime.weekday(.narrow))
        case .month: return date.formatted(.dateTime.day())
        case .year: return date.formatted(.dateTime.month(.narrow))
        }
    }

    private func isDimmed(_ bar: InsightsBar) -> Bool {
        guard let selectedDate else { return false }
        return !Calendar.current.isDate(bar.date, equalTo: selectedDate, toGranularity: unit)
    }

    private func fill(for bar: InsightsBar) -> LinearGradient {
        let colors: [Color]
        if bar.amount <= 0 {
            colors = [theme.well, Color(hex: 0xF1E2D5)]
        } else if bar.met {
            colors = [Palette.aquaLight, Palette.aqua]
        } else if bar.isCurrent {
            colors = [Palette.peach.blended(with: .white, by: 0.3), Palette.peach]
        } else {
            colors = [Palette.lilac.blended(with: .white, by: 0.3), Palette.lilac]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Rhythm chart

private struct InsightsRhythmChart: View {
    @Environment(\.dewyTheme) private var theme
    var rhythm: [Int: Double]
    var peak: Int
    var appeared: Bool

    private let hours = Array(6...23)

    var body: some View {
        Chart {
            ForEach(hours, id: \.self) { hour in
                BarMark(
                    x: .value("Hour", Double(hour)),
                    y: .value("Amount", appeared ? (rhythm[hour] ?? 0) : 0),
                    width: .fixed(10)
                )
                .cornerRadius(5)
                .foregroundStyle(hour == peak ? theme.accent : Palette.aquaLight.opacity(0.45))
            }
        }
        .chartXScale(domain: 5.5...23.5)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: [6.0, 12.0, 18.0, 23.0]) { value in
                AxisValueLabel {
                    if let hour = value.as(Double.self).map({ Int($0) }) {
                        Text(hour == 12 ? "noon" : hour < 12 ? "\(hour)am" : "\(hour - 12)pm")
                            .font(.display(12))
                            .foregroundStyle(theme.inkSoft)
                    }
                }
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: appeared)
    }
}

// MARK: - Hero pieces

/// A soft pastel well with a clay icon and one number.
private struct InsightsHeroStat: View {
    @Environment(\.dewyTheme) private var theme
    var glyph: ClayGlyph
    var value: String
    var label: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            ClayIcon(glyph: glyph, size: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.display(20))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.dewy(12, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(LinearGradient(colors: [.white.opacity(0.9), .clear], startPoint: .top, endPoint: .center), lineWidth: 1.2)
                }
        }
    }
}

/// The last seven days as little Dewy silhouettes, each filled to that day's progress.
private struct InsightsWeekDroplets: View {
    @Environment(\.dewyTheme) private var theme
    var days: [DayTotal]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                dayColumn(day, isToday: index == days.count - 1)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(theme.well, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func dayColumn(_ day: DayTotal, isToday: Bool) -> some View {
        let height: CGFloat = 34
        let fill: CGFloat = height * CGFloat(min(max(day.amount, 0), 1))
        let percent: Int = Int((day.amount * 100).rounded())
        let reached = day.amount >= 1
        return VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                DewyShape()
                    .fill(Color.white)
                Rectangle()
                    .fill(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .top, endPoint: .bottom))
                    .frame(height: fill)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .clipShape(DewyShape())
                DewyShape()
                    .stroke(Color.white.opacity(0.9), lineWidth: 1.2)
                if reached {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color.white)
                        .padding(.bottom, 7)
                }
            }
            .frame(width: 27, height: height)
            .shadow(color: Palette.shadow.opacity(0.18), radius: 3, x: 0, y: 2)
            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                .font(.display(13))
                .foregroundStyle(isToday ? Color.white : theme.inkSoft)
                .frame(width: 24, height: 24)
                .background {
                    if isToday {
                        Circle().fill(theme.accent)
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.date.formatted(.dateTime.weekday(.wide))): \(percent) percent")
    }
}

/// A white clay tile with an icon, a number and a label.
private struct InsightsStatTile<Icon: View>: View {
    @Environment(\.dewyTheme) private var theme
    let value: String
    let label: String
    let icon: Icon

    init(value: String, label: String, @ViewBuilder icon: () -> Icon) {
        self.value = value
        self.label = label
        self.icon = icon()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            icon
                .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.display(24))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(.dewy(13, .semibold))
                    .foregroundStyle(theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dewyCard(padding: 16, radius: 22)
    }
}

// MARK: - Calendar pieces

private struct InsightsCalendarCell {
    var day: Int?
    var met = false
    var isFuture = false
    var isToday = false
    var run: Int?
    var partial: Double = 0
}

private struct InsightsRunSegment: Identifiable {
    var start: Int
    var length: Int
    var run: Int
    var id: Int { start }
}

/// One week of the calendar. Consecutive goal days are joined into a puffy clay capsule.
private struct InsightsCalendarWeekRow: View {
    @Environment(\.dewyTheme) private var theme
    var cells: [InsightsCalendarCell]

    private var segments: [InsightsRunSegment] {
        var result: [InsightsRunSegment] = []
        for (index, cell) in cells.enumerated() {
            guard let run = cell.run else { continue }
            if let last = result.last, last.run == run, last.start + last.length == index {
                result[result.count - 1].length += 1
            } else {
                result.append(InsightsRunSegment(start: index, length: 1, run: run))
            }
        }
        return result
    }

    var body: some View {
        GeometryReader { proxy in
            let cellWidth = proxy.size.width / 7
            let rowHeight = proxy.size.height - 3
            ZStack(alignment: .topLeading) {
                ForEach(segments) { segment in
                    runCapsule(color: Palette.runs[segment.run % Palette.runs.count])
                        .frame(width: CGFloat(segment.length) * cellWidth - 4, height: rowHeight)
                        .offset(x: CGFloat(segment.start) * cellWidth + 2)
                }
                HStack(spacing: 0) {
                    ForEach(0..<cells.count, id: \.self) { index in
                        cellView(cells[index])
                            .frame(width: cellWidth, height: rowHeight)
                    }
                }
            }
        }
        .frame(height: 42)
    }

    private func runCapsule(color: Color) -> some View {
        Capsule()
            .fill(LinearGradient(colors: [color.blended(with: .white, by: 0.22), color], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(height: 8)
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
            }
            .background(Capsule().fill(color.blended(with: Color(hex: 0x6B4A3A), by: 0.18)).offset(y: 3))
    }

    @ViewBuilder
    private func cellView(_ cell: InsightsCalendarCell) -> some View {
        if let day = cell.day {
            if cell.met {
                Text("\(day)")
                    .font(.display(16))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color(hex: 0x6B4A3A).opacity(0.25), radius: 0, x: 0, y: 1)
            } else if cell.isToday {
                Text("\(day)")
                    .font(.display(16))
                    .foregroundStyle(Palette.aquaDeep)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(Palette.aquaSoft)
                            .overlay(Circle().stroke(theme.accent, lineWidth: 2))
                    }
            } else if cell.isFuture {
                Text("\(day)")
                    .font(.display(16, .medium))
                    .foregroundStyle(theme.inkFaint)
            } else {
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.display(16, .medium))
                        .foregroundStyle(theme.inkSoft)
                    Circle()
                        .fill(cell.partial >= 0.5 ? theme.accent : theme.inkFaint)
                        .frame(width: 5, height: 5)
                }
            }
        } else {
            Color.clear
        }
    }
}
