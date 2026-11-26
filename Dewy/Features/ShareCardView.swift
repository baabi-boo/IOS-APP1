import SwiftUI

/// A sheet that previews today's shareable card and hands it to the share sheet.
struct ShareDaySheet: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.dewyTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var rendered: Image?

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    CapsLabel(text: "Show off a little", color: theme.inkSoft, size: 11)
                    Text("Share your day")
                        .font(.display(28))
                        .foregroundStyle(theme.ink)
                }
                Spacer()
                CircleIconButton(systemImage: "xmark") { dismiss() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)

            DayCard(theme: theme, store: store)
                .frame(width: 300, height: 420)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: theme.sky[0].opacity(0.3), radius: 24, x: 0, y: 14)
                .rotationEffect(.degrees(-2))

            Spacer(minLength: 0)

            Group {
                if let rendered {
                    ShareLink(item: rendered, preview: SharePreview("My Dewy day", image: rendered)) {
                        HStack(spacing: 10) {
                            Text("Share")
                            Image(systemName: "square.and.arrow.up").font(.system(size: 18, weight: .heavy))
                        }
                        .font(.display(21))
                        .foregroundStyle(theme.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                    }
                    .buttonStyle(CandyButtonStyle(fill: theme.accent, lip: theme.accentDeep))
                } else {
                    ProgressView().frame(height: 65)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
        .background(theme.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(36)
        .onAppear(perform: render)
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: DayCard(theme: theme, store: store).frame(width: 360, height: 504))
        renderer.scale = 3
        if let image = renderer.uiImage {
            rendered = Image(uiImage: image)
        }
    }
}

/// The card itself: Dewy holding today's drinks, the total, and the day's favorite drink.
struct DayCard: View {
    var theme: AppTheme
    var store: HydrationStore

    private var favorite: DrinkKind? {
        store.kindTotals(on: .now).max { $0.amount < $1.amount }?.kind
    }

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let s = w / 300
            ZStack {
                theme.skyGradient
                VStack(spacing: 0) {
                    Spacer()
                    theme.seaGradient
                        .frame(height: 160 * s)
                        .overlay(alignment: .top) {
                            Rectangle().fill(theme.seaGlint).frame(height: 4 * s)
                        }
                }
                VStack(spacing: 6 * s) {
                    CapsLabel(text: Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()), color: .white.opacity(0.85), size: 10 * s)
                        .padding(.top, 26 * s)
                    (Text("My ") + Text((favorite?.name ?? "Water").lowercased()).foregroundColor(Color(hex: 0xFFE27A)) + Text("\n") + Text(Date.now.formatted(.dateTime.weekday(.wide))))
                        .font(.display(30 * s))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    MascotView(
                        progress: store.todayProgress,
                        mood: store.mood,
                        size: 132 * s,
                        bands: store.todayBands,
                        animated: false
                    )
                    .environment(\.dewyTheme, theme)
                    .padding(.top, 2 * s)
                    HStack(alignment: .firstTextBaseline, spacing: 3 * s) {
                        Text(store.format(store.todayTotal, withUnit: false))
                            .font(.display(44 * s))
                        Text(store.profile.unit.label)
                            .font(.display(18 * s))
                            .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    HStack(spacing: -6 * s) {
                        ForEach(Array(Set(store.todayEntries.map(\.kind))).sorted { $0.rawValue < $1.rawValue }.prefix(6)) { kind in
                            DrinkBadge(kind: kind, size: 32 * s)
                                .overlay(RoundedRectangle(cornerRadius: 12 * s, style: .continuous).stroke(Color.white, lineWidth: 2.5 * s))
                        }
                    }
                    Spacer(minLength: 0)
                    Text("dewy · \(Int((store.todayProgress * 100).rounded()))% of my goal")
                        .font(.display(12 * s, .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.bottom, 14 * s)
                }
            }
        }
    }
}
