//
//  LocalTimeBadge.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

/// Local Time Modern
struct LocalTimeBadgeModern: View {
    let time: String?
    var showClockIcon: Bool = true
    var surfaceStyle: SurfaceStyle = .rounded
    
    @Environment(\.theme) private var theme
    @Environment(\.overlayRenderSize) private var renderSize
    
    init(time: String? = nil, showClockIcon: Bool = true, surfaceStyle: SurfaceStyle = .rounded) {
        self.time = time
        self.showClockIcon = showClockIcon
        self.surfaceStyle = surfaceStyle
    }

    var body: some View {
        guard let label = displayTime, !label.isEmpty else { return AnyView(EmptyView()) }
        let t = theme.typography
        let e = theme.effects
        let s = t.scale(for: renderSize)

        return AnyView(
            HStack(spacing: e.insetSmall * s) {
                if showClockIcon {
                    Text("🕒").font(t.emojiFont(for: renderSize))
                }
                Text(label)
                    .font(t.numericFont(for: renderSize))
                    .monospacedDigit()
                    .foregroundStyle(theme.colors.textPrimary)
                    .shadow(color: theme.colors.shadow, radius: 2 * s, y: 1 * s)
            }
            .padding(.horizontal, e.insetLarge * s)
            .padding(.vertical, e.insetSmall * s)
            .background(SurfaceBackground(theme: theme, scale: s, style: surfaceStyle))
            .allowsHitTesting(false)
        )
    }

    private var displayTime: String? {
        if let t = time, !t.isEmpty { return t }
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.timeStyle = .short
        return fmt.string(from: Date())
    }
}

#if DEBUG
#Preview("Classic Theme - Rounded") {
    LocalTimeBadgeModern(
        time: "2:30 PM",
        showClockIcon: true,
        surfaceStyle: .rounded
    )
    .padding()
    .background(.white)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    LocalTimeBadgeModern(
        time: "14:30",
        showClockIcon: false,
        surfaceStyle: .square
    )
    .padding()
    .background(.black)
    .environment(\.theme, .midnight)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded (Auto Time)") {
    LocalTimeBadgeModern(
        time: nil,
        showClockIcon: true,
        surfaceStyle: .rounded
    )
    .padding()
    .background(.gray.opacity(0.3))
    .environment(\.theme, .dawn)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
