//
//  ModernProfessional.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Modern professional preset with profile circle and enhanced styling
struct ModernProfessional: OverlayViewProviding {
    static let presetId = "swiftui.modern.professional"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            VStack {
                Spacer()
                
                HStack {
                    BottomBarV2(
                        displayName: tokens.displayName,
                        tagline: tokens.tagline,
                        accentColor: accentColor
                    )
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        if TokenHelpers.hasWeatherData(tokens) {
                            WeatherTicker(
                                location: tokens.city,
                                weatherEmoji: tokens.weatherEmoji,
                                temperature: tokens.weatherText
                            )
                        }
                        
                        HStack(spacing: 8) {
                            if let time = tokens.localTime {
                                TimeTicker(time: time)
                            }
                            
                            if let logoText = tokens.logoText {
                                LogoBadge(logoText: logoText, accentColor: accentColor)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#if DEBUG
#Preview {
    ModernProfessional()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
}
#endif
