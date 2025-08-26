//
//  CameraExtensionProvider.swift
//  CameraExtension
//
//  Created by Danny Francken on 8/2/25.
//

import Foundation
import CoreMediaIO
import IOKit.audio
import AVFoundation
import Cocoa
import OSLog

	// UNUSED: Legacy constant from Core Graphics overlay system - can be removed
	let kWhiteStripeHeight: Int = 10
	let kFrameRate: Int = 60


private let extensionLogger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Extension")

// Phase 4.2: Import dedicated managers for better separation of concerns
// Error types and performance types are now defined in their respective manager files

// MARK: - ExtensionDeviceSourceDelegate

// MARK: -

class CameraExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource, AVCaptureVideoDataOutputSampleBufferDelegate {
	
	private(set) var device: CMIOExtensionDevice!
	
	private var _streamSource: CameraExtensionStreamSource!
	
	private var _streamingCounter: UInt32 = 0
	
	private var _videoDescription: CMFormatDescription!
	
	private var _bufferPool: CVPixelBufferPool!
	
	private var _bufferAuxAttributes: NSDictionary!
	
	// Timer-based frame generation (like working sample)
	private var _timer: DispatchSourceTimer?
	private let _timerQueue = DispatchQueue(label: "timerQueue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem, target: .global(qos: .userInteractive))
	
	// Phase 2.4: Health monitoring & heartbeat system
	private var _heartbeatTimer: DispatchSourceTimer?
	private let _heartbeatQueue = DispatchQueue(label: "heartbeatQueue", qos: .utility)
	
	// Phase 4.2: Dedicated managers for error handling and performance optimization
	private var errorManager: CameraExtensionErrorManager?
	private var performanceManager: CameraExtensionPerformanceManager?
	
	// Phase 4.3: Diagnostic system for structured logging and performance metrics
	private var diagnostics: CameraExtensionDiagnostics?
	
	// Phase 4.2: Lazy frame storage managed by performance manager
	private var _currentCameraFrame: CVPixelBuffer?
	private let _cameraFrameLock = NSLock()
	
	// UNUSED: Legacy frame counting for overlay sizing - can be removed
	private var _frameCount = 0
	
	// Streaming state management
	private var _isAppControlledStreaming = false
	private let _streamStateLock = NSLock()
	
	// Camera capture components - using shared CaptureSessionManager
	private var captureSessionManager: CaptureSessionManager?
	// Device selection tracking for proper initialization
	private var selectedCameraDeviceID: String?
	
	// Overlay settings
	private var overlaySettings: OverlaySettings = OverlaySettings()
	private let overlaySettingsLock = NSLock()
	
	// Phase 4.2: Lazy-loaded overlay system components
	private lazy var overlayRenderer: OverlayRenderer = CameraOverlayRenderer()
	private lazy var overlayPresetStore: OverlayPresetStore = OverlayPresetStore()
	
	// Phase 4.2: Overlay caching optimized by performance manager
	private var lastRenderedOverlay: CIImage?
	private var lastAspectRatio: OverlayAspect?
	
	// Phase 4.3: Overlay render timing tracking
	private var lastOverlayRenderTime: TimeInterval = 0
	
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
	
	func startStreaming() {
		extensionLogger.debug("Virtual camera requested by external app - starting frame generation")
		
		// Phase 4.3: Log streaming start event
		diagnostics?.logEvent(.sessionStarted)
		
		guard let _ = _bufferPool else {
			extensionLogger.error("No buffer pool available")
			diagnostics?.recordError(CameraExtensionError.configurationFailed, context: "startStreaming - no buffer pool")
			return
		}
		
		_streamingCounter += 1
		extensionLogger.debug("Virtual camera streaming counter: \(self._streamingCounter)")
		
		// Always start the timer for virtual camera (this provides splash screen when app isn't streaming)
		if _timer == nil {
			_timer = DispatchSource.makeTimerSource(flags: .strict, queue: _timerQueue)
			_timer!.schedule(deadline: .now(), repeating: 1.0/Double(kFrameRate), leeway: .seconds(0))
			
			_timer!.setEventHandler { [weak self] in
				guard let self = self else { return }
				self.generateVirtualCameraFrame()
			}
			
			_timer!.setCancelHandler {
				// Timer cleanup handled in stopStreaming
			}
			
			_timer!.resume()
			extensionLogger.debug("Started virtual camera frame generation timer")
		}
		
		// Phase 2.4: Start heartbeat monitoring when streaming begins
		startHeartbeatTimer()
		
		// Phase 4.2: Reset error tracking when streaming starts
		errorManager?.recordSuccess()
		
		// Phase 2.2: Auto-start camera feature for seamless Google Meet integration
		_streamStateLock.lock()
		let currentAppControlledStreaming = _isAppControlledStreaming
		
		// Check if auto-start is enabled and we're not already streaming
		if !currentAppControlledStreaming && ExtensionStatusManager.getAutoStartEnabled() {
			extensionLogger.debug("Auto-start enabled - automatically starting camera capture for external app")
			_isAppControlledStreaming = true
			_streamStateLock.unlock()
			
			// Report auto-start status
			ExtensionStatusManager.writeStatus(.starting, error: nil)
			startCameraCapture()
		} else {
			_streamStateLock.unlock()
			
			if currentAppControlledStreaming {
				startCameraCapture()
			} else {
				extensionLogger.debug("Auto-start disabled - showing splash screen until app enables streaming")
			}
		}
	}
	
	func startAppControlledStreaming() {
		extensionLogger.debug("App requesting camera stream start")
		
		_streamStateLock.lock()
		_isAppControlledStreaming = true
		_streamStateLock.unlock()
		
		startCameraCapture()
	}
	
	func stopAppControlledStreaming() {
		extensionLogger.debug("App requesting camera stream stop")
		
		_streamStateLock.lock()
		_isAppControlledStreaming = false
		_streamStateLock.unlock()
		
		stopCameraCapture()
	}
	
	private func startCameraCapture() {
		print("🎬 [Camera Extension] Starting real camera capture...")
		extensionLogger.debug("Starting real camera capture...")
		
		// Phase 4.2: Check camera permissions using error manager
		guard errorManager?.checkCameraPermissions() ?? false else {
			extensionLogger.error("❌ Camera permission denied - cannot start capture")
			ExtensionStatusManager.writeStatus(.error, error: "Camera permission denied")
			return
		}
		
		// Phase 2: Report status to main app
		ExtensionStatusManager.writeStatus(.starting)
		
			// Lazy initialization: setup capture session on first use
	if captureSessionManager == nil {
		print("🔧 [Camera Extension] First camera start - initializing capture session...")
		extensionLogger.debug("Lazy initializing capture session on first camera start")
		
		// Check if we have a stored device selection before initializing
		if let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
		   let deviceID = userDefaults.string(forKey: ExtensionStatusKeys.selectedDeviceID) {
			extensionLogger.debug("📷 Found stored device selection: \(deviceID) - will apply during initialization")
			selectedCameraDeviceID = deviceID
		}
		
		setupCaptureSession()
	}
		
		if let manager = captureSessionManager, manager.configured {
			print("✅ [Camera Extension] CaptureSessionManager is configured")
			extensionLogger.debug("CaptureSessionManager is configured and ready")
			
			if !manager.captureSession.isRunning {
				print("🚀 [Camera Extension] Starting capture session...")
				extensionLogger.debug("Starting capture session...")
				
				// Set self as the delegate for video frames
				manager.videoOutput?.setSampleBufferDelegate(self, queue: manager.dataOutputQueue)
				
				manager.captureSession.startRunning()
				print("✅ [Camera Extension] Started real camera capture session")
				extensionLogger.debug("Started real camera capture session for content")
				
				// Phase 2: Report streaming status with device name
				if let deviceName = getCurrentDeviceName() {
					ExtensionStatusManager.writeStatus(.streaming, deviceName: deviceName)
				} else {
					ExtensionStatusManager.writeStatus(.streaming)
				}
			} else {
				print("✅ [Camera Extension] Capture session already running")
				extensionLogger.debug("Capture session already running")
			}
		} else {
			print("❌ [Camera Extension] CaptureSessionManager not configured - setup failed")
			extensionLogger.error("CaptureSessionManager configuration failed even after setup attempt")
			
			// Phase 4.2: Handle configuration failure through error manager
			errorManager?.handleError(.configurationFailed)
		}
	}
	
	private func stopCameraCapture() {
		print("🛑 [Camera Extension] Stopping real camera capture...")
		extensionLogger.debug("Stopping real camera capture...")
		
		if let manager = captureSessionManager, manager.captureSession.isRunning {
			manager.captureSession.stopRunning()
			print("✅ [Camera Extension] Stopped real camera capture session")
			extensionLogger.debug("Stopped real camera capture session")
		}
		
		// Clear current camera frame so splash screen shows
		_cameraFrameLock.lock()
		_currentCameraFrame = nil
		_cameraFrameLock.unlock()
	}
	
	func stopStreaming() {
		extensionLogger.debug("External app stopping virtual camera streaming")
		
		// Phase 4.3: Log streaming stop event
		diagnostics?.logEvent(.sessionStopped)
		
		if _streamingCounter > 1 {
			_streamingCounter -= 1
			extensionLogger.debug("Virtual camera streaming counter: \(self._streamingCounter)")
		} else {
			_streamingCounter = 0
			
			// Stop timer-based frame generation
			if let timer = _timer {
				timer.cancel()
				_timer = nil
				extensionLogger.debug("Stopped virtual camera frame generation timer")
			}
			
			// Phase 2.4: Stop heartbeat monitoring when streaming ends completely
			stopHeartbeatTimer()
			
			// Phase 4.2: Frame generation monitoring is now handled by error manager
			
			// ❌ CRITICAL FIX: Don't reset app state when external apps stop
			// This was causing Google Meet toggle issues - when Meet stops/starts video,
			// it would reset _isAppControlledStreaming = false, causing splash screen
			// 
			// OLD BROKEN CODE: _isAppControlledStreaming = false
			
			// Only stop camera if app explicitly wants it stopped
			_streamStateLock.lock()
			let shouldStopCamera = !_isAppControlledStreaming
			_streamStateLock.unlock()
			
			if shouldStopCamera {
				// Phase 2.2: Report stopping status
				ExtensionStatusManager.writeStatus(.stopping)
				stopCameraCapture()
				// Phase 2.2: Report idle status after stopping
				ExtensionStatusManager.writeStatus(.idle)
				extensionLogger.debug("Stopped camera capture - app not streaming")
			} else {
				extensionLogger.debug("Keeping camera active - app still wants streaming (including auto-start)")
			}
		}
	}
	
	// MARK: - Phase 2.4: Health Monitoring & Heartbeat System
	
	private func startHeartbeatTimer() {
		guard _heartbeatTimer == nil else { return }
		
		_heartbeatTimer = DispatchSource.makeTimerSource(queue: _heartbeatQueue)
		_heartbeatTimer!.schedule(deadline: .now(), repeating: 2.0, leeway: .milliseconds(500))
		
		_heartbeatTimer!.setEventHandler { [weak self] in
			guard let self = self else { return }
			
			// Only send heartbeat if extension is actively doing something
			_streamStateLock.lock()
			let isActivelyStreaming = _streamingCounter > 0 || _isAppControlledStreaming
			_streamStateLock.unlock()
			
			if isActivelyStreaming {
				ExtensionStatusManager.updateHeartbeat()
				extensionLogger.debug("💓 Heartbeat sent - extension is healthy")
			}
		}
		
		_heartbeatTimer!.setCancelHandler {
			// Cleanup handled in stopHeartbeatTimer
		}
		
		_heartbeatTimer!.resume()
		extensionLogger.debug("✅ Started heartbeat timer (2s interval)")
	}
	
	private func stopHeartbeatTimer() {
		if let timer = _heartbeatTimer {
			timer.cancel()
			_heartbeatTimer = nil
			extensionLogger.debug("🛑 Stopped heartbeat timer")
		}
	}
	
	// MARK: Virtual Camera Frame Generation
	
	private func generateVirtualCameraFrame() {
		guard _streamingCounter > 0 else { return }
		
		// Phase 4.3: Track frame generation timing
		let frameStartTime = Date()
		
		// Phase 4.2: Update frame generation timestamp in error manager
		errorManager?.recordFrameGenerated()
		
		var err: OSStatus = 0
		var pixelBuffer: CVPixelBuffer?
		
		// Create a new pixel buffer from our pool
		err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
			kCFAllocatorDefault, 
			_bufferPool, 
			_bufferAuxAttributes, 
			&pixelBuffer
		)
		
		if err != 0 {
			extensionLogger.error("Failed to create pixel buffer: \(err)")
			// Phase 4.2: Handle pixel buffer creation error
			errorManager?.handleError(.pixelBufferCreationFailed(err))
			return
		}
		
		guard let pixelBuffer = pixelBuffer else {
			extensionLogger.error("Pixel buffer is nil")
			// Phase 4.2: Handle nil pixel buffer error
			errorManager?.handleError(.pixelBufferCreationFailed(-1))
			return
		}
		
		// Lock the pixel buffer for drawing
		CVPixelBufferLockBaseAddress(pixelBuffer, [])
		defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
		
		let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
		let width = CVPixelBufferGetWidth(pixelBuffer)
		let height = CVPixelBufferGetHeight(pixelBuffer)
		let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
		
		guard let context = CGContext(
			data: pixelData,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
			space: rgbColorSpace,
			bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
		) else {
			extensionLogger.error("Failed to create CGContext")
			return
		}
		
		// Clear the buffer first
		let rect = CGRect(x: 0, y: 0, width: width, height: height)
		context.clear(rect)
		context.setFillColor(NSColor.black.cgColor)
		context.fill(rect)
		
		// Draw the current camera frame if available
		_cameraFrameLock.lock()
		if let cameraFrame = _currentCameraFrame {
			// Convert camera frame to CGImage and draw it
			if let cgImage = createCGImage(from: cameraFrame) {
				context.draw(cgImage, in: rect)
			} else {
				// Failed to convert camera frame to CGImage
				drawSplashScreen(context: context, rect: rect)
			}
		} else {
			// No camera frame available - draw professional splash screen
			drawSplashScreen(context: context, rect: rect)
		}
		_cameraFrameLock.unlock()
		
		// Always use preset system for overlays
		drawOverlaysWithPresetSystem(pixelBuffer: pixelBuffer, context: context, rect: rect)
		
		// Create and send CMSampleBuffer
		var sampleBuffer: CMSampleBuffer?
		var timingInfo = CMSampleTimingInfo()
		timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
		
		err = CMSampleBufferCreateForImageBuffer(
			allocator: kCFAllocatorDefault,
			imageBuffer: pixelBuffer,
			dataReady: true,
			makeDataReadyCallback: nil,
			refcon: nil,
			formatDescription: _videoDescription,
			sampleTiming: &timingInfo,
			sampleBufferOut: &sampleBuffer
		)
		
		if err == 0, let sampleBuffer = sampleBuffer {
			
			_streamSource.stream.send(
				sampleBuffer,
				discontinuity: [],
				hostTimeInNanoseconds: UInt64(timingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC))
			)
			
			// Phase 4.3: Record successful frame generation with timing
			let frameProcessingTime = Date().timeIntervalSince(frameStartTime)
			// Note: overlayTime will be calculated in drawOverlaysWithPresetSystem and passed via a property
			diagnostics?.recordFrameGenerated(processingTime: frameProcessingTime, overlayTime: lastOverlayRenderTime)
			
		} else {
			extensionLogger.error("Failed to create sample buffer: \(err)")
			// Phase 4.2: Handle sample buffer creation error
			errorManager?.handleError(.sampleBufferCreationFailed(err))
			// Phase 4.3: Record frame drop due to sample buffer creation failure
			diagnostics?.recordFrameDropped(reason: "Sample buffer creation failed: \(err)")
		}
	}
	
	// UNUSED: Legacy splash screen text rendering - can be simplified to just show "Headliner" logo
	private func drawSplashScreen(context: CGContext, rect: CGRect) {
		let width = Int(rect.width)
		let height = Int(rect.height)
		
		// Draw professional gradient background
		let colors = [
			NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0).cgColor,  // Dark blue-gray
			NSColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0).cgColor    // Lighter blue-gray
		] as CFArray
		
		if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
			context.drawLinearGradient(
				gradient,
				start: CGPoint(x: 0, y: 0),
				end: CGPoint(x: 0, y: height),
				options: []
			)
		}
		
		// Setup NSGraphicsContext for text drawing
		let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
		NSGraphicsContext.saveGraphicsState()
		NSGraphicsContext.current = graphicsContext
		
		// Check if app-controlled streaming is active
		_streamStateLock.lock()
		let isAppStreaming = _isAppControlledStreaming
		_streamStateLock.unlock()
		
		// Draw main title
		let titleText = "Headliner"
		let titleFont = NSFont.systemFont(ofSize: min(CGFloat(width)/12, 72), weight: .bold)
		let titleAttributes: [NSAttributedString.Key: Any] = [
			.font: titleFont,
			.foregroundColor: NSColor.white,  // white
			.paragraphStyle: {
				let style = NSMutableParagraphStyle()
				style.alignment = .center
				return style
			}()
		]
		
		let titleSize = NSString(string: titleText).size(withAttributes: titleAttributes)
		let titleRect = CGRect(
			x: 0,
			y: CGFloat(height/2 + 20),
			width: CGFloat(width),
			height: titleSize.height
		)
		titleText.draw(in: titleRect, withAttributes: titleAttributes)
		
		// Draw status message
		let statusText = isAppStreaming ? "Starting Camera..." : "Camera Stopped"
		let statusFont = NSFont.systemFont(ofSize: min(CGFloat(width)/20, 36), weight: .medium)
		let statusColor = isAppStreaming ? NSColor.systemGreen : NSColor.systemGray  // green or gray
		let statusAttributes: [NSAttributedString.Key: Any] = [
			.font: statusFont,
			.foregroundColor: statusColor,
			.paragraphStyle: {
				let style = NSMutableParagraphStyle()
				style.alignment = .center
				return style
			}()
		]
		
		let statusSize = NSString(string: statusText).size(withAttributes: statusAttributes)
		let statusRect = CGRect(
			x: 0,
			y: CGFloat(height/2 - 20) - statusSize.height,
			width: CGFloat(width),
			height: statusSize.height
		)
		statusText.draw(in: statusRect, withAttributes: statusAttributes)
		
		// Draw subtle instruction text at bottom
		let instructionText = "Start camera from Headliner app"
		let instructionFont = NSFont.systemFont(ofSize: min(CGFloat(width)/30, 24), weight: .regular)
		let instructionAttributes: [NSAttributedString.Key: Any] = [
			.font: instructionFont,
			.foregroundColor: NSColor.systemGray,  // gray
			.paragraphStyle: {
				let style = NSMutableParagraphStyle()
				style.alignment = .center
				return style
			}()
		]
		
		let instructionSize = NSString(string: instructionText).size(withAttributes: instructionAttributes)
		let instructionRect = CGRect(
			x: 0,
			y: 60,
			width: CGFloat(width),
			height: instructionSize.height
		)
		instructionText.draw(in: instructionRect, withAttributes: instructionAttributes)
		
		NSGraphicsContext.restoreGraphicsState()
	}
	
	private func createCGImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
		let context = CIContext(options: nil)
		return context.createCGImage(ciImage, from: ciImage.extent)
	}
	
	
	
	
	
	// MARK: Overlay Settings Management
	
	// UNUSED: Legacy overlay settings loading from Core Graphics system - can be removed
	private func loadOverlaySettings() {
        self.overlaySettingsLock.lock()
        defer { self.overlaySettingsLock.unlock() }
        
        // Load from app group UserDefaults (shared between app and extension)
        if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup),
           let overlayData = sharedDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings) {
            do {
                let decodedSettings = try JSONDecoder().decode(OverlaySettings.self, from: overlayData)
                self.overlaySettings = decodedSettings
                extensionLogger.debug("✅ Loaded overlay settings from app group defaults: enabled=\(self.overlaySettings.isEnabled), userName='\(self.overlaySettings.userName)', position=\(self.overlaySettings.namePosition.rawValue), fontSize=\(self.overlaySettings.fontSize)")
                return
            } catch {
                extensionLogger.error("❌ Failed to decode overlay settings from app group defaults: \(error)")
            }
        }
        
        // Fallback: Use default settings with system username
        extensionLogger.debug("📝 Using default overlay settings as fallback")
        self.overlaySettings = OverlaySettings()
        self.overlaySettings.userName = NSUserName()
        self.overlaySettings.isEnabled = true
        self.overlaySettings.showUserName = true
        extensionLogger.debug("Using default overlay settings with user name: \(self.overlaySettings.userName)")
    }
	
	func updateOverlaySettings() {
		loadOverlaySettings()
		// Clear cached overlay when settings change
		lastRenderedOverlay = nil
		extensionLogger.debug("Overlay settings updated from UserDefaults")
	}
	
	// MARK: Preset System Support
	
	// Phase 4.2: Optimized overlay rendering with performance management
	private func drawOverlaysWithPresetSystem(pixelBuffer: CVPixelBuffer, context: CGContext, rect: CGRect) {
		// Phase 4.2: Skip overlay rendering under memory pressure for performance
		if performanceManager?.shouldSkipOverlayFrame() == true {
			// Phase 4.3: Log overlay frame skip for performance
			diagnostics?.logEvent(.overlaySkipped, metadata: ["reason": "performance_optimization"])
			lastOverlayRenderTime = 0
			
			// Use cached overlay if available
			if let cachedOverlay = lastRenderedOverlay {
				if let cgImage = CIContext().createCGImage(cachedOverlay, from: cachedOverlay.extent) {
					context.draw(cgImage, in: rect)
				}
			}
			return
		}
		
		// Phase 4.2: Overlay components are now lazy-loaded automatically
		let renderer = overlayRenderer
		let presetStore = overlayPresetStore
		
		overlaySettingsLock.lock()
		let settings = self.overlaySettings
		overlaySettingsLock.unlock()
		
		// Only draw overlays if enabled
		guard settings.isEnabled else { 
			lastOverlayRenderTime = 0
			return 
		}
		
		// Get current preset and tokens
		var preset = presetStore.selectedPreset
		var tokens = presetStore.overlayTokens
		
		// Check if we have custom settings that override preset
		if let customTokens = settings.overlayTokens {
			tokens = customTokens
		}
		
		// If using preset from settings
		if !settings.selectedPresetId.isEmpty {
			if let selectedPreset = OverlayPresets.preset(withId: settings.selectedPresetId) {
				preset = selectedPreset
			} 
		} else {
			extensionLogger.debug("📝 [Preset Selection] No preset ID in settings, using default: '\(preset.name)'")
		}
		
		// Update tokens with current user name if needed
		if tokens.displayName.isEmpty {
			tokens.displayName = settings.userName.isEmpty ? NSUserName() : settings.userName
		}
		
		// Check for aspect ratio change
		let currentAspect = settings.overlayAspect
		let aspectChanged = lastAspectRatio != nil && lastAspectRatio != currentAspect
		
		// Note: aspect is now a computed property in OverlayTokens (returns .widescreen)
		
		// Notify renderer about aspect change for optimized crossfade
		if aspectChanged {
			renderer.notifyAspectChanged()
		}
		
		// Phase 4.3: Track overlay rendering timing
		let overlayStartTime = Date()
		
		// Render overlay using Core Image renderer
		let overlayImage = renderer.render(
			pixelBuffer: pixelBuffer,
			preset: preset,
			tokens: tokens,
			previousFrame: aspectChanged ? lastRenderedOverlay : nil
		)
		
		// Phase 4.3: Record overlay rendering time
		let overlayRenderTime = Date().timeIntervalSince(overlayStartTime)
		lastOverlayRenderTime = overlayRenderTime
		diagnostics?.logEvent(.overlayRendered, metadata: [
			"render_time_ms": overlayRenderTime * 1000,
			"preset": preset.name,
			"aspect_changed": aspectChanged
		])
		
		// Cache the rendered overlay and aspect
		lastRenderedOverlay = overlayImage
		lastAspectRatio = currentAspect
		
		// Convert CIImage to CGImage and draw it
		if let cgImage = CIContext().createCGImage(overlayImage, from: overlayImage.extent) {
			context.draw(cgImage, in: rect)
		}
	}
	
	// MARK: Camera Setup
	
	// NOTE: This method is REQUIRED - sets up physical camera capture for extension
	private func setupCaptureSession() {
		print("🔧 [Camera Extension] Setting up capture session using CaptureSessionManager...")
		extensionLogger.debug("Setting up Camera Extension capture session using shared CaptureSessionManager...")
		
		// Use the shared CaptureSessionManager (same as main app)
		captureSessionManager = CaptureSessionManager(capturingHeadliner: false)
		
		if let manager = captureSessionManager, manager.configured {
			print("✅ [Camera Extension] CaptureSessionManager configured successfully")
			extensionLogger.debug("CaptureSessionManager configured successfully for Camera Extension")
			
			// Configure video output for our specific needs
			if let videoOutput = manager.videoOutput {
				videoOutput.videoSettings = [
					kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
				]
				videoOutput.alwaysDiscardsLateVideoFrames = true
							print("✅ [Camera Extension] Video output configured for virtual camera")
		}
		
		// If we have a stored device ID, verify it's applied to the new capture session
		if let deviceID = selectedCameraDeviceID {
			extensionLogger.debug("Verifying stored device selection: \(deviceID) in new capture session")
			if let input = manager.captureSession.inputs.first as? AVCaptureDeviceInput {
				extensionLogger.debug("Capture session configured with device: \(input.device.localizedName) (ID: \(input.device.uniqueID))")
				if input.device.uniqueID == deviceID {
					extensionLogger.debug("✅ Device selection correctly applied to capture session")
				} else {
					extensionLogger.warning("⚠️ Device selection mismatch - expected: \(deviceID), got: \(input.device.uniqueID)")
				}
			}
		}
	} else {
		print("❌ [Camera Extension] Failed to configure CaptureSessionManager")
		extensionLogger.error("Failed to configure CaptureSessionManager for Camera Extension")
	}
	}
	
	// Enhanced device selection method with better error handling and fallback
	func setCameraDevice(_ deviceID: String) {
		print("📷 [Camera Extension] Setting camera device to: \(deviceID)")
		extensionLogger.debug("Setting camera device to: \(deviceID)")
		
		// Store the selected device ID for when capture session initializes
		selectedCameraDeviceID = deviceID
		
		// Phase 2.3: Enhanced device switching with live camera reconfiguration
		if let manager = captureSessionManager {
			// If camera is currently running, perform live device switch
			if manager.captureSession.isRunning {
				extensionLogger.debug("Performing live camera device switch during streaming")
				
				// Manual configuration for better control and debugging
				manager.captureSession.beginConfiguration()
				
				// Remove existing camera input
				if let currentInput = manager.captureSession.inputs.first {
					manager.captureSession.removeInput(currentInput)
					if let deviceInput = currentInput as? AVCaptureDeviceInput {
						extensionLogger.debug("Removed existing camera input: \(deviceInput.device.localizedName)")
					} else {
						extensionLogger.debug("Removed existing camera input")
					}
				}
				
				// Add new camera input
				if let newDevice = findDeviceByID(deviceID),
				   let newInput = try? AVCaptureDeviceInput(device: newDevice),
				   manager.captureSession.canAddInput(newInput) {
					manager.captureSession.addInput(newInput)
					manager.captureSession.commitConfiguration()
					extensionLogger.debug("✅ Live camera device switch successful")
					
					// Report device switch success with device name  
					ExtensionStatusManager.writeStatus(.streaming, deviceName: newDevice.localizedName)
				} else {
					manager.captureSession.commitConfiguration()
					extensionLogger.error("❌ Failed to switch to device: \(deviceID)")
					
					// Enhanced error reporting
					if let newDevice = findDeviceByID(deviceID) {
						extensionLogger.error("Device found but input creation failed: \(newDevice.localizedName)")
					} else {
						extensionLogger.error("Device not found: \(deviceID)")
					}
					
					ExtensionStatusManager.writeStatus(.error, error: "Failed to switch camera device")
				}
			} else {
				// Camera not running - device change will take effect on next start
				extensionLogger.debug("Camera not active - device change will apply on next start")
			}
		} else {
			extensionLogger.debug("No capture session manager - device change will apply on camera initialization")
		}
	}
	
	private func findDeviceByID(_ deviceID: String) -> AVCaptureDevice? {
		let discoverySession = AVCaptureDevice.DiscoverySession(
			deviceTypes: [.builtInWideAngleCamera, .deskViewCamera, .external, .continuityCamera],
			mediaType: .video,
			position: .unspecified
		)
		
		return discoverySession.devices.first { $0.uniqueID == deviceID }
	}
	

	
	
	// MARK: - Camera Dimensions Caching
	
	// NOTE: REQUIRED - Cache camera dimensions for main app overlay rendering and preview sizing
	/// Cache the actual camera dimensions in App Group for overlay rendering sync
	private func cacheCameraDimensions(width: Int, height: Int) {
		guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup) else {
			extensionLogger.error("Failed to access App Group UserDefaults for caching camera dimensions")
			return
		}
		
		// Read current settings or create default
		var settings: OverlaySettings
		if let data = userDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
		   let decoded = try? JSONDecoder().decode(OverlaySettings.self, from: data) {
			settings = decoded
		} else {
			settings = OverlaySettings()
		}
		
		// Update camera dimensions
		settings.cameraDimensions = CGSize(width: width, height: height)
		
		// Write back to App Group
		if let encoded = try? JSONEncoder().encode(settings) {
			userDefaults.set(encoded, forKey: OverlayUserDefaultsKeys.overlaySettings)
			userDefaults.synchronize()
			extensionLogger.debug("📐 Cached camera dimensions: \(width)x\(height) to App Group")
		} else {
			extensionLogger.error("Failed to encode OverlaySettings with camera dimensions")
		}
	}
	
	// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
	
	// NOTE: This method is REQUIRED - captures frames from physical camera for virtual camera output
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		// Store the latest camera frame for use by the virtual camera timer
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			print("❌ [Camera Extension] Failed to get pixel buffer from sample buffer")
			// Phase 4.2: Handle frame extraction error
			errorManager?.handleError(.sampleBufferCreationFailed(-1))
			return
		}
		
		// Phase 4.2: Reset error tracking on successful frame capture
		errorManager?.recordSuccess()
		
		// UNUSED: Legacy overlay sizing debug logging - can be removed
		// Log camera input resolution for debugging overlay sizing
		if self._frameCount == 0 {
			let inputWidth = CVPixelBufferGetWidth(pixelBuffer)
			let inputHeight = CVPixelBufferGetHeight(pixelBuffer)
			print("📐 [Camera Extension] Real camera input: \(inputWidth)x\(inputHeight), Virtual output: 1920x1080")
			extensionLogger.debug("Camera input resolution: \(inputWidth)x\(inputHeight), Virtual output: 1920x1080")
		}
		
		// Phase 4.2: Store camera frame using performance manager's retention policy
		_cameraFrameLock.lock()
		if performanceManager?.shouldRetainFrame(frameCount: _frameCount) == true || _currentCameraFrame == nil {
			_currentCameraFrame = pixelBuffer
		}
		_cameraFrameLock.unlock()
		
		// UNUSED: Legacy frame counting for overlay sizing - can be removed
		// Log occasionally to avoid spam
		self._frameCount += 1
	}
	
	private func getCurrentDeviceName() -> String? {
		guard let manager = captureSessionManager,
		      let input = manager.captureSession.inputs.first as? AVCaptureDeviceInput else {
			return nil
		}
		return input.device.localizedName
	}
	
	/// Health check using error manager
	func performHealthCheck() -> Bool {
		return errorManager?.isSystemHealthy() ?? false
	}
	
	// MARK: - Phase 4.2: Capture Session Interruption Handling
	
	@objc private func captureSessionWasInterrupted(_ notification: Notification) {
		extensionLogger.warning("⚠️ Capture session was interrupted")
		
		// Phase 4.2: Handle interruption through error manager
		errorManager?.handleError(.captureSessionInterrupted)
	}
	
	@objc private func captureSessionInterruptionEnded(_ notification: Notification) {
		extensionLogger.debug("✅ Capture session interruption ended - attempting recovery")
		
		// Phase 4.2: Reset error tracking through error manager
		errorManager?.recordSuccess()
		
		// Ensure session is running if we should be streaming
		_streamStateLock.lock()
		let shouldBeStreaming = _isAppControlledStreaming || (_streamingCounter > 0 && ExtensionStatusManager.getAutoStartEnabled())
		_streamStateLock.unlock()
		
		if shouldBeStreaming {
			if let manager = captureSessionManager, !manager.captureSession.isRunning {
				manager.captureSession.startRunning()
				extensionLogger.debug("🚀 Restarted capture session after interruption ended")
			}
		}
	}
	
	deinit {
		// Phase 4.2: Cleanup dedicated managers
		errorManager = nil
		performanceManager = nil
		
		// Phase 2.4: Cleanup heartbeat timer
		stopHeartbeatTimer()
		
		// NOTE: This removes AVFoundation system notification observers (capture session interruptions)
		// This is NOT related to our custom notification migration - it's for system hardware events
		NotificationCenter.default.removeObserver(self)
		extensionLogger.debug("🧼 Cleaned up CameraExtensionDeviceSource resources")
	}
}

