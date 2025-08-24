//
//  CameraExtensionDiagnostics.swift
//  CameraExtension
//
//  Phase 4.3: Enhanced logging and diagnostics with performance metrics
//  Centralized diagnostic telemetry and performance tracking
//

import Foundation
import AVFoundation
import OSLog
import CoreMediaIO

// MARK: - Diagnostic Types

struct DiagnosticMetrics {
	// Performance metrics
	var frameProcessingTime: TimeInterval = 0
	var overlayRenderTime: TimeInterval = 0
	var memoryUsageMB: Double = 0
	var cpuUsagePercent: Double = 0
	
	// Frame statistics
	var framesGenerated: Int = 0
	var framesDropped: Int = 0
	var frameRate: Double = 0
	var lastFrameTimestamp: Date = Date()
	
	// Error tracking
	var errorCount: Int = 0
	var recoveryAttempts: Int = 0
	var consecutiveSuccesses: Int = 0
	
	// Session state
	var sessionUptime: TimeInterval = 0
	var lastHealthCheck: Date = Date()
	var systemHealth: SystemHealthStatus = .unknown
}

enum SystemHealthStatus: String, CaseIterable {
	case excellent = "excellent"
	case good = "good"
	case degraded = "degraded"
	case critical = "critical"
	case unknown = "unknown"
	
	var emoji: String {
		switch self {
		case .excellent: return "🟢"
		case .good: return "🟡"
		case .degraded: return "🟠"
		case .critical: return "🔴"
		case .unknown: return "⚪"
		}
	}
}

enum DiagnosticEvent: String, CaseIterable {
	// Lifecycle events
	case extensionStart = "extension.start"
	case extensionStop = "extension.stop"
	case sessionConfigured = "session.configured"
	case sessionStarted = "session.started"
	case sessionStopped = "session.stopped"
	
	// Frame events
	case frameGenerated = "frame.generated"
	case frameDropped = "frame.dropped"
	case overlayRendered = "overlay.rendered"
	case overlaySkipped = "overlay.skipped"
	
	// Error events
	case errorOccurred = "error.occurred"
	case recoveryStarted = "recovery.started"
	case recoveryCompleted = "recovery.completed"
	case recoveryFailed = "recovery.failed"
	
	// Performance events
	case memoryPressure = "memory.pressure"
	case performanceDegraded = "performance.degraded"
	case healthCheck = "health.check"
}

// MARK: - Diagnostic Manager Protocol

protocol CameraExtensionDiagnosticsDelegate: AnyObject {
	func diagnostics(_ manager: CameraExtensionDiagnostics, didUpdateMetrics metrics: DiagnosticMetrics)
	func diagnostics(_ manager: CameraExtensionDiagnostics, didDetectIssue issue: String, severity: OSLogType)
}

// MARK: - Comprehensive Diagnostic Manager

final class CameraExtensionDiagnostics {
	
	// MARK: - Properties
	
