//
//  OnboardingWindowManager.swift
//  Headliner
//
//  Manages the onboarding window lifecycle
//

import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowManager: ObservableObject {
  private var window: NSWindow?
  private var windowDelegate: OnboardingWindowDelegate?
  private let logger = HeadlinerLogger.logger(for: .application)
  
  /// Shows the onboarding window
  func showOnboarding(appCoordinator: AppCoordinator) {
    if let existingWindow = window, existingWindow.isVisible {
      // Window already exists and is visible - bring it to front
      logger.debug("🔄 Onboarding window already exists - bringing to front")
      NSApplication.shared.activate(ignoringOtherApps: true)
      existingWindow.makeKeyAndOrderFront(nil)
      existingWindow.orderFrontRegardless()
      return
    }
    
    // Create new window if none exists or existing one is closed
    logger.debug("🚀 Creating onboarding window...")
    
    let onboardingView = ModernOnboardingView()
      .withAppCoordinator(appCoordinator)
    
    let hostingController = NSHostingController(rootView: onboardingView)
    
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    
    window?.title = "Welcome to Headliner"
    window?.contentViewController = hostingController
    window?.center()
    window?.setFrameAutosaveName("OnboardingWindow")
    
    // Set window properties for better visibility
    window?.level = .floating  // Keep above other windows
    window?.isReleasedWhenClosed = false
    
    // Handle window closing
    windowDelegate = OnboardingWindowDelegate { [weak self] in
      self?.window = nil
      self?.windowDelegate = nil
    }
    window?.delegate = windowDelegate
    
    // Bring app to foreground and show window prominently
    NSApplication.shared.activate(ignoringOtherApps: true)
    window?.makeKeyAndOrderFront(nil)
    window?.orderFrontRegardless()  // Ensure it comes to front
    
    logger.debug("✅ Onboarding window created and displayed")
  }
  
  /// Hides and closes the onboarding window
  func hideOnboarding() {
    window?.close()
    window = nil
  }
  
  /// Whether the onboarding window is currently visible
  var isVisible: Bool {
    window?.isVisible == true
  }
}

// MARK: - Window Delegate

private class OnboardingWindowDelegate: NSObject, NSWindowDelegate {
  let onClose: () -> Void
  
  init(onClose: @escaping () -> Void) {
    self.onClose = onClose
  }
  
  func windowWillClose(_ notification: Notification) {
    onClose()
  }
}