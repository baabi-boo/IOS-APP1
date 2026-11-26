import SwiftUI
import Charts

struct InsightsView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dewyTheme) private var theme

    enum InsightRange: String, CaseIterable, Identifiable {
        case week, month
        var id: String { rawValue }
        var title: String { self == .week ? "7 days" : "30 days" }
        var days: Int { self == .week ? 7 : 30 }
    }

    @State private var range: InsightRange = .week
    @State private var appeared = false
    @State private var showPaywall = false
    @Namespace private var namespace

    private static let milestones = [3, 7, 14, 30, 60, 100, 180, 365]

    var body: some View {
        let days = range.days
        let average = store.average(days: days)

        ScrollView {
            VStack(spacing: 0) {
                hero
                VStack(spacing: 18) {
                    rangePicker.floatIn(appeared, index: 2)
                    chartCard(days: days, average: average).floatIn(appeared, index: 3)
                    statsGrid(days: days).floatIn(appeared, index: 4)
                    calendarCard.floatIn(appeared, index: 5)
                    breakdownCard(days: days).floatIn(appeared, index: 6)
                    caffeineCard(days: days).floatIn(appeared, index: 7)
                    rhythmCard(days: days).floatIn(appeared, index: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 30)
                .canvasSheet()
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: Hero

    private var nextMilestone: Int {
        Self.milestones.first { $0 > store.currentStreak } ?? (store.currentStreak + 30)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    CapsLabel(text: "Your flow", color: theme.onHeroSoft, size: 12)
                    Text("Insights")
                        .font(.display(34))
                        .foregroundStyle(.white)
                }
                Spacer()
                HStack(spacing: 6) {
                    DewyShape()
                        .fill(theme.water)
                        .frame(width: 15, height: 19)
                    Text(store.formatLiters(store.totalEffective))
                        .font(.display(18))
                        .foregroundStyle(Palette.ink)
                }
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(Color.white, in: Capsule())
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
            }
            .floatIn(appeared, index: 0)

            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 8) {
                        FlameGlyph()
                            .frame(width: 40, height: 46)
                        Text("\(store.currentStreak)")
                            .font(.display(72))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: Double(store.currentStreak)))
                            .shadow(color: theme.sky[0].opacity(0.4), radius: 0, x: 0, y: 3)
                    }
                    Text("day streak")
                        .font(.display(22))
                        .foregroundStyle(.white)
                    Text("Best \(store.bestStreak) · \(nextMilestone - store.currentStreak) to go for \(nextMilestone)")
                        .font(.dewy(14, .bold))
                        .foregroundStyle(theme.onHeroSoft)
                }
                Spacer(minLength: 0)
                MascotView(progress: 1.05, mood: .ecstatic, size: 128, accessory: .flame, liquid: Color(hex: 0xFF8A5C))
                    .padding(.trailing, -6)
            }
            .floatIn(appeared, index: 1)

            WeekDroplets(days: store.weekProgress(), goalLabel: store.format(store.goal))
                .floatIn(appeared, index: 1)
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 30)
        .background(alignment: .top) {
            SkyHeaderBackground(height: 470, sunY: 30)
        }
    }

    // MARK: Range

    private var rangePicker: some View {
        HStack(spacing: 4) {
            ForEach(InsightRange.allCases) { option in
                let locked = option == .month && !purchases.isPremium
                Button {
                    if locked {
                        Haptics.warning()
                        showPaywall = true
                        return
                    }
                    Haptics.select()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { range = option }
                } label: {
                    HStack(spacing: 5) {
                        Text(option.title)
                        if locked {
                            Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
                        }
                    }
                    .font(.display(17))
                    .foregroundStyle(range == option ? theme.onAccent : theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background {
                        if range == option {
                            Capsule()
                                .fill(theme.accent)
                                .background(Capsule().fill(theme.accentDeep).offset(y: 3))
                                .matchedGeometryEffect(id: "range", in: namespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.95))
            }
        }
        .padding(5)
        .padding(.bottom, 3)
        .background(theme.card, in: Capsule())
        .shadow(color: theme.shadow, radius: 12, x: 0, y: 6)
    }

    // MARK: Chart

    private func chartCard(days: Int, average: Double) -> some View {
        let goal = store.goal
        let dates = store.dailyTotals(days: days).map(\.date)
        let stacks = dates.map { store.kindTotals(on: $0) }
        let dayTotals = stacks.map { stack in stack.reduce(0) { $0 + $1.amount } }
        let maxValue = max(goal * 1.2, dayTotals.max() ?? 0)
        let isWeek = days <= 7
        let spacing: CGFloat = isWeek ? 12 : 3

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    CapsLabel(text: "Daily average", color: theme.inkSoft, size: 11)
                    Text(store.format(average))
                        .font(.display(32))
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: average))
                }
                Spacer()
                Text("Goal \(store.format(goal))")
                    .font(.display(14))
                    .foregroundStyle(theme.link)
                    .padding(.horizontal, 11)
                    .frame(height: 30)
                    .background(theme.accentSoft, in: Capsule())
            }

            GeometryReader { proxy in
                let height = proxy.size.height
                let goalY = height - height * CGFloat(goal / maxValue)
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(Array(dates.enumerated()), id: \.offset) { index, _ in
                            StackedBar(
                                segments: stacks[index],
                                maxValue: maxValue,
                                height: height,
                                radius: isWeek ? 12 : 4,
                                reachedGoal: dayTotals[index] >= goal
                            )
                            .scaleEffect(x: 1, y: appeared ? 1 : 0.02, anchor: .bottom)
                            .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(Double(index) * 0.025), value: appeared)
                        }
                    }
                    .frame(height: height, alignment: .bottom)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: goalY))
                    }
                    .stroke(theme.ink.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 6]))
                }
            }
            .frame(height: 170)
            .animation(.spring(response: 0.8, dampingFraction: 0.75), value: range)

            HStack(spacing: spacing) {
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    let showLabel = isWeek || index % 7 == 0
                    Text(showLabel ? (isWeek ? date.formatted(.dateTime.weekday(.narrow)) : date.formatted(.dateTime.day())) : " ")
                        .font(.display(13))
                        .foregroundStyle(index == dates.count - 1 ? theme.link : theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: !isWeek, vertical: false)
                }
            }
        }
        .dewyCard()
    }

    // MARK: Stats

    private func statsGrid(days: Int) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        let shares = store.breakdown(days: days)
        let favorite = shares.first?.kind ?? .water
        let start = Calendar.current.date(byAdding: .day, value: -(days - 1), to: Calendar.current.startOfDay(for: .now)) ?? .now
        let logged = store.entries.filter { $0.date >= start }.count
        let sipped = store.dailyTotals(days: days).reduce(0) { $0 + $1.amount }
        return LazyVGrid(columns: columns, spacing: 12) {
            StatTile(icon: "target", color: Color(hex: 0x22B07D), deep: Color(hex: 0x15875E), value: "\(Int((store.hitRate(days: days) * 100).rounded()))", unit: "%", label: "Goal hit rate")
            StatTile(icon: "drop.fill", color: Color(hex: 0x3AA3FF), deep: Color(hex: 0x1F7FD6), value: store.formatLiters(sipped), unit: "", label: "Sipped in \(days) days")
            StatTile(icon: "mug.fill", color: Color(hex: 0xFF8A4C), deep: Color(hex: 0xDB6630), value: "\(logged)", unit: "", label: "Drinks logged")
            StatTile(icon: "heart.fill", color: Color(hex: 0x8E6CF5), deep: Color(hex: 0x6A48D6), value: favorite.name, unit: "", label: "Favorite drink")
        }
    }

    // MARK: Calendar

    private var calendarCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let monthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
        let dayCount = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let leading = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        let totals = store.totalsByDay()
        let goal = store.goal

        var cells: [CalendarCell] = Array(repeating: CalendarCell(), count: leading)
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
            cells.append(CalendarCell(day: day, met: met, isFuture: isFuture, isToday: date == today, run: met ? run : nil, partial: amount / goal))
        }
        while cells.count % 7 != 0 { cells.append(CalendarCell()) }
        let rows = cells.count / 7

        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let weekdays = Array(symbols[first...] + symbols[..<first])

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(today.formatted(.dateTime.month(.wide)))
                    .font(.display(26))
                    .foregroundStyle(theme.ink)
                Spacer()
                Text("\(goalDays) goal days")
                    .font(.display(14))
                    .foregroundStyle(theme.link)
                    .padding(.horizontal, 11)
                    .frame(height: 30)
                    .background(theme.accentSoft, in: Capsule())
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
                    CalendarWeekRow(cells: Array(cells[(row * 7)..<(row * 7 + 7)]))
                }
            }
        }
        .dewyCard()
    }

    // MARK: Breakdown

    private func breakdownCard(days: Int) -> some View {
        let shares = store.breakdown(days: days)
        let top = shares.first
        return VStack(alignment: .leading, spacing: 14) {
            Text("What you drink")
                .font(.display(21))
                .foregroundStyle(theme.ink)
            HStack(spacing: 18) {
                ZStack {
                    Chart(shares) { share in
                        SectorMark(
                            angle: .value("Amount", appeared ? share.amount : 0.0001),
                            innerRadius: .ratio(0.64),
                            angularInset: 2.5
                        )
                        .cornerRadius(7)
                        .foregroundStyle(share.kind.color)
                    }
                    .chartLegend(.hidden)
                    let topPercent: Int = Int(((top?.share ?? 0) * 100).rounded())
                    VStack(spacing: 0) {
                        DrinkIcon(kind: top?.kind ?? .water, size: 46)
                        Text("\(topPercent)%")
                            .font(.display(17))
                            .foregroundStyle(theme.ink)
                    }
                }
                .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(shares.prefix(5)) { share in
                        HStack(spacing: 8) {
                            DrinkBadge(kind: share.kind, size: 26)
                            Text(share.kind.name)
                                .font(.display(15))
                                .foregroundStyle(theme.ink)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text("\(Int((share.share * 100).rounded()))%")
                                .font(.display(14))
                                .foregroundStyle(theme.inkSoft)
                        }
                    }
                }
            }
        }
        .dewyCard()
    }

    // MARK: Caffeine

    private func caffeineCard(days: Int) -> some View {
        let today = store.todayCaffeine
        let limit = max(store.profile.caffeineLimit, 1)
        let average = store.averageCaffeine(days: days)
        let tint = Color(hex: 0x9C6ADE)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                DrinkBadge(kind: .coffee, size: 46)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Caffeine")
                        .font(.display(21))
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
                            .fill(LinearGradient(colors: [Color(hex: 0xC9A2FF), tint], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(14, proxy.size.width * CGFloat(min(today / limit, 1))))
                            .scaleEffect(x: appeared ? 1 : 0, anchor: .leading)
                    }
                }
                .frame(height: 14)
                HStack {
                    Text(today < limit ? "\(Int((limit - today).rounded())) mg left in today's budget" : "Over today's budget, maybe water next?")
                    Spacer()
                    Text("\(Int(limit)) mg")
                }
                .font(.dewy(12, .bold))
                .foregroundStyle(theme.inkSoft)
            }
        }
        .dewyCard()
    }

    // MARK: Rhythm

    private func rhythmCard(days: Int) -> some View {
        let rhythm = store.hourlyRhythm(days: days)
        let hours = Array(6...23)
        let peak = rhythm.max { $0.value < $1.value }?.key ?? 9
        let peakLabel = Calendar.current.date(bySettingHour: peak, minute: 0, second: 0, of: .now)?
            .formatted(date: .omitted, time: .shortened) ?? ""
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sip rhythm")
                    .font(.display(21))
                    .foregroundStyle(theme.ink)
                Spacer()
                Text("Peak · \(peakLabel)")
                    .font(.display(14))
                    .foregroundStyle(theme.link)
            }
            Chart {
                ForEach(hours, id: \.self) { hour in
                    BarMark(
                        x: .value("Hour", Double(hour)),
                        y: .value("Amount", appeared ? (rhythm[hour] ?? 0) : 0),
                        width: .fixed(10)
                    )
                    .cornerRadius(5)
                    .foregroundStyle(hour == peak ? theme.accent : theme.accent.opacity(0.22))
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
            .frame(height: 96)
        }
        .dewyCard()
    }
}

