//
//  AppStateTypes.swift
//  HeadlinerShared
//
//  Essential types extracted from deprecated AppState.swift
//  These are the minimal shared types needed by services and components
//

import AVFoundation
import Foundation

// MARK: - Error Types

/// Standardized error types for service operations
enum AppStateError: LocalizedError, Equatable {
  case cameraPermissionDenied
  case cameraPermissionRestricted
  case cameraNotFound(String)
  case extensionNotInstalled
  case captureSessionConfigurationFailed
  case overlaySettingsSaveFailed(String)
  case appGroupAccessFailed
  
  static func == (lhs: AppStateError, rhs: AppStateError) -> Bool {
    switch (lhs, rhs) {
    case (.cameraPermissionDenied, .cameraPermissionDenied),
         (.cameraPermissionRestricted, .cameraPermissionRestricted),
         (.extensionNotInstalled, .extensionNotInstalled),
         (.captureSessionConfigurationFailed, .captureSessionConfigurationFailed),
         (.appGroupAccessFailed, .appGroupAccessFailed):
      return true
    case (.cameraNotFound(let a), .cameraNotFound(let b)):
      return a == b
    case (.overlaySettingsSaveFailed(let a), .overlaySettingsSaveFailed(let b)):
      return a == b
    default:
      return false
    }
  }
  
  var errorDescription: String? {
    switch self {
    case .cameraPermissionDenied:
      return "Camera access denied - enable in System Settings > Privacy & Security > Camera"
    case .cameraPermissionRestricted:
      return "Camera access restricted by system policy"
    case .cameraNotFound(let id):
      return "Camera device with ID \(id) not found"
    case .extensionNotInstalled:
      return "System extension is not installed"
    case .captureSessionConfigurationFailed:
      return "Failed to configure camera preview"
    case .overlaySettingsSaveFailed(let errorMessage):
      return "Failed to save overlay settings: \(errorMessage)"
    case .appGroupAccessFailed:
      return "Failed to access shared app group storage"
    }
  }
}

// MARK: - Status Types

/// System extension operational status (installation)
enum ExtensionStatus: Equatable {
  case unknown
  case notInstalled
  case installing
  case installed
  case error(AppStateError)

  var displayText: String {
    switch self {
    case .unknown: "Checking..."
    case .notInstalled: "Not Installed"
    case .installing: "Installing..."
    case .installed: "Installed"
    case let .error(error): error.localizedDescription ?? "Error"
    }
  }

  var isInstalled: Bool {
    if case .installed = self { return true }
    return false
  }
}

/// Extension runtime status for reliable app-extension communication
/// (Different from ExtensionStatus which tracks installation)
enum ExtensionRuntimeStatus: String, CaseIterable, Codable {
    case idle = "idle"
    case starting = "starting" 
    case streaming = "streaming"
    case stopping = "stopping"
    case error = "error"
    
    var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .starting:
            return "Starting..."
        case .streaming:
            return "Streaming"
        case .stopping:
            return "Stopping..."
        case .error:
            return "Error"
        }
    }
    
    var isActive: Bool {
        return self == .streaming
    }
}

/// Camera service operational status
enum CameraStatus: Equatable {
  case stopped
  case starting
  case running
  case stopping
  case error(AppStateError)

  var displayText: String {
    switch self {
    case .stopped: "Stopped"
    case .starting: "Starting..."
    case .running: "Running"
    case .stopping: "Stopping..."
    case let .error(error): error.localizedDescription ?? "Error"
    }
  }

  var isRunning: Bool {
    if case .running = self { return true }
    return false
  }
}

// MARK: - Device Types

/// Represents a physical camera device
struct CameraDevice: Identifiable, Equatable, Hashable {
  let id: String
  let name: String
  let deviceType: String
}

// MARK: - AVCaptureDevice Extension

extension AVCaptureDevice.DeviceType {
  var displayName: String {
    switch self {
    case .builtInWideAngleCamera: "Built-in Camera"
    case .external: "External Camera"
    case .continuityCamera: "iPhone Camera"
    case .deskViewCamera: "Desk View Camera"
    default: "Camera"
    }
  }
}

// MARK: - App Group UserDefaults Keys

/// Keys for reliable status communication via App Group UserDefaults
enum ExtensionStatusKeys {
    // Legacy key - now used for installation status if needed
    static let status = "HL.ext.status"
    
    // New separate key for runtime status (streaming/idle/starting/etc)
    static let runtimeStatus = "HL.ext.runtimeStatus"
    
    static let lastHeartbeat = "HL.ext.lastHeartbeat"
    static let selectedDeviceID = "HL.selectedDeviceID"
    static let autoStartCamera = "HL.autoStartCamera"
    
    // Additional status info
    static let currentDeviceName = "HL.ext.currentDeviceName"
    static let errorMessage = "HL.ext.errorMessage"
}

