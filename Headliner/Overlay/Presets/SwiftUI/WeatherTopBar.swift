import SwiftUI

struct WeatherTopBar: OverlayViewProviding {
    static let presetId = "swiftui.weather.topbar"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        return SafeAreaContainer(mode: settings.safeAreaMode) {
            OverlayScaleReader { theme, s in
                let e = theme.effects
                return VStack(spacing: 0) {
                    HStack {
                        SimpleWeatherTicker(
                            weatherEmoji: tokens.weatherEmoji,
                            temperature: tokens.weatherText,
                            surfaceStyle: .rounded
                        )
                        Spacer(minLength: 0)
                        HStack(spacing: e.insetSmall * s) {
                            CityBadgeModern(city: tokens.city, surfaceStyle: .rounded)
                            LocalTimeBadgeModern(time: tokens.localTime, surfaceStyle: .rounded)
                        }
                    }
                    .padding(.top, (e.insetLarge + 4) * s)
                    .padding(.horizontal, e.insetLarge * s)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

// Small helper so you can read theme + scale together anywhere.
private struct OverlayScaleReader<Content: View>: View {
    @Environment(\.theme) private var theme
    @Environment(\.overlayRenderSize) private var renderSize
    let content: (_ theme: Theme, _ s: CGFloat) -> Content
    var body: some View {
        let s = theme.typography.scale(for: renderSize)
        content(theme, s)
    }
}

#if DEBUG
#Preview("Classic Theme") {
    WeatherTopBar()
        .makeView(tokens: OverlayTokens.previewDanny)
        .environment(\.theme, .classic)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme") {
    WeatherTopBar()
        .makeView(tokens: OverlayTokens.previewDanny)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme") {
    WeatherTopBar()
        .makeView(tokens: OverlayTokens.previewDanny)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
