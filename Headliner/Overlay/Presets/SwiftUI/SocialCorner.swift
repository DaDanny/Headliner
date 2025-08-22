//
//  SocialCorner.swift
//  Headliner
//
//  Social corner overlay with social media handles in top-left
//

import SwiftUI

/// Social corner overlay: social media handles in top-left
struct SocialCorner: OverlayViewProviding {
    static let presetId = "swiftui.social.corner"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let socialHandles = TokenHelpers.extractSocialHandles(from: tokens)
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            SocialCornerContent(socialHandles: socialHandles)
        }
    }
}

// Separate view to use @Environment properly
private struct SocialCornerContent: View {
    let socialHandles: [String: String]
    
    @Environment(\.surfaceStyle) private var surfaceStyle
    
    var body: some View {
        OverlayScaleReader { theme, s in
            let e = theme.effects
            
            return ZStack(alignment: .topLeading) {
                if !socialHandles.isEmpty {
                    SocialMediaBadgeModern(
                        socialHandles: socialHandles,
                        surfaceStyle: surfaceStyle
                    )
                    .padding(.top, e.insetLarge * s)
                    .padding(.leading, e.insetLarge * s)
                }
            }
            .allowsHitTesting(false)
        }
    }
}

// Helper for theme-aware debug visualization
private struct ThemeAwareDebugBorder: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Rectangle()
            .stroke(theme.colors.accent.opacity(0.3), lineWidth: 2)
            .fill(Color.clear)
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
#Preview("Classic Theme - Rounded") {
    SocialCorner()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .classic)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    SocialCorner()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded") {
    SocialCorner()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .dawn)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
