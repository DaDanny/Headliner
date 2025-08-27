//
//  ExtensionStatusManager.swift
//  Headliner
//
//  Created by Danny Francken on 8/23/25.
//  Phase 2: Reliable Status Communication System
//

import Foundation

/// Manages bidirectional status communication between app and extension
final class ExtensionStatusManager {
  private static let logger = HeadlinerLogger.logger(for: .application)
  
  // MARK: - Runtime Status Writing (Extension Side)
  
  /// Write runtime status to App Group UserDefaults (called from extension)
  static func writeRuntimeStatus(_ status: ExtensionRuntimeStatus, deviceName: String? = nil, error: String? = nil) {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) else {
      logger.error("Failed to access app group UserDefaults for runtime status writing")
      return
    }
    
    // Write runtime status and timestamp
    sharedDefaults.set(status.rawValue, forKey: ExtensionStatusKeys.runtimeStatus)
    sharedDefaults.set(Date().timeIntervalSince1970, forKey: ExtensionStatusKeys.lastHeartbeat)
    
    // Optional additional info
    if let deviceName = deviceName {
      sharedDefaults.set(deviceName, forKey: ExtensionStatusKeys.currentDeviceName)
    }
    
    if let error = error {
      sharedDefaults.set(error, forKey: ExtensionStatusKeys.errorMessage)
    } else {
      sharedDefaults.removeObject(forKey: ExtensionStatusKeys.errorMessage)
    }
    
    sharedDefaults.synchronize()
    
    // Notify app of runtime status change via Darwin notifications
    Notifications.CrossApp.post(.statusChanged)
    
    logger.debug("Extension runtime status updated: \(status.displayText)")
  }
  
  /// Legacy method - redirects to writeRuntimeStatus for backward compatibility
  static func writeStatus(_ status: ExtensionRuntimeStatus, deviceName: String? = nil, error: String? = nil) {
    writeRuntimeStatus(status, deviceName: deviceName, error: error)
  }
  
  /// Update heartbeat (called periodically from extension while active)
  static func updateHeartbeat() {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return }
    
    sharedDefaults.set(Date().timeIntervalSince1970, forKey: ExtensionStatusKeys.lastHeartbeat)
    sharedDefaults.synchronize()
  }
  
  // MARK: - Runtime Status Reading (App Side)
  
  /// Read current extension runtime status (called from main app)
  static func readRuntimeStatus() -> ExtensionRuntimeStatus {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let statusString = sharedDefaults.string(forKey: ExtensionStatusKeys.runtimeStatus),
          let status = ExtensionRuntimeStatus(rawValue: statusString) else {
      return .idle // Default status
    }
    return status
  }
  
  /// Legacy method - redirects to readRuntimeStatus for backward compatibility
  static func readStatus() -> ExtensionRuntimeStatus {
    return readRuntimeStatus()
  }
  
  /// Check if extension is healthy (recent heartbeat)
  static func isExtensionHealthy(timeoutSeconds: TimeInterval = 10.0) -> Bool {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return false }
    
    let lastHeartbeat = sharedDefaults.double(forKey: ExtensionStatusKeys.lastHeartbeat)
    guard lastHeartbeat > 0 else { return false }
    
    let now = Date().timeIntervalSince1970
    let timeSinceHeartbeat = now - lastHeartbeat
    
    return timeSinceHeartbeat <= timeoutSeconds
  }
  
  /// Get current device name from extension
  static func getCurrentDeviceName() -> String? {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return nil }
    return sharedDefaults.string(forKey: ExtensionStatusKeys.currentDeviceName)
  }
  
  /// Get error message if extension is in error state
  static func getErrorMessage() -> String? {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return nil }
    return sharedDefaults.string(forKey: ExtensionStatusKeys.errorMessage)
  }
  
  // MARK: - User Preferences
  
  /// Get auto-start camera preference (default: true for seamless experience)
  static func getAutoStartEnabled() -> Bool {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return true }
    
    // Check if value has been set, default to true if not
    if sharedDefaults.object(forKey: ExtensionStatusKeys.autoStartCamera) == nil {
      return true
    }
    return sharedDefaults.bool(forKey: ExtensionStatusKeys.autoStartCamera)
  }
  
  /// Set auto-start camera preference
  static func setAutoStartEnabled(_ enabled: Bool) {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return }
    
    sharedDefaults.set(enabled, forKey: ExtensionStatusKeys.autoStartCamera)
    sharedDefaults.synchronize()
    
    logger.debug("Auto-start camera preference: \(enabled)")
  }
}
