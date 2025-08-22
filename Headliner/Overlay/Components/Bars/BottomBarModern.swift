//
//  BottomBarModern.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

/// Minimal, compact bottom bar for subtle overlays
struct BottomBarModern: View {
    let displayName: String
    let tagline: String?
    let accentColor: Color
    var surfaceStyle: SurfaceStyle = .rounded
    
    @Environment(\.theme) private var theme
    @Environment(\.overlayRenderSize) private var renderSize


    init(displayName: String, tagline: String? = nil, accentColor: Color = .green, surfaceStyle: SurfaceStyle = .rounded) {
        self.displayName = displayName
        self.tagline = tagline
        self.accentColor = accentColor
        self.surfaceStyle = surfaceStyle
    }
    
    var body: some View {
        let t = theme.typography
        let e = theme.effects
        let s = t.scale(for: renderSize)
        
        let nameSize = (t.baseDisplay) * s
        let subSize  = (t.baseBody) * s
        // Make the line roughly match the text block height
        let lineH = max(nameSize, subSize * 1.25)

        
        HStack(spacing: e.insetMedium * s) {
            // Accent line indicator
            RoundedRectangle(cornerRadius: 1.5 * s, style: .continuous)
                .fill(accentColor)
                .frame(width: 3 * s, height: lineH)
            
            VStack(alignment: .leading, spacing: (e.insetSmall * 0.25) * s) {
                Text(displayName)
                    .font(t.nameFont(for: renderSize))              // semantic title
                    .foregroundStyle(theme.colors.textPrimary)
                    .shadow(color: theme.colors.shadow, radius: 2 * s, y: 1 * s)

                if let tagline = tagline, !tagline.isEmpty {
                    Text(tagline)
                        .font(t.subtitleFont(for: renderSize))           // semantic body
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, e.insetLarge * s)
        .padding(.vertical, e.insetCozy * s)
        .background(
            SurfaceBackground(theme: theme, scale: s, style: surfaceStyle)
        )
        .allowsHitTesting(false)
    }
}

#if DEBUG
#Preview("Classic Theme - Rounded") {
    BottomBarModern(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342"),
        surfaceStyle: .rounded
    )
    .padding()
    .background(.thinMaterial)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Rounded") {
    BottomBarModern(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342"),
        surfaceStyle: .rounded
    )
    .padding()
    .background(.thinMaterial)
    .environment(\.theme, .midnight)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Rounded") {
    BottomBarModern(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342"),
        surfaceStyle: .rounded
    )
    .padding()
    .background(.thinMaterial)
    .environment(\.theme, .dawn)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Classic Theme - Square") {
    BottomBarModern(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342"),
        surfaceStyle: .square
    )
    .padding()
    .background(.thinMaterial)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme - Square") {
    BottomBarModern(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342"),
        surfaceStyle: .square
    )
    .padding()
    .background(.thinMaterial)
    .environment(\.theme, .midnight)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme - Square") {
    BottomBarModern(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342"),
        surfaceStyle: .square
    )
    .padding()
    .background(.thinMaterial)
    .environment(\.theme, .dawn)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
