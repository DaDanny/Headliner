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
    
    /// Get cached camera dimensions from App Group, falling back to default if unavailable
    private func getCachedCameraDimensions() -> CGSize {
        guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
              let data = userDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
              let settings = try? JSONDecoder().decode(OverlaySettings.self, from: data) else {
            logger.debug("📐 [OverlayBroker] No cached camera dimensions, using default 1920x1080")
            return CGSize(width: 1920, height: 1080)
        }
        
        logger.debug("📐 [OverlayBroker] Using cached camera dimensions: \(Int(settings.cameraDimensions.width))x\(Int(settings.cameraDimensions.height))")
        return settings.cameraDimensions
    }

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
    
    /// Convenience method that automatically uses cached camera dimensions
    public func updateOverlay<P: OverlayViewProviding>(
        provider: P,
        tokens: OverlayTokens
    ) async {
        let dimensions = getCachedCameraDimensions()
        await updateOverlay(provider: provider, tokens: tokens, pixelSize: dimensions)
    }
    
    /// Clear the current overlay
    public func clearOverlay() {
        SharedOverlayStore.clearOverlay()
        NotificationManager.postNotification(named: .overlayUpdated)
        logger.info("🗑️ [OverlayBroker] Cleared overlay and notified extension")
    }
}