// MARK: - Week droplets

/// The last seven days as little Dewy silhouettes, each filled to that day's progress.
struct WeekDroplets: View {
    @Environment(\.dewyTheme) private var theme
    var days: [DayTotal]
    var goalLabel: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                dayColumn(day, isToday: index == days.count - 1)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1.5)
        }
    }

    private func dayColumn(_ day: DayTotal, isToday: Bool) -> some View {
        let fill: CGFloat = 40 * CGFloat(min(max(day.amount, 0), 1))
        let percent: Int = Int((day.amount * 100).rounded())
        let reached = day.amount >= 1
        return VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                DewyShape()
                    .fill(Color.white.opacity(0.3))
                Rectangle()
                    .fill(reached ? Color.white : Color.white.opacity(0.85))
                    .frame(height: fill)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .clipShape(DewyShape())
                if reached {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(theme.isDark ? theme.sky[1] : theme.accent)
                        .padding(.bottom, 8)
                }
            }
            .frame(width: 32, height: 40)
            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                .font(.display(14))
                .foregroundStyle(isToday ? Palette.ink : Color.white.opacity(0.9))
                .frame(width: 24, height: 24)
                .background {
                    if isToday { Circle().fill(Color.white) }
                }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.date.formatted(.dateTime.weekday(.wide))): \(percent) percent")
    }
}

