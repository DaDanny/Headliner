//
//  ExtensionService.swift
//  Headliner
//
//  Manages system extension lifecycle and status monitoring
//

import Foundation
import Combine
import SystemExtensions
import AppKit
import AVFoundation

// MARK: - Protocol

protocol ExtensionServiceProtocol: ObservableObject {
  var status: ExtensionStatus { get }
  var statusMessage: String { get }
  
  func install()
  func checkStatus()
  func waitForInstallation() async
}

// MARK: - Implementation

@MainActor
final class ExtensionService: ObservableObject {
  // MARK: - Published Properties
  
  @Published private(set) var status: ExtensionStatus = .unknown
  @Published private(set) var statusMessage: String = ""
  
  // MARK: - Dependencies
  
  private let requestManager: SystemExtensionRequestManager
  private let logger = HeadlinerLogger.logger(for: .systemExtension)
  
  // Phase 3.1: Direct device detection (replaced CustomPropertyManager)
  private lazy var discoverySession = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera],
    mediaType: .video,
    position: .unspecified
  )
  
  // MARK: - Private Properties
  
  private var cancellables = Set<AnyCancellable>()
  
  // Phase 2.4: Health monitoring & heartbeat system
  private var healthMonitorTimer: Timer?
  
  // MARK: - Constants
  
  private enum Keys {
    static let extensionProviderReady = "ExtensionProviderReady"
  }
  
  // MARK: - Initialization
  
  init(requestManager: SystemExtensionRequestManager) {
    self.requestManager = requestManager
    
    setupBindings()
    checkStatus()
  }
  
  deinit {
    healthMonitorTimer?.invalidate()
  }
  
  // MARK: - Public Methods
  
  func install() {
    status = .installing
    statusMessage = "Installing system extension..."
    requestManager.install()
  }
  
  func checkStatus() {
    logger.debug("Checking extension status...")
    
    // More robust detection - check both flags and device presence
    let providerReady = isProviderReady
    let deviceAvailable = isExtensionDeviceAvailable()
    
    logger.debug("Status check: providerReady=\(providerReady), deviceAvailable=\(deviceAvailable)")
    
    // Only consider installed if BOTH provider is ready AND device is available
    if providerReady && deviceAvailable {
      status = .installed
      statusMessage = "Extension is installed and ready"
      logger.debug("✅ Extension confirmed installed (provider + device)")
      startHealthMonitoring()
    } else if providerReady && !deviceAvailable {
      // Provider flag set but no device - possible stale state
      status = .notInstalled
      statusMessage = "Extension needs to be reinstalled"
      logger.debug("⚠️ Provider flag set but no device found - clearing stale state")
      clearProviderFlag()
    } else if !providerReady && deviceAvailable {
      // Device exists but no provider flag - extension may be initializing
      status = .installing
      statusMessage = "Extension found, checking readiness..."
      logger.debug("⏳ Device found but provider not ready - extension may be starting")
    } else {
      // Neither flag nor device - definitely not installed
      status = .notInstalled
      statusMessage = "Extension needs to be installed"
      logger.debug("❌ Extension not detected")
    }
  }
  
  func waitForInstallation() async {
    guard status != .installed else { return }
    
    // Wait up to 60 seconds for installation
    for _ in 0..<60 {
      if status == .installed { return }
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      checkStatus()
    }
  }
  
  // MARK: - Private Methods
  
  /// Conservative status refresh on app activation - doesn't reset installed status
  private func refreshStatusOnAppActivation() {
    logger.debug("App became active - refreshing extension status...")
    
    // If already installed, just verify it's still working
    if status == .installed {
      let deviceAvailable = isExtensionDeviceAvailable()
      let providerReady = isProviderReady
      
      if !deviceAvailable && !providerReady {
        // Both checks failed - extension may have been uninstalled
        logger.warning("⚠️ Extension appears to have been uninstalled - both device and provider checks failed")
        status = .notInstalled
        statusMessage = "Extension needs to be reinstalled"
        stopHealthMonitoring()
      } else {
        // At least one check passed - keep installed status but update message
        logger.debug("✅ Extension still available (device: \(deviceAvailable), provider: \(providerReady))")
        statusMessage = "Extension is installed and ready"
      }
    } else {
      // Not currently installed - do full check
      checkStatus()
    }
  }
  
  private func setupBindings() {
    // Phase 3.2: Monitor installation progress via phases (more reliable than log parsing)
    requestManager.$phase
      .receive(on: DispatchQueue.main)
      .sink { [weak self] phase in
        self?.handleInstallationPhase(phase)
      }
      .store(in: &cancellables)
    
    // Phase 3.2: Monitor extension runtime status changes (replaces log parsing)
    // TODO: Re-enable once notification system is stabilized
    /*
    NotificationCenter.default.publisher(for: NotificationName.statusChanged.nsNotificationName)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.handleExtensionStatusChange()
      }
      .store(in: &cancellables)
    */
    
    // Recheck on app activation (but don't reset if already installed)
    NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.refreshStatusOnAppActivation()
      }
      .store(in: &cancellables)
  }
  
  // Phase 3.2: Handle extension runtime status changes (replaces log parsing)
  private func handleExtensionStatusChange() {
    let runtimeStatus = ExtensionStatusManager.readStatus()
    
    // Only update status messages based on runtime status if extension is installed
    guard status == .installed else {
      logger.debug("Ignoring runtime status change - extension not installed")
      return
    }
    
    // Update status message based on runtime status without affecting installation status
    switch runtimeStatus {
    case .idle:
      statusMessage = "Extension ready"
    case .starting:
      statusMessage = "Extension starting camera..."
    case .streaming:
      statusMessage = "Extension streaming"
    case .stopping:
      statusMessage = "Extension stopping..."
    case .error:
      statusMessage = "Extension error - check logs"
    }
    
    logger.debug("📊 Extension runtime status: \(runtimeStatus.rawValue) -> '\(self.statusMessage)'")
  }
  
  private func handleInstallationPhase(_ phase: ExtensionInstallPhase) {
    switch phase {
    case .needsApproval:
      status = .installing
      statusMessage = "Approve the extension in System Settings…"
    case .installed:
      status = .installed
      statusMessage = "Extension installed. Finalizing…"
      // Phase 3.2: Simplified verification instead of complex polling
      verifyInstallationCompletion()
    default:
      break
    }
  }
  
  // MARK: - Phase 3.2: Simplified Installation Verification
  
  /// Simple verification that extension is fully operational (replaces complex polling)
  private func verifyInstallationCompletion() {
    // Give extension a moment to initialize, then verify
    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
      await finalizeInstallation()
    }
  }
  
  @MainActor
  private func finalizeInstallation() {
    // Check provider flag first (fastest)
    if isProviderReady {
      status = .installed
      statusMessage = "Extension installed and ready"
      startHealthMonitoring()
      logger.debug("✅ Extension verified via provider flag")
      return
    }
    
    // Device scan fallback
    if isExtensionDeviceAvailable() {
      status = .installed
      statusMessage = "Extension installed and ready"
      startHealthMonitoring()
      logger.debug("✅ Extension verified via device scan")
    } else {
      // Extension may need more time or manual intervention
      statusMessage = "Extension installed but not yet ready - check System Settings"
      logger.debug("⚠️ Extension installed but virtual camera not detected")
    }
  }
  
  // MARK: - Phase 2.4: Health Monitoring & Heartbeat System
  
  func startHealthMonitoring() {
    guard healthMonitorTimer == nil else { return }
    
    healthMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.checkExtensionHealth()
      }
    }
    
    logger.debug("✅ Started extension health monitoring (5s interval)")
  }
  
  func stopHealthMonitoring() {
    healthMonitorTimer?.invalidate()
    healthMonitorTimer = nil
    logger.debug("🛑 Stopped extension health monitoring")
  }
  
  private func checkExtensionHealth() {
    guard status == .installed else {
      // Only monitor health if extension is installed
      return
    }
    
    let isHealthy = ExtensionStatusManager.isExtensionHealthy(timeoutSeconds: 15.0)
    let currentStatus = ExtensionStatusManager.readStatus()
    
    if isHealthy {
      // Extension is healthy - update status message with runtime status
      statusMessage = "Extension active: \(currentStatus.displayText)"
      
      if let deviceName = ExtensionStatusManager.getCurrentDeviceName() {
        statusMessage += " (\(deviceName))"
      }
      
      if let errorMessage = ExtensionStatusManager.getErrorMessage() {
        statusMessage += " - Error: \(errorMessage)"
      }
    } else {
      // Extension appears unresponsive
      if currentStatus == .streaming || currentStatus == .starting {
        statusMessage = "Extension may be unresponsive (no heartbeat for >15s)"
        logger.warning("⚠️ Extension health check failed - no recent heartbeat")
      } else {
        // Extension is idle, which is normal - no heartbeat expected
        statusMessage = "Extension idle"
      }
    }
    
    logger.debug("🩺 Health check: \(isHealthy ? "healthy" : "unhealthy") - \(currentStatus.displayText)")
  }
  
  // MARK: - Computed Properties
  
  private var isProviderReady: Bool {
    UserDefaults(suiteName: Identifiers.appGroup)?
      .bool(forKey: Keys.extensionProviderReady) ?? false
  }
  
  /// Clear stale provider flag when device is not available
  private func clearProviderFlag() {
    UserDefaults(suiteName: Identifiers.appGroup)?
      .removeObject(forKey: Keys.extensionProviderReady)
    logger.debug("🧹 Cleared stale provider flag")
  }
  
  var isInstalled: Bool {
    status == .installed
  }
  
  var isInstalling: Bool {
    status == .installing
  }
  
  // MARK: - Private Extension Detection
  
  private func isExtensionDeviceAvailable() -> Bool {
    // Refresh the discovery session to ensure we have latest devices
    discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera],
      mediaType: .video,
      position: .unspecified
    )
    
    let headlinerDevice = discoverySession.devices.first {
      $0.localizedName.contains("Headliner")
    }
    
    if let device = headlinerDevice {
      logger.debug("Found Headliner extension device: \(device.localizedName)")
      return true
    } else {
      logger.debug("Headliner extension device not found")
      return false
    }
  }
}

// MARK: - ExtensionServiceProtocol Conformance

extension ExtensionService: ExtensionServiceProtocol {}