import SwiftUI

struct CityBadgeModern: View {
    let city: String?
    var surfaceStyle: SurfaceStyle = .rounded

    @Environment(\.theme) private var theme
    @Environment(\.overlayRenderSize) private var renderSize

    var body: some View {
        guard let city, !city.isEmpty else { return AnyView(EmptyView()) }
        let t = theme.typography
        let e = theme.effects
        let s = t.scale(for: renderSize)

        return AnyView(
            HStack(spacing: e.insetSmall * s) {
                Text("📍").font(t.emojiFont(for: renderSize))
                Text(city)
                    .font(t.bodyFont(for: renderSize))
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .padding(.horizontal, e.insetLarge * s)
            .padding(.vertical, e.insetSmall * s)
            .background(SurfaceBackground(theme: theme, scale: s, style: surfaceStyle))
            .allowsHitTesting(false)
        )
    }
}

#if DEBUG
#Preview("Classic Theme - Rounded") {
    CityBadgeModern(
        city: "San Francisco",
        surfaceStyle: .rounded
    )
    .padding()
    .background(.white)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    CityBadgeModern(
        city: "New York",
        surfaceStyle: .square
    )
    .padding()
    .background(.white)
    .environment(\.theme, .midnight)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded") {
    CityBadgeModern(
        city: "Austin",
        surfaceStyle: .rounded
    )
    .padding()
    .background(.gray.opacity(0.3))
    .environment(\.theme, .dawn)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
