//
//  ModernPersonal.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

/// Modern Personal Preset with all the bells and whistles
struct ModernPersonal: OverlayViewProviding {
    static let presetId = "swiftui.modern.personal"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            OverlayScaleReader { theme, s in
                let e = theme.effects
                
                return ZStack(alignment: .top) {
//                    ThemeAwareDebugBorder()

                    VStack(spacing: 0) {

                        // TOP BAR AREA
                        HStack {
                            SimpleWeatherTicker(
                                weatherEmoji: tokens.weatherEmoji,
                                temperature: tokens.weatherText
                            )

                            Spacer(minLength: 0)
                        }

                        Spacer(minLength: 0)

                        // BOTTOM BAR AREA
                        BottomBarModern(
                            displayName: tokens.displayName,
                            tagline: tokens.tagline,
                            accentColor: accentColor
                        )
                    }
                }
                .allowsHitTesting(false) // overlay is decorative
            }
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
#Preview("Classic Theme") {
    ModernPersonal()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .classic)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme") {
    ModernPersonal()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme") {
    ModernPersonal()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .dawn)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
