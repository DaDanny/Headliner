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
    // if !AppLifecycleManager.enforcesSingleInstance() {
    //   logger.error("Multiple instances detected - terminating")
    //   NSApplication.shared.terminate(nil)
    //   return
    // }
    
    // Check for zombie processes
    AppLifecycleManager.checkForZombieProcesses()
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Menu bar apps should stay running even if windows close
    return false
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
  
  // Temporarily disable this method to debug the termination issue
  // Menu bar apps shouldn't terminate from normal menu operations
  /*
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    logger.debug("Should terminate requested")
    return .terminateNow
  }
  */
}