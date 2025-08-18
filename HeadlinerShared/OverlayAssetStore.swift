//
//  OverlayAssetStore.swift
//  HeadlinerShared
//
//  Manages overlay assets and metadata in App Group storage.
//

import Foundation
import CoreImage
import OSLog

// MARK: - Overlay Metadata

/// Metadata for overlay assets stored in App Group
struct OverlayMetadata: Codable {
    let version: Int
    let presetID: String
    let aspectBucket: String
    let width: Int
    let height: Int
    let colorSpace: String
    let updatedAt: String // ISO8601 timestamp
    let hash: String // SHA-256 of image bytes
    
    init(
        version: Int,
        presetID: String,
        aspectBucket: String,
        width: Int,
        height: Int,
        colorSpace: String = "sRGB",
        hash: String
    ) {
        self.version = version
        self.presetID = presetID
        self.aspectBucket = aspectBucket
        self.width = width
        self.height = height
        self.colorSpace = colorSpace
        self.hash = hash
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - Overlay Asset Store

/// Manages overlay assets in App Group storage with atomic operations and caching
final class OverlayAssetStore {
    
    // MARK: - Properties
    
    private let logger = HeadlinerLogger.logger(for: .overlayStore)
    
    /// App Group container URL
    private let appGroupURL: URL
    
    /// Directory for overlay assets
    private let overlayDir: URL
    
    /// Current overlay image file
    private let overlayImageURL: URL
    
    /// Current overlay metadata file
    private let overlayMetaURL: URL
    
    /// File manager instance
    private let fileManager = FileManager.default
    
    /// Queue for thread-safe file operations
    private let fileQueue = DispatchQueue(label: "OverlayAssetStore.fileQueue", qos: .utility)
    
    // MARK: - Initialization
    
    init?() {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Identifiers.appGroup) else {
            return nil
        }
        
        self.appGroupURL = appGroupURL
        self.overlayDir = appGroupURL.appending(path: "overlay")
        self.overlayImageURL = overlayDir.appending(path: "overlay.png")
        self.overlayMetaURL = overlayDir.appending(path: "overlay.json")
        
        // Ensure overlay directory exists
        try? fileManager.createDirectory(at: overlayDir, withIntermediateDirectories: true)
        
        logger.debug("OverlayAssetStore initialized with overlay directory: \(self.overlayDir.path)")
    }
    
    // MARK: - Write Operations
    
    /// Write overlay image and metadata atomically
    /// - Parameters:
    ///   - pngData: PNG image data with transparency
    ///   - metadata: Overlay metadata
    /// - Returns: Success status
    @discardableResult
    func writeOverlay(pngData: Data, metadata: OverlayMetadata) -> Bool {
        return fileQueue.sync {
            do {
                // Create temporary files for atomic write
                let tempImageURL = overlayImageURL.appendingPathExtension("tmp")
                let tempMetaURL = overlayMetaURL.appendingPathExtension("tmp")
                
                // Write image data
                try pngData.write(to: tempImageURL)
                
                // Write metadata
                let jsonData = try JSONEncoder().encode(metadata)
                try jsonData.write(to: tempMetaURL)
                
                // Atomic move - both files or neither
                try fileManager.moveItem(at: tempImageURL, to: overlayImageURL)
                try fileManager.moveItem(at: tempMetaURL, to: overlayMetaURL)
                
                logger.info("Successfully wrote overlay: \(metadata.presetID) (\(metadata.hash.prefix(8)))")
                return true
                
            } catch {
                logger.error("Failed to write overlay: \(error.localizedDescription)")
                
                // Clean up any partial writes
                try? fileManager.removeItem(at: overlayImageURL.appendingPathExtension("tmp"))
                try? fileManager.removeItem(at: overlayMetaURL.appendingPathExtension("tmp"))
                
                return false
            }
        }
    }
    
    /// Write overlay from CIImage
    /// - Parameters:
    ///   - ciImage: Core Image with transparency
    ///   - metadata: Overlay metadata
    /// - Returns: Success status
    @discardableResult
    func writeOverlay(ciImage: CIImage, metadata: OverlayMetadata) -> Bool {
        // Convert CIImage to PNG data
        guard let pngData = ciImageToPNGData(ciImage) else {
            logger.error("Failed to convert CIImage to PNG data")
            return false
        }
        
        return writeOverlay(pngData: pngData, metadata: metadata)
    }
    
    // MARK: - Read Operations
    
    /// Read current overlay metadata
    /// - Returns: Overlay metadata if available and valid
    func readOverlayMeta() -> OverlayMetadata? {
        return fileQueue.sync {
            do {
                let data = try Data(contentsOf: overlayMetaURL)
                let metadata = try JSONDecoder().decode(OverlayMetadata.self, from: data)
                return metadata
            } catch {
                // Not an error - might just be first run
                logger.debug("No overlay metadata found: \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    /// Read current overlay image as CIImage
    /// - Returns: CIImage if available and valid
    func readOverlayImage() -> CIImage? {
        return fileQueue.sync {
            do {
                let data = try Data(contentsOf: overlayImageURL)
                return CIImage(data: data)
            } catch {
                logger.debug("No overlay image found: \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    /// Read current overlay image as raw PNG data
    /// - Returns: PNG data if available
    func readOverlayPNGData() -> Data? {
        return fileQueue.sync {
            do {
                return try Data(contentsOf: overlayImageURL)
            } catch {
                logger.debug("No overlay PNG data found: \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    /// Check if current overlay matches the given hash
    /// - Parameter expectedHash: SHA-256 hash to compare against
    /// - Returns: True if overlay exists and hash matches
    func isOverlayCurrent(expectedHash: String) -> Bool {
        guard let metadata = readOverlayMeta() else {
            return false
        }
        return metadata.hash == expectedHash
    }
    
    // MARK: - Clear Operations
    
    /// Clear current overlay (for "no overlay" state)
    /// - Returns: Success status
    @discardableResult
    func clearOverlay() -> Bool {
        return fileQueue.sync {
            do {
                // Remove both files if they exist
                try? fileManager.removeItem(at: overlayImageURL)
                try? fileManager.removeItem(at: overlayMetaURL)
                
                logger.info("Successfully cleared overlay")
                return true
                
            } catch {
                logger.error("Failed to clear overlay: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert CIImage to PNG data
    private func ciImageToPNGData(_ ciImage: CIImage) -> Data? {
        let context = CIContext()
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent, format: .BGRA8, colorSpace: colorSpace) else {
            return nil
        }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.png" as CFString,
            1,
            nil
        ) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 1.0
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return mutableData as Data
    }
    
    /// Get overlay directory for debugging
    var debugOverlayDirectory: URL {
        overlayDir
    }
    
    /// Get current overlay file URLs for debugging
    var debugFileURLs: (image: URL, metadata: URL) {
        (overlayImageURL, overlayMetaURL)
    }
}

// MARK: - Logger Category Extension

extension HeadlinerLogger.Category {
    static let overlayStore = HeadlinerLogger.Category("OverlayStore")
}