import Foundation
import CoreGraphics
import CoreImage
import SwiftUI

/// Renders SwiftUI overlays in the APP and publishes them to the App Group store.
@MainActor
public final class OverlayRenderBroker {
    public static let shared = OverlayRenderBroker()
    private let logger = HeadlinerLogger.logger(for: .overlays)
    private init() {}

    /// Render once (scale = 1.0 for pixel-true; pass exact pixel size), write to App Group, post notify.
    public func updateOverlay<P: OverlayViewProviding>(
        provider: P,
        tokens: OverlayTokens,
        pixelSize: CGSize
    ) async {
        logger.debug("🚀 [OverlayBroker] Starting updateOverlay for \(P.presetId)")
        
        guard let cg = await SwiftUIOverlayRenderer.shared.renderCGImage(
            provider: provider,
            tokens: tokens,
            size: pixelSize,
            scale: 1.0 // IMPORTANT: pixel == point
        ) else { 
            logger.warning("⚠️ [OverlayBroker] Failed to render SwiftUI overlay")
            return 
        }

        logger.debug("🎯 [OverlayBroker] Got CGImage from SwiftUIRenderer (\(cg.width)x\(cg.height)), writing to App Group...")
        do {
            try SharedOverlayStore.writeOverlay(cg)
            NotificationManager.postNotification(named: .overlayUpdated)
            logger.debug("✅ [OverlayBroker] Updated overlay (\(Int(pixelSize.width))x\(Int(pixelSize.height))) and notified extension")
        } catch {
            logger.debug("❌ [OverlayBroker] Write failed: \(error)")
        }
    }
    
    /// Clear the current overlay
    public func clearOverlay() {
        SharedOverlayStore.clearOverlay()
        NotificationManager.postNotification(named: .overlayUpdated)
        logger.info("🗑️ [OverlayBroker] Cleared overlay and notified extension")
    }
}
