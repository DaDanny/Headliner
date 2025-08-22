//
//  StatusBar.swift
//  Headliner
//
//  Status bar overlay with weather, time, and location
//

import SwiftUI

/// Status bar overlay: weather, time, and location in top bar
struct StatusBar: OverlayViewProviding {
    static let presetId = "swiftui.status.bar"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            StatusBarContent(tokens: tokens)
        }
    }
}

// Separate view to use @Environment properly
private struct StatusBarContent: View {
    let tokens: OverlayTokens
    
    @Environment(\.surfaceStyle) private var surfaceStyle
    
    var body: some View {
        OverlayScaleReader { theme, s in
            let e = theme.effects
            
            return ZStack(alignment: .top) {
                HStack(spacing: e.insetMedium * s) {
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
                    
                    Spacer(minLength: 0)
                    
                    // Local time
                    if let localTime = tokens.localTime, !localTime.isEmpty {
                        LocalTimeBadgeModern(
                            time: localTime,
                            surfaceStyle: surfaceStyle
                        )
                    }
                }
                .padding(.horizontal, e.insetLarge * s)
                .padding(.top, e.insetMedium * s)
                .frame(maxWidth: .infinity, alignment: .center) // width fill
                .frame(maxHeight: .infinity, alignment: .bottom) // <-- pin to bottom
                .padding(.bottom, e.insetLarge * s) // optional bottom inset
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
    StatusBar()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .classic)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    StatusBar()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded") {
    StatusBar()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .dawn)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
