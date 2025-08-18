//
//  OverlayCache.swift
//  CameraExtension
//
//  Cache for SwiftUI overlay images loaded from App Group storage.
//

import CoreImage
import Foundation
import OSLog

// MARK: - Overlay Cache

/// Thread-safe cache for overlay images loaded from App Group storage
final class OverlayCache {
    
    // MARK: - Properties
    
    private let logger = HeadlinerLogger.logger(for: .overlayCache)
    
    /// Metal-backed Core Image context for optimal performance
    let ciContext: CIContext
    
    /// Currently cached overlay image
    private var _currentCIImage: CIImage?
    
    /// Hash of currently cached overlay for change detection
    private var _currentHash: String = ""
    
    /// Aspect bucket of currently cached overlay
    private var _currentAspectBucket: String = ""
    
    /// Timestamp when overlay was last loaded
    private var _lastLoadTime: CFTimeInterval = 0
    
    /// Thread synchronization
    private let queue = DispatchQueue(label: "OverlayCache", qos: .userInteractive)
    
    /// App Group overlay asset store
    private let assetStore: OverlayAssetStore?
    
    // MARK: - Initialization
    
    init() {
        // Create Metal-backed CIContext for GPU acceleration
        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(
                mtlDevice: device,
                options: [
                    .workingColorSpace: NSNull(), // Linear for compositing
                    .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                    .priorityRequestLow: false,
                    .cacheIntermediates: true
                ]
            )
            logger.debug("Created Metal-backed CIContext for overlay cache")
        } else {
            self.ciContext = CIContext(options: [
                .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                .useSoftwareRenderer: true
            ])
            logger.debug("Created CPU CIContext for overlay cache (Metal unavailable)")
        }
        
        // Initialize asset store
        self.assetStore = OverlayAssetStore()
        if assetStore == nil {
            logger.error("Failed to initialize OverlayAssetStore - overlays will be disabled")
        }
    }
    
    // MARK: - Public Interface (Thread-Safe)
    
    /// Current overlay image (thread-safe access)
    var currentCIImage: CIImage? {
        return queue.sync { _currentCIImage }
    }
    
    /// Current overlay hash (thread-safe access)
    var currentHash: String {
        return queue.sync { _currentHash }
    }
    
    /// Current aspect bucket (thread-safe access) 
    var currentAspectBucket: String {
        return queue.sync { _currentAspectBucket }
    }
    
    /// Check if overlay has been loaded recently
    var hasRecentOverlay: Bool {
        return queue.sync {
            let timeSinceLoad = CFAbsoluteTimeGetCurrent() - _lastLoadTime
            return timeSinceLoad < 300 && _currentCIImage != nil // 5 minutes
        }
    }
    
    // MARK: - Loading Operations
    
    /// Load overlay from disk if changed (call on notification or startup)
    func loadFromDiskIfChanged() {
        queue.async { [weak self] in
            guard let self = self,
                  let assetStore = self.assetStore else {
                return
            }
            
            // Read metadata to check for changes
            guard let metadata = assetStore.readOverlayMeta() else {
                // No overlay available - clear current if any
                if self._currentCIImage != nil {
                    self.logger.info("No overlay metadata found - clearing current overlay")
                    self._currentCIImage = nil
                    self._currentHash = ""
                    self._currentAspectBucket = ""
                }
                return
            }
            
            // Check if overlay has changed
            if metadata.hash == self._currentHash && 
               metadata.aspectBucket == self._currentAspectBucket {
                // No change - update timestamp and return
                self._lastLoadTime = CFAbsoluteTimeGetCurrent()
                return
            }
            
            // Load new overlay image
            guard let overlayImage = assetStore.readOverlayImage() else {
                self.logger.error("Failed to load overlay image despite valid metadata")
                return
            }
            
            // Optional: Transform overlay if aspect or size differs from expected
            let processedImage = self.processOverlayImage(overlayImage, metadata: metadata)
            
            // Update cache atomically
            self._currentCIImage = processedImage
            self._currentHash = metadata.hash
            self._currentAspectBucket = metadata.aspectBucket
            self._lastLoadTime = CFAbsoluteTimeGetCurrent()
            
            self.logger.info("Loaded new overlay: \(metadata.presetID) (\(metadata.hash.prefix(8))) \(metadata.width)x\(metadata.height)")
        }
    }
    
    /// Force reload overlay from disk (for debugging)
    func forceReload() {
        queue.async { [weak self] in
            self?._currentHash = "" // Force reload by clearing hash
            self?.loadFromDiskIfChanged()
        }
    }
    
    /// Clear current overlay (for "no overlay" state)
    func clearOverlay() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self._currentCIImage = nil
            self._currentHash = ""
            self._currentAspectBucket = ""
            self._lastLoadTime = 0
            
            self.logger.info("Cleared overlay cache")
        }
    }
    
    // MARK: - Private Processing
    
    /// Process loaded overlay image (resize, color space conversion, etc.)
    private func processOverlayImage(_ image: CIImage, metadata: OverlayMetadata) -> CIImage {
        var processedImage = image
        
        // Ensure color space consistency
        let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        if image.colorSpace != sRGBColorSpace {
            processedImage = processedImage.matchedToWorkingSpace(from: image.colorSpace ?? sRGBColorSpace)
        }
        
        // Note: We avoid resizing here since overlays should be pre-rendered at target resolution
        // If resizing is needed later for aspect ratio changes, we can cache transformed versions
        
        return processedImage
    }
    
    /// Get scaled overlay for different aspect ratios (future use)
    func getScaledOverlay(for targetSize: CGSize) -> CIImage? {
        guard let currentImage = currentCIImage else { return nil }
        
        let currentExtent = currentImage.extent
        let scaleX = targetSize.width / currentExtent.width
        let scaleY = targetSize.height / currentExtent.height
        
        // Only scale if significantly different to avoid quality loss
        if abs(scaleX - 1.0) > 0.1 || abs(scaleY - 1.0) > 0.1 {
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            return currentImage.transformed(by: transform)
        }
        
        return currentImage
    }
    
    // MARK: - Debug Information
    
    /// Get debug info about current cache state
    var debugInfo: [String: Any] {
        return queue.sync {
            [
                "hasOverlay": _currentCIImage != nil,
                "currentHash": _currentHash.isEmpty ? "none" : String(_currentHash.prefix(8)),
                "aspectBucket": _currentAspectBucket.isEmpty ? "none" : _currentAspectBucket,
                "lastLoadTime": _lastLoadTime,
                "timeSinceLoad": CFAbsoluteTimeGetCurrent() - _lastLoadTime,
                "imageExtent": _currentCIImage?.extent.debugDescription ?? "none"
            ]
        }
    }
}

// MARK: - Logger Category Extension

extension HeadlinerLogger.Category {
    static let overlayCache = HeadlinerLogger.Category("OverlayCache")
}