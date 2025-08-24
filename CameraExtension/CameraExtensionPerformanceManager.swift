//
//  CameraExtensionPerformanceManager.swift
//  CameraExtension
//
//  Phase 4.2: Dedicated performance optimization and memory management
//  Extracted from CameraExtensionProvider for better separation of concerns
//

import Foundation
import Dispatch
import OSLog

// MARK: - Performance Types

enum FrameRetentionPolicy {
	case always // Always retain last frame (high memory, best quality)
	case adaptive // Adapt based on system pressure (balanced)
	case minimal // Drop frames aggressively (low memory, lower quality)
}

enum PerformanceMode {
	case optimal // Full quality rendering
	case balanced // Reduced quality under pressure
	case powerSaver // Minimal rendering for battery life
}

// MARK: - Performance Manager Protocol

protocol CameraExtensionPerformanceManagerDelegate: AnyObject {
	func performanceManager(_ manager: CameraExtensionPerformanceManager, shouldClearCaches: Bool)
	func performanceManager(_ manager: CameraExtensionPerformanceManager, shouldDropCurrentFrame: Bool)
}

// MARK: - Dedicated Performance Manager

final class CameraExtensionPerformanceManager {
	
	// MARK: - Properties
	
	private let logger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Extension")
	weak var delegate: CameraExtensionPerformanceManagerDelegate?
	
	// Memory pressure monitoring
	private var memoryPressureSource: DispatchSourceMemoryPressure?
	private let performanceQueue = DispatchQueue(label: "performanceQueue", qos: .utility)
	
	// Performance state
	private(set) var frameRetentionPolicy: FrameRetentionPolicy = .adaptive
	private(set) var currentPerformanceMode: PerformanceMode = .optimal
	
	// Overlay frame skipping for performance
	private var overlayFrameSkipCounter: Int = 0
	private let overlayFrameSkipThreshold: Int = 2 // Render overlays every 3rd frame under pressure
	
	// Performance metrics
	private var lastPerformanceUpdate: Date = Date()
	private let performanceUpdateInterval: TimeInterval = 5.0
	
	// MARK: - Initialization
	
	init(delegate: CameraExtensionPerformanceManagerDelegate? = nil) {
		self.delegate = delegate
		setupMemoryPressureHandling()
	}
	
	deinit {
		stopMemoryPressureHandling()
		logger.debug("🧼 Cleaned up CameraExtensionPerformanceManager")
	}
	
	// MARK: - Public Interface
	
	/// Check if overlay frame should be skipped for performance
	func shouldSkipOverlayFrame() -> Bool {
		guard frameRetentionPolicy == .minimal else { return false }
		
		overlayFrameSkipCounter = (overlayFrameSkipCounter + 1) % (overlayFrameSkipThreshold + 1)
		return overlayFrameSkipCounter != 0
	}
	
	/// Determine if frame should be retained based on current policy
	func shouldRetainFrame(frameCount: Int) -> Bool {
		switch frameRetentionPolicy {
		case .always:
			return true
		case .adaptive:
			// Only retain every other frame under pressure
			return frameCount % 2 == 0
		case .minimal:
			// Only retain if we don't have a current frame (handled by caller)
			return false
		}
	}
	
	/// Get current performance metrics
	func getPerformanceMetrics() -> [String: Any] {
		return [
			"frameRetentionPolicy": String(describing: frameRetentionPolicy),
			"performanceMode": String(describing: currentPerformanceMode),
			"overlayFrameSkipThreshold": overlayFrameSkipThreshold,
			"memoryPressureActive": memoryPressureSource != nil
		]
	}
	
	/// Manually trigger performance optimization (e.g., from external thermal pressure)
	func optimizeForPowerSaving() {
		logger.debug("🔋 Switching to power saving mode")
		currentPerformanceMode = .powerSaver
		frameRetentionPolicy = .minimal
		delegate?.performanceManager(self, shouldClearCaches: true)
	}
	
	/// Reset to optimal performance when conditions improve
	func resetToOptimalPerformance() {
		logger.debug("⚡ Resetting to optimal performance mode")
		currentPerformanceMode = .optimal
		frameRetentionPolicy = .adaptive
	}
	
	// MARK: - Private Methods
	
	/// Setup memory pressure monitoring for adaptive performance
	private func setupMemoryPressureHandling() {
		memoryPressureSource = DispatchSource.makeMemoryPressureSource(
			eventMask: [.warning, .critical],
			queue: performanceQueue
		)
		
		memoryPressureSource?.setEventHandler { [weak self] in
			guard let self = self else { return }
			
			let data = self.memoryPressureSource?.data ?? 0
			if data & DispatchSource.MemoryPressureEvent.critical.rawValue != 0 {
				logger.warning("🔥 Critical memory pressure - switching to minimal frame retention")
				self.handleMemoryPressure(.critical)
			} else if data & DispatchSource.MemoryPressureEvent.warning.rawValue != 0 {
				logger.debug("⚠️ Memory pressure warning - switching to adaptive mode")
				self.handleMemoryPressure(.warning)
			}
		}
		
		memoryPressureSource?.resume()
		logger.debug("✅ Memory pressure monitoring started")
	}
	
	/// Stop memory pressure monitoring
	private func stopMemoryPressureHandling() {
		if let source = memoryPressureSource {
			source.cancel()
			memoryPressureSource = nil
			logger.debug("🛑 Stopped memory pressure monitoring")
		}
	}
	
	/// Handle memory pressure events with adaptive performance adjustments
	private func handleMemoryPressure(_ level: DispatchSource.MemoryPressureEvent) {
		switch level {
		case .warning:
			frameRetentionPolicy = .adaptive
			currentPerformanceMode = .balanced
			// Clear overlay caches under pressure
			delegate?.performanceManager(self, shouldClearCaches: true)
			logger.debug("🧼 Cleared overlay caches due to memory pressure")
			
		case .critical:
			frameRetentionPolicy = .minimal
			currentPerformanceMode = .powerSaver
			// Aggressively clear caches and current frame
			delegate?.performanceManager(self, shouldClearCaches: true)
			delegate?.performanceManager(self, shouldDropCurrentFrame: true)
			logger.warning("💥 Critical memory pressure - dropped current frame and all caches")
			
		default:
			frameRetentionPolicy = .adaptive
			currentPerformanceMode = .optimal
		}
		
		logPerformanceUpdate()
	}
	
	/// Log performance updates periodically
	private func logPerformanceUpdate() {
		let now = Date()
		if now.timeIntervalSince(lastPerformanceUpdate) >= performanceUpdateInterval {
			logger.debug("📊 Performance: \(String(describing: self.currentPerformanceMode)), Frame retention: \(String(describing: self.frameRetentionPolicy))")
			lastPerformanceUpdate = now
		}
	}
}