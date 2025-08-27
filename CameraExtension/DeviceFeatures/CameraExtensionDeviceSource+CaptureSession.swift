//
//  CameraExtensionDeviceSource+CaptureSession.swift
//  CameraExtension
//
//  Extracted from CameraExtensionProvider.swift on 2025-01-28. No functional changes.
//

import Foundation
import CoreMediaIO
import AVFoundation
import OSLog

// MARK: - Logger Access

// Access shared loggers from core
fileprivate let extensionLogger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Extension")

// MARK: - CameraExtensionDeviceSource+CaptureSession

extension CameraExtensionDeviceSource {
	
	// MARK: Streaming Control
	
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
		
		// Phase 1.1: Pure client-based auto-start - camera always starts when external apps connect
		extensionLogger.debug("External app connected - automatically starting camera capture")
		
		// Report auto-start status
		ExtensionStatusManager.writeStatus(.starting, error: nil)
		startCameraCapture()
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
			
			// Phase 1.1: Pure client-based logic - stop camera when no external apps are connected
			_streamStateLock.lock()
			let noExternalApps = _streamingCounter == 0
			_streamStateLock.unlock()
			
			if noExternalApps {
				// Phase 2.2: Report stopping status
				ExtensionStatusManager.writeStatus(.stopping)
				stopCameraCapture()
				// Phase 2.2: Report idle status after stopping
				ExtensionStatusManager.writeStatus(.idle)
				extensionLogger.debug("Stopped camera capture - no external apps connected")
			} else {
				extensionLogger.debug("Keeping camera active - external apps still connected (streaming counter: \(self._streamingCounter))")
			}
		}
	}
	
	
	// MARK: Camera Capture Management
	
	fileprivate func startCameraCapture() {
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
	
	fileprivate func stopCameraCapture() {
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
	
	// MARK: Heartbeat System
	
	fileprivate func startHeartbeatTimer() {
		guard _heartbeatTimer == nil else { return }
		
		_heartbeatTimer = DispatchSource.makeTimerSource(queue: _heartbeatQueue)
		_heartbeatTimer!.schedule(deadline: .now(), repeating: 2.0, leeway: .milliseconds(500))
		
		_heartbeatTimer!.setEventHandler { [weak self] in
			guard let self = self else { return }
			
			// Only send heartbeat if extension is actively streaming
			_streamStateLock.lock()
			let isActivelyStreaming = _streamingCounter > 0
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
	
	fileprivate func stopHeartbeatTimer() {
		if let timer = _heartbeatTimer {
			timer.cancel()
			_heartbeatTimer = nil
			extensionLogger.debug("🛑 Stopped heartbeat timer")
		}
	}
	
	// MARK: Capture Session Setup
	
	// NOTE: This method is REQUIRED - sets up physical camera capture for extension
	fileprivate func setupCaptureSession() {
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
	
	// MARK: Device Management
	
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
				// Camera not running - start preview mode for immediate device switching
				extensionLogger.debug("Camera not active - starting preview mode to apply device change immediately")
				
				// Check if we should start streaming (external app requesting)
				_streamStateLock.lock()
				let shouldStartPreview = _streamingCounter > 0
				_streamStateLock.unlock()
				
				if shouldStartPreview {
					extensionLogger.debug("🚀 Starting camera capture to apply device change")
					startCameraCapture()
				} else {
					extensionLogger.debug("💤 Device change queued - will apply when streaming starts")
				}
			}
		} else {
			extensionLogger.debug("No capture session manager - device change will apply on camera initialization")
		}
	}
	
	fileprivate func findDeviceByID(_ deviceID: String) -> AVCaptureDevice? {
		let discoverySession = AVCaptureDevice.DiscoverySession(
			deviceTypes: [.builtInWideAngleCamera, .deskViewCamera, .external, .continuityCamera],
			mediaType: .video,
			position: .unspecified
		)
		
		return discoverySession.devices.first { $0.uniqueID == deviceID }
	}
	
	fileprivate func getCurrentDeviceName() -> String? {
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
	
	// MARK: Capture Session Interruption Handling
	
	@objc func captureSessionWasInterrupted(_ notification: Notification) {
		extensionLogger.warning("⚠️ Capture session was interrupted")
		
		// Phase 4.2: Handle interruption through error manager
		errorManager?.handleError(.captureSessionInterrupted)
	}
	
	@objc func captureSessionInterruptionEnded(_ notification: Notification) {
		extensionLogger.debug("✅ Capture session interruption ended - attempting recovery")
		
		// Phase 4.2: Reset error tracking through error manager
		errorManager?.recordSuccess()
		
		// Ensure session is running if external apps are connected
		_streamStateLock.lock()
		let shouldBeStreaming = _streamingCounter > 0
		_streamStateLock.unlock()
		
		if shouldBeStreaming {
			if let manager = captureSessionManager, !manager.captureSession.isRunning {
				manager.captureSession.startRunning()
				extensionLogger.debug("🚀 Restarted capture session after interruption ended")
			}
		}
	}
}

// MARK: - Error Manager Delegate (moved from core)

extension CameraExtensionDeviceSource {
	
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