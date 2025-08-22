//
//  Professional.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Professional preset using component library with safe area support
struct Professional: OverlayViewProviding {
    static let presetId = "swiftui.professional"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            VStack {
                Spacer()
                
                HStack {
                    BottomBar(
                        displayName: tokens.displayName,
                        tagline: tokens.tagline,
                        accentColor: accentColor
                    )
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        if TokenHelpers.hasWeatherData(tokens) {
                            WeatherTicker(
                                location: tokens.city,
                                weatherEmoji: tokens.weatherEmoji,
                                temperature: tokens.weatherText
                            )
                        }
                        
                        if let time = tokens.localTime {
                            TimeTicker(time: time)
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
    Professional()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
}
#endif
