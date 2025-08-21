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
import SwiftUI
import OSLog

/// Hybrid overlay renderer that can use either the existing Core Graphics approach
/// or the new SwiftUI rendering approach based on preset configuration
class HybridOverlayRenderer: OverlayRenderer {
    
    private let logger = HeadlinerLogger.logger(for: .overlays)
    
    private let coreGraphicsRenderer: OverlayRenderer
    private let swiftUIRenderer: SwiftUIOverlayRenderer?
    
    init(coreGraphicsRenderer: OverlayRenderer) {
        self.coreGraphicsRenderer = coreGraphicsRenderer
        
        // Only create SwiftUI renderer on iOS 16+
        if #available(iOS 16.0, macOS 13.0, *) {
            self.swiftUIRenderer = SwiftUIOverlayRenderer()
        } else {
            self.swiftUIRenderer = nil
        }
    }
    
    func render(pixelBuffer: CVPixelBuffer,
                preset: OverlayPreset,
                tokens: OverlayTokens,
                previousFrame: CIImage?) -> CIImage {
        
        let base = CIImage(cvPixelBuffer: pixelBuffer)
        
        // For POC: Use SwiftUI renderer for specific presets, fallback to Core Graphics
        if shouldUseSwiftUIRenderer(for: preset), 
           let swiftUIRenderer = swiftUIRenderer,
           #available(iOS 16.0, macOS 13.0, *) {
            
            logger.info("🎨 [SwiftUI POC] Using SwiftUI renderer for preset: \(preset.name) (id: \(preset.id))")
            
            let size = CGSize(width: CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                            height: CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
            
            // For now, use a synchronous approach with a timeout for the POC
            // In production, you'd want to pre-render these asynchronously
            let semaphore = DispatchSemaphore(value: 0)
            var overlayImage: CIImage?
            
            Task {
                overlayImage = await swiftUIRenderer.renderOverlay(tokens: tokens, size: size, presetId: preset.id)
                semaphore.signal()
            }
            
            // Wait up to 10ms for SwiftUI rendering (should be cached anyway)
            if semaphore.wait(timeout: .now() + 0.01) == .success,
               let image = overlayImage {
                logger.info("✅ [SwiftUI POC] Successfully rendered SwiftUI overlay")
                // Crop to match video frame and composite
                let croppedOverlay = image.cropped(to: base.extent)
                return croppedOverlay.composited(over: base)
            } else {
                logger.warning("⚠️ [SwiftUI POC] SwiftUI rendering timed out, falling back to Core Graphics")
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
        
        // Clear SwiftUI cache since aspect ratio affects layout
        if #available(iOS 16.0, macOS 13.0, *) {
            swiftUIRenderer?.clearCache()
        }
    }
    
    /// Determine whether to use SwiftUI renderer for this preset
    private func shouldUseSwiftUIRenderer(for preset: OverlayPreset) -> Bool {
        // For POC: Use SwiftUI for specific test presets
        let useSwiftUI = preset.id == "swiftui-demo" || preset.id == "simple-components" || preset.id == "swiftui-demo-2"
        logger.debug("🔍 [SwiftUI POC] Checking preset '\(preset.name)' (id: '\(preset.id)') -> SwiftUI: \(useSwiftUI)")
        return useSwiftUI
    }
}

// MARK: - Demo SwiftUI Preset

extension OverlayPreset {
    /// Demo preset that will be rendered using SwiftUI
    static let swiftUIDemo: OverlayPreset = {
        // Empty nodes array since we're not using the Core Graphics pipeline
        let nodes: [OverlayNode] = []
        
        // Empty layout since SwiftUI handles positioning
        let layout = OverlayLayout(
            widescreen: [],
            fourThree: []
        )
        
        return OverlayPreset(
            id: "swiftui-demo",
            name: "SwiftUI Demo",
            nodes: nodes,
            layout: layout
        )
    }()
    
    /// Flashy Bonusly-branded SwiftUI preset
    static let swiftUIDemo2: OverlayPreset = {
        // Empty nodes array since we're not using the Core Graphics pipeline
        let nodes: [OverlayNode] = []
        
        // Empty layout since SwiftUI handles positioning
        let layout = OverlayLayout(
            widescreen: [],
            fourThree: []
        )
        
        return OverlayPreset(
            id: "swiftui-demo-2",
            name: "SwiftUI Flashy",
            nodes: nodes,
            layout: layout
        )
    }()
}
