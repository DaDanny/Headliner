//
//  WeatherTicker.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Weather information display with location and temperature
struct WeatherTicker: View {
    let location: String?
    let weatherEmoji: String?
    let temperature: String?
    
    init(location: String? = nil, weatherEmoji: String? = nil, temperature: String? = nil) {
        self.location = location
        self.weatherEmoji = weatherEmoji
        self.temperature = temperature
    }
    
    var body: some View {
        if hasContent {
            HStack(spacing: 8) {
                if let emoji = weatherEmoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let location = location, !location.isEmpty {
                        Text(location)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    if let temperature = temperature, !temperature.isEmpty {
                        Text(temperature)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.thinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
    
    private var hasContent: Bool {
        (location?.isEmpty == false) || 
        (weatherEmoji?.isEmpty == false) || 
        (temperature?.isEmpty == false)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        WeatherTicker(
            location: "Pittsburgh, PA",
            weatherEmoji: "☀️",
            temperature: "72°F"
        )
        
        WeatherTicker(
            location: "New York, NY",
            temperature: "68°F"
        )
        
        WeatherTicker(
            weatherEmoji: "🌧️",
            temperature: "65°F"
        )
    }
    .padding()
    .background(.black)
}
#endif
