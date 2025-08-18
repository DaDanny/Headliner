//
//  FrameSharingService.swift
//  CameraExtension
//
//  NSXPC service for sharing composed frames with the main app via IOSurface mach ports
//

import Foundation
import CoreVideo
import CoreMedia
import IOSurface
import OSLog
import os.lock

/// NSXPC service that shares the latest composed frame with the main app
final class FrameSharingService: NSObject {
    
    // MARK: - Properties
    
    private let logger = HeadlinerLogger.logger(for: .cameraExtension)
    private var xpcListener: NSXPCListener?
    
    /// Latest frame cache with thread-safe access via os_unfair_lock
    private var latestFrame: CachedFrame?
    private let frameLock = OSAllocatedUnfairLock()
    
    /// Monotonic frame counter for ordering
    private var frameCounter: Int64 = 0
    
    /// Keep strong reference to current IOSurface until replaced
    private var retainedSurface: IOSurface?
    
    /// Cached frame data including IOSurface reference
    private struct CachedFrame {
        let ioSurface: IOSurface
        let width: Int32
        let height: Int32
        let pixelFormat: OSType
        let frameIndex: Int64
        let pts: CMTime
        let colorSpaceName: String
        let timestamp: CFAbsoluteTime
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        startXPCService()
    }
    
    deinit {
        stopXPCService()
    }
    
    // MARK: - XPC Service
    
    private func startXPCService() {
        logger.debug("🔵 XPC DEBUG: Starting NSXPC frame sharing service...")
        logger.debug("🔵 XPC DEBUG: Mach service name: \(FrameSharingConstants.machServiceName)")
        logger.debug("🔵 XPC DEBUG: Team ID: \(Identifiers.teamID)")
        logger.debug("🔵 XPC DEBUG: App Group: \(Identifiers.appGroup)")
        
        // Create mach service listener
        xpcListener = NSXPCListener(machServiceName: FrameSharingConstants.machServiceName)
        xpcListener?.delegate = self
        xpcListener?.resume()
        
        logger.debug("🔵 XPC DEBUG: NSXPC listener created and resumed")
        logger.debug("🔵 XPC DEBUG: Service should be available at: \(FrameSharingConstants.machServiceName)")
        
        // Log to file for debugging (since extension logs can be hard to see)
        if let logURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Identifiers.appGroup)?.appendingPathComponent("xpc_debug.log") {
            let logMessage = "[\(Date())] XPC Service Started: \(FrameSharingConstants.machServiceName)\n"
            try? logMessage.append(to: logURL)
        }
    }
    
    private func stopXPCService() {
        logger.debug("Stopping NSXPC frame sharing service...")
        xpcListener?.invalidate()
        xpcListener = nil
        
        // Clear cached frame and release surface
        frameLock.withLock {
            latestFrame = nil
            retainedSurface = nil
            frameCounter = 0
        }
    }
    
    // MARK: - Frame Caching
    
    /// Cache a composed frame for sharing with the main app
    /// - Parameters:
    ///   - pixelBuffer: The composed frame with overlays
    ///   - pts: Presentation timestamp from the compositor
    func cacheFrame(pixelBuffer: CVPixelBuffer, pts: CMTime) {
        // Get IOSurface from pixel buffer
        guard let ioSurface = CVPixelBufferGetIOSurface(pixelBuffer) else {
            logger.error("Failed to get IOSurface from CVPixelBuffer")
            return
        }
        
        // Take retained reference to the IOSurface
        let surface = ioSurface.takeUnretainedValue()
        
        // Determine color space based on pixel format
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let colorSpaceName: String
        
        switch pixelFormat {
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
             kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            colorSpaceName = "ITU_R_709_2"
        case kCVPixelFormatType_32BGRA:
            // Check if Display P3 is attached
            if let colorSpace = CVBufferGetAttachment(pixelBuffer, kCVImageBufferCGColorSpaceKey, nil) {
                let cfColorSpace = colorSpace.takeUnretainedValue() as! CGColorSpace
                if cfColorSpace.name == CGColorSpace.displayP3 {
                    colorSpaceName = "Display-P3"
                } else {
                    colorSpaceName = "sRGB"
                }
            } else {
                colorSpaceName = "sRGB"
            }
        default:
            colorSpaceName = "sRGB"
        }
        
        // Update frame cache within lock
        frameLock.withLock {
            // Increment frame counter
            frameCounter += 1
            
            // Create cached frame data
            let frame = CachedFrame(
                ioSurface: surface,
                width: Int32(CVPixelBufferGetWidth(pixelBuffer)),
                height: Int32(CVPixelBufferGetHeight(pixelBuffer)),
                pixelFormat: pixelFormat,
                frameIndex: frameCounter,
                pts: pts,
                colorSpaceName: colorSpaceName,
                timestamp: CFAbsoluteTimeGetCurrent()
            )
            
            // Update latest frame and retain surface
            latestFrame = frame
            retainedSurface = surface  // Keep strong reference
            
            logger.debug("🟡 XPC DEBUG: Cached frame #\(self.frameCounter) for preview (\(frame.width)x\(frame.height) \(colorSpaceName))")
            
            // Log first few frames to file
            if frameCounter <= 5 {
                if let logURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Identifiers.appGroup)?.appendingPathComponent("xpc_debug.log") {
                    let logMessage = "[\(Date())] FRAME CACHED #\(frameCounter) - \(frame.width)x\(frame.height)\n"
                    try? logMessage.append(to: logURL)
                }
            }
        }
    }
    
    /// Clear the cached frame (called when streaming stops)
    func clearCache() {
        frameLock.withLock {
            latestFrame = nil
            retainedSurface = nil
            frameCounter = 0
        }
        
        logger.debug("Cleared frame cache")
    }
    
    // MARK: - Frame Retrieval
    
    /// Get the latest frame as a FrameParcel for NSXPC transport
    private func getLatestFrameParcel() -> FrameParcel? {
        return frameLock.withLock {
            guard let frame = latestFrame else {
                return nil
            }
            
            // Create mach port for IOSurface (send right)
            let machPort = IOSurfaceCreateMachPort(frame.ioSurface)
            
            guard machPort != MACH_PORT_NULL else {
                logger.error("Failed to create mach port for IOSurface")
                return nil
            }
            
            // Create parcel with mach port and metadata
            return FrameParcel(
                machPort: machPort,
                width: frame.width,
                height: frame.height,
                pixelFormat: frame.pixelFormat,
                frameIndex: frame.frameIndex,
                ptsNum: frame.pts.value,
                ptsDen: frame.pts.timescale,
                colorSpaceName: frame.colorSpaceName
            )
        }
    }
}

