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

let kWhiteStripeHeight: Int = 10
let kFrameRate: Int = 60


private let extensionLogger = HeadlinerLogger.logger(for: .cameraExtension)

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
	
	// Current camera frame storage
	private var _currentCameraFrame: CVPixelBuffer?
	private let _cameraFrameLock = NSLock()
	
	// Frame counting for logging
	private var _frameCount = 0
	
	// Streaming state management
	private var _isAppControlledStreaming = false
	private let _streamStateLock = NSLock()
	
	// Camera capture components - using shared CaptureSessionManager
	private var captureSessionManager: CaptureSessionManager?
	private var selectedCameraDevice: AVCaptureDevice?
	
	// Overlay settings
	private var overlaySettings: OverlaySettings = OverlaySettings()
	private let overlaySettingsLock = NSLock()
	
	// Preset system components
	private var overlayRenderer: CameraOverlayRenderer?
	private var overlayPresetStore: OverlayPresetStore?
	private var lastRenderedOverlay: CIImage?
	private var lastAspectRatio: OverlayAspect?
	
	// Frame sharing service for live preview
	private var frameSharingService: FrameSharingService?
	
	// Composition queue for thread safety
	private let compositionQueue = DispatchQueue(label: "com.headliner.composition", qos: .userInteractive)
	
	init(localizedName: String) {
		
		super.init()
		let deviceID = UUID() // replace this with your device UUID
		self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)
		
		let dims = CMVideoDimensions(width: 1920, height: 1080)
		CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault, codecType: kCVPixelFormatType_32BGRA, width: dims.width, height: dims.height, extensions: nil, formatDescriptionOut: &_videoDescription)
		
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
		
		// Initialize capture session using shared CaptureSessionManager
		extensionLogger.debug("🚀 CameraExtensionDeviceSource init - about to call setupCaptureSession")
		setupCaptureSession()
		extensionLogger.debug("✅ CameraExtensionDeviceSource init - setupCaptureSession completed")
		
		// Load overlay settings
		loadOverlaySettings()
		extensionLogger.debug("✅ CameraExtensionDeviceSource init - overlay settings loaded")
		
		// Initialize preset system components
		// Use thread-safe renderer with Core frameworks only (no AppKit)
		overlayRenderer = CameraOverlayRenderer()
		overlayPresetStore = OverlayPresetStore()
		extensionLogger.debug("✅ Initialized camera overlay renderer (thread-safe, Metal-backed)")
		
		// Initialize frame sharing service for live preview
		frameSharingService = FrameSharingService()
		extensionLogger.debug("✅ Initialized frame sharing service for live preview")
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
	
	func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
		
		// Handle settable properties here.
	}
	
	func startStreaming() {
		extensionLogger.debug("Virtual camera requested by external app - starting frame generation")
		
		guard let _ = _bufferPool else {
			extensionLogger.error("No buffer pool available")
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
		
		// Only start real camera capture if app has enabled streaming
		_streamStateLock.lock()
		let shouldStartCameraCapture = _isAppControlledStreaming
		_streamStateLock.unlock()
		
		if shouldStartCameraCapture {
			startCameraCapture()
		} else {
			extensionLogger.debug("App-controlled streaming not enabled - showing splash screen")
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
		
		// Clear frame cache and notify main app
		frameSharingService?.clearCache()
		NotificationManager.postNotification(named: .streamStopped)
	}
	
	private func startCameraCapture() {
		print("🎬 [Camera Extension] Starting real camera capture...")
		extensionLogger.debug("Starting real camera capture...")
		
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
			} else {
				print("✅ [Camera Extension] Capture session already running")
				extensionLogger.debug("Capture session already running")
			}
		} else {
			print("❌ [Camera Extension] CaptureSessionManager not configured - retrying setup")
			extensionLogger.error("CaptureSessionManager not configured - attempting retry")
			setupCaptureSession()
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
			
			// Stop real camera capture session
			stopCameraCapture()
			
			// Clear frame cache and notify main app
			frameSharingService?.clearCache()
			NotificationManager.postNotification(named: .streamStopped)
			
			// Also disable app-controlled streaming
			_streamStateLock.lock()
			_isAppControlledStreaming = false
			_streamStateLock.unlock()
		}
	}
	
	// MARK: Virtual Camera Frame Generation
	
	private func generateVirtualCameraFrame() {
		guard _streamingCounter > 0 else { return }
		
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
			return
		}
		
		guard let pixelBuffer = pixelBuffer else {
			extensionLogger.error("Pixel buffer is nil")
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
			extensionLogger.debug("Sending virtual camera frame to stream")
			_streamSource.stream.send(
				sampleBuffer,
				discontinuity: [],
				hostTimeInNanoseconds: UInt64(timingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC))
			)
			
			// Cache frame for live preview in main app (zero-copy via IOSurface)
			// IMPORTANT: Cache first, then notify to ensure frame is ready when fetched
			frameSharingService?.cacheFrame(pixelBuffer: pixelBuffer, pts: timingInfo.presentationTimeStamp)
			
			// Notify main app that a new frame is available (after caching)
			NotificationManager.postNotification(named: .frameAvailable)
		} else {
			extensionLogger.error("Failed to create sample buffer: \(err)")
		}
	}
	
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
			.foregroundColor: NSColor.white,
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
		let statusColor = isAppStreaming ? NSColor.systemGreen : NSColor.systemGray
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
			.foregroundColor: NSColor.systemGray,
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
	
	private func drawOverlays(on context: CGContext, in rect: CGRect) {
		self.overlaySettingsLock.lock()
		let settings = self.overlaySettings
		self.overlaySettingsLock.unlock()
		
		// Only draw overlays if enabled
		guard settings.isEnabled else { return }
		
		// Setup NSGraphicsContext for text drawing
		let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
		NSGraphicsContext.saveGraphicsState()
		NSGraphicsContext.current = graphicsContext
		
		// Draw user name overlay if enabled and name is provided
		if settings.showUserName && !settings.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			drawUserNameOverlay(settings: settings, in: rect)
		}
		
		// Draw version overlay if enabled
		if settings.showVersion {
			drawVersionOverlay(settings: settings, in: rect)
		}
		
		NSGraphicsContext.restoreGraphicsState()
	}
	
	private func drawUserNameOverlay(settings: OverlaySettings, in rect: CGRect) {
		let userName = settings.userName.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !userName.isEmpty else { return }
		
		// Create attributed string for the user name
		let font = NSFont.systemFont(ofSize: settings.fontSize, weight: .medium)
		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.foregroundColor: settings.nameTextColor.nsColor
		]
		
		let attributedString = NSAttributedString(string: userName, attributes: attributes)
		let textSize = attributedString.size()
		
		// Calculate background rect with padding
		let backgroundWidth = textSize.width + (settings.padding * 2)
		let backgroundHeight = textSize.height + (settings.padding * 2)
		
		// Calculate position based on overlay position setting
		let overlayRect = calculateOverlayRect(
			size: CGSize(width: backgroundWidth, height: backgroundHeight),
			position: settings.namePosition,
			containerRect: rect,
			margin: settings.margin
		)
		
		// Draw background with corner radius
		let backgroundPath = NSBezierPath(roundedRect: overlayRect, xRadius: settings.cornerRadius, yRadius: settings.cornerRadius)
		settings.nameBackgroundColor.nsColor.setFill()
		backgroundPath.fill()
		
		// Draw text centered in the background
		let textRect = CGRect(
			x: overlayRect.origin.x + settings.padding,
			y: overlayRect.origin.y + settings.padding,
			width: textSize.width,
			height: textSize.height
		)
		
		attributedString.draw(in: textRect)
	}
	
	private func drawVersionOverlay(settings: OverlaySettings, in rect: CGRect) {
		// Resolve version text from bundle
		let bundle = Bundle.main
		let shortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
		let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
		let versionText = "Headliner V\(shortVersion) (\(buildNumber))"
		
		let font = NSFont.systemFont(ofSize: settings.versionFontSize, weight: .regular)
		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.foregroundColor: settings.versionTextColor.nsColor
		]
		let attributedString = NSAttributedString(string: versionText, attributes: attributes)
		let textSize = attributedString.size()
		
		let backgroundWidth = textSize.width + (settings.padding * 2)
		let backgroundHeight = textSize.height + (settings.padding * 2)
		
		let overlayRect = calculateOverlayRect(
			size: CGSize(width: backgroundWidth, height: backgroundHeight),
			position: settings.versionPosition,
			containerRect: rect,
			margin: settings.margin
		)
		
		let backgroundPath = NSBezierPath(roundedRect: overlayRect, xRadius: settings.cornerRadius, yRadius: settings.cornerRadius)
		settings.versionBackgroundColor.nsColor.setFill()
		backgroundPath.fill()
		
		let textRect = CGRect(
			x: overlayRect.origin.x + settings.padding,
			y: overlayRect.origin.y + settings.padding,
			width: textSize.width,
			height: textSize.height
		)
		attributedString.draw(in: textRect)
	}
	
	private func calculateOverlayRect(size: CGSize, position: OverlayPosition, containerRect: CGRect, margin: CGFloat) -> CGRect {
		let x: CGFloat
		let y: CGFloat
		
		switch position {
		case .topLeft:
			x = margin
			y = containerRect.height - size.height - margin
		case .topCenter:
			x = (containerRect.width - size.width) / 2
			y = containerRect.height - size.height - margin
		case .topRight:
			x = containerRect.width - size.width - margin
			y = containerRect.height - size.height - margin
		case .centerLeft:
			x = margin
			y = (containerRect.height - size.height) / 2
		case .center:
			x = (containerRect.width - size.width) / 2
			y = (containerRect.height - size.height) / 2
		case .centerRight:
			x = containerRect.width - size.width - margin
			y = (containerRect.height - size.height) / 2
		case .bottomLeft:
			x = margin
			y = margin
		case .bottomCenter:
			x = (containerRect.width - size.width) / 2
			y = margin
		case .bottomRight:
			x = containerRect.width - size.width - margin
			y = margin
		}
		
		return CGRect(x: x, y: y, width: size.width, height: size.height)
	}
	
	// MARK: Overlay Settings Management
	
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
	
	private func drawOverlaysWithPresetSystem(pixelBuffer: CVPixelBuffer, context: CGContext, rect: CGRect) {
		guard let renderer = overlayRenderer,
		      let presetStore = overlayPresetStore else {
			extensionLogger.error("Preset system components not initialized")
			return
		}
		
		overlaySettingsLock.lock()
		let settings = self.overlaySettings
		overlaySettingsLock.unlock()
		
		// Only draw overlays if enabled
		guard settings.isEnabled else { return }
		
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
		}
		
		// Update tokens with current user name if needed
		if tokens.displayName.isEmpty {
			tokens.displayName = settings.userName.isEmpty ? NSUserName() : settings.userName
		}
		
		// Check for aspect ratio change
		let currentAspect = settings.overlayAspect
		let aspectChanged = lastAspectRatio != nil && lastAspectRatio != currentAspect
		
		// Notify renderer about aspect change for optimized crossfade
		if aspectChanged {
			renderer.notifyAspectChanged()
		}
		
		// Render overlay using Core Image renderer
		let overlayImage = renderer.render(
			pixelBuffer: pixelBuffer,
			preset: preset,
			tokens: tokens,
			previousFrame: aspectChanged ? lastRenderedOverlay : nil
		)
		
		// Cache the rendered overlay and aspect
		lastRenderedOverlay = overlayImage
		lastAspectRatio = currentAspect
		
		// Convert CIImage to CGImage and draw it
		if let cgImage = CIContext().createCGImage(overlayImage, from: overlayImage.extent) {
			context.draw(cgImage, in: rect)
		}
	}
	
	// MARK: Camera Setup
	
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
		} else {
			print("❌ [Camera Extension] Failed to configure CaptureSessionManager")
			extensionLogger.error("Failed to configure CaptureSessionManager for Camera Extension")
		}
	}
	
	func setCameraDevice(_ deviceID: String) {
		print("📷 [Camera Extension] Setting camera device to: \(deviceID)")
		extensionLogger.debug("Setting camera device to: \(deviceID)")
		
		// Store the selected device ID in UserDefaults so CaptureSessionManager can use it
        if let userDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
			userDefaults.set(deviceID, forKey: "SelectedCameraID")
			userDefaults.synchronize()
			print("✅ [Camera Extension] Saved camera device selection to UserDefaults")
		}
		
		// Recreate the capture session with the new device
		setupCaptureSession()
	}
	

	
	// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
	
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		// Store the latest camera frame for use by the virtual camera timer
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			print("❌ [Camera Extension] Failed to get pixel buffer from sample buffer")
			return
		}
		
		// Store the current camera frame (thread-safe)
		_cameraFrameLock.lock()
		_currentCameraFrame = pixelBuffer
		_cameraFrameLock.unlock()
		
		// Log occasionally to avoid spam
		self._frameCount += 1
		if self._frameCount == 1 {
			print("🎉 [Camera Extension] Received FIRST camera frame! Camera capture is working.")
			extensionLogger.debug("Received first camera frame - camera capture is working")
		} else if self._frameCount % 60 == 0 {
			print("📸 [Camera Extension] Captured real camera frame \(self._frameCount)")
			extensionLogger.debug("Captured real camera frame \(self._frameCount) for virtual camera content")
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
    
    private let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
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
    
	func connect(to client: CMIOExtensionClient) throws {
		
		// Handle client connect
	}
	
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
	
	func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
		
		// Handle settable properties here.
	}
    
    // MARK: Private
    
    private func notificationReceived(notificationName: String) {
        extensionLogger.debug("📡 Received notification: \(notificationName)")
        
        guard let name = NotificationName(rawValue: notificationName) else {
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
            extensionLogger.debug("Camera device selection changed")
            handleCameraDeviceChange()
        case .updateOverlaySettings:
            extensionLogger.debug("🎨 Overlay settings changed - updating now")
            deviceSource.updateOverlaySettings()
        case .frameAvailable, .streamStopped:
            // These notifications are sent BY the extension TO the main app
            // The extension doesn't need to handle them, but we include them
            // here to satisfy the exhaustive switch requirement
            break
        }
    }

    private func startNotificationListeners() {
        for notificationName in NotificationName.allCases {
            let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), observer, { _, observer, name, _, _ in
                if let observer = observer, let name = name {
                    let extensionProviderSourceSelf = Unmanaged<CameraExtensionProviderSource>.fromOpaque(observer).takeUnretainedValue()
                    extensionProviderSourceSelf.notificationReceived(notificationName: name.rawValue as String)
                }
            },
            notificationName.rawValue as CFString, nil, .deliverImmediately)
        }
    }

    private func stopNotificationListeners() {
        if notificationListenerStarted {
            CFNotificationCenterRemoveEveryObserver(notificationCenter,
                                                    Unmanaged.passRetained(self)
                                                        .toOpaque())
            notificationListenerStarted = false
        }
    }
    
    private func handleCameraDeviceChange() {
        // Read camera device ID from UserDefaults
        if let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
           let deviceID = userDefaults.string(forKey: "SelectedCameraID") {
            extensionLogger.debug("Setting camera device to: \(deviceID)")
            deviceSource.setCameraDevice(deviceID)
        }
    }
}

