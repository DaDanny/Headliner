//
//  SystemExtensionRequestManager.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI
import SystemExtensions

enum ExtensionInstallPhase: String {
  case idle, requesting, needsApproval, installing, installed, willCompleteAfterReboot, failed
}

class SystemExtensionRequestManager: NSObject, ObservableObject {
  // MARK: Lifecycle

  init(logText: String) {
    super.init()
    self.logText = logText
  }

  @Published var logText: String = "Installation results here"
  @Published var phase: ExtensionInstallPhase = .idle

  @discardableResult
  func postNotification(named notificationName: CrossAppNotificationName) -> Bool {
    logger
      .debug(
        "Posting notification \(notificationName.rawValue) from container app"
      )

    Notifications.CrossApp.post(notificationName)
    return true
  }

  func install() {
    guard let extensionIdentifier = _extensionBundle().bundleIdentifier else { return }
    let activationRequest = OSSystemExtensionRequest.activationRequest(
      forExtensionWithIdentifier: extensionIdentifier,
      queue: .main
    )
    activationRequest.delegate = self
    OSSystemExtensionManager.shared.submitRequest(activationRequest)
  }

  @discardableResult
  func uninstall() -> Bool {
    guard let extensionIdentifier = _extensionBundle().bundleIdentifier else { return false }
    let deactivationRequest = OSSystemExtensionRequest.deactivationRequest(
      forExtensionWithIdentifier: extensionIdentifier,
      queue: .main
    )
    deactivationRequest.delegate = self
    OSSystemExtensionManager.shared.submitRequest(deactivationRequest)
    return true
  }

  func _extensionBundle() -> Bundle {
    let extensionsDirectoryURL = URL(
      fileURLWithPath: "Contents/Library/SystemExtensions",
      relativeTo: Bundle.main.bundleURL
    )
    let extensionURLs: [URL]
    do {
      extensionURLs = try FileManager.default.contentsOfDirectory(
        at: extensionsDirectoryURL,
        includingPropertiesForKeys: nil,
        options: .skipsHiddenFiles
      )
    } catch {
      let msg = "failed to get the contents of \(extensionsDirectoryURL.absoluteString): \(error.localizedDescription)"
      fatalError(msg)
    }
    guard let extensionURL = extensionURLs.first else {
      fatalError("failed to find any system extensions")
    }
    guard let extensionBundle = Bundle(url: extensionURL) else {
      fatalError("failed to create a bundle with URL \(extensionURL.absoluteString)")
    }
    return extensionBundle
  }

  // Call this on app launch in DEBUG (or behind a user-facing "Reload Extension" button)
  func activateLatest() {
    guard let id = _extensionBundle().bundleIdentifier else { return }
    phase = .requesting
    let req = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: id, queue: .main)
    req.delegate = self
    OSSystemExtensionManager.shared.submitRequest(req)
  }
}

extension SystemExtensionRequestManager: OSSystemExtensionRequestDelegate {
  func request(
    _ request: OSSystemExtensionRequest,
    actionForReplacingExtension existing: OSSystemExtensionProperties,
    withExtension ext: OSSystemExtensionProperties
  ) -> OSSystemExtensionRequest.ReplacementAction {
    logText = "Replacing extension version \(existing.bundleShortVersion) with \(ext.bundleShortVersion)"
    phase = .installing
    return .replace
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    logText = "Extension needs user approval"
    phase = .needsApproval
  }

  func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
    switch result {
    case .completed:
      logText = "Extension activation completed"
      phase = .installed
    case .willCompleteAfterReboot:
      logText = "Extension will complete after reboot"
      phase = .willCompleteAfterReboot
    @unknown default:
      logText = "Extension finished with result \(result.rawValue)"
      phase = .installing
    }
  }

  func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
    let ns = error as NSError
    logText = "Extension failed: \(ns.code) \(ns.localizedDescription)"
    phase = .failed
  }
}
