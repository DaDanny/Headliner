//
//  SimpleWeatherTicker.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

/// Weather information display with location and temperature
struct SimpleWeatherTicker: View {
    let weatherEmoji: String?
    let temperature: String?
    var surfaceStyle: SurfaceStyle = .rounded

    @Environment(\.theme) private var theme

    init(weatherEmoji: String? = nil, temperature: String? = nil, surfaceStyle: SurfaceStyle = .rounded) {
        self.weatherEmoji = weatherEmoji
        self.temperature = temperature
        self.surfaceStyle = surfaceStyle
    }

    @Environment(\.overlayRenderSize) private var renderSize
    
    var body: some View {
        if hasContent {
            let t = theme.typography
            let e = theme.effects
            let s = t.scale(for: renderSize)

            HStack(spacing: e.insetSmall * s) {
                if let emoji = weatherEmoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(t.emojiFont(for: renderSize))
                }

                if let temperature = temperature, !temperature.isEmpty {
                    Text(temperature)
                        .font(t.numericFont(for: renderSize))
                        .monospacedDigit()
                        .foregroundStyle(theme.colors.textPrimary)
                        .shadow(color: theme.colors.shadow, radius: 2 * s, y: 1 * s)
                }
            }
            .padding(.horizontal, e.insetLarge * s)
            .padding(.vertical, (e.insetCozy) * s)
            .background(
                SurfaceBackground(theme: theme, scale: s, style: surfaceStyle)
            )
        }
    }

    private var hasContent: Bool {
        (weatherEmoji?.isEmpty == false) ||
        (temperature?.isEmpty == false)
    }
}

#if DEBUG
#Preview("Classic Theme - Rounded") {
    VStack(spacing: 20) {
        SimpleWeatherTicker(
            weatherEmoji: "☀️",
            temperature: "72°F",
            surfaceStyle: .rounded
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            temperature: "68°F",
            surfaceStyle: .rounded
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            weatherEmoji: "🌧️",
            temperature: "65°F",
            surfaceStyle: .rounded
        )
        .frame(height: 64)
    }
    .padding()
    .background(.white)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    VStack(spacing: 20) {
        SimpleWeatherTicker(
            weatherEmoji: "☀️",
            temperature: "72°F",
            surfaceStyle: .square
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            temperature: "68°F",
            surfaceStyle: .square
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            weatherEmoji: "🌧️",
            temperature: "65°F",
            surfaceStyle: .square
        )
        .frame(height: 64)
    }
    .padding()
    .background(.black)
    .environment(\.theme, .midnight)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded") {
    VStack(spacing: 20) {
        SimpleWeatherTicker(
            weatherEmoji: "☀️",
            temperature: "72°F",
            surfaceStyle: .rounded
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            temperature: "68°F",
            surfaceStyle: .rounded
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            weatherEmoji: "🌧️",
            temperature: "65°F",
            surfaceStyle: .rounded
        )
        .frame(height: 64)
    }
    .padding()
    .background(.gray.opacity(0.3))
    .environment(\.theme, .dawn)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