// MARK: - Calendar pieces

private struct CalendarCell {
    var day: Int?
    var met = false
    var isFuture = false
    var isToday = false
    var run: Int?
    var partial: Double = 0
}

private struct RunSegment: Identifiable {
    var start: Int
    var length: Int
    var run: Int
    var id: Int { start }
}

/// One week of the calendar. Consecutive goal days are joined into a bold capsule.
private struct CalendarWeekRow: View {
    @Environment(\.dewyTheme) private var theme
    var cells: [CalendarCell]

    private var segments: [RunSegment] {
        var result: [RunSegment] = []
        for (index, cell) in cells.enumerated() {
            guard let run = cell.run else { continue }
            if let last = result.last, last.run == run, last.start + last.length == index {
                result[result.count - 1].length += 1
            } else {
                result.append(RunSegment(start: index, length: 1, run: run))
            }
        }
        return result
    }

    var body: some View {
        GeometryReader { proxy in
            let cellWidth = proxy.size.width / 7
            ZStack(alignment: .topLeading) {
                ForEach(segments) { segment in
                    let color = Palette.runs[segment.run % Palette.runs.count]
                    Capsule()
                        .fill(color)
                        .background(Capsule().fill(color).brightness(-0.12).offset(y: 3))
                        .frame(width: CGFloat(segment.length) * cellWidth - 4, height: proxy.size.height - 3)
                        .offset(x: CGFloat(segment.start) * cellWidth + 2)
                }
                HStack(spacing: 0) {
                    ForEach(0..<cells.count, id: \.self) { index in
                        cellView(cells[index])
                            .frame(width: cellWidth, height: proxy.size.height - 3)
                    }
                }
            }
        }
        .frame(height: 42)
    }

