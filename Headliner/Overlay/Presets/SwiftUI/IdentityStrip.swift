//
//  IdentityStrip.swift
//  Headliner
//
//  Identity strip overlay with name, role, and company mark
//

import SwiftUI

/// Identity strip overlay: name, role, and company mark in bottom strip
struct IdentityStrip: OverlayViewProviding {
    static let presetId = "swiftui.identity.strip"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            IdentityStripContent(tokens: tokens, accentColor: accentColor)
        }
    }
}

// Separate view to use @Environment properly
private struct IdentityStripContent: View {
    let tokens: OverlayTokens
    let accentColor: Color
    
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.overlayRenderSize) private var renderSize
    
    var body: some View {
        OverlayScaleReader { theme, s in
            let e = theme.effects
            
            return ZStack(alignment: .bottom) {
                HStack(spacing: e.insetMedium * s) {
                    // Company mark (compact)
                    if let logoText = tokens.logoText, !logoText.isEmpty {
                        CompanyMarkBadgeModern(
                            companyName: logoText,
                            markImage: nil,
                            showName: false, // Just show the mark
                            accentColor: accentColor,
                            surfaceStyle: surfaceStyle
                        )
                    }
                    
                    // Name and role
                    VStack(alignment: .leading, spacing: (e.insetSmall * 0.5) * s) {
                        Text(tokens.displayName)
                            .font(theme.typography.titleFont(for: renderSize))
                            .foregroundStyle(theme.colors.textPrimary)
                            .shadow(color: theme.colors.shadow, radius: 2 * s, y: 1 * s)
                        
                        if let tagline = tokens.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(theme.typography.bodyFont(for: renderSize))
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Accent indicator
                    RoundedRectangle(cornerRadius: 2 * s, style: .continuous)
                        .fill(accentColor)
                        .frame(width: 4 * s, height: 40 * s)
                }
                .padding(.horizontal, e.insetLarge * s)
                .padding(.vertical, e.insetMedium * s)
                .background(
                    SurfaceBackground(theme: theme, scale: s, style: surfaceStyle)
                )
                .frame(maxWidth: .infinity, alignment: .center) // width fill
                .frame(maxHeight: .infinity, alignment: .bottom) // <-- pin to bottom
                .padding(.bottom, e.insetLarge * s) // optional bottom inset
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
    IdentityStrip()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .classic)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    IdentityStrip()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded") {
    IdentityStrip()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .dawn)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
