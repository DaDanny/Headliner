//
//  SocialMediaBadgeModern.swift
//  Headliner
//
//  Modern social media badge with platform icons and handles
//

import SwiftUI

/// Modern social media badge displaying platform icons and handles
struct SocialMediaBadgeModern: View {
    let socialHandles: [String: String]
    var surfaceStyle: SurfaceStyle = .rounded
    
    @Environment(\.theme) private var theme
    @Environment(\.overlayRenderSize) private var renderSize
    
    init(socialHandles: [String: String], surfaceStyle: SurfaceStyle = .rounded) {
        self.socialHandles = socialHandles
        self.surfaceStyle = surfaceStyle
    }
    
    var body: some View {
        if !socialHandles.isEmpty {
            let t = theme.typography
            let e = theme.effects
            let s = t.scale(for: renderSize)
            
            HStack(spacing: e.insetSmall * s) {
                ForEach(Array(socialHandles.prefix(3)), id: \.key) { platform, handle in
                    HStack(spacing: e.insetMicro * s) {
                        // Platform icon
                        platformIcon(for: platform)
                            .font(.system(size: t.baseSmall * 0.8 * s))
                            .foregroundStyle(theme.colors.accent)
                        
                        // Handle
                        Text(handle)
                            .font(t.pillFont(for: renderSize))
                            .foregroundStyle(theme.colors.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, e.insetSmall * s)
                    .padding(.vertical, e.insetMicro * s)
                    .background(
                        RoundedRectangle(cornerRadius: e.insetSmall * s, style: .continuous)
                            .fill(theme.colors.surfaceAccent.opacity(0.3))
                    )
                }
            }
            .padding(.horizontal, e.insetMedium * s)
            .padding(.vertical, e.insetSmall * s)
            .background(
                SurfaceBackground(theme: theme, scale: s, style: surfaceStyle)
            )
        }
    }
    
    @ViewBuilder
    private func platformIcon(for platform: String) -> some View {
        let icon = platformIconName(for: platform)
        Image(systemName: icon)
    }
    
    private func platformIconName(for platform: String) -> String {
        switch platform.lowercased() {
        case "twitter", "x":
            return "bird.fill"
        case "instagram":
            return "camera.fill"
        case "tiktok":
            return "music.note"
        case "youtube":
            return "play.rectangle.fill"
        case "linkedin":
            return "building.2.fill"
        case "github":
            return "chevron.left.forwardslash.chevron.right"
        case "facebook":
            return "person.2.fill"
        case "twitch":
            return "gamecontroller.fill"
        default:
            return "person.fill"
        }
    }
}

#if DEBUG
#Preview("Classic Theme - Rounded") {
    SocialMediaBadgeModern(
        socialHandles: [
            "twitter": "@dannyf",
            "instagram": "@dannyfrancken",
            "github": "dannyfrancken"
        ],
        surfaceStyle: .rounded
    )
    .padding()
    .background(.thinMaterial)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    SocialMediaBadgeModern(
        socialHandles: [
            "twitter": "@dannyf",
            "instagram": "@dannyfrancken"
        ],
        surfaceStyle: .square
    )
    .padding()
    .background(.thinMaterial)
    .environment(\.theme, .midnight)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded") {
    SocialMediaBadgeModern(
        socialHandles: [
            "github": "dannyfrancken",
            "linkedin": "dannyfrancken"
        ],
        surfaceStyle: .rounded
    )
    .padding()
    .background(.thinMaterial)
    .environment(\.theme, .dawn)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