    @ViewBuilder
    private func cellView(_ cell: CalendarCell) -> some View {
        if let day = cell.day {
            if cell.met {
                Text("\(day)")
                    .font(.display(16))
                    .foregroundStyle(.white)
            } else if cell.isToday {
                Text("\(day)")
                    .font(.display(16))
                    .foregroundStyle(theme.isDark ? Palette.ink : .white)
                    .frame(width: 38, height: 38)
                    .background(theme.isDark ? Color.white : Palette.ink, in: Circle())
            } else if cell.isFuture {
                Text("\(day)")
                    .font(.display(16, .medium))
                    .foregroundStyle(theme.inkSoft.opacity(0.45))
            } else {
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.display(16, .medium))
                        .foregroundStyle(theme.inkSoft)
                    Circle()
                        .fill(cell.partial >= 0.5 ? theme.accent : theme.inkSoft.opacity(0.35))
                        .frame(width: 5, height: 5)
                }
            }
        } else {
            Color.clear
        }
    }
}

/// A day's bar, stacked with the colors of the drinks that filled it.
private struct StackedBar: View {
    @Environment(\.dewyTheme) private var theme
    var segments: [KindAmount]
    var maxValue: Double
    var height: CGFloat
    var radius: CGFloat
    var reachedGoal: Bool

    var body: some View {
        let total = segments.reduce(0) { $0 + $1.amount }
        let barHeight = max(6, height * CGFloat(total / max(maxValue, 1)))
        VStack(spacing: 2) {
            if segments.isEmpty {
                Rectangle().fill(theme.well)
            } else {
                ForEach(Array(segments.reversed())) { segment in
                    Rectangle()
                        .fill(segment.kind.color)
                        .frame(height: max(1, (barHeight - CGFloat(segments.count - 1) * 2) * CGFloat(segment.amount / max(total, 1))))
                }
            }
        }
        .frame(height: barHeight)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(alignment: .top) {
            if reachedGoal && radius > 6 {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Palette.sunshine)
                    .offset(y: -16)
            }
        }
    }
}

/// A bold candy tile with one number.
struct StatTile: View {
    var icon: String
    var color: Color
    var deep: Color
    var value: String
    var unit: String
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.24), in: Circle())
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.display(28))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.display(16))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            Text(label)
                .font(.dewy(13, .bold))
                .foregroundStyle(Color.white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(color)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 74, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.14))
                        .rotationEffect(.degrees(-14))
                        .offset(x: 16, y: 18)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.18), .clear], startPoint: .top, endPoint: .center))
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(deep)
                        .offset(y: 5)
                }
        }
        .padding(.bottom, 5)
    }
}
