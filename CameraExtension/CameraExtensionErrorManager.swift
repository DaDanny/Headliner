//
//  CameraExtensionErrorManager.swift
//  CameraExtension
//
//  Phase 4.2: Dedicated error handling and recovery management
//  Extracted from CameraExtensionProvider for better separation of concerns
//

import Foundation
import AVFoundation
import OSLog

// MARK: - Error Types

enum CameraExtensionError: Error, LocalizedError {
	case permissionDenied
	case configurationFailed
	case deviceBusy
	case pixelBufferCreationFailed(OSStatus)
	case sampleBufferCreationFailed(OSStatus)
	case frameGenerationTimeout
	case captureSessionInterrupted
	
	var errorDescription: String? {
		switch self {
		case .permissionDenied:
			return "Camera permission denied"
		case .configurationFailed:
			return "Failed to configure capture session"
		case .deviceBusy:
			return "Camera device is busy"
		case .pixelBufferCreationFailed(let status):
			return "Failed to create pixel buffer: \(status)"
		case .sampleBufferCreationFailed(let status):
			return "Failed to create sample buffer: \(status)"
		case .frameGenerationTimeout:
			return "Frame generation timeout - no frames for >5s"
		case .captureSessionInterrupted:
			return "Capture session was interrupted"
		}
	}
}

enum RecoveryStrategy {
	case lightweight // Reconnect video output, reset buffers
	case full // Rebuild capture session completely
	case exponentialBackoff(attempt: Int) // Retry with increasing delays
}

// MARK: - Error Manager Protocol

protocol CameraExtensionErrorManagerDelegate: AnyObject {
	func errorManager(_ manager: CameraExtensionErrorManager, needsLightweightRecovery completion: @escaping (Bool) -> Void)
	func errorManager(_ manager: CameraExtensionErrorManager, needsFullRecovery completion: @escaping (Bool) -> Void)
	func errorManager(_ manager: CameraExtensionErrorManager, permissionsCheckRequired completion: @escaping (Bool) -> Void)
}

// MARK: - Dedicated Error Manager

final class CameraExtensionErrorManager {
	
	// MARK: - Properties
	
