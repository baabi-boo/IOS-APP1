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

        ZStack {
            HeroBackdrop()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 22)
                        .floatIn(appeared, index: 0)
                    streakHero
                        .floatIn(appeared, index: 1)
                    VStack(spacing: 18) {
                        calendarCard.floatIn(appeared, index: 2)
                        rangePicker.floatIn(appeared, index: 3)
                        chartCard(days: days, average: average).floatIn(appeared, index: 4)
                        statsGrid(days: days).floatIn(appeared, index: 5)
                        breakdownCard(days: days).floatIn(appeared, index: 6)
                        rhythmCard(days: days).floatIn(appeared, index: 7)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .padding(.bottom, 30)
                    .canvasSheet()
                }
                .padding(.top, 6)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                CapsLabel(text: "Your flow", color: theme.onHeroSoft, size: 12)
                Text("Insights")
                    .font(.dewy(32, .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .foregroundStyle(theme.water)
                Text(store.formatLiters(store.totalEffective))
                    .foregroundStyle(Color(hex: 0x1E2340))
            }
            .font(.dewy(16, .black))
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Color.white, in: Capsule())
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
        }
    }

    // MARK: Streak hero

    private var streakHero: some View {
        let streak = store.currentStreak
        let next = Self.milestones.first { $0 > streak } ?? (streak + 30)
        let previous = Self.milestones.last { $0 <= streak } ?? 0
        let ring = Double(streak - previous) / Double(max(next - previous, 1))

        return VStack(spacing: 20) {
            ZStack {
                HaloRings(diameter: 290)
                Circle()
                    .stroke(Color.white.opacity(0.22), lineWidth: 18)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: appeared ? max(ring, 0.02) : 0)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3), value: appeared)
                Circle()
                    .fill(theme.heroDeep)
                    .frame(width: 156, height: 156)
                    .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 8)
                VStack(spacing: -4) {
                    Text("\(streak)")
                        .font(.dewy(72, .black))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: Double(streak)))
                    CapsLabel(text: "day streak", color: theme.onHeroSoft, size: 12)
                }
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Palette.flame)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: Circle())
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .offset(y: -100)
            }
            .frame(height: 250)

            HStack(spacing: 10) {
                heroStat(value: "\(store.bestStreak)", label: "Best streak")
                heroStat(value: "\(store.goalMetDays)", label: "Goal days")
                heroStat(value: "\(next - streak)", label: "To \(next) days")
            }
            .padding(.horizontal, 22)
        }
        .padding(.top, 14)
        .padding(.bottom, 30)
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.dewy(24, .black))
                .foregroundStyle(.white)
            CapsLabel(text: label, color: theme.onHeroSoft, size: 10)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                    .font(.dewy(24, .black))
                    .foregroundStyle(theme.ink)
                Spacer()
                Text("\(goalDays) goal days")
                    .font(.dewy(13, .heavy))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(theme.accent.opacity(0.12), in: Capsule())
            }
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.dewy(12, .heavy))
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
                        Text(option.title.uppercased())
                            .tracking(0.6)
                        if locked {
                            Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
                        }
                    }
                    .font(.dewy(14, .black))
                    .foregroundStyle(range == option ? Color.white : theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background {
                        if range == option {
                            Capsule()
                                .fill(theme.accent)
                                .shadow(color: theme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
                                .matchedGeometryEffect(id: "range", in: namespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(SquishyButtonStyle(scale: 0.95))
            }
        }
        .padding(5)
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
                VStack(alignment: .leading, spacing: 2) {
                    CapsLabel(text: "Daily average", color: theme.inkSoft, size: 12)
                    Text(store.format(average))
                        .font(.dewy(30, .black))
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: average))
                }
                Spacer()
                Label("Goal \(store.format(goal))", systemImage: "target")
                    .font(.dewy(13, .heavy))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.accent.opacity(0.12), in: Capsule())
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
                                radius: isWeek ? 10 : 4
                            )
                            .scaleEffect(x: 1, y: appeared ? 1 : 0.02, anchor: .bottom)
                            .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(Double(index) * 0.02), value: appeared)
                        }
                    }
                    .frame(height: height, alignment: .bottom)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: goalY))
                    }
                    .stroke(theme.ink.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 5]))
                }
            }
            .frame(height: 170)
            .animation(.spring(response: 0.8, dampingFraction: 0.75), value: range)

            HStack(spacing: spacing) {
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    let showLabel = isWeek || index % 7 == 0
                    Text(showLabel ? (isWeek ? date.formatted(.dateTime.weekday(.narrow)) : date.formatted(.dateTime.day())) : " ")
                        .font(.dewy(12, .heavy))
                        .foregroundStyle(index == dates.count - 1 ? theme.accent : theme.inkSoft)
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
            StatTile(icon: "target", color: Color(hex: 0x1FA463), value: "\(Int((store.hitRate(days: days) * 100).rounded()))", unit: "%", label: "Goal hit rate")
            StatTile(icon: "drop.fill", color: Color(hex: 0x2E8BFF), value: store.formatLiters(sipped), unit: "", label: "Sipped in \(days) days")
            StatTile(icon: "cup.and.saucer.fill", color: Color(hex: 0xFF7A45), value: "\(logged)", unit: "", label: "Drinks logged")
            StatTile(icon: "heart.fill", color: Color(hex: 0x8C6BFF), value: favorite.name, unit: "", label: "Favorite drink")
        }
    }

    // MARK: Breakdown

    private func breakdownCard(days: Int) -> some View {
        let shares = store.breakdown(days: days)
        let top = shares.first
        return VStack(alignment: .leading, spacing: 16) {
            CapsLabel(text: "What you drink", color: theme.inkSoft, size: 12)
            HStack(spacing: 18) {
                ZStack {
                    Chart(shares) { share in
                        SectorMark(
                            angle: .value("Amount", appeared ? share.amount : 0.0001),
                            innerRadius: .ratio(0.62),
                            angularInset: 2.5
                        )
                        .cornerRadius(6)
                        .foregroundStyle(share.kind.color)
                    }
                    .chartLegend(.hidden)
                    VStack(spacing: 2) {
                        DrinkVessel(kind: top?.kind ?? .water, fill: 0.72, width: 26)
                        Text("\(Int(((top?.share ?? 0) * 100).rounded()))%")
                            .font(.dewy(16, .black))
                            .foregroundStyle(theme.ink)
                    }
                }
                .frame(width: 136, height: 136)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(shares.prefix(5)) { share in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(share.kind.color)
                                .frame(width: 14, height: 14)
                            Text(share.kind.name)
                                .font(.dewy(15, .heavy))
                                .foregroundStyle(theme.ink)
                            Spacer(minLength: 4)
                            Text("\(Int((share.share * 100).rounded()))%")
                                .font(.dewy(14, .heavy))
                                .foregroundStyle(theme.inkSoft)
                        }
                    }
                }
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
            HStack {
                CapsLabel(text: "Sip rhythm", color: theme.inkSoft, size: 12)
                Spacer()
                Text("Peak · \(peakLabel)")
                    .font(.dewy(13, .heavy))
                    .foregroundStyle(theme.accent)
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
                                .font(.dewy(11, .heavy))
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
                    Capsule()
                        .fill(Palette.runs[segment.run % Palette.runs.count])
                        .frame(width: CGFloat(segment.length) * cellWidth - 4, height: proxy.size.height)
                        .offset(x: CGFloat(segment.start) * cellWidth + 2)
                }
                HStack(spacing: 0) {
                    ForEach(0..<cells.count, id: \.self) { index in
                        cellView(cells[index])
                            .frame(width: cellWidth, height: proxy.size.height)
                    }
                }
            }
        }
        .frame(height: 40)
    }

    @ViewBuilder
    private func cellView(_ cell: CalendarCell) -> some View {
        if let day = cell.day {
            if cell.met {
                Text("\(day)")
                    .font(.dewy(15, .black))
                    .foregroundStyle(.white)
            } else if cell.isToday {
                Text("\(day)")
                    .font(.dewy(15, .black))
                    .foregroundStyle(theme.isDark ? Color(hex: 0x1E2340) : .white)
                    .frame(width: 38, height: 38)
                    .background(theme.isDark ? Color.white : Color(hex: 0x1E2340), in: Circle())
            } else if cell.isFuture {
                Text("\(day)")
                    .font(.dewy(15, .bold))
                    .foregroundStyle(theme.inkSoft.opacity(0.45))
            } else {
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.dewy(15, .heavy))
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
    }
}

struct StatTile: View {
    var icon: String
    var color: Color
    var value: String
    var unit: String
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.22), in: Circle())
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.dewy(26, .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.dewy(15, .heavy))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            CapsLabel(text: label, color: Color.white.opacity(0.85), size: 10)
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
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: color.opacity(0.35), radius: 12, x: 0, y: 7)
        }
    }
}
