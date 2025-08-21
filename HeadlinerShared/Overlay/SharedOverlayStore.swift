import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers

public enum SharedOverlayStore {
    private static let logger = HeadlinerLogger.logger(for: .overlays)
    // App Group identifier from shared identifiers
    static let appGroupId = Identifiers.appGroup

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        else { fatalError("App Group not configured: \(appGroupId)") }
        return url
    }

    /// Path of the current overlay PNG (premultiplied BGRA, sRGB, transparent)
    public static var currentOverlayURL: URL { 
        containerURL.appendingPathComponent("overlay/current.png") 
    }

    /// Atomically write CGImage to the current overlay path
    public static func writeOverlay(_ image: CGImage) throws {
        logger.debug("📝 [SharedStore] Starting write of \(image.width)x\(image.height) overlay to App Group")
        let dir = currentOverlayURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dst = currentOverlayURL
        let tmp = containerURL.appendingPathComponent("overlay/current.tmp")

        logger.debug("📝 [SharedStore] Writing to path: \(dst.path)")
        guard let dest = CGImageDestinationCreateWithURL(tmp as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { 
            logger.debug("❌ [SharedStore] Failed to create image destination")
            throw NSError(domain: "SharedOverlayStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"]) 
        }

        CGImageDestinationAddImage(dest, image, [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyPNGInterlaceType: 0
            ]
        ] as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            logger.debug("❌ [SharedStore] Failed to finalize image destination")
            throw NSError(domain: "SharedOverlayStore", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize image destination"])
        }

        logger.debug("📝 [SharedStore] PNG finalized, performing atomic replace...")
        // Atomic replace
        if FileManager.default.fileExists(atPath: dst.path) { 
            try FileManager.default.removeItem(at: dst) 
        }
        try FileManager.default.moveItem(at: tmp, to: dst)
        logger.debug("✅ [SharedStore] Successfully wrote overlay to App Group at \(dst.path)")
    }

    /// Load overlay CGImage if present
    public static func readOverlay() -> CGImage? {
        guard FileManager.default.fileExists(atPath: currentOverlayURL.path) else { 
            logger.debug("📖 [SharedStore] No overlay file exists at \(currentOverlayURL.path)")
            return nil 
        }
        
        guard let src = CGImageSourceCreateWithURL(currentOverlayURL as CFURL, nil) else { 
            logger.debug("❌ [SharedStore] Failed to create image source from \(currentOverlayURL.path)")
            return nil 
        }
        
        guard let image = CGImageSourceCreateImageAtIndex(src, 0, [kCGImageSourceShouldCache: true] as CFDictionary) else {
            let status = CGImageSourceGetStatus(src)
            logger.debug("❌ [SharedStore] Failed to create image from source (status: \(status.rawValue))")
            return nil
        }
        
        return image
    }
    
    /// Clear the current overlay
    public static func clearOverlay() {
        logger.debug("🗑️ [SharedStore] Clearing overlay at \(currentOverlayURL.path)")
        try? FileManager.default.removeItem(at: currentOverlayURL)
        logger.debug("✅ [SharedStore] Overlay cleared from App Group")
    }
}
