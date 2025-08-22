//
//  LocalTimeBadge.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

enum SurfaceStyle: String, CaseIterable, Identifiable { case rounded, square; var id: String { rawValue } }
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
                    Text("🕒")
                        .font(t.emojiFont(for: renderSize))
                }

                Text(label)
                    .font(t.numericFont(for: renderSize))   // monospaced digits recommended in your Typography
                    .monospacedDigit()
                    .foregroundStyle(theme.colors.textPrimary)
                    .shadow(color: theme.colors.shadow, radius: 2 * s, y: 1 * s)
            }
            .padding(.horizontal, e.insetLarge * s)
            .padding(.vertical, e.insetSmall * s)
            .background(
                badgeBackground(style: .rounded, s: s)
            )
            .allowsHitTesting(false)
        )
    }

    private var displayTime: String? {
        if let t = time, !t.isEmpty { return t }
        // Simple local time fallback
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.timeStyle = .short    // e.g., “7:43 PM”
        return fmt.string(from: Date())
    }
    
    @ViewBuilder
    private func badgeBackground(style: SurfaceStyle, s: CGFloat) -> some View {
        switch style {
        case .rounded:
            Capsule()
                .fill(theme.colors.surface)
                .overlay(
                    Capsule().stroke(theme.colors.surfaceStroke, lineWidth: theme.effects.strokeWidth * s)
                )
                .shadow(color: theme.colors.shadow, radius: theme.effects.shadowRadius * s, y: 2 * s)

        case .square:
            // Slight radius so it doesn’t look harsh on video; adjust if you add `squareRadius` to ThemeEffects
            let r = max(6, theme.effects.cornerRadius * 0.35) * s
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(theme.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .stroke(theme.colors.surfaceStroke, lineWidth: theme.effects.strokeWidth * s)
                )
                .shadow(color: theme.colors.shadow, radius: theme.effects.shadowRadius * s, y: 2 * s)
        }
    }
}

#if DEBUG
#Preview("Classic – Rounded") {
    VStack(spacing: 20) {
        LocalTimeBadgeModern(time: "8:12 PM", surfaceStyle: .rounded)
            .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
            .frame(height: 64)
        
        LocalTimeBadgeModern(time: "8:12 PM", showClockIcon: false, surfaceStyle: .rounded)
            .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
            .frame(height: 64)
    }
    .padding()
    .background(.gray.opacity(0.3))
    .environment(\.theme, .classic)
}

#Preview("Midnight – Square") {
    LocalTimeBadgeModern(time: nil, surfaceStyle: .square) // uses current time
        .padding()
        .background(.black)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn – Rounded") {
    LocalTimeBadgeModern(time: "7:43 PM")
        .padding()
        .background(.white)
        .environment(\.theme, .dawn)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