	private let logger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "ExtensionErrorManager")
	weak var delegate: CameraExtensionErrorManagerDelegate?
	
	// Error tracking
	private var consecutiveErrors: Int = 0
	private var isInRecoveryMode: Bool = false
	private let maxConsecutiveErrors = 5
	
	// Frame monitoring
	private var frameGenerationTimer: DispatchSourceTimer?
	private let recoveryQueue = DispatchQueue(label: "recoveryQueue", qos: .utility)
	private var lastFrameTime: Date = Date()
	private let frameTimeoutSeconds: TimeInterval = 5.0
	
	// MARK: - Initialization
	
	init(delegate: CameraExtensionErrorManagerDelegate? = nil) {
		self.delegate = delegate
		startFrameGenerationMonitoring()
	}
	
	deinit {
		stopFrameGenerationMonitoring()
		logger.debug("🧼 Cleaned up CameraExtensionErrorManager")
	}
	
	// MARK: - Public Interface
	
	/// Record successful operation to reset error tracking
	func recordSuccess() {
		if consecutiveErrors > 0 || isInRecoveryMode {
			consecutiveErrors = 0
			isInRecoveryMode = false
			logger.debug("✅ Reset error tracking - system healthy")
		}
	}
	
	/// Update frame generation timestamp
	func recordFrameGenerated() {
		lastFrameTime = Date()
	}
	
	/// Handle a capture error with appropriate recovery strategy
	func handleError(_ error: CameraExtensionError) {
		consecutiveErrors += 1
		logger.error("🚨 Capture error (\(self.consecutiveErrors)/\(self.maxConsecutiveErrors)): \(error.localizedDescription)")
		
		// Report error to main app
		ExtensionStatusManager.writeStatus(.error, error: error.localizedDescription)
		
		// Determine recovery strategy based on error type and count
		let strategy = determineRecoveryStrategy(for: error)
		
		if consecutiveErrors >= maxConsecutiveErrors {
			logger.error("💥 Maximum consecutive errors reached - entering recovery mode")
			isInRecoveryMode = true
			// Full recovery as last resort
			performRecovery(.full)
		} else if !isInRecoveryMode {
			// Attempt recovery based on strategy
			performRecovery(strategy)
		} else {
			logger.debug("Already in recovery mode - skipping additional recovery attempts")
		}
	}
	
	/// Check if the system is healthy
	func isSystemHealthy() -> Bool {
		let isHealthy = consecutiveErrors < maxConsecutiveErrors && !isInRecoveryMode
		logger.debug("🩺 Health check: \(isHealthy ? "healthy" : "unhealthy") (errors: \(self.consecutiveErrors), recovery: \(self.isInRecoveryMode))")
		return isHealthy
	}
	
	/// Check camera permissions
	func checkCameraPermissions() -> Bool {
		let status = AVCaptureDevice.authorizationStatus(for: .video)
		switch status {
		case .authorized:
			return true
		case .denied, .restricted:
			logger.error("🚫 Camera permission denied or restricted")
			return false
		case .notDetermined:
			logger.warning("⚠️ Camera permission not determined - may cause issues")
			return false
		@unknown default:
			logger.error("🚫 Unknown camera permission status")
			return false
		}
	}
	
	// MARK: - Private Methods
	
	/// Start monitoring frame generation for timeout detection
	private func startFrameGenerationMonitoring() {
		guard frameGenerationTimer == nil else { return }
		
		frameGenerationTimer = DispatchSource.makeTimerSource(queue: recoveryQueue)
		frameGenerationTimer!.schedule(deadline: .now() + frameTimeoutSeconds, repeating: frameTimeoutSeconds)
		
		frameGenerationTimer!.setEventHandler { [weak self] in
			guard let self = self else { return }
			
			let timeSinceLastFrame = Date().timeIntervalSince(self.lastFrameTime)
			if timeSinceLastFrame > self.frameTimeoutSeconds {
				logger.warning("⚠️ Frame generation timeout detected: \(timeSinceLastFrame)s since last frame")
				self.handleError(.frameGenerationTimeout)
			}
		}
		
		frameGenerationTimer!.setCancelHandler {
			// Cleanup handled in stopFrameGenerationMonitoring
		}
		
		frameGenerationTimer!.resume()
		logger.debug("✅ Started frame generation monitoring (\(self.frameTimeoutSeconds)s timeout)")
	}
	
	/// Stop frame generation monitoring
	private func stopFrameGenerationMonitoring() {
		if let timer = frameGenerationTimer {
			timer.cancel()
			frameGenerationTimer = nil
			logger.debug("🛑 Stopped frame generation monitoring")
		}
	}
	
	/// Determine the appropriate recovery strategy for an error
	private func determineRecoveryStrategy(for error: CameraExtensionError) -> RecoveryStrategy {
		switch error {
		case .permissionDenied:
			return .exponentialBackoff(attempt: consecutiveErrors)
		case .configurationFailed:
			return consecutiveErrors < 3 ? .lightweight : .full
		case .deviceBusy:
			return .exponentialBackoff(attempt: consecutiveErrors)
		case .pixelBufferCreationFailed, .sampleBufferCreationFailed:
			return .lightweight
		case .frameGenerationTimeout:
			return consecutiveErrors < 2 ? .lightweight : .full
		case .captureSessionInterrupted:
			return .full
		}
	}
	
	/// Perform recovery based on strategy
	private func performRecovery(_ strategy: RecoveryStrategy) {
		Task {
			switch strategy {
			case .lightweight:
				await performLightweightRecovery()
			case .full:
				await performFullRecovery()
			case .exponentialBackoff(let attempt):
				let delay = min(pow(2.0, Double(attempt)), 30.0) // Cap at 30 seconds
				logger.debug("⏱️ Exponential backoff: waiting \(delay)s before retry (attempt \(attempt))")
				try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
				await performLightweightRecovery()
			}
		}
	}
	
	/// Perform lightweight recovery
	@MainActor
	private func performLightweightRecovery() async {
		logger.debug("🔧 Performing lightweight recovery...")
		
		delegate?.errorManager(self, needsLightweightRecovery: { [weak self] success in
			guard let self = self else { return }
			
			if success {
				// Reset error count on successful lightweight recovery
				if self.consecutiveErrors > 0 {
					self.consecutiveErrors = max(0, self.consecutiveErrors - 1)
					self.logger.debug("✅ Lightweight recovery completed - reduced error count to \(self.consecutiveErrors)")
				}
				
				self.isInRecoveryMode = false
				ExtensionStatusManager.writeStatus(.streaming)
			} else {
				self.logger.error("❌ Lightweight recovery failed")
			}
		})
	}
	
	/// Perform full recovery
	@MainActor
	private func performFullRecovery() async {
		logger.debug("🔄 Performing full recovery - rebuilding capture session...")
		
		delegate?.errorManager(self, needsFullRecovery: { [weak self] success in
			guard let self = self else { return }
			
			if success {
				// Reset all error tracking on successful full recovery
				self.consecutiveErrors = 0
				self.isInRecoveryMode = false
				
				self.logger.debug("✅ Full recovery completed successfully")
				ExtensionStatusManager.writeStatus(.streaming)
			} else {
				self.logger.error("💥 Full recovery failed - capture session still not configured")
				ExtensionStatusManager.writeStatus(.error, error: "Full recovery failed")
			}
		})
	}
}