//
//  ProfessionalCorner.swift
//  Headliner
//
//  Professional corner overlay with company branding and time
//

import SwiftUI

/// Professional corner overlay: company mark + time in top-right
struct ProfessionalCorner: OverlayViewProviding {
    static let presetId = "swiftui.professional.corner"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            ProfessionalCornerContent(logoText: tokens.logoText, localTime: tokens.localTime, accentColor: accentColor)
        }
    }
}

// Separate view to use @Environment properly
private struct ProfessionalCornerContent: View {
    let logoText: String?
    let localTime: String?
    let accentColor: Color
    
    @Environment(\.surfaceStyle) private var surfaceStyle
    
    var body: some View {
        OverlayScaleReader { theme, s in
            let e = theme.effects
            
            return ZStack(alignment: .topTrailing) {
                VStack(spacing: e.insetSmall * s) {
                    // Company branding
                    if let logoText = logoText, !logoText.isEmpty {
                        CompanyMarkBadgeModern(
                            companyName: logoText,
                            markImage: nil,
                            showName: true,
                            accentColor: accentColor,
                            surfaceStyle: surfaceStyle
                        )
                    }
                    
                    // Local time
                    if let localTime = localTime, !localTime.isEmpty {
                        LocalTimeBadgeModern(
                            time: localTime,
                            surfaceStyle: surfaceStyle
                        )
                    }
                }
                .padding(.top, e.insetLarge * s)
                .padding(.trailing, e.insetLarge * s)
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
    ProfessionalCorner()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .classic)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    ProfessionalCorner()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded") {
    ProfessionalCorner()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .dawn)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