// MARK: - Phase 4.2: Error Manager Delegate

extension CameraExtensionDeviceSource: CameraExtensionErrorManagerDelegate {
	
	func errorManager(_ manager: CameraExtensionErrorManager, needsLightweightRecovery completion: @escaping (Bool) -> Void) {
		guard let captureManager = captureSessionManager else {
			completion(false)
			return
		}
		
		// Reconnect video output delegate
		if let videoOutput = captureManager.videoOutput {
			videoOutput.setSampleBufferDelegate(nil, queue: nil)
			videoOutput.setSampleBufferDelegate(self, queue: captureManager.dataOutputQueue)
			extensionLogger.debug("🔗 Reconnected video output delegate")
		}
		
		// Clear current frame to reset state
		_cameraFrameLock.lock()
		_currentCameraFrame = nil
		_cameraFrameLock.unlock()
		
		completion(true)
	}
	
	func errorManager(_ manager: CameraExtensionErrorManager, needsFullRecovery completion: @escaping (Bool) -> Void) {
		// Stop current session if running
		if let captureManager = captureSessionManager, captureManager.captureSession.isRunning {
			captureManager.captureSession.stopRunning()
			extensionLogger.debug("🛑 Stopped existing capture session for full recovery")
		}
		
		// Reinitialize capture session
		captureSessionManager = nil
		setupCaptureSession()
		
		// Restart if we have a valid session
		let success = captureSessionManager?.configured == true
		if success, let manager = captureSessionManager {
			manager.videoOutput?.setSampleBufferDelegate(self, queue: manager.dataOutputQueue)
			manager.captureSession.startRunning()
			extensionLogger.debug("✅ Full recovery completed successfully")
		} else {
			extensionLogger.error("💥 Full recovery failed - capture session still not configured")
		}
		
		completion(success)
	}
	
