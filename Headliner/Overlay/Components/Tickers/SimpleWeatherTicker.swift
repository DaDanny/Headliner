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

    @Environment(\.theme) private var theme

    init(weatherEmoji: String? = nil, temperature: String? = nil) {
        self.weatherEmoji = weatherEmoji
        self.temperature = temperature
    }

    var body: some View {
        GeometryReader { geometry in
            if hasContent {
                let t = theme.typography
                let e = theme.effects
                let scale = t.scale(for: geometry.size)

                HStack(spacing: e.insetSmall * scale) {
                    if let emoji = weatherEmoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(t.emojiFont(for: geometry.size))
                    }

                    if let temperature = temperature, !temperature.isEmpty {
                        Text(temperature)
                            .font(t.numericFont(for: geometry.size))
                            .monospacedDigit()
                            .foregroundStyle(theme.colors.textPrimary)
                            .shadow(color: theme.colors.shadow, radius: 2 * scale, y: 1 * scale)
                    }
                }
                .padding(.horizontal, e.insetLarge * scale)
                .padding(.vertical, (e.insetCozy) * scale)
                .background(
                    Capsule()
                        .fill(theme.colors.surface)
                        .overlay(
                            Capsule().stroke(theme.colors.surfaceStroke,
                                           lineWidth: theme.effects.strokeWidth * scale)
                        )
                        .shadow(color: theme.colors.shadow,
                               radius: theme.effects.shadowRadius * scale,
                               x: 0, y: 2 * scale)
                )
            }
        }
    }

    private var hasContent: Bool {
        (weatherEmoji?.isEmpty == false) ||
        (temperature?.isEmpty == false)
    }
}

#if DEBUG
#Preview("Classic Theme") {
    VStack(spacing: 20) {
        SimpleWeatherTicker(
            weatherEmoji: "☀️",
            temperature: "72°F"
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            temperature: "68°F"
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            weatherEmoji: "🌧️",
            temperature: "65°F"
        )
        .frame(height: 64)
    }
    .padding()
    .background(.white)
    .environment(\.theme, .classic)
}

#Preview("Midnight Theme") {
    VStack(spacing: 20) {
        SimpleWeatherTicker(
            weatherEmoji: "☀️",
            temperature: "72°F"
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            temperature: "68°F"
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            weatherEmoji: "🌧️",
            temperature: "65°F"
        )
        .frame(height: 64)
    }
    .padding()
    .background(.white)
    .environment(\.theme, .midnight)
}

#Preview("Dawn Theme") {
    VStack(spacing: 20) {
        SimpleWeatherTicker(
            weatherEmoji: "☀️",
            temperature: "72°F"
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            temperature: "68°F"
        )
        .frame(height: 64)

        SimpleWeatherTicker(
            weatherEmoji: "🌧️",
            temperature: "65°F"
        )
        .frame(height: 64)
    }
    .padding()
    .background(.gray.opacity(0.3))
    .environment(\.theme, .dawn)
}
#endif