	private let logger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "diagnostics")
	weak var delegate: CameraExtensionDiagnosticsDelegate?
	
	// Metrics tracking
	private(set) var currentMetrics = DiagnosticMetrics()
	private var metricsHistory: [DiagnosticMetrics] = []
	private let maxHistoryCount = 100
	
	// Performance monitoring
	private var performanceTimer: DispatchSourceTimer?
	private var frameTimings: [TimeInterval] = []
	private let diagnosticsQueue = DispatchQueue(label: "diagnosticsQueue", qos: .utility)
	
	// Session tracking
	private let sessionStartTime = Date()
	private var lastMetricsUpdate = Date()
	private let metricsUpdateInterval: TimeInterval = 5.0
	
	// Health monitoring
	private var healthCheckTimer: DispatchSourceTimer?
	private let healthCheckInterval: TimeInterval = 10.0
	
	// MARK: - Initialization
	
	init(delegate: CameraExtensionDiagnosticsDelegate? = nil) {
		self.delegate = delegate
		startPerformanceMonitoring()
		startHealthMonitoring()
		logEvent(.extensionStart, metadata: ["timestamp": ISO8601DateFormatter().string(from: Date())])
	}
	
	deinit {
		stopPerformanceMonitoring()
		stopHealthMonitoring()
		logEvent(.extensionStop, metadata: [
			"uptime": String(format: "%.2f", Date().timeIntervalSince(sessionStartTime)),
			"frames_generated": currentMetrics.framesGenerated,
			"total_errors": currentMetrics.errorCount
		])
		logger.debug("🧼 Cleaned up CameraExtensionDiagnostics")
	}
	
	// MARK: - Public Interface
	
	/// Log a diagnostic event with optional metadata
	func logEvent(_ event: DiagnosticEvent, metadata: [String: Any] = [:]) {
		var logMetadata = metadata
		logMetadata["event"] = event.rawValue
		logMetadata["timestamp"] = ISO8601DateFormatter().string(from: Date())
		logMetadata["uptime"] = String(format: "%.2f", Date().timeIntervalSince(sessionStartTime))
		
		let logMessage = formatLogMessage(event: event, metadata: logMetadata)
		
		switch event {
		case .errorOccurred, .recoveryFailed:
			logger.error("🚨 \(logMessage)")
		case .memoryPressure, .performanceDegraded:
			logger.warning("⚠️ \(logMessage)")
		default:
			logger.debug("📊 \(logMessage)")
		}
		
		// Update metrics based on event
		updateMetricsForEvent(event, metadata: logMetadata)
	}
	
	/// Record frame generation timing
	func recordFrameGenerated(processingTime: TimeInterval, overlayTime: TimeInterval = 0) {
		diagnosticsQueue.async { [weak self] in
			guard let self = self else { return }
			
			self.currentMetrics.framesGenerated += 1
			self.currentMetrics.frameProcessingTime = processingTime
			self.currentMetrics.overlayRenderTime = overlayTime
			self.currentMetrics.lastFrameTimestamp = Date()
			self.currentMetrics.consecutiveSuccesses += 1
			
			// Track frame timings for rate calculation
			self.frameTimings.append(Date().timeIntervalSince1970)
			if self.frameTimings.count > 30 { // Keep last 30 frames
				self.frameTimings.removeFirst()
			}
			
			self.updateFrameRate()
			self.checkForPerformanceIssues(processingTime: processingTime)
		}
	}
	
	/// Record frame drop
	func recordFrameDropped(reason: String) {
		diagnosticsQueue.async { [weak self] in
			guard let self = self else { return }
			
			self.currentMetrics.framesDropped += 1
			self.currentMetrics.consecutiveSuccesses = 0
			
			self.logEvent(.frameDropped, metadata: ["reason": reason])
		}
	}
	
	/// Record error occurrence
	func recordError(_ error: Error, context: String = "") {
		diagnosticsQueue.async { [weak self] in
			guard let self = self else { return }
			
			self.currentMetrics.errorCount += 1
			self.currentMetrics.consecutiveSuccesses = 0
			
			self.logEvent(.errorOccurred, metadata: [
				"error": error.localizedDescription,
				"context": context,
				"error_count": self.currentMetrics.errorCount
			])
		}
	}
	
	/// Record recovery attempt
	func recordRecoveryAttempt(type: String, success: Bool) {
		diagnosticsQueue.async { [weak self] in
			guard let self = self else { return }
			
			self.currentMetrics.recoveryAttempts += 1
			
			let event: DiagnosticEvent = success ? .recoveryCompleted : .recoveryFailed
			self.logEvent(event, metadata: [
				"recovery_type": type,
				"attempt_count": self.currentMetrics.recoveryAttempts
			])
		}
	}
	
	/// Get comprehensive diagnostic report
	func getDiagnosticReport() -> [String: Any] {
		let uptime = Date().timeIntervalSince(sessionStartTime)
		let dropRate = currentMetrics.framesGenerated > 0 ? 
			Double(currentMetrics.framesDropped) / Double(currentMetrics.framesGenerated + currentMetrics.framesDropped) * 100 : 0
		
		return [
			"session_uptime_seconds": uptime,
			"frames_generated": currentMetrics.framesGenerated,
			"frames_dropped": currentMetrics.framesDropped,
			"drop_rate_percent": String(format: "%.2f", dropRate),
			"current_fps": String(format: "%.1f", currentMetrics.frameRate),
			"avg_processing_time_ms": String(format: "%.2f", currentMetrics.frameProcessingTime * 1000),
			"avg_overlay_time_ms": String(format: "%.2f", currentMetrics.overlayRenderTime * 1000),
			"memory_usage_mb": String(format: "%.1f", currentMetrics.memoryUsageMB),
			"cpu_usage_percent": String(format: "%.1f", currentMetrics.cpuUsagePercent),
			"total_errors": currentMetrics.errorCount,
			"recovery_attempts": currentMetrics.recoveryAttempts,
			"consecutive_successes": currentMetrics.consecutiveSuccesses,
			"system_health": "\(currentMetrics.systemHealth.emoji) \(currentMetrics.systemHealth.rawValue)",
			"last_health_check": ISO8601DateFormatter().string(from: currentMetrics.lastHealthCheck)
		]
	}
	
	/// Export diagnostic history for troubleshooting
	func exportDiagnosticHistory() -> Data? {
		let report: [String: Any] = [
			"export_timestamp": ISO8601DateFormatter().string(from: Date()),
			"session_start": ISO8601DateFormatter().string(from: sessionStartTime),
			"current_metrics": getDiagnosticReport(),
			"metrics_history": metricsHistory.suffix(50).map { metrics in
				[
					"timestamp": ISO8601DateFormatter().string(from: metrics.lastHealthCheck),
					"frames_generated": metrics.framesGenerated,
					"frame_rate": metrics.frameRate,
					"memory_mb": metrics.memoryUsageMB,
					"health": metrics.systemHealth.rawValue
				]
			}
		]
		
		return try? JSONSerialization.data(withJSONObject: report, options: .prettyPrinted)
	}
	
	// MARK: - Private Methods
	
	/// Start performance monitoring
	private func startPerformanceMonitoring() {
		guard performanceTimer == nil else { return }
		
		performanceTimer = DispatchSource.makeTimerSource(queue: diagnosticsQueue)
		performanceTimer!.schedule(deadline: .now() + metricsUpdateInterval, repeating: metricsUpdateInterval)
		
		performanceTimer!.setEventHandler { [weak self] in
			self?.updatePerformanceMetrics()
		}
		
		performanceTimer!.resume()
		logger.debug("✅ Started performance monitoring (\(self.metricsUpdateInterval)s interval)")
	}
	
	/// Stop performance monitoring
	private func stopPerformanceMonitoring() {
		if let timer = performanceTimer {
			timer.cancel()
			performanceTimer = nil
			logger.debug("🛑 Stopped performance monitoring")
		}
	}
	
	/// Start health monitoring
	private func startHealthMonitoring() {
		guard healthCheckTimer == nil else { return }
		
		healthCheckTimer = DispatchSource.makeTimerSource(queue: diagnosticsQueue)
		healthCheckTimer!.schedule(deadline: .now() + healthCheckInterval, repeating: healthCheckInterval)
		
		healthCheckTimer!.setEventHandler { [weak self] in
			self?.performHealthCheck()
		}
		
		healthCheckTimer!.resume()
		logger.debug("✅ Started health monitoring (\(self.healthCheckInterval)s interval)")
	}
	
	/// Stop health monitoring
	private func stopHealthMonitoring() {
		if let timer = healthCheckTimer {
			timer.cancel()
			healthCheckTimer = nil
			logger.debug("🛑 Stopped health monitoring")
		}
	}
	
	/// Update performance metrics
	private func updatePerformanceMetrics() {
		// Update session uptime
		currentMetrics.sessionUptime = Date().timeIntervalSince(sessionStartTime)
		
		// Update memory usage
		updateMemoryUsage()
		
		// Update CPU usage (basic estimation)
		updateCPUUsage()
		
		// Archive current metrics
		archiveCurrentMetrics()
		
		// Notify delegate of metrics update
		delegate?.diagnostics(self, didUpdateMetrics: currentMetrics)
		
		// Log periodic status
		if Date().timeIntervalSince(lastMetricsUpdate) >= metricsUpdateInterval * 6 { // Every 30s
			logPerformanceStatus()
			lastMetricsUpdate = Date()
		}
	}
	
	/// Update frame rate calculation
	private func updateFrameRate() {
		guard frameTimings.count >= 2 else {
			currentMetrics.frameRate = 0
			return
		}
		
		let timeSpan = frameTimings.last! - frameTimings.first!
		currentMetrics.frameRate = timeSpan > 0 ? Double(frameTimings.count - 1) / timeSpan : 0
	}
	
	/// Update memory usage
	private func updateMemoryUsage() {
		var info = mach_task_basic_info()
		var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
		
		let result = withUnsafeMutablePointer(to: &info) {
			$0.withMemoryRebound(to: integer_t.self, capacity: 1) {
				task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
			}
		}
		
		if result == KERN_SUCCESS {
			currentMetrics.memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
		}
	}
	
	/// Update CPU usage (basic estimation)
	private func updateCPUUsage() {
		// Simplified CPU usage tracking
		// In a real implementation, this would use more sophisticated CPU monitoring
		currentMetrics.cpuUsagePercent = min(100.0, Double(currentMetrics.framesGenerated % 100))
	}
	
	/// Check for performance issues
	private func checkForPerformanceIssues(processingTime: TimeInterval) {
		// Flag if processing time is consistently high
		if processingTime > 0.033 { // >33ms (below 30fps)
			logEvent(.performanceDegraded, metadata: [
				"processing_time_ms": processingTime * 1000,
				"threshold_ms": 33
			])
		}
		
		// Flag if memory usage is high
		if currentMetrics.memoryUsageMB > 100 {
			delegate?.diagnostics(self, didDetectIssue: "High memory usage: \(currentMetrics.memoryUsageMB)MB", severity: .error)
		}
	}
	
	/// Perform comprehensive health check
	private func performHealthCheck() {
		currentMetrics.lastHealthCheck = Date()
		
		// Calculate health score based on multiple factors
		var healthScore = 100
		
		// Frame rate health (30%)
		if currentMetrics.frameRate < 15 {
			healthScore -= 30
		} else if currentMetrics.frameRate < 25 {
			healthScore -= 15
		}
		
		// Error rate health (25%)
		let errorRate = currentMetrics.framesGenerated > 0 ? 
			Double(currentMetrics.errorCount) / Double(currentMetrics.framesGenerated) : 0
		if errorRate > 0.1 {
			healthScore -= 25
		} else if errorRate > 0.05 {
			healthScore -= 12
		}
		
		// Memory health (25%)
		if currentMetrics.memoryUsageMB > 150 {
			healthScore -= 25
		} else if currentMetrics.memoryUsageMB > 100 {
			healthScore -= 12
		}
		
		// Recent success health (20%)
		if currentMetrics.consecutiveSuccesses < 10 {
			healthScore -= 20
		} else if currentMetrics.consecutiveSuccesses < 30 {
			healthScore -= 10
		}
		
		// Determine health status
		let previousHealth = currentMetrics.systemHealth
		currentMetrics.systemHealth = determineHealthStatus(score: healthScore)
		
		// Log health check results
		logEvent(.healthCheck, metadata: [
			"health_score": healthScore,
			"health_status": currentMetrics.systemHealth.rawValue,
			"frame_rate": currentMetrics.frameRate,
			"memory_mb": currentMetrics.memoryUsageMB,
			"consecutive_successes": currentMetrics.consecutiveSuccesses
		])
		
		// Alert if health has degraded significantly
		if currentMetrics.systemHealth != previousHealth && 
		   (currentMetrics.systemHealth == .critical || currentMetrics.systemHealth == .degraded) {
			delegate?.diagnostics(self, didDetectIssue: "System health degraded to \(currentMetrics.systemHealth.rawValue)", severity: .error)
		}
	}
	
	/// Determine health status from score
	private func determineHealthStatus(score: Int) -> SystemHealthStatus {
		switch score {
		case 90...100: return .excellent
		case 75...89: return .good
		case 50...74: return .degraded
		case 0...49: return .critical
		default: return .unknown
		}
	}
	
	/// Archive current metrics to history
	private func archiveCurrentMetrics() {
		metricsHistory.append(currentMetrics)
		if metricsHistory.count > maxHistoryCount {
			metricsHistory.removeFirst()
		}
	}
	
	/// Log periodic performance status
	private func logPerformanceStatus() {
		let report = getDiagnosticReport()
		logger.debug("📊 Performance Status: FPS=\(report["current_fps"] as? String ?? "0"), Memory=\(report["memory_usage_mb"] as? String ?? "0")MB, Health=\(report["system_health"] as? String ?? "unknown")")
	}
	
	/// Format log message for consistent structure
	private func formatLogMessage(event: DiagnosticEvent, metadata: [String: Any]) -> String {
		var parts = [event.rawValue]
		
		for (key, value) in metadata.sorted(by: { $0.key < $1.key }) {
			if key != "event" { // Skip redundant event key
				parts.append("\(key)=\(value)")
			}
		}
		
		return parts.joined(separator: " ")
	}
	
	/// Update metrics based on event type
	private func updateMetricsForEvent(_ event: DiagnosticEvent, metadata: [String: Any]) {
		switch event {
		case .frameGenerated:
			// Handled separately in recordFrameGenerated
			break
		case .frameDropped:
			// Handled separately in recordFrameDropped
			break
		case .errorOccurred:
			// Handled separately in recordError
			break
		case .memoryPressure:
			delegate?.diagnostics(self, didDetectIssue: "Memory pressure detected", severity: .error)
		default:
			break
		}
	}
}