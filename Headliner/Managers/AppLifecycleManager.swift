//
//  AppLifecycleManager.swift
//  Headliner
//
//  Ensures clean app startup and shutdown to prevent multiple instances
//

import AppKit
import AVFoundation

@MainActor
final class AppLifecycleManager {
  private static let logger = HeadlinerLogger.logger(for: .application)
  
  /// Ensure only one instance is running
  static func enforcesSingleInstance() -> Bool {
    let bundleID = Bundle.main.bundleIdentifier ?? "com.unknown"
    
    // Check for existing instances
    let runningApps = NSWorkspace.shared.runningApplications
    let instances = runningApps.filter { $0.bundleIdentifier == bundleID }
    
    if instances.count > 1 {
      logger.warning("⚠️ Multiple instances detected: \(instances.count)")
      
      // Find and terminate other instances
      for app in instances where app != NSRunningApplication.current {
        logger.debug("Terminating duplicate instance: \(app.processIdentifier)")
        app.terminate()
      }
      
      // Give them time to close
      Thread.sleep(forTimeInterval: 1.0)
      return false
    }
    
    return true
  }
  
  /// Clean shutdown of all resources
  static func performCleanShutdown(
    captureManager: CaptureSessionManager?,
    extensionManager: SystemExtensionRequestManager?,
    coordinator: AppCoordinator?
  ) {
    logger.debug("🛑 Beginning clean shutdown...")
    
    // 1. Stop camera immediately
    if let capture = captureManager {
      if capture.captureSession.isRunning {
        logger.debug("Stopping capture session...")
        capture.captureSession.stopRunning()
      }
      
      // Remove all inputs/outputs
      capture.captureSession.inputs.forEach { capture.captureSession.removeInput($0) }
      capture.captureSession.outputs.forEach { capture.captureSession.removeOutput($0) }
    }
    
    // 2. Stop services
    coordinator?.stopCamera()
    coordinator?.personalInfo.stop()
    
    // 3. Invalidate all timers
    logger.debug("Invalidating timers...")
    // This is now handled in service deinits
    
    // 4. Remove menu bar icon if exists
    removeMenuBarIcon()
    
    // 5. Post shutdown notification to extension
    NotificationManager.postNotification(named: .stopStream)
    
    // 6. Force synchronize UserDefaults
    UserDefaults.standard.synchronize()
    if let appGroup = UserDefaults(suiteName: Identifiers.appGroup) {
      appGroup.synchronize()
    }
    
    logger.debug("✅ Clean shutdown completed")
  }
  
  /// Remove menu bar icon
  private static func removeMenuBarIcon() {
    // If you have a menu bar icon/status item
    if let statusItem = NSApp.windows.first(where: { $0.title == "Item-0" }) {
      logger.debug("Removing menu bar icon...")
      statusItem.close()
    }
  }
  
  /// Check for zombie processes
  static func checkForZombieProcesses() {
    let task = Process()
    task.launchPath = "/bin/ps"
    task.arguments = ["aux"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    task.launch()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
      let lines = output.components(separatedBy: "\n")
      let headlinerProcesses = lines.filter { $0.contains("Headliner") && !$0.contains("grep") }
      
      if headlinerProcesses.count > 1 {
        logger.warning("⚠️ Found \(headlinerProcesses.count) Headliner processes:")
        headlinerProcesses.forEach { logger.debug("\($0)") }
      }
    }
  }
}

// MARK: - NSApplication Extension

extension NSApplication {
  /// Register for termination cleanup
  func registerForCleanShutdown(coordinator: AppCoordinator?, captureManager: CaptureSessionManager?) {
    NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification,
      object: nil,
      queue: .main
    ) { _ in
      AppLifecycleManager.performCleanShutdown(
        captureManager: captureManager,
        extensionManager: nil,
        coordinator: coordinator
      )
    }
  }
}