import SwiftUI

public protocol OverlayViewProviding {
    associatedtype Body: View
    @ViewBuilder
    func makeView(tokens: OverlayTokens) -> Body
    /// A stable identifier used in cache keys
    static var presetId: String { get }
    /// Default logical canvas size (used by previews; renderer will override)
    static var defaultSize: CGSize { get }
}
