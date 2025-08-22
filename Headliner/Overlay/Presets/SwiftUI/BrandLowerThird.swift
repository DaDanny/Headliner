import SwiftUI

struct BrandLowerThird: OverlayViewProviding {
    static let presetId = "swiftui.brand.lowerthird"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)

        return SafeAreaContainer(mode: settings.safeAreaMode) {
            OverlayScaleReader { theme, s in
                let e = theme.effects
                return VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    HStack {
                        CompanyMarkBadgeModern(
                            companyName: tokens.logoText ?? "Company",
                            markImage: Image("Bonusly-Mark"),
                            showName: false,
                            accentColor: accentColor,
                            surfaceStyle: .square
                        )
                        BottomBarModern(
                            displayName: tokens.displayName,
                            tagline: tokens.tagline,
                            accentColor: accentColor,
                            surfaceStyle: .square
                        )
                    }
                    .padding(.horizontal, e.insetLarge * s)
                    .padding(.bottom, (e.insetLarge + 4) * s)
                }
            }
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
#Preview("Classic Theme") {
    BrandLowerThird()
        .makeView(tokens: OverlayTokens.previewDanny)
        .environment(\.theme, .classic)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Midnight Theme") {
    BrandLowerThird()
        .makeView(tokens: OverlayTokens.previewDanny)
        .environment(\.theme, .midnight)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}

#Preview("Dawn Theme") {
    BrandLowerThird()
        .makeView(tokens: OverlayTokens.previewDanny)
        .environment(\.theme, .dawn)
        .environment(\.overlayRenderSize, .init(width: 1920, height: 1080))
}
#endif
