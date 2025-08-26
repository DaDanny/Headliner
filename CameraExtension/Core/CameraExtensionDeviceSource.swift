//
//  CameraExtensionDeviceSource.swift
//  CameraExtension
//
//  Extracted from CameraExtensionProvider.swift on 2025-01-28. No functional changes.
//

import Foundation
import CoreMediaIO
import IOKit.audio
import AVFoundation
import Cocoa
import OSLog

// MARK: - Shared Constants and Loggers

let kWhiteStripeHeight: Int = 10
// Note: kFrameRate is defined in CameraExtensionStreamSource.swift to avoid duplication

fileprivate let extensionLogger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Extension")
fileprivate let diagnosticsLogger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Diagnostics")

// MARK: - CameraExtensionDeviceSource

class CameraExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource, AVCaptureVideoDataOutputSampleBufferDelegate, CameraExtensionErrorManagerDelegate, CameraExtensionPerformanceManagerDelegate, CameraExtensionDiagnosticsDelegate {
	
	// MARK: Core Properties
	// Note: Properties are internal to allow access from same-target extensions
	
	internal private(set) var device: CMIOExtensionDevice!
	
	internal var _streamSource: CameraExtensionStreamSource!
	
	internal var _streamingCounter: UInt32 = 0
	
	internal var _videoDescription: CMFormatDescription!
	
	internal var _bufferPool: CVPixelBufferPool!
	
	internal var _bufferAuxAttributes: NSDictionary!
	
	// Timer-based frame generation (like working sample)
	internal var _timer: DispatchSourceTimer?
	internal let _timerQueue = DispatchQueue(label: "timerQueue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem, target: .global(qos: .userInteractive))
	
	// Phase 2.4: Health monitoring & heartbeat system
	internal var _heartbeatTimer: DispatchSourceTimer?
	internal let _heartbeatQueue = DispatchQueue(label: "heartbeatQueue", qos: .utility)
	
	// Phase 4.2: Dedicated managers for error handling and performance optimization
	internal var errorManager: CameraExtensionErrorManager?
	internal var performanceManager: CameraExtensionPerformanceManager?
	
	// Phase 4.3: Diagnostic system for structured logging and performance metrics
	internal var diagnostics: CameraExtensionDiagnostics?
	
	// Phase 4.2: Lazy frame storage managed by performance manager
	internal var _currentCameraFrame: CVPixelBuffer?
	internal let _cameraFrameLock = NSLock()
	
	// UNUSED: Legacy frame counting for overlay sizing - can be removed
	internal var _frameCount = 0
	
	// Streaming state management
	internal var _isAppControlledStreaming = false
	internal let _streamStateLock = NSLock()
	
	// Camera capture components - using shared CaptureSessionManager
	internal var captureSessionManager: CaptureSessionManager?
	// Device selection tracking for proper initialization
	internal var selectedCameraDeviceID: String?
	
	// Overlay settings
	internal var overlaySettings: OverlaySettings = OverlaySettings()
	internal let overlaySettingsLock = NSLock()
	
	// Phase 4.2: Lazy-loaded overlay system components
	internal lazy var overlayRenderer: OverlayRenderer = CameraOverlayRenderer()
	internal lazy var overlayPresetStore: OverlayPresetStore = OverlayPresetStore()
	
	// Phase 4.2: Overlay caching optimized by performance manager
	internal var lastRenderedOverlay: CIImage?
	internal var lastAspectRatio: OverlayAspect?
	
	// Phase 4.3: Overlay render timing tracking
	internal var lastOverlayRenderTime: TimeInterval = 0
	
	// MARK: Initialization
	
	init(localizedName: String) {
		
		super.init()
		
		// Phase 4.1: Add capture session interruption notifications
		// NOTE: These are AVFoundation SYSTEM notifications, NOT custom app notifications
		// DO NOT migrate these to CrossAppExtensionNotifications - they handle camera hardware interruptions
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(captureSessionWasInterrupted(_:)),
			name: AVCaptureSession.wasInterruptedNotification, // System notification from AVFoundation
			object: nil
		)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(captureSessionInterruptionEnded(_:)),
			name: AVCaptureSession.interruptionEndedNotification, // System notification from AVFoundation
			object: nil
		)
		let deviceID = UUID() // replace this with your device UUID
		self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)
		
		let dims = CMVideoDimensions(width: 1920, height: 1080)
		CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault, codecType: kCVPixelFormatType_32BGRA, width: dims.width, height: dims.height, extensions: nil, formatDescriptionOut: &_videoDescription)
		
		// NOTE: REQUIRED - Cache camera dimensions for main app overlay rendering
		cacheCameraDimensions(width: Int(dims.width), height: Int(dims.height))
		
		
		let pixelBufferAttributes: NSDictionary = [
			kCVPixelBufferWidthKey: dims.width,
			kCVPixelBufferHeightKey: dims.height,
			kCVPixelBufferPixelFormatTypeKey: _videoDescription.mediaSubType,
			kCVPixelBufferIOSurfacePropertiesKey: [:] as NSDictionary
		]
		CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes, &_bufferPool)
		
		let videoStreamFormat = CMIOExtensionStreamFormat.init(formatDescription: _videoDescription, maxFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)), minFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)), validFrameDurations: nil)
		_bufferAuxAttributes = [kCVPixelBufferPoolAllocationThresholdKey: 5]
		
		let videoID = UUID() // replace this with your video UUID
		_streamSource = CameraExtensionStreamSource(localizedName: "Headliner.Video", streamID: videoID, streamFormat: videoStreamFormat, device: device)
		do {
			try device.addStream(_streamSource.stream)
		} catch let error {
			fatalError("Failed to add stream: \(error.localizedDescription)")
		}
		
		// ❌ CRITICAL FIX: Remove immediate camera initialization 
		// This was causing camera to run on app launch even when not needed
		// Implement lazy initialization - camera only starts when external app requests it
		//
		// OLD PROBLEMATIC CODE: setupCaptureSession()
		
		extensionLogger.debug("✅ CameraExtensionDeviceSource init - using lazy camera initialization")
		
		// Load overlay settings
		loadOverlaySettings()
		extensionLogger.debug("✅ CameraExtensionDeviceSource init - overlay settings loaded")
		
		// Phase 4.2: Initialize dedicated managers
		errorManager = CameraExtensionErrorManager(delegate: self)
		performanceManager = CameraExtensionPerformanceManager(delegate: self)
		
		// Phase 4.3: Initialize diagnostic system
		diagnostics = CameraExtensionDiagnostics(delegate: self)
		extensionLogger.debug("✅ Initialized error, performance, and diagnostic managers")
		
		// Phase 4.2: Lazy initialization - overlay components created on first use
		extensionLogger.debug("✅ Setup lazy overlay system initialization (Metal-backed)")
	}
	
	// MARK: Core CMIO Extension Methods
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		return [.deviceTransportType, .deviceModel]
	}
	
	func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
		
		let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
		if properties.contains(.deviceTransportType) {
			deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
		}
		if properties.contains(.deviceModel) {
			deviceProperties.model = "Headliner Model"
		}
		
		return deviceProperties
	}
	
	// UNUSED: Empty method stub - can be removed
	func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
		
		// Handle settable properties here.
	}
	
	// MARK: Cleanup
	
	deinit {
		// Phase 4.2: Cleanup dedicated managers
		errorManager = nil
		performanceManager = nil
		
		// NOTE: This removes AVFoundation system notification observers (capture session interruptions)
		// This is NOT related to our custom notification migration - it's for system hardware events
		NotificationCenter.default.removeObserver(self)
		extensionLogger.debug("🧼 Cleaned up CameraExtensionDeviceSource resources")
	}
}

