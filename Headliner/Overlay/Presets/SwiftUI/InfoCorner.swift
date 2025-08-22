//
//  InfoCorner.swift
//  Headliner
//
//  Info corner overlay with weather and location in bottom-right
//

import SwiftUI

/// Info corner overlay: weather and location in bottom-right
struct InfoCorner: OverlayViewProviding {
    static let presetId = "swiftui.info.corner"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            InfoCornerContent(tokens: tokens)
        }
    }
}

// Separate view to use @Environment properly
private struct InfoCornerContent: View {
    let tokens: OverlayTokens
    
    @Environment(\.surfaceStyle) private var surfaceStyle
    
    var body: some View {
        OverlayScaleReader { theme, s in
            let e = theme.effects
            
            return ZStack(alignment: .bottomTrailing) {
                VStack(spacing: e.insetSmall * s) {
                    // Weather ticker
                    if TokenHelpers.hasWeatherData(tokens) {
                        SimpleWeatherTicker(
                            weatherEmoji: tokens.weatherEmoji,
                            temperature: tokens.weatherText,
                            surfaceStyle: surfaceStyle
                        )
                    }
                    
                    // City badge
                    if let city = tokens.city, !city.isEmpty {
                        CityBadgeModern(
                            city: city,
                            surfaceStyle: surfaceStyle
                        )
                    }
                }
                .padding(.bottom, e.insetLarge * s)
                .padding(.trailing, e.insetLarge * s)
            }
            .allowsHitTesting(false)
        }
    }
}

// Helper for theme-aware debug visualization
private struct ThemeAwareDebugBorder: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Rectangle()
            .stroke(theme.colors.accent.opacity(0.3), lineWidth: 2)
            .fill(Color.clear)
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
#Preview("Classic Theme - Rounded") {
    InfoCorner()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .classic)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    InfoCorner()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded") {
    InfoCorner()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .dawn)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