	func errorManager(_ manager: CameraExtensionErrorManager, permissionsCheckRequired completion: @escaping (Bool) -> Void) {
		let hasPermission = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
		completion(hasPermission)
	}
}

// MARK: - Phase 4.2: Performance Manager Delegate

extension CameraExtensionDeviceSource: CameraExtensionPerformanceManagerDelegate {
	
	func performanceManager(_ manager: CameraExtensionPerformanceManager, shouldClearCaches: Bool) {
		if shouldClearCaches {
			// Cast to CameraOverlayRenderer to access clearCaches method
			if let cameraRenderer = overlayRenderer as? CameraOverlayRenderer {
				cameraRenderer.clearCaches()
				extensionLogger.debug("🧼 Cleared overlay caches due to performance optimization")
			}
		}
	}
	
	func performanceManager(_ manager: CameraExtensionPerformanceManager, shouldDropCurrentFrame: Bool) {
		if shouldDropCurrentFrame {
			_cameraFrameLock.lock()
			_currentCameraFrame = nil
			_cameraFrameLock.unlock()
			extensionLogger.debug("💥 Dropped current frame for memory optimization")
		}
	}
}

// MARK: - Diagnostic System Delegate

extension CameraExtensionDeviceSource: CameraExtensionDiagnosticsDelegate {
	