// MARK: - Placeholder methods for extensions

// These methods will be moved to extensions in subsequent steps
extension CameraExtensionDeviceSource {
	
	// MARK: Capture Session Methods (implemented in +CaptureSession extension)
	
	// Methods implemented in CameraExtensionDeviceSource+CaptureSession.swift:
	// - startStreaming()
	// - stopStreaming() 
	// - startAppControlledStreaming()
	// - stopAppControlledStreaming()
	// - setCameraDevice()
	// - @objc captureSessionWasInterrupted()
	// - @objc captureSessionInterruptionEnded()
	// - performHealthCheck()
	// - private startCameraCapture()
	// - private stopCameraCapture()
	// - private startHeartbeatTimer()
	// - private stopHeartbeatTimer()
	// - private setupCaptureSession()
	// - private findDeviceByID()
	// - private getCurrentDeviceName()
	
	// MARK: Frame Pipeline Methods (implemented in +FramePipeline extension)
	
	// Methods implemented in CameraExtensionDeviceSource+FramePipeline.swift:
	// - generateVirtualCameraFrame()
	// - captureOutput(_:didOutput:from:)
	// - updateOverlaySettings()
	// - loadOverlaySettings()
	// - cacheCameraDimensions()
	// - private drawSplashScreen()
	// - private createCGImage()
	// - private drawOverlaysWithPresetSystem()
	// - CameraExtensionPerformanceManagerDelegate methods
}

// MARK: - Delegate Protocol Implementations

// Delegate implementations are now in their appropriate extensions:
// - CameraExtensionErrorManagerDelegate -> +CaptureSession extension (capture session recovery)
// - CameraExtensionPerformanceManagerDelegate -> TODO: will be in +FramePipeline extension  
// - CameraExtensionDiagnosticsDelegate -> TODO: will stay in core or move to appropriate extension

// CameraExtensionPerformanceManagerDelegate methods are now in +FramePipeline extension

// MARK: Placeholder CameraExtensionDiagnosticsDelegate (will stay in core)

extension CameraExtensionDeviceSource {
	func diagnostics(_ manager: CameraExtensionDiagnostics, didUpdateMetrics metrics: DiagnosticMetrics) {
		// TODO: Keep in core or move to appropriate extension
		diagnosticsLogger.debug("📊 Metrics Update: FPS=\(String(format: "%.1f", metrics.frameRate)), Memory=\(String(format: "%.1f", metrics.memoryUsageMB))MB, Health=\(metrics.systemHealth.emoji)\(metrics.systemHealth.rawValue)")
	}
	
	func diagnostics(_ manager: CameraExtensionDiagnostics, didDetectIssue issue: String, severity: OSLogType) {
		// TODO: Keep in core or move to appropriate extension
		switch severity {
		case .error:
			diagnosticsLogger.error("🚨 Diagnostic Issue: \(issue, privacy: .public)")
		default:
			diagnosticsLogger.warning("⚠️ Diagnostic Issue: \(issue, privacy: .public)")
		}
	}
}