//
//  ModernCompanyBar.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Company-branded bottom bar with name/tagline on left and company logo on right
struct ModernCompanyBar: View {
    let displayName: String
    let tagline: String?
    let companyLogoType: CompanyLogoType
    var surfaceStyle: SurfaceStyle = .rounded
    
    @Environment(\.theme) private var theme
    @Environment(\.overlayRenderSize) private var renderSize
    
    enum CompanyLogoType {
        case mark      // Bonusly-Mark (icon only)
        case logo      // Bonusly-Logo (full wordmark)
    }

    init(displayName: String, 
         tagline: String? = nil, 
         companyLogoType: CompanyLogoType = .mark,
         surfaceStyle: SurfaceStyle = .rounded) {
        self.displayName = displayName
        self.tagline = tagline
        self.companyLogoType = companyLogoType
        self.surfaceStyle = surfaceStyle
    }
    
    var body: some View {
        OverlayScaleReader { theme, s in
            let t = theme.typography
            let e = theme.effects
            
            let nameSize = (t.baseDisplay) * s
            let subSize  = (t.baseBody) * s
            // Make the line roughly match the text block height
            let lineH = max(nameSize, subSize * 1.25)

            return HStack(spacing: e.insetMedium * s) {
                // Left side: Accent line + Name & Tagline
                HStack(spacing: e.insetMedium * s) {
                    // Accent line indicator
                    RoundedRectangle(cornerRadius: 1.5 * s, style: .continuous)
                        .fill(Color(hex: "#118342")) // Bonusly green
                        .frame(width: 3 * s, height: lineH)
                    
                    VStack(alignment: .leading, spacing: (e.insetSmall * 0.25) * s) {
                        Text(displayName)
                            .font(t.nameFont(for: renderSize))
                            .foregroundStyle(theme.colors.textPrimary)
                            .shadow(color: theme.colors.shadow, radius: 2 * s, y: 1 * s)

                        if let tagline = tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(t.subtitleFont(for: renderSize))
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                // Right side: Company branding
                companyBrandingView(theme: theme, scale: s)
            }
            .padding(.horizontal, e.insetLarge * s)
            .padding(.vertical, e.insetCozy * s)
            .background(
                SurfaceBackground(theme: theme, scale: s, style: surfaceStyle)
            )
            .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    private func companyBrandingView(theme: Theme, scale: CGFloat) -> some View {
        let t = theme.typography
        let e = theme.effects
        let s = scale
        
        switch companyLogoType {
        case .mark:
            // Bonusly-Mark (icon only)
            Image("Bonusly-Mark")
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(height: max(20, t.baseBody * 1.2) * s)
                .accessibilityLabel("Bonusly")
                
        case .logo:
            // Bonusly-Logo (full wordmark)
            Image("Bonusly-Logo")
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(height: max(18, t.baseBody * 1.0) * s)
                .accessibilityLabel("Bonusly")
        }
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
#Preview("Mark - Classic Theme - Rounded") {
    ModernCompanyBar(
        displayName: "Danny F",
        tagline: "High School Intern",
        companyLogoType: .mark,
        surfaceStyle: .rounded
    )
    .padding()
    .background(.black)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Logo - Midnight Theme - Rounded") {
    ModernCompanyBar(
        displayName: "Danny F",
        tagline: "High School Intern",
        companyLogoType: .logo,
        surfaceStyle: .rounded
    )
    .padding()
    .background(.black)
    .environment(\.theme, .midnight)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Mark - Dawn Theme - Square") {
    ModernCompanyBar(
        displayName: "Danny F",
        tagline: "High School Intern",
        companyLogoType: .mark,
        surfaceStyle: .square
    )
    .padding()
    .background(.black)
    .environment(\.theme, .dawn)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Logo - Classic Theme - Square") {
    ModernCompanyBar(
        displayName: "Danny F",
        tagline: "High School Intern",
        companyLogoType: .logo,
        surfaceStyle: .square
    )
    .padding()
    .background(.black)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
