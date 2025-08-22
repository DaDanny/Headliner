//
//  CompanyFun.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Company Fun - Company branding with logo, location, and weather
struct CompanyFun: OverlayViewProviding {
    static let presetId = "swiftui.company.fun"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            CompanyFunContent(tokens: tokens)
        }
    }
}

private struct CompanyFunContent: View {
    let tokens: OverlayTokens
    
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.theme) private var theme
    @Environment(\.overlayRenderSize) private var renderSize
    
    var body: some View {
        ZStack {
            // Top section with location, weather, and company logo in a single row
            VStack {
                HStack {
                    // Location badge (left)
                    if let extras = tokens.extras,
                       let city = extras["location"] as? String, !city.isEmpty {
                        CityBadgeModern(
                            city: city,
                            surfaceStyle: surfaceStyle
                        )
                    }
                    
                    Spacer()
                    
                    // Weather ticker (center)
                    if let extras = tokens.extras,
                       let weatherEmoji = extras["weatherEmoji"] as? String,
                       let temperature = extras["weatherText"] as? String {
                        SimpleWeatherTicker(
                            weatherEmoji: weatherEmoji,
                            temperature: temperature,
                            surfaceStyle: surfaceStyle
                        )
                    }
                    
                    Spacer()
                    
                    // Company logo (right)
                    CompanyLogoBadgeModern(
                        logoAssetName: "Bonusly-Logo",
                        companyName: "Bonusly",
                        surfaceStyle: surfaceStyle
                    )
                }
                .padding(.horizontal, theme.effects.insetLarge * theme.typography.scale(for: renderSize))
                .padding(.top, theme.effects.insetMedium * theme.typography.scale(for: renderSize))
                
                Spacer()
            }
            
            // Bottom bar with name and tagline
            VStack {
                Spacer()
                
                BottomBarModern(
                    displayName: tokens.displayName ?? "Name",
                    tagline: tokens.tagline,
                    accentColor: Color(hex: "#118342"), // Bonusly green
                    surfaceStyle: surfaceStyle
                )
            }
        }
    }
}

#if DEBUG
struct CompanyFun_Previews: PreviewProvider {
    static var previews: some View {
        CompanyFunContent(tokens: OverlayTokens.previewDanny)
            .environment(\.theme, .classic)
            .environment(\.overlayRenderSize, .init(width: 640, height: 360))
            .environment(\.surfaceStyle, .rounded)
            .frame(width: 640, height: 360)
            .background(Color.black)
    }
}
#endif
