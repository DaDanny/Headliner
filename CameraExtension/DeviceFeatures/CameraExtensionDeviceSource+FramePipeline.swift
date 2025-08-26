//
//  CameraExtensionDeviceSource+FramePipeline.swift
//  CameraExtension
//
//  Extracted from CameraExtensionProvider.swift on 2025-01-28. No functional changes.
//

import Foundation
import CoreMediaIO
import AVFoundation
import Cocoa
import OSLog

// MARK: - Logger Access

// Access shared loggers from core
fileprivate let extensionLogger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Extension")
fileprivate let diagnosticsLogger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Diagnostics")

// MARK: - CameraExtensionDeviceSource+FramePipeline

extension CameraExtensionDeviceSource {
	
	// MARK: Virtual Camera Frame Generation
	
	func generateVirtualCameraFrame() {
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
	
	// MARK: Splash Screen Rendering
	
	// UNUSED: Legacy splash screen text rendering - can be simplified to just show "Headliner" logo
	fileprivate func drawSplashScreen(context: CGContext, rect: CGRect) {
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
	
	fileprivate func createCGImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
		let context = CIContext(options: nil)
		return context.createCGImage(ciImage, from: ciImage.extent)
	}
	
	// MARK: Overlay Settings Management
	
	// UNUSED: Legacy overlay settings loading from Core Graphics system - can be removed
	func loadOverlaySettings() {
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
	fileprivate func drawOverlaysWithPresetSystem(pixelBuffer: CVPixelBuffer, context: CGContext, rect: CGRect) {
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
	
	// MARK: - Camera Dimensions Caching
	
	// NOTE: REQUIRED - Cache camera dimensions for main app overlay rendering and preview sizing
	/// Cache the actual camera dimensions in App Group for overlay rendering sync
	func cacheCameraDimensions(width: Int, height: Int) {
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
}

// MARK: - Performance Manager Delegate (moved from core)

extension CameraExtensionDeviceSource {
	
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