//
//  CustomPropertyManager.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import AVFoundation
import CoreMediaIO
import Foundation
import OSLog
import SwiftUI

private let propertyLogger = HeadlinerLogger.logger(for: .customProperty)

class CustomPropertyManager: NSObject, ObservableObject {
  // MARK: Lifecycle

  override init() {
    super.init()
    // Simplified - no effects functionality
  }

  // MARK: Internal

  var deviceObjectID: CMIOObjectID? {
    let device = getExtensionDevice(name: "Headliner")
    propertyLogger.debug("Extension device detection result: \(device?.localizedName ?? "nil")")
    // Simplified check - just return a placeholder ID if device exists
    return device != nil ? 1 : nil
  }

  func getExtensionDevice(name: String) -> AVCaptureDevice? {
    // Check for both standard devices and virtual cameras
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera],
      mediaType: .video,
      position: .unspecified
    )

    propertyLogger.debug("Looking for extension device named: \(name)")
    propertyLogger.debug("Available devices:")
    for device in discoverySession.devices {
      propertyLogger.debug("  - \(device.localizedName) (ID: \(device.uniqueID))")
    }

    // Look for our virtual camera device
    let headlinerDevice = discoverySession.devices.first {
      $0.localizedName.contains("Headliner") || $0.localizedName == name
    }

    if let device = headlinerDevice {
      propertyLogger.debug("Found Headliner extension device: \(device.localizedName)")
    } else {
      propertyLogger.debug("Headliner extension device not found")
    }

    return headlinerDevice
  }

  func refreshExtensionStatus() {
    // No-op: deviceObjectID is computed each time now.
  }
}
