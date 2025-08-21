//
//  SwiftUIOverlayRenderer.swift
//  HeadlinerShared
//
//  Render SwiftUI overlays into CGImages with correct sizing, transparency, and caching.
//

import SwiftUI
import CoreImage
import CoreGraphics

/// Render SwiftUI overlays into CGImages with correct sizing, transparency, and caching.
/// NOTE: ImageRenderer requires main-thread. We isolate main-thread work and keep the API async.
@available(macOS 13.0, *)
public final class SwiftUIOverlayRenderer {
    /*
     Example usage in your pipeline:
     
     let tokens = OverlayTokens.previewDanny
     let targetSize = CGSize(width: bufferWidth, height: bufferHeight)
     
     // Choose a preset to render:
     let cg = await SwiftUIOverlayRenderer.shared.renderCGImage(
       provider: StandardLowerThird(),
       tokens: tokens,
       size: targetSize,
       scale: 2.0
     )
     
     // If you need CIImage for CoreImage composition:
     let ci = await SwiftUIOverlayRenderer.shared.renderCIImage(
       provider: BrandRibbon(),
       tokens: tokens,
       size: targetSize,
       scale: 2.0
     )
    */
    
    public static let shared = SwiftUIOverlayRenderer()

    private let cache = NSCache<NSString, CGImageWrapper>()
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private let cacheExpirationTime: TimeInterval = 30 // 30 seconds
    private let logger = HeadlinerLogger.logger(for: .overlays)
    
    private init() {
        // Reasonable memory bound: ~64MB total (tune as needed)
        cache.totalCostLimit = 64 * 1024 * 1024
    }

    private final class CGImageWrapper: NSObject {
        let image: CGImage
        let cost: Int
        let timestamp: Date
        init(_ image: CGImage, cost: Int) { 
            self.image = image
            self.cost = cost 
            self.timestamp = Date()
        }
    }

    /// Stable cache key composition
    private func cacheKey(tokens: OverlayTokens, size: CGSize, scale: CGFloat, presetId: String) -> NSString {
        var hasher = Hasher()
        hasher.combine(tokens)
        hasher.combine(Int(size.width))
        hasher.combine(Int(size.height))
        hasher.combine(Int(scale * 1000))
        hasher.combine(presetId)
        return NSString(string: String(hasher.finalize()))
    }

    /// Public API: render an overlay provider into a CGImage (transparent, sRGB).
    public func renderCGImage<P: OverlayViewProviding>(
        provider: P,
        tokens: OverlayTokens,
        size: CGSize,
        scale: CGFloat = 1.0  // Use 1.0 for runtime (size already in pixels), 2.0 for previews
    ) async -> CGImage? {
        let key = cacheKey(tokens: tokens, size: size, scale: scale, presetId: P.presetId)
        
        logger.debug("🎨 [SwiftUIRenderer] Starting render for \(P.presetId) at \(Int(size.width))x\(Int(size.height))")

        if let wrapped = cache.object(forKey: key) {
            let age = Date().timeIntervalSince(wrapped.timestamp)
            if age < cacheExpirationTime {
                logger.debug("🎯 [SwiftUIRenderer] Cache hit for \(P.presetId) (age: \(Int(age))s)")
                return wrapped.image
            } else {
                logger.debug("⏰ [SwiftUIRenderer] Cache expired for \(P.presetId) (age: \(Int(age))s), re-rendering...")
                cache.removeObject(forKey: key)
            }
        }

        logger.debug("🔄 [SwiftUIRenderer] Cache miss, rendering on main thread...")
        // Main-thread render (ImageRenderer requirement)
        return await MainActor.run {
            let canvas = OverlayCanvas(size: size) {
                provider.makeView(tokens: tokens)
            }

            let renderer = ImageRenderer(content: canvas)
            renderer.scale = scale
            renderer.isOpaque = false
            
            logger.debug("📸 [SwiftUIRenderer] ImageRenderer configured, extracting CGImage...")

            // Render to CGImage
            guard let cg = renderer.cgImage else { 
                logger.error("❌ [SwiftUIRenderer] Failed to extract CGImage from ImageRenderer")
                return nil 
            }

            logger.debug("✅ [SwiftUIRenderer] Successfully rendered CGImage, caching...")
            // Cost ~ width * height * 4 bytes (RGBA)
            let cost = Int(size.width * size.height * 4.0 * scale * scale)
            cache.setObject(CGImageWrapper(cg, cost: max(cost, 1)), forKey: key, cost: cost)
            return cg
        }
    }

    /// Convenience: get CIImage for downstream CoreImage pipelines
    public func renderCIImage<P: OverlayViewProviding>(
        provider: P,
        tokens: OverlayTokens,
        size: CGSize,
        scale: CGFloat = 1.0  // Use 1.0 for runtime (size already in pixels), 2.0 for previews
    ) async -> CIImage? {
        guard let cg = await renderCGImage(provider: provider, tokens: tokens, size: size, scale: scale) else {
            return nil
        }
        return CIImage(cgImage: cg, options: [.colorSpace: colorSpace])
    }

    public func clearCache() {
        cache.removeAllObjects()
        logger.debug("🗑️ [SwiftUIRenderer] Cache cleared")
    }
    
    /// Clear only expired entries from cache
    public func clearExpiredCache() {
        // Note: NSCache doesn't support enumeration, so we rely on lazy expiration during access
        // This is a placeholder for potential future enhancement with a different cache implementation
        logger.debug("🧹 [SwiftUIRenderer] Expired cache cleanup (lazy expiration active)")
    }
}