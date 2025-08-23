//
//  AppDelegate+Lifecycle.swift
//  Headliner
//
//  Ensures single instance and clean shutdown
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
  private let logger = HeadlinerLogger.logger(for: .application)
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    logger.debug("🚀 App launched")
    
    // Enforce single instance
    if !AppLifecycleManager.enforcesSingleInstance() {
      logger.error("Multiple instances detected - terminating")
      NSApplication.shared.terminate(nil)
      return
    }
    
    // Check for zombie processes
    AppLifecycleManager.checkForZombieProcesses()
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Don't keep app running if window is closed
    return true
  }
  
  func applicationWillTerminate(_ notification: Notification) {
    logger.debug("🛑 App will terminate")
    
    // Perform cleanup (coordinator will be injected via SwiftUI)
    // This is a backup in case the other cleanup didn't run
    AppLifecycleManager.performCleanShutdown(
      captureManager: nil,
      extensionManager: nil,
      coordinator: nil
    )
  }
  
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    logger.debug("Should terminate requested")
    
    // Perform async cleanup
    Task { @MainActor in
      // Give services time to clean up
      try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
      NSApplication.shared.reply(toApplicationShouldTerminate: true)
    }
    
    // Delay termination for cleanup
    return .terminateLater
  }
}