	func diagnostics(_ manager: CameraExtensionDiagnostics, didUpdateMetrics metrics: DiagnosticMetrics) {
		// Log periodic metrics updates for monitoring
		extensionLogger.debug("📊 Metrics Update: FPS=\(String(format: "%.1f", metrics.frameRate)), Memory=\(String(format: "%.1f", metrics.memoryUsageMB))MB, Health=\(metrics.systemHealth.emoji)\(metrics.systemHealth.rawValue)")
	}
	
	func diagnostics(_ manager: CameraExtensionDiagnostics, didDetectIssue issue: String, severity: OSLogType) {
		switch severity {
		case .error:
			extensionLogger.error("🚨 Diagnostic Issue: \(issue, privacy: .public)")
		default:
			extensionLogger.warning("⚠️ Diagnostic Issue: \(issue, privacy: .public)")
		}
	}
}

// MARK: -

class CameraExtensionStreamSource: NSObject, CMIOExtensionStreamSource {
	
	private(set) var stream: CMIOExtensionStream!
	
	let device: CMIOExtensionDevice
	
	private let _streamFormat: CMIOExtensionStreamFormat
	
	init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice) {
		
		self.device = device
		self._streamFormat = streamFormat
		super.init()
		self.stream = CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction: .source, clockType: .hostTime, source: self)
	}
	
	var formats: [CMIOExtensionStreamFormat] {
		
		return [_streamFormat]
	}
	
	var activeFormatIndex: Int = 0 {
		
		didSet {
			if activeFormatIndex >= 1 {
				extensionLogger.error("Invalid index")
			}
		}
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		return [.streamActiveFormatIndex, .streamFrameDuration]
	}
	
	func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
		
		let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
		if properties.contains(.streamActiveFormatIndex) {
			streamProperties.activeFormatIndex = 0
		}
		if properties.contains(.streamFrameDuration) {
			let frameDuration = CMTime(value: 1, timescale: Int32(kFrameRate))
			streamProperties.frameDuration = frameDuration
		}
		
		return streamProperties
	}
	
	func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
		
		if let activeFormatIndex = streamProperties.activeFormatIndex {
			self.activeFormatIndex = activeFormatIndex
		}
	}
	
	func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
		extensionLogger.debug("External app requesting stream authorization: \(client.clientID)")
		// An opportunity to inspect the client info and decide if it should be allowed to start the stream.
		return true
	}
	
	func startStream() throws {
		extensionLogger.debug("External app starting virtual camera stream")
		guard let deviceSource = device.source as? CameraExtensionDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.startStreaming()
	}
	
	func stopStream() throws {
		extensionLogger.debug("External app stopping virtual camera stream")
		guard let deviceSource = device.source as? CameraExtensionDeviceSource else {
			fatalError("Unexpected source type \(String(describing: device.source))")
		}
		deviceSource.stopStreaming()
	}
}

