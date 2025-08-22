//
//  CompanyLogoBadgeModern.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

/// Badge that shows a full company wordmark (logo-with-text) inside a glass chip.
/// Rounded-only (no SurfaceStyle yet).
struct CompanyLogoBadgeModern: View {
    // MARK: API
    let logoImage: Image
    var companyName: String? = nil           // for accessibility; optional
    var preferredHeightMultiplier: CGFloat = 1.30 // relative to baseBody
    var horizontalPaddingMultiplier: CGFloat = 1.0

    // MARK: Env
    @Environment(\.theme) private var theme
    @Environment(\.overlayRenderSize) private var renderSize

    // Convenience init if you want to pass an asset name
    init(logoAssetName: String,
         companyName: String? = nil,
         preferredHeightMultiplier: CGFloat = 1.30,
         horizontalPaddingMultiplier: CGFloat = 1.0) {
        self.logoImage = Image(logoAssetName)
        self.companyName = companyName
        self.preferredHeightMultiplier = preferredHeightMultiplier
        self.horizontalPaddingMultiplier = horizontalPaddingMultiplier
    }

    init(logoImage: Image,
         companyName: String? = nil,
         preferredHeightMultiplier: CGFloat = 1.30,
         horizontalPaddingMultiplier: CGFloat = 1.0) {
        self.logoImage = logoImage
        self.companyName = companyName
        self.preferredHeightMultiplier = preferredHeightMultiplier
        self.horizontalPaddingMultiplier = horizontalPaddingMultiplier
    }

    // MARK: View
    var body: some View {
        let t = theme.typography
        let e = theme.effects
        let s = t.scale(for: renderSize)

        // Wordmark height tuned to feel balanced with body text
        let logoH = max(18, t.baseBody * preferredHeightMultiplier) * s
        let strokeW = max(1, e.strokeWidth) * s

        HStack(spacing: 0) {
            logoImage
                .renderingMode(.original) // keep brand colors
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(height: logoH)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, e.insetLarge * horizontalPaddingMultiplier * s)
        .padding(.vertical, e.insetSmall * s)
        .background(
            Capsule()
                .fill(theme.colors.surface)
                .overlay(
                    Capsule()
                        .stroke(theme.colors.surfaceStroke, lineWidth: strokeW)
                )
                .shadow(color: theme.colors.shadow, radius: e.shadowRadius * s, y: 2 * s)
        )
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(companyName.map { "Company: \($0)" } ?? "Company logo badge")
    }
}

#if DEBUG
#Preview("Midnight – Wordmark") {
    CompanyLogoBadgeModern(logoAssetName: "Bonusly-Logo", companyName: "Bonusly")
        .padding()
        .background(.black)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Classic – Wider Padding") {
    CompanyLogoBadgeModern(
        logoAssetName: "Bonusly-Logo",
        companyName: "Bonusly",
        preferredHeightMultiplier: 1.25,
        horizontalPaddingMultiplier: 1.2
    )
    .padding()
    .background(.black)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
