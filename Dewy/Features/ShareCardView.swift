import SwiftUI

/// A sheet that previews today's shareable card and hands it to the share sheet.
///
/// The card is fully static (every mascot, lily pad and scene uses `animated: false`) so that
/// `ImageRenderer` exports exactly what the preview shows.
struct ShareDaySheet: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.dewyTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var rendered: Image?
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            header
                .padding(.horizontal, 22)
                .padding(.top, 26)

            GeometryReader { proxy in
                let scale = min(
                    1,
                    (proxy.size.width - 40) / ShareDayCard.size.width,
                    (proxy.size.height - 24) / ShareDayCard.size.height
                )
                ShareDayCard(store: store, theme: theme)
                    .scaleEffect(appeared ? scale : scale * 0.9)
                    .rotationEffect(.degrees(appeared ? -2 : 0))
                    .opacity(appeared ? 1 : 0)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }

            shareButton
                .padding(.horizontal, 22)
                .padding(.bottom, 12)
        }
        .background(theme.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(36)
        .onAppear {
            render()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.05)) {
                appeared = true
            }
        }
    }

    private var header: some View {
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
    }

    @ViewBuilder
    private var shareButton: some View {
        if let rendered {
            ShareLink(item: rendered, preview: SharePreview("My Dewy day", image: rendered)) {
                HStack(spacing: 10) {
                    Text("Share")
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .heavy))
                }
                .font(.display(21))
                .foregroundStyle(theme.onAccent)
                .shadow(color: theme.accentDeep.opacity(0.35), radius: 0, x: 0, y: 1)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .contentShape(Capsule())
            }
            .buttonStyle(CandyButtonStyle(fill: theme.accent, lip: theme.accentDeep))
            .shadow(color: theme.accentDeep.opacity(0.3), radius: 16, x: 0, y: 10)
        } else {
            ProgressView()
                .tint(theme.accent)
                .frame(height: 65)
        }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: ShareDayExport(store: store, theme: theme))
        renderer.scale = 3
        renderer.isOpaque = true
        if let image = renderer.uiImage {
            rendered = Image(uiImage: image)
        }
    }
}

// MARK: - Export

/// The card on a cream mat, so its clay shadow survives in the exported image.
private struct ShareDayExport: View {
    var store: HydrationStore
    var theme: AppTheme

    var body: some View {
        ShareDayCard(store: store, theme: theme)
            .padding(28)
            .background(Palette.cream)
    }
}

// MARK: - Card

/// The card itself: a little clay world with Dewy on a lily pad, then today's numbers.
private struct ShareDayCard: View {
    var store: HydrationStore
    var theme: AppTheme

    static let size = CGSize(width: 320, height: 486)
    private static let sceneHeight: CGFloat = 214
    private static let contentWidth: CGFloat = 280

    private var percent: Int { Int((store.todayProgress * 100).rounded()) }

    var body: some View {
        VStack(spacing: 0) {
            scene
                .padding(.horizontal, 12)
                .padding(.top, 12)
            stats
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 16)
            Spacer(minLength: 0)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background {
            ClaySurface(shape: RoundedRectangle(cornerRadius: 34, style: .continuous), fill: Palette.paper)
        }
        .environment(\.dewyTheme, theme)
    }

    // MARK: Scene

    private var scene: some View {
        ZStack(alignment: .bottom) {
            ClayWorld(horizon: 128, animated: false, decor: store.placedDecor)

            ZStack(alignment: .bottom) {
                LilyPad(width: 112, animated: false)
                MascotView(
                    progress: store.todayProgress,
                    mood: store.mood,
                    size: 104,
                    outfits: store.outfits,
                    sparkles: store.todayProgress >= 1,
                    bands: store.todayBands,
                    backdrop: .color,
                    animated: false,
                    showsShadow: false
                )
                .padding(.bottom, 15)
            }
            .padding(.bottom, 4)
        }
        .frame(height: Self.sceneHeight)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
        }
        .overlay(alignment: .topLeading) {
            drinksChip
                .padding(12)
        }
    }

    /// Today's drinks as a little row of clay illustrations.
    @ViewBuilder
    private var drinksChip: some View {
        let kinds = Array(Set(store.todayEntries.map(\.kind))).sorted { $0.rawValue < $1.rawValue }.prefix(4)
        if !kinds.isEmpty {
            HStack(spacing: -4) {
                ForEach(Array(kinds)) { kind in
                    DrinkIcon(kind: kind, size: 24)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 32)
            .background(Color.white.opacity(0.85), in: Capsule())
        }
    }

    // MARK: Numbers

    private var stats: some View {
        VStack(spacing: 12) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(store.format(store.todayTotal, withUnit: false))
                        .font(.display(50))
                        .foregroundStyle(theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(store.profile.unit.label)
                        .font(.display(20))
                        .foregroundStyle(theme.inkSoft)
                }
                Text("of \(store.format(store.goal)) today")
                    .font(.dewy(14, .semibold))
                    .foregroundStyle(theme.inkSoft)
            }

            progressBar

            HStack(spacing: 8) {
                ShareStatTile(value: "\(percent)%", label: "of goal", tint: Palette.aquaSoft, labelColor: Palette.aquaDeep) {
                    DewyShape()
                        .fill(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .top, endPoint: .bottom))
                        .frame(width: 17, height: 22)
                }
                ShareStatTile(value: "\(store.currentStreak)", label: "day streak", tint: Palette.butterSoft, labelColor: Palette.butterDeep.blended(with: Ink.primary, by: 0.3)) {
                    ClayIcon(glyph: .flame, size: 24)
                }
                ShareStatTile(value: "+\(store.todayDrops)", label: "drops", tint: Palette.coralSoft, labelColor: Palette.coralDeep) {
                    ClayIcon(glyph: .drop, size: 24)
                }
            }

            footer
        }
    }

    private var progressBar: some View {
        let fraction = CGFloat(min(max(store.todayProgress, 0), 1))
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color(hex: 0xF3E8DE))
            Capsule()
                .fill(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 3)
                        .padding(.horizontal, 5)
                        .padding(.top, 2)
                }
                .frame(width: max(10, Self.contentWidth * fraction))
        }
        .frame(width: Self.contentWidth, height: 10)
    }

    private var footer: some View {
        HStack(spacing: 5) {
            DewyShape()
                .fill(LinearGradient(colors: [Palette.aquaLight, Palette.aqua], startPoint: .top, endPoint: .bottom))
                .frame(width: 12, height: 16)
            Text("dewy")
                .font(.display(17, .bold))
                .foregroundStyle(Palette.aquaDeep)
            Spacer(minLength: 0)
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(.dewy(12, .bold))
                .foregroundStyle(theme.inkSoft)
        }
    }
}

/// A pastel tile with a clay icon, a number and a label.
private struct ShareStatTile<Icon: View>: View {
    let value: String
    let label: String
    let tint: Color
    let labelColor: Color
    let icon: Icon

    init(value: String, label: String, tint: Color, labelColor: Color, @ViewBuilder icon: () -> Icon) {
        self.value = value
        self.label = label
        self.tint = tint
        self.labelColor = labelColor
        self.icon = icon()
    }

    var body: some View {
        VStack(spacing: 3) {
            icon
                .frame(width: 24, height: 24)
            Text(value)
                .font(.display(18))
                .foregroundStyle(Ink.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.dewy(11, .heavy))
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(LinearGradient(colors: [.white.opacity(0.9), .clear], startPoint: .top, endPoint: .center), lineWidth: 1.2)
                }
        }
    }
}