// MARK: -

class CameraExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
	
	private(set) var provider: CMIOExtensionProvider!
	
	private var deviceSource: CameraExtensionDeviceSource!
    
    private var notificationListenerStarted = false

	
	// CMIOExtensionProviderSource protocol methods (all are required)
	
	init(clientQueue: DispatchQueue?) {
		
		super.init()
        startNotificationListeners()
        
		provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
		deviceSource = CameraExtensionDeviceSource(localizedName: "Headliner")
		
		do {
			try provider.addDevice(deviceSource.device)
		} catch let error {
			fatalError("Failed to add device: \(error.localizedDescription)")
		}

		// Signal readiness to the container app via shared defaults
        if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
			sharedDefaults.set(true, forKey: "ExtensionProviderReady")
			sharedDefaults.synchronize()
			extensionLogger.debug("✅ Marked ExtensionProviderReady in shared defaults")
		}
	}
    
    deinit {
        stopNotificationListeners()
    }
	
    // MARK: Internal
    
	// UNUSED: Empty method stubs - can be removed
	func connect(to client: CMIOExtensionClient) throws {
		
		// Handle client connect
	}
	
	// UNUSED: Empty method stub - can be removed
	func disconnect(from client: CMIOExtensionClient) {
		
		// Handle client disconnect
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		// See full list of CMIOExtensionProperty choices in CMIOExtensionProperties.h
		return [.providerManufacturer]
	}
	
	func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
		
		let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
		if properties.contains(.providerManufacturer) {
			providerProperties.manufacturer = "Headliner Manufacturer"
		}
		return providerProperties
	}
	
	// UNUSED: Empty method stub - can be removed
	func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
		
		// Handle settable properties here.
	}
    
    // MARK: Private
    
    private func notificationReceived(notificationName: String) {
        extensionLogger.debug("📡 Received notification: \(notificationName)")
        
        guard let name = CrossAppNotificationName(rawValue: notificationName) else {
            extensionLogger.debug("❌ Unknown notification name: \(notificationName)")
            return
        }

        switch name {
        case .startStream:
            extensionLogger.debug("App requesting camera stream start")
            deviceSource.startAppControlledStreaming()
        case .stopStream:
            extensionLogger.debug("App requesting camera stream stop")
            deviceSource.stopAppControlledStreaming()
        case .setCameraDevice:
            extensionLogger.debug("📡 Camera device selection changed - processing notification")
            handleCameraDeviceChange()
        case .updateOverlaySettings:
            extensionLogger.debug("🎨 Overlay settings changed - updating now")
            deviceSource.updateOverlaySettings()
        case .overlayUpdated:
            extensionLogger.debug("📡 Pre-rendered overlay updated - will be refreshed on next frame")
        // Phase 2: New enhanced notifications
        case .requestStart:
            extensionLogger.debug("📡 Request start - same as startStream")
            deviceSource.startAppControlledStreaming()
        case .requestStop:
            extensionLogger.debug("📡 Request stop - same as stopStream")
            deviceSource.stopAppControlledStreaming()
        case .requestSwitchDevice:
            extensionLogger.debug("📡 Request switch device - same as setCameraDevice")
            handleCameraDeviceChange()
        case .statusChanged:
            extensionLogger.debug("📡 Status changed notification - no action needed (app-side notification)")
        }
    }

    private func startNotificationListeners() {
        for notificationName in CrossAppNotificationName.allCases {
            let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

            CrossAppExtensionNotifications.addObserver(
                observer: observer,
                callback: { _, observer, name, _, _ in
                    if let observer = observer, let name = name {
                        let extensionProviderSourceSelf = Unmanaged<CameraExtensionProviderSource>.fromOpaque(observer).takeUnretainedValue()
                        extensionProviderSourceSelf.notificationReceived(notificationName: name.rawValue as String)
                    }
                },
                name: notificationName
            )
        }
        
        notificationListenerStarted = true
        extensionLogger.debug("✅ Started notification listeners for \(CrossAppNotificationName.allCases.count) notifications")
    }

    private func stopNotificationListeners() {
        if notificationListenerStarted {
            let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
            CrossAppExtensionNotifications.removeAllObservers(observer: observer)
            notificationListenerStarted = false
        }
    }
    
    private func handleCameraDeviceChange() {
        // Read camera device ID from UserDefaults
        if let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
           let deviceID = userDefaults.string(forKey: ExtensionStatusKeys.selectedDeviceID) {
            extensionLogger.debug("📡 Camera device change notification - setting device to: \(deviceID)")
            
            // Add a small delay to ensure UserDefaults are fully written
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Re-read to ensure we have the latest value
                if let latestDeviceID = userDefaults.string(forKey: ExtensionStatusKeys.selectedDeviceID),
                   latestDeviceID == deviceID {
                    extensionLogger.debug("✅ Confirmed device selection: \(latestDeviceID)")
                    self.deviceSource.setCameraDevice(latestDeviceID)
                } else {
                    extensionLogger.warning("⚠️ Device ID changed during processing - expected: \(deviceID)")
                }
            }
        } else {
            extensionLogger.warning("⚠️ No device ID found in UserDefaults for camera change")
        }
    }
}

