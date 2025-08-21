import SwiftUI

/// Wraps any overlay view in a fixed-size transparent canvas so ImageRenderer
/// captures the full frame without clipping.
struct OverlayCanvas<Content: View>: View {
    let size: CGSize
    let content: () -> Content

    init(size: CGSize, @ViewBuilder content: @escaping () -> Content) {
        self.size = size
        self.content = content
    }

    var body: some View {
        ZStack {
            Color.clear
            content()
        }
        .frame(width: size.width, height: size.height, alignment: .center)
        .compositingGroup()          // flatten layers before render
        .drawingGroup()              // better AA for text/shapes
        .ignoresSafeArea()           // prevent safe-area shrink
        .accessibilityHidden(true)   // overlays are decorative
    }
}
