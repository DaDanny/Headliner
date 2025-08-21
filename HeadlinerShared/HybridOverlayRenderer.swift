//
//  HybridOverlayRenderer.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//
//  Proof-of-concept: Hybrid renderer that can use either Core Graphics or SwiftUI
//

import CoreImage
import CoreVideo
import OSLog

/// Hybrid overlay renderer that can use either the existing Core Graphics approach
/// or the new SwiftUI rendering approach based on preset configuration
class HybridOverlayRenderer: OverlayRenderer {
    
    private let logger = HeadlinerLogger.logger(for: .overlays)
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])  // Reused Metal-backed context
    
    private let coreGraphicsRenderer: OverlayRenderer
    
    init(coreGraphicsRenderer: OverlayRenderer) {
        self.coreGraphicsRenderer = coreGraphicsRenderer
    }
    
    func render(pixelBuffer: CVPixelBuffer,
                preset: OverlayPreset,
                tokens: OverlayTokens,
                previousFrame: CIImage?) -> CIImage {
        
        let base = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Use pre-rendered overlay from App Group (SwiftUI is not available in the extension)
        if shouldUseSwiftUIRenderer(for: preset) {
            if let overlayCG = SharedOverlayStore.readOverlay() {
                let overlayCI = CIImage(cgImage: overlayCG)
                // Ensure overlay matches base extent (crop if needed)
                let croppedOverlay = overlayCI.cropped(to: base.extent)
                logger.info("✅ [SharedOverlay] Using pre-rendered overlay from App Group")
                return croppedOverlay.composited(over: base)
            } else {
                logger.info("⚠️ [SharedOverlay] No pre-rendered overlay available, falling back to Core Graphics")
            }
        }
        
        // Fallback to existing Core Graphics renderer
        logger.info("🖼️ [Core Graphics] Using Core Graphics renderer for preset: \(preset.name)")
        return coreGraphicsRenderer.render(pixelBuffer: pixelBuffer, 
                                         preset: preset, 
                                         tokens: tokens, 
                                         previousFrame: previousFrame)
    }
    
    func notifyAspectChanged() {
        // Forward to the Core Graphics renderer (it handles crossfade transitions)
        coreGraphicsRenderer.notifyAspectChanged()
        
        // Note: SwiftUI overlays are pre-rendered in the app, no cache to clear here
    }
    
    /// Determine whether to use pre-rendered overlay for this preset
    private func shouldUseSwiftUIRenderer(for preset: OverlayPreset) -> Bool {
        // TESTING: Always use SwiftUI pre-rendered overlays for now
        logger.debug("🔍 [SharedOverlay] Testing mode - always using SwiftUI pre-rendered overlay for preset '\(preset.name)' (id: '\(preset.id)')")
        return true
    }
    

}
