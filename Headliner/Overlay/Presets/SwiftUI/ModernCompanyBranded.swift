//
//  ModernCompanyBranded.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Modern Company Branded Preset with company branding and personal info
struct ModernCompanyBranded: OverlayViewProviding {
    static let presetId = "swiftui.modern.company.branded"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            ModernCompanyBrandedContent(tokens: tokens, accentColor: accentColor)
        }
    }
}

// Separate view to use @Environment properly
private struct ModernCompanyBrandedContent: View {
    let tokens: OverlayTokens
    let accentColor: Color
    
    @Environment(\.surfaceStyle) private var surfaceStyle
    
    var body: some View {
        OverlayScaleReader { theme, s in
            let e = theme.effects
            
            return ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    // TOP BAR AREA
                    HStack {
                        // City badge (left)
                        if let extras = tokens.extras,
                           let city = extras["location"] as? String, !city.isEmpty {
                            CityBadgeModern(
                                city: city,
                                surfaceStyle: surfaceStyle
                            )
                        }
                        
                        Spacer(minLength: 0)
                        
                        // Weather ticker (right)
                        SimpleWeatherTicker(
                            weatherEmoji: tokens.weatherEmoji,
                            temperature: tokens.weatherText,
                            surfaceStyle: surfaceStyle
                        )
                    }

                    Spacer(minLength: 0)

                    // BOTTOM BAR AREA
                    ModernCompanyBar(
                        displayName: tokens.displayName ?? "Name",
                        tagline: tokens.tagline,
                        companyLogoType: .mark, // Use mark for more compact look
                        surfaceStyle: surfaceStyle
                    )
                }
            }
            .allowsHitTesting(false) // overlay is decorative
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
    ModernCompanyBranded()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .classic)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme") {
    ModernCompanyBranded()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme") {
    ModernCompanyBranded()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .dawn)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
