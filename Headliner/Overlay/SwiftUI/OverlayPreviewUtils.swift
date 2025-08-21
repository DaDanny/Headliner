import SwiftUI

@available(macOS 13.0, *)
enum OverlayPreviewUtils {
    @MainActor
    static func snapshot<ViewType: View>(_ view: ViewType, size: CGSize, scale: CGFloat = 2.0) -> CGImage? {
        let canvas = OverlayCanvas(size: size) { view }
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.cgImage
    }
}