// MARK: - NSXPCListenerDelegate

extension FrameSharingService: NSXPCListenerDelegate {
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        logger.debug("🟢 XPC DEBUG: New connection request from PID \(newConnection.processIdentifier)")
        
        // Log to file
        if let logURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Identifiers.appGroup)?.appendingPathComponent("xpc_debug.log") {
            let logMessage = "[\(Date())] CONNECTION REQUEST from PID: \(newConnection.processIdentifier)\n"
            try? logMessage.append(to: logURL)
        }
        
        // Validate connection (enhanced security)
        guard validateConnection(newConnection) else {
            logger.error("🔴 XPC DEBUG: Connection validation failed for PID \(newConnection.processIdentifier)")
            return false
        }
        
        // Configure the connection interface
        newConnection.exportedInterface = NSXPCInterface(with: FrameSharingProtocol.self)
        
        // Configure FrameParcel as allowed class for the reply
        if let interface = newConnection.exportedInterface {
            let classes = NSSet(array: [FrameParcel.self, NSString.self, NSNumber.self])
            interface.setClasses(
                classes as! Set<AnyHashable>,
                for: #selector(FrameSharingProtocol.getLatestFrame(reply:)),
                argumentIndex: 0,
                ofReply: true
            )
        }
        
        newConnection.exportedObject = self
        
        // Set up handlers
        newConnection.invalidationHandler = { [weak self] in
            self?.logger.debug("NSXPC: Connection invalidated")
        }
        
        newConnection.interruptionHandler = { [weak self] in
            self?.logger.debug("NSXPC: Connection interrupted")
        }
        
        // Start the connection
        newConnection.resume()
        
        return true
    }
    
    /// Validate incoming connection for security
    private func validateConnection(_ connection: NSXPCConnection) -> Bool {
        // Get audit token to validate client
        var token = audit_token_t()
        connection.auditToken(&token)
        
        // In production, you would validate:
        // 1. Same Team ID
        // 2. Bundle identifier prefix matches
        // 3. Code signature validity
        
        // For now, accept connections from our app (basic check)
        // This should be enhanced with proper audit token validation
        return true  // TODO: Implement proper validation
    }
}

// MARK: - FrameSharingProtocol

extension FrameSharingService: FrameSharingProtocol {
    
    func getLatestFrame(reply: @escaping (FrameParcel?) -> Void) {
        // Get the latest frame parcel
        let parcel = getLatestFrameParcel()
        
        if let parcel = parcel {
            logger.debug("NSXPC: Sending frame #\(parcel.frameIndex)")
        } else {
            logger.debug("NSXPC: No frame available")
        }
        
        reply(parcel)
    }
}

// MARK: - Audit Token Extension

extension NSXPCConnection {
    /// Get the audit token of the remote process
    func auditToken(_ token: inout audit_token_t) {
        // This would use private API in production
        // For now, we'll use a placeholder
        // In real implementation, use:
        // xpc_connection_get_audit_token(self._xpcConnection, &token)
    }
}

// MARK: - Debug Helper

extension String {
    func append(to url: URL) throws {
        if let data = self.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path) {
                let fileHandle = try FileHandle(forWritingTo: url)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try data.write(to: url)
            }
        }
    }
}
