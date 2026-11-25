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

    var body: some View {
        let days = range.days
        let totals = store.dailyTotals(days: days)
        let average = store.average(days: days)

        ScrollView {
            VStack(spacing: 18) {
                header.floatIn(appeared, index: 0)
                rangePicker.floatIn(appeared, index: 1)
                chartCard(totals: totals, average: average).floatIn(appeared, index: 2)
                statsGrid(days: days, average: average).floatIn(appeared, index: 3)
                breakdownCard(days: days).floatIn(appeared, index: 4)
                rhythmCard(days: days).floatIn(appeared, index: 5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 24)
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

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR FLOW")
                    .font(.dewy(13, .bold))
                    .tracking(1.2)
                    .foregroundStyle(theme.inkSoft)
                Text("Insights")
                    .font(.dewy(30, .heavy))
                    .foregroundStyle(theme.ink)
            }
            Spacer()
            MascotView(progress: 0.75, mood: .happy, size: 46)
        }
    }

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
                    .font(.dewy(15, .bold))
                    .foregroundStyle(range == option ? Color.white : theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background {
                        if range == option {
                            Capsule()
                                .fill(theme.accentGradient)
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
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
    }

    // MARK: Chart

    private func chartCard(totals: [DayTotal], average: Double) -> some View {
        let goal = store.goal
        let maxValue = max(goal * 1.25, totals.map(\.amount).max() ?? 0)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily average")
                        .font(.dewy(14, .semibold))
                        .foregroundStyle(theme.inkSoft)
                    Text(store.format(average))
                        .font(.dewy(30, .heavy))
                        .foregroundStyle(theme.ink)
                        .contentTransition(.numericText(value: average))
                }
                Spacer()
                Label("Goal \(store.format(goal))", systemImage: "target")
                    .font(.dewy(13, .bold))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.accent.opacity(0.12), in: Capsule())
            }

            Chart {
                ForEach(totals) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Amount", appeared ? day.amount : 0),
                        width: .ratio(range == .week ? 0.55 : 0.7)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: day.amount >= goal ? [theme.waterTop, theme.waterBottom] : [theme.waterTop.opacity(0.5), theme.waterBottom.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(range == .week ? 8 : 4)
                }
                RuleMark(y: .value("Goal", goal))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 5]))
                    .foregroundStyle(theme.accent.opacity(0.7))
            }
            .chartYScale(domain: 0...maxValue)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [2, 4]))
                        .foregroundStyle(theme.inkSoft.opacity(0.3))
                    AxisValueLabel {
                        if let ml = value.as(Double.self) {
                            Text(store.formatLiters(ml))
                                .font(.dewy(10, .semibold))
                                .foregroundStyle(theme.inkSoft)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: range == .week ? 1 : 7)) { value in
                    AxisValueLabel(centered: range == .week) {
                        if let date = value.as(Date.self) {
                            Text(range == .week
                                 ? date.formatted(.dateTime.weekday(.narrow))
                                 : date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.dewy(range == .week ? 12 : 11, .bold))
                                .foregroundStyle(theme.inkSoft)
                        }
                    }
                }
            }
            .frame(height: 190)
            .animation(.spring(response: 0.8, dampingFraction: 0.75), value: range)
        }
        .glassCard()
    }

    // MARK: Stats

    private func statsGrid(days: Int, average: Double) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            StatTile(icon: "flame.fill", tint: Color(hex: 0xFF8A5B), value: "\(store.currentStreak)", unit: "days", label: "Current streak")
            StatTile(icon: "trophy.fill", tint: Color(hex: 0xFFB531), value: "\(store.bestStreak)", unit: "days", label: "Best streak")
            StatTile(icon: "target", tint: theme.accent, value: "\(Int((store.hitRate(days: days) * 100).rounded()))", unit: "%", label: "Goal hit rate")
            StatTile(icon: "drop.fill", tint: Color(hex: 0x4FB8FF), value: store.formatLiters(store.totalEffective), unit: "", label: "Total sipped")
        }
    }

    // MARK: Breakdown

    private func breakdownCard(days: Int) -> some View {
        let shares = store.breakdown(days: days)
        let top = shares.first
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "What you drink")
            HStack(spacing: 18) {
                ZStack {
                    Chart(shares) { share in
                        SectorMark(
                            angle: .value("Amount", appeared ? share.amount : 0.0001),
                            innerRadius: .ratio(0.64),
                            angularInset: 2.5
                        )
                        .cornerRadius(6)
                        .foregroundStyle(share.kind.color)
                    }
                    .chartLegend(.hidden)
                    VStack(spacing: 0) {
                        Text(top?.kind.emoji ?? "💧")
                            .font(.system(size: 26))
                        Text("\(Int(((top?.share ?? 0) * 100).rounded()))%")
                            .font(.dewy(15, .heavy))
                            .foregroundStyle(theme.ink)
                    }
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 9) {
                    ForEach(shares.prefix(5)) { share in
                        HStack(spacing: 8) {
                            Circle().fill(share.kind.color).frame(width: 10, height: 10)
                            Text(share.kind.name)
                                .font(.dewy(14, .semibold))
                                .foregroundStyle(theme.ink)
                            Spacer(minLength: 4)
                            Text("\(Int((share.share * 100).rounded()))%")
                                .font(.dewy(14, .bold))
                                .foregroundStyle(theme.inkSoft)
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: Rhythm

    private func rhythmCard(days: Int) -> some View {
        let rhythm = store.hourlyRhythm(days: days)
        let hours = Array(6...23)
        let peak = rhythm.max { $0.value < $1.value }?.key ?? 9
        let peakLabel = Calendar.current.date(bySettingHour: peak, minute: 0, second: 0, of: .now)?
            .formatted(date: .omitted, time: .shortened) ?? ""
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Sip rhythm", trailing: "Peak · \(peakLabel)")
            Chart {
                ForEach(hours, id: \.self) { hour in
                    BarMark(
                        x: .value("Hour", Double(hour)),
                        y: .value("Amount", appeared ? (rhythm[hour] ?? 0) : 0),
                        width: .fixed(9)
                    )
                    .cornerRadius(4.5)
                    .foregroundStyle(hour == peak ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.inkSoft.opacity(0.22)))
                }
            }
            .chartXScale(domain: 5.5...23.5)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: [6.0, 12.0, 18.0, 23.0]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Double.self).map({ Int($0) }) {
                            Text(hour == 12 ? "noon" : hour < 12 ? "\(hour)am" : "\(hour - 12)pm")
                                .font(.dewy(11, .bold))
                                .foregroundStyle(theme.inkSoft)
                        }
                    }
                }
            }
            .frame(height: 90)
        }
        .glassCard()
    }
}

struct StatTile: View {
    @Environment(\.dewyTheme) private var theme
    var icon: String
    var tint: Color
    var value: String
    var unit: String
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.dewy(26, .heavy))
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.dewy(14, .bold))
                        .foregroundStyle(theme.inkSoft)
                }
            }
            Text(label)
                .font(.dewy(13, .semibold))
                .foregroundStyle(theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 16, radius: 24)
    }
}
