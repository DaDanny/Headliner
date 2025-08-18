//
//  OverlayRenderService.swift
//  Headliner
//
//  Service for rasterizing SwiftUI overlays to images.
//

import SwiftUI
import CoreImage
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - Overlay Render Service

/// Service responsible for rasterizing SwiftUI overlay views to various image formats
final class OverlayRenderService {
    
    // MARK: - Properties
    
    /// Metal-backed Core Image context for optimal performance
    private let ciContext: CIContext
    
    /// sRGB color space for consistent color handling
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    
    // MARK: - Initialization
    
    init() {
        // Create Metal-backed CIContext if available, fallback to CPU
        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(
                mtlDevice: device,
                options: [
                    .workingColorSpace: NSNull(), // Linear color space for compositing
                    .outputColorSpace: colorSpace,
                    .priorityRequestLow: false,
                    .cacheIntermediates: true
                ]
            )
        } else {
            self.ciContext = CIContext(options: [
                .workingColorSpace: colorSpace,
                .outputColorSpace: colorSpace,
                .useSoftwareRenderer: true
            ])
        }
    }
    
    // MARK: - Main Rendering Methods
    
    /// Render SwiftUI overlay to CIImage
    /// - Parameter props: Overlay properties defining the content and styling
    /// - Returns: CIImage with transparency, ready for compositing, or nil on failure
    func renderCIImage(props: OverlayProps) -> CIImage? {
        return autoreleasepool {
            // Create SwiftUI view from catalog
            let overlayView = OverlayCatalog.view(for: props)
            
            // Configure ImageRenderer
            let renderer = ImageRenderer(content: overlayView)
            renderer.scale = props.scale
            renderer.isOpaque = false // Critical for transparency
            renderer.proposedSize = ProposedViewSize(
                width: props.targetResolution.width,
                height: props.targetResolution.height
            )
            
            // Render to CGImage
            guard let cgImage = renderer.cgImage else {
                return nil
            }
            
            // Wrap in CIImage with proper color space
            return CIImage(
                cgImage: cgImage,
                options: [
                    .colorSpace: colorSpace,
                    .applyOrientationProperty: false
                ]
            )
        }
    }
    
    /// Render SwiftUI overlay to PNG data
    /// - Parameter props: Overlay properties defining the content and styling
    /// - Returns: PNG data ready for file storage, or nil on failure
    func renderPNGData(props: OverlayProps) -> Data? {
        guard let ciImage = renderCIImage(props: props) else {
            return nil
        }
        
        return autoreleasepool {
            // Create PNG representation
            guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
                return nil
            }
            
            // Create PNG data
            let mutableData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                mutableData,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else {
                return nil
            }
            
            // Configure PNG options for transparency
            let options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: 1.0 // Max quality
            ]
            
            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
            guard CGImageDestinationFinalize(destination) else {
                return nil
            }
            
            return mutableData as Data
        }
    }
    
    /// Render SwiftUI overlay to raw BGRA bytes
    /// - Parameter props: Overlay properties defining the content and styling
    /// - Returns: Tuple containing BGRA bytes and metadata, or nil on failure
    func renderBGRABytes(props: OverlayProps) -> (data: Data, width: Int, height: Int, bytesPerRow: Int)? {
        guard let ciImage = renderCIImage(props: props) else {
            return nil
        }
        
        return autoreleasepool {
            let width = Int(props.targetResolution.width)
            let height = Int(props.targetResolution.height)
            let bytesPerRow = width * 4 // BGRA = 4 bytes per pixel
            
            // Create buffer for raw pixel data
            var pixelData = Data(count: bytesPerRow * height)
            
            return pixelData.withUnsafeMutableBytes { bytes in
                guard let baseAddress = bytes.baseAddress else {
                    return nil
                }
                
                // Render to raw pixel buffer
                ciContext.render(
                    ciImage,
                    toBitmap: baseAddress,
                    rowBytes: bytesPerRow,
                    bounds: CGRect(x: 0, y: 0, width: width, height: height),
                    format: .BGRA8, // Premultiplied BGRA
                    colorSpace: colorSpace
                )
                
                return (data: pixelData, width: width, height: height, bytesPerRow: bytesPerRow)
            }
        }
    }
    
    /// Render SwiftUI overlay to CVPixelBuffer (for future IOSurface support)
    /// - Parameter props: Overlay properties defining the content and styling
    /// - Returns: CVPixelBuffer ready for zero-copy sharing, or nil on failure
    func renderPixelBuffer(props: OverlayProps) -> CVPixelBuffer? {
        guard let ciImage = renderCIImage(props: props) else {
            return nil
        }
        
        return autoreleasepool {
            let width = Int(props.targetResolution.width)
            let height = Int(props.targetResolution.height)
            
            // Create pixel buffer attributes for IOSurface compatibility
            let attributes: [CFString: Any] = [
                kCVPixelBufferWidthKey: width,
                kCVPixelBufferHeightKey: height,
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
                kCVPixelBufferMetalCompatibilityKey: true
            ]
            
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_32BGRA,
                attributes as CFDictionary,
                &pixelBuffer
            )
            
            guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
                return nil
            }
            
            // Render to pixel buffer
            ciContext.render(ciImage, to: buffer)
            
            return buffer
        }
    }
}

// MARK: - Render Cache

/// Simple cache for rendered overlays to avoid redundant rasterization
final class OverlayRenderCache {
    
    private struct CacheKey: Hashable {
        let propsHash: Int
        let aspectBucket: String
        
        init(props: OverlayProps) {
            self.propsHash = props.hashValue
            self.aspectBucket = props.aspectBucket.rawValue
        }
    }
    
    private struct CachedResult {
        let imageHash: String
        let pngData: Data
        let timestamp: Date
    }
    
    private var cache: [CacheKey: CachedResult] = [:]
    private let maxCacheSize = 20
    private let cacheQueue = DispatchQueue(label: "OverlayRenderCache", qos: .utility)
    
    /// Get cached PNG data if available and still valid
    func getCachedPNG(for props: OverlayProps) -> Data? {
        let key = CacheKey(props: props)
        
        return cacheQueue.sync {
            guard let cached = cache[key] else {
                return nil
            }
            
            // Check if cache entry is still fresh (1 hour)
            if Date().timeIntervalSince(cached.timestamp) > 3600 {
                cache.removeValue(forKey: key)
                return nil
            }
            
            return cached.pngData
        }
    }
    
    /// Cache PNG data for future use
    func cachePNG(_ data: Data, for props: OverlayProps) {
        let key = CacheKey(props: props)
        let imageHash = data.sha256
        let cached = CachedResult(imageHash: imageHash, pngData: data, timestamp: Date())
        
        cacheQueue.async { [weak self] in
            self?.cache[key] = cached
            
            // LRU eviction if over capacity
            if let strongSelf = self, strongSelf.cache.count > strongSelf.maxCacheSize {
                let sortedEntries = strongSelf.cache.sorted { $0.value.timestamp < $1.value.timestamp }
                let toRemove = sortedEntries.prefix(strongSelf.cache.count - strongSelf.maxCacheSize)
                for (key, _) in toRemove {
                    strongSelf.cache.removeValue(forKey: key)
                }
            }
        }
    }
    
    /// Clear all cached entries
    func clearCache() {
        cacheQueue.async { [weak self] in
            self?.cache.removeAll()
        }
    }
}

// MARK: - Data Extension for SHA256

extension Data {
    var sha256: String {
        let digest = self.withUnsafeBytes { bytes in
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(self.count), &digest)
            return digest
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// Import for SHA256
import CommonCrypto