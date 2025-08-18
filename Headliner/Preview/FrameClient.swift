//
//  FrameClient.swift
//  Headliner
//
//  NSXPC client that fetches frames from the camera extension
//

import Foundation
import CoreVideo
import CoreMedia
import IOSurface
import OSLog

/// NSXPC client that connects to the camera extension's frame sharing service
final class FrameClient: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = HeadlinerLogger.logger(for: .application)
    private var xpcConnection: NSXPCConnection?
    private var service: FrameSharingProtocol?
    
    /// Observers for Darwin notifications (stored as raw pointers)
    private var frameAvailableObserver: UnsafeMutableRawPointer?
    private var streamStoppedObserver: UnsafeMutableRawPointer?
    
    /// Coalescing flag to prevent overlapping fetches
    private var isFetching = false
    private let fetchLock = NSLock()
    
    /// Fallback polling timer (only used when notifications fail)
    private var fallbackTimer: Timer?
    private var lastFrameTime: CFAbsoluteTime = 0
    private let fallbackPollingInterval: TimeInterval = 1.0 / 15.0  // 15Hz fallback
    private let fallbackThreshold: TimeInterval = 0.25  // 250ms
    
    /// Frame fetch callback
    var onFrameReceived: ((CVPixelBuffer, CMTime) -> Void)?
    var onStreamStopped: (() -> Void)?
    
    /// Connection state
    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    
    /// Retry logic
    private var retryCount = 0
    private let maxRetries = 5
    private var retryTimer: Timer?
    
    /// Format description cache
    private var formatDescriptionCache: [String: CMFormatDescription] = [:]
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
        // Delay initial connection attempt to allow extension to initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.connectToService()
        }
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - XPC Connection
    
    private func connectToService() {
        logger.debug("🔵 XPC CLIENT DEBUG: Attempting to connect to frame sharing service...")
        logger.debug("🔵 XPC CLIENT DEBUG: Mach service name: \(FrameSharingConstants.machServiceName)")
        logger.debug("🔵 XPC CLIENT DEBUG: Team ID: \(Identifiers.teamID)")
        logger.debug("🔵 XPC CLIENT DEBUG: App Group: \(Identifiers.appGroup)")
        
        // Log to file for debugging
        if let logURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Identifiers.appGroup)?.appendingPathComponent("xpc_client_debug.log") {
            let logMessage = "[\(Date())] CLIENT: Attempting connection to: \(FrameSharingConstants.machServiceName)\n"
            try? logMessage.write(to: logURL, atomically: true, encoding: .utf8)
        }
        
        // Create NSXPC connection using mach service name
        xpcConnection = NSXPCConnection(machServiceName: FrameSharingConstants.machServiceName)
        
        guard let connection = xpcConnection else {
            logger.error("🔴 XPC CLIENT DEBUG: Failed to create NSXPC connection")
            connectionError = "Failed to create connection"
            scheduleRetry()
            return
        }
        
        // Configure the connection interface
        connection.remoteObjectInterface = NSXPCInterface(with: FrameSharingProtocol.self)
        
        // Configure FrameParcel as allowed class for the reply
        if let interface = connection.remoteObjectInterface {
            let classes = NSSet(array: [FrameParcel.self, NSString.self, NSNumber.self])
            interface.setClasses(
                classes as! Set<AnyHashable>,
                for: #selector(FrameSharingProtocol.getLatestFrame(reply:)),
                argumentIndex: 0,
                ofReply: true
            )
        }
        
        // Set up handlers
        connection.invalidationHandler = { [weak self] in
            self?.logger.debug("NSXPC connection invalidated")
            self?.handleConnectionInvalidated()
        }
        
        connection.interruptionHandler = { [weak self] in
            self?.logger.debug("NSXPC connection interrupted")
            self?.handleConnectionInterrupted()
        }
        
        // Start the connection
        connection.resume()
        
        // Get the remote service proxy with timeout
        let proxy = connection.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.logger.error("NSXPC proxy error: \(error.localizedDescription)")
            self?.connectionError = error.localizedDescription
            self?.scheduleRetry()
        }
        
        service = proxy as? FrameSharingProtocol
        
        if service != nil {
            logger.debug("🟢 XPC CLIENT DEBUG: Successfully connected to frame sharing service!")
            isConnected = true
            connectionError = nil
            retryCount = 0
            
            // Log successful connection
            if let logURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Identifiers.appGroup)?.appendingPathComponent("xpc_client_debug.log") {
                let logMessage = "[\(Date())] CLIENT: CONNECTED SUCCESSFULLY!\n"
                try? logMessage.append(to: logURL)
            }
            
            // Start with a test fetch to verify connection
            fetchLatestFrame()
        } else {
            logger.error("🔴 XPC CLIENT DEBUG: Service proxy is nil")
        }
    }
    
    private func disconnect() {
        logger.debug("Disconnecting from frame sharing service...")
        
        // Remove notification observers
        if let observer = frameAvailableObserver {
            CFNotificationCenterRemoveObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                observer,
                nil,
                nil
            )
            frameAvailableObserver = nil
        }
        
        if let observer = streamStoppedObserver {
            CFNotificationCenterRemoveObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                observer,
                nil,
                nil
            )
            streamStoppedObserver = nil
        }
        
        // Stop timers
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        retryTimer?.invalidate()
        retryTimer = nil
        
        // Close XPC connection
        xpcConnection?.invalidate()
        xpcConnection = nil
        service = nil
        isConnected = false
    }
    
    // MARK: - Connection Handling
    
    private func handleConnectionInvalidated() {
        isConnected = false
        service = nil
        scheduleRetry()
    }
    
    private func handleConnectionInterrupted() {
        // Connection interrupted but may recover
        isConnected = false
        scheduleRetry()
    }
    
    private func scheduleRetry() {
        guard retryCount < maxRetries else {
            logger.error("Max retries reached, giving up")
            connectionError = "Unable to connect to camera extension"
            return
        }
        
        retryCount += 1
        let delay = min(pow(2.0, Double(retryCount - 1)), 30.0)  // Exponential backoff, max 30s
        
        logger.debug("Scheduling retry #\(self.retryCount) in \(delay) seconds")
        
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connectToService()
        }
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        
        // Observe frameAvailable notification
        let observer1 = Unmanaged.passUnretained(self).toOpaque()
        frameAvailableObserver = observer1
        CFNotificationCenterAddObserver(
            center,
            observer1,
            { _, observer, name, _, _ in
                guard let observer = observer else { return }
                let client = Unmanaged<FrameClient>.fromOpaque(observer).takeUnretainedValue()
                client.handleFrameAvailable()
            },
            NotificationName.frameAvailable.rawValue as CFString,
            nil,
            .deliverImmediately
        )
        
        // Observe streamStopped notification
        let observer2 = Unmanaged.passUnretained(self).toOpaque()
        streamStoppedObserver = observer2
        CFNotificationCenterAddObserver(
            center,
            observer2,
            { _, observer, name, _, _ in
                guard let observer = observer else { return }
                let client = Unmanaged<FrameClient>.fromOpaque(observer).takeUnretainedValue()
                client.handleStreamStopped()
            },
            NotificationName.streamStopped.rawValue as CFString,
            nil,
            .deliverImmediately
        )
        
        logger.debug("Set up Darwin notification observers")
    }
    
    // MARK: - Notification Handlers
    
    private func handleFrameAvailable() {
        logger.debug("🟡 XPC CLIENT DEBUG: Received frameAvailable notification")
        
        // Log notification received
        if let logURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Identifiers.appGroup)?.appendingPathComponent("xpc_client_debug.log") {
            let logMessage = "[\(Date())] CLIENT: frameAvailable notification received\n"
            try? logMessage.append(to: logURL)
        }
        
        // Update last frame time
        lastFrameTime = CFAbsoluteTimeGetCurrent()
        
        // Stop fallback polling if it's running
        if fallbackTimer != nil {
            fallbackTimer?.invalidate()
            fallbackTimer = nil
            logger.debug("Stopped fallback polling (notifications working)")
        }
        
        // Fetch the latest frame (with coalescing)
        fetchLatestFrame()
    }
    
    private func handleStreamStopped() {
        logger.debug("Received streamStopped notification")
        
        // Stop fallback polling
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        
        // Clear format cache
        formatDescriptionCache.removeAll()
        
        // Notify UI
        DispatchQueue.main.async { [weak self] in
            self?.onStreamStopped?()
        }
    }
    
    // MARK: - Frame Fetching
    
    func fetchLatestFrame() {
        guard isConnected, let service = service else {
            logger.debug("Not connected, skipping frame fetch")
            checkFallbackPolling()
            return
        }
        
        // Coalesce fetches - skip if one is already in progress
        fetchLock.lock()
        if isFetching {
            fetchLock.unlock()
            logger.debug("Frame fetch already in progress, skipping")
            return
        }
        isFetching = true
        fetchLock.unlock()
        
        // Fetch with short timeout (20-30ms)
        service.getLatestFrame { [weak self] parcel in
            self?.fetchLock.lock()
            self?.isFetching = false
            self?.fetchLock.unlock()
            
            self?.processFrameParcel(parcel)
        }
    }
    
    private func processFrameParcel(_ parcel: FrameParcel?) {
        guard let parcel = parcel else {
            logger.debug("No frame available")
            checkFallbackPolling()
            return
        }
        
        // Lookup IOSurface from mach port
        guard let surface = IOSurfaceLookupFromMachPort(parcel.machPort) else {
            logger.error("Failed to lookup IOSurface from mach port")
            
            // Deallocate the mach port send right
            mach_port_deallocate(mach_task_self_, parcel.machPort)
            return
        }
        
        // Create or get cached format description
        let formatKey = "\(parcel.width)x\(parcel.height)_\(parcel.pixelFormat)_\(parcel.colorSpaceName)"
        
        let formatDescription: CMFormatDescription
        if let cached = formatDescriptionCache[formatKey] {
            formatDescription = cached
        } else {
            // Create new format description
            var newFormat: CMFormatDescription?
            
            // Build extensions dictionary with color space info
            var extensions: [CFString: Any] = [:]
            
            // Add color space based on pixel format
            if parcel.pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
               parcel.pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                extensions[kCVImageBufferYCbCrMatrixKey] = parcel.cvColorSpace
                extensions[kCVImageBufferColorPrimariesKey] = kCVImageBufferColorPrimaries_ITU_R_709_2
                extensions[kCVImageBufferTransferFunctionKey] = kCVImageBufferTransferFunction_ITU_R_709_2
            } else if let colorSpace = parcel.cgColorSpace {
                extensions[kCVImageBufferCGColorSpaceKey] = colorSpace
            }
            
            let result = CMVideoFormatDescriptionCreate(
                allocator: kCFAllocatorDefault,
                codecType: parcel.pixelFormat,
                width: parcel.width,
                height: parcel.height,
                extensions: extensions as CFDictionary,
                formatDescriptionOut: &newFormat
            )
            
            if result == noErr, let format = newFormat {
                formatDescription = format
                formatDescriptionCache[formatKey] = format
                logger.debug("Created new format description for \(formatKey)")
            } else {
                logger.error("Failed to create format description: \(result)")
                mach_port_deallocate(mach_task_self_, parcel.machPort)
                return
            }
        }
        
        // Create CVPixelBuffer from IOSurface
        var pixelBuffer: Unmanaged<CVPixelBuffer>?
        
        let pixelBufferAttributes: [CFString: Any] = [
            kCVPixelBufferWidthKey: parcel.width,
            kCVPixelBufferHeightKey: parcel.height,
            kCVPixelBufferPixelFormatTypeKey: parcel.pixelFormat,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as NSDictionary,
            kCVPixelBufferMetalCompatibilityKey: true
        ]
        
        let result = CVPixelBufferCreateWithIOSurface(
            kCFAllocatorDefault,
            surface,
            pixelBufferAttributes as CFDictionary,
            &pixelBuffer
        )
        
        // Deallocate the mach port send right after use
        mach_port_deallocate(mach_task_self_, parcel.machPort)
        
        if result == kCVReturnSuccess, let buffer = pixelBuffer?.takeRetainedValue() {
            logger.debug("Successfully created CVPixelBuffer for frame #\(parcel.frameIndex)")
            
            // Apply color space attachments if needed
            if parcel.pixelFormat == kCVPixelFormatType_32BGRA,
               let colorSpace = parcel.cgColorSpace {
                CVBufferSetAttachment(buffer, kCVImageBufferCGColorSpaceKey, colorSpace, .shouldPropagate)
            }
            
            // Deliver frame to UI
            DispatchQueue.main.async { [weak self] in
                self?.onFrameReceived?(buffer, parcel.presentationTimeStamp)
            }
        } else {
            logger.error("Failed to create CVPixelBuffer from IOSurface: \(result)")
        }
    }
    
    // MARK: - Fallback Polling
    
    private func checkFallbackPolling() {
        // Start fallback polling if we haven't received a notification recently
        let timeSinceLastFrame = CFAbsoluteTimeGetCurrent() - lastFrameTime
        
        if timeSinceLastFrame > fallbackThreshold && fallbackTimer == nil {
            logger.debug("Starting fallback polling (no notifications for \(timeSinceLastFrame)s)")
            startFallbackPolling()
        }
    }
    
    private func startFallbackPolling() {
        fallbackTimer?.invalidate()
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: fallbackPollingInterval, repeats: true) { [weak self] _ in
            self?.fetchLatestFrame()
        }
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