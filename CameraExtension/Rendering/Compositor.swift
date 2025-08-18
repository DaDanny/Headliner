//
//  Compositor.swift
//  CameraExtension
//
//  Composites SwiftUI overlays over camera frames.
//

import CoreImage
import CoreVideo
import CoreGraphics
import OSLog

// MARK: - SwiftUI Overlay Compositor

/// High-performance compositor for SwiftUI overlays over camera frames
final class SwiftUIOverlayCompositor {
    
    // MARK: - Properties
    
    private let logger = HeadlinerLogger.logger(for: .compositor)
    
    /// Core Image context for GPU acceleration
    private let ciContext: CIContext
    
    /// sRGB color space for consistent output
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    
    /// Overlay cache instance
    private let overlayCache: OverlayCache
    
    /// Source over compositing filter (reused for performance)
    private let sourceOverFilter = CIFilter(name: "CISourceOverCompositing")!
    
    // MARK: - Initialization
    
    init(overlayCache: OverlayCache) {
        self.overlayCache = overlayCache
        
        // Reuse the same CIContext from the overlay cache for efficiency
        self.ciContext = overlayCache.ciContext
        
        logger.debug("SwiftUI overlay compositor initialized")
    }
    
    // MARK: - Main Compositing Method
    
    /// Composite overlay over camera frame
    /// - Parameters:
    ///   - cameraFrame: Input camera frame as CIImage
    ///   - frameSize: Expected output frame size
    /// - Returns: Composited image with overlay, or original frame if no overlay
    func compose(cameraFrame: CIImage, frameSize: CGSize? = nil) -> CIImage {
        // Get current overlay from cache (thread-safe)
        guard let overlayImage = overlayCache.currentCIImage else {
            // No overlay - return camera frame as-is
            return cameraFrame
        }
        
        return autoreleasepool {
            // Ensure both images are in the same coordinate system
            let processedCamera = ensureCompatibleColorSpace(cameraFrame)
            let processedOverlay = ensureCompatibleColorSpace(overlayImage)
            
            // Handle size/aspect differences if needed
            let alignedOverlay = alignOverlayToCamera(
                overlay: processedOverlay,
                cameraFrame: processedCamera,
                targetSize: frameSize
            )
            
            // Perform source-over compositing (overlay over camera)
            sourceOverFilter.setValue(processedCamera, forKey: kCIInputBackgroundImageKey)
            sourceOverFilter.setValue(alignedOverlay, forKey: kCIInputImageKey)
            
            guard let result = sourceOverFilter.outputImage else {
                logger.warning("Source over compositing failed - returning original camera frame")
                return processedCamera
            }
            
            // Crop to camera frame extent to prevent edge artifacts
            return result.cropped(to: processedCamera.extent)
        }
    }
    
    /// Composite overlay over camera frame from pixel buffer (convenience method)
    /// - Parameters:
    ///   - pixelBuffer: Input camera frame as CVPixelBuffer
    ///   - frameSize: Expected output frame size
    /// - Returns: Composited image with overlay, or original frame if no overlay
    func compose(pixelBuffer: CVPixelBuffer, frameSize: CGSize? = nil) -> CIImage {
        let cameraFrame = CIImage(
            cvPixelBuffer: pixelBuffer,
            options: [.colorSpace: colorSpace]
        )
        return compose(cameraFrame: cameraFrame, frameSize: frameSize)
    }
    
    // MARK: - Image Processing Helpers
    
    /// Ensure image has compatible color space for compositing
    private func ensureCompatibleColorSpace(_ image: CIImage) -> CIImage {
        // Convert to sRGB if needed
        if image.colorSpace != colorSpace {
            return image.matchedToWorkingSpace(from: image.colorSpace ?? colorSpace)
        }
        return image
    }
    
    /// Align overlay to camera frame, handling size/aspect differences
    private func alignOverlayToCamera(
        overlay: CIImage,
        cameraFrame: CIImage,
        targetSize: CGSize?
    ) -> CIImage {
        let cameraExtent = cameraFrame.extent
        let overlayExtent = overlay.extent
        
        // Use target size if provided, otherwise use camera frame size
        let targetFrameSize = targetSize ?? cameraExtent.size
        
        // Check if overlay size matches expected output
        if abs(overlayExtent.width - targetFrameSize.width) < 1.0 &&
           abs(overlayExtent.height - targetFrameSize.height) < 1.0 {
            // Overlay is already the right size - just position it
            return overlay.transformed(by: CGAffineTransform(
                translationX: cameraExtent.minX - overlayExtent.minX,
                y: cameraExtent.minY - overlayExtent.minY
            ))
        }
        
        // Overlay needs scaling - calculate transform
        let scaleX = targetFrameSize.width / overlayExtent.width
        let scaleY = targetFrameSize.height / overlayExtent.height
        
        // Apply scaling and positioning transform
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            .concatenating(CGAffineTransform(
                translationX: cameraExtent.minX,
                y: cameraExtent.minY
            ))
        
        let scaledOverlay = overlay.transformed(by: transform)
        
        logger.debug("Scaled overlay from \(overlayExtent.size) to \(targetFrameSize) for camera frame \(cameraExtent.size)")
        
        return scaledOverlay
    }
    
    // MARK: - Performance Monitoring
    
    /// Get performance statistics
    var performanceStats: [String: Any] {
        [
            "hasOverlay": overlayCache.currentCIImage != nil,
            "overlayHash": overlayCache.currentHash.isEmpty ? "none" : String(overlayCache.currentHash.prefix(8)),
            "cacheInfo": overlayCache.debugInfo
        ]
    }
    
    // MARK: - Notification Handling
    
    /// Handle overlay update notification (refresh cache)
    func handleOverlayUpdated() {
        logger.debug("Received overlay updated notification")
        overlayCache.loadFromDiskIfChanged()
    }
    
    /// Handle overlay cleared notification (clear cache)
    func handleOverlayCleared() {
        logger.debug("Received overlay cleared notification")
        overlayCache.clearOverlay()
    }
}

// MARK: - Logger Category Extension

extension HeadlinerLogger.Category {
    static let compositor = HeadlinerLogger.Category("Compositor")
}

// MARK: - Extensions

extension CGSize {
    var debugDescription: String {
        return "\(Int(width))x\(Int(height))"
    }
}