//
//  CompanyLogoBadgeModern.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

/// Compact company badge: mark (or initials) + optional company name.
/// - Rounded-only (no SurfaceStyle yet)
struct CompanyMarkBadgeModern: View {
    // MARK: API
    let companyName: String?
    let markImage: Image?
    var showName: Bool = true
    var accentColor: Color? = nil   // Optional accent override (falls back to theme.colors.accent)

    // MARK: Env
    @Environment(\.theme) private var theme
    @Environment(\.overlayRenderSize) private var renderSize

    init(companyName: String? = nil,
         markImage: Image? = nil,
         showName: Bool = true,
         accentColor: Color? = nil) {
        self.companyName = companyName
        self.markImage = markImage
        self.showName = showName
        self.accentColor = accentColor
    }

    // MARK: View
    var body: some View {
        let t = theme.typography
        let e = theme.effects
        let s = t.scale(for: renderSize)

        // Icon sizing relative to body text feels balanced
        let iconSide = max(20, t.baseBody * 1.15) * s
        let strokeW  = max(1, e.strokeWidth) * s

        HStack(spacing: e.insetSmall * s) {
            // Logo or Initials
            markView(side: iconSide, strokeW: strokeW)

            if showName, let name = companyName, !name.isEmpty {
                Text(name)
                    .font(t.bodyFont(for: renderSize))
                    .foregroundStyle(theme.colors.textPrimary)
                    .shadow(color: theme.colors.shadow, radius: 2 * s, y: 1 * s)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, e.insetLarge * s)
        .padding(.vertical, e.insetSmall * s)
        .background(
            Capsule()
                .fill(theme.colors.surface)
                .overlay(
                    Capsule().stroke(theme.colors.surfaceStroke, lineWidth: strokeW)
                )
                .shadow(color: theme.colors.shadow, radius: e.shadowRadius * s, y: 2 * s)
        )
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Subviews

    @ViewBuilder
    private func markView(side: CGFloat, strokeW: CGFloat) -> some View {
        if let img = markImage {
            img
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: side * 0.22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                        .stroke(theme.colors.surfaceStroke, lineWidth: strokeW * 0.8)
                )
        } else {
            // Initials fallback
            let initials = companyInitials(from: companyName)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                    .fill((accentColor ?? theme.colors.accent).opacity(0.22))
                Text(initials)
                    .font(.system(size: side * 0.52, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)
                    .shadow(color: theme.colors.shadow, radius: side * 0.06, y: side * 0.02)
            }
            .frame(width: side, height: side)
            .overlay(
                RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                    .stroke(theme.colors.surfaceStroke, lineWidth: strokeW * 0.8)
            )
        }
    }

    // MARK: Helpers

    private var accessibilityLabel: String {
        if let name = companyName, !name.isEmpty { return "Company: \(name)" }
        return "Company badge"
    }

    private func companyInitials(from name: String?) -> String {
        guard let name = name?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else { return "•" }

        // Take first character of up to two words (e.g., "Bonusly Inc." -> "BI")
        let words = name.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first }.map { String($0).uppercased() }
        return letters.joined()
    }
}

#if DEBUG
#Preview("Classic – With Mark") {
    CompanyMarkBadgeModern(
        companyName: "Bonusly",
        markImage: Image("Bonusly-Mark"),
        showName: false
    )
    .padding()
    .background(.black)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Classic – Initials Only") {
    VStack(spacing: 20) {
        CompanyMarkBadgeModern(
            companyName: "Bonusly Inc.",
            markImage: nil,
            showName: false
        )
        .frame(height: 64)
        CompanyMarkBadgeModern(
            companyName: "Bonusly Inc.",
            markImage: nil,
            showName: false
        )
        .frame(height: 64)
    }
    .padding()
    .background(.black)
    .environment(\.theme, .classic)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn – Name Only") {
    CompanyMarkBadgeModern(
        companyName: "Acme Co.",
        markImage: nil,
        showName: true
    )
    .padding()
    .background(.white)
    .environment(\.theme, .dawn)
    .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
