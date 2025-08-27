//
//  Notifications.swift
//  Headliner
//
//  Unified notification system with Internal and CrossApp domains
//  Phase 2: Single-file MVP architecture
//

import Foundation
import Combine
import OSLog

// MARK: - Notification Names

enum InternalNotificationName: String, CaseIterable {
  case extensionStatusChanged
  case locationPermissionGranted
  case appStateChanged
  
  var rawValue: String {
    switch self {
    case .extensionStatusChanged:
      return "\(Identifiers.notificationPrefix).internal.extensionStatusChanged.v1"
    case .locationPermissionGranted:
      return "\(Identifiers.notificationPrefix).internal.locationPermissionGranted.v1"
    case .appStateChanged:
      return "\(Identifiers.notificationPrefix).internal.appStateChanged.v1"
    }
  }
  
  var notificationName: NSNotification.Name {
    NSNotification.Name(self.rawValue)
  }
  
  static var allCases: [InternalNotificationName] {
    [.extensionStatusChanged, .locationPermissionGranted, .appStateChanged]
  }
  
  init?(rawValue: String) {
    for notification in InternalNotificationName.allCases {
      if notification.rawValue == rawValue {
        self = notification
        return
      }
    }
    return nil
  }
}

enum CrossAppNotificationName: String, CaseIterable {
  case startStream
  case stopStream
  case setCameraDevice
  case updateOverlaySettings
  case overlayUpdated
  case requestStart
  case requestStop
  case requestSwitchDevice
  case statusChanged
  // Phase 1.2: New typed notifications for auto-start
  case appConnected
  case appDisconnected
  case cameraActivated
  case cameraDeactivated
  
  var rawValue: String {
    switch self {
    case .startStream:
      return "\(Identifiers.notificationPrefix).startStream.v1"
    case .stopStream:
      return "\(Identifiers.notificationPrefix).stopStream.v1"
    case .setCameraDevice:
      return "\(Identifiers.notificationPrefix).setCameraDevice.v1"
    case .updateOverlaySettings:
      return "\(Identifiers.notificationPrefix).updateOverlaySettings.v1"
    case .overlayUpdated:
      return "\(Identifiers.notificationPrefix).overlayUpdated.v1"
    case .requestStart:
      return "\(Identifiers.notificationPrefix).request.start.v1"
    case .requestStop:
      return "\(Identifiers.notificationPrefix).request.stop.v1"
    case .requestSwitchDevice:
      return "\(Identifiers.notificationPrefix).request.switchDevice.v1"
    case .statusChanged:
      return "\(Identifiers.notificationPrefix).status.changed.v1"
    // Phase 1.2: New typed notifications
    case .appConnected:
      return "\(Identifiers.notificationPrefix).app.connected.v1"
    case .appDisconnected:
      return "\(Identifiers.notificationPrefix).app.disconnected.v1"
    case .cameraActivated:
      return "\(Identifiers.notificationPrefix).camera.activated.v1"
    case .cameraDeactivated:
      return "\(Identifiers.notificationPrefix).camera.deactivated.v1"
    }
  }
  
  static var allCases: [CrossAppNotificationName] {
    [.startStream, .stopStream, .setCameraDevice, .updateOverlaySettings, .overlayUpdated,
     .requestStart, .requestStop, .requestSwitchDevice, .statusChanged,
     .appConnected, .appDisconnected, .cameraActivated, .cameraDeactivated]
  }
  
  init?(rawValue: String) {
    for notification in CrossAppNotificationName.allCases {
      if notification.rawValue == rawValue {
        self = notification
        return
      }
    }
    return nil
  }
}

// MARK: - Unified Notifications System

final class Notifications {
  
  private init() {}
  
  // MARK: - Internal Notifications (NSNotificationCenter)
  
  enum Internal {
    private static let logger = HeadlinerLogger.logger(for: .internalNotifications)
    
    static func post(_ name: InternalNotificationName, userInfo: [AnyHashable: Any]? = nil) {
      precondition(Thread.isMainThread, "Internal notifications should be posted on main thread")
      
      logger.debug("📱 Internal notification: \(name.rawValue)")
      NotificationCenter.default.post(
        name: name.notificationName,
        object: nil,
        userInfo: userInfo
      )
    }
    
    @discardableResult
    static func addObserver(
      for name: InternalNotificationName,
      using block: @escaping (Notification) -> Void
    ) -> NSObjectProtocol {
      logger.debug("🔔 Adding observer for: \(name.rawValue)")
      return NotificationCenter.default.addObserver(
        forName: name.notificationName,
        object: nil,
        queue: .main,
        using: block
      )
    }
    
    static func removeObserver(_ token: NSObjectProtocol) {
      NotificationCenter.default.removeObserver(token)
    }
    
    static func publisher(for name: InternalNotificationName) -> NotificationCenter.Publisher {
      NotificationCenter.default.publisher(for: name.notificationName)
    }
  }
  
  // MARK: - Cross-App Notifications (Darwin/CFNotificationCenter)
  
  enum CrossApp {
    private static let logger = HeadlinerLogger.logger(for: .crossAppNotifications)
    
    static func post(_ name: CrossAppNotificationName) {
      logger.debug("🌉 Cross-app notification: \(name.rawValue)")
      CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(name.rawValue as NSString),
        nil,
        nil,
        true
      )
    }
    
    static func post(_ name: CrossAppNotificationName, overlaySettings: OverlaySettings) {
      logger.debug("🌉 Cross-app notification with overlay settings: \(name.rawValue)")
      
      // Save settings to shared app group defaults
      if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup),
         let encoded = try? JSONEncoder().encode(overlaySettings) {
        sharedDefaults.set(encoded, forKey: OverlayUserDefaultsKeys.overlaySettings)
        sharedDefaults.synchronize()
      }
      
      // Post the notification
      post(name)
    }
    
    static func addObserver(
      observer: UnsafeRawPointer,
      callback: @escaping CFNotificationCallback,
      name: CrossAppNotificationName
    ) {
      logger.debug("🔔 Adding Darwin observer for: \(name.rawValue)")
      CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        observer,
        callback,
        name.rawValue as CFString,
        nil,
        .deliverImmediately
      )
    }
    
    static func removeAllObservers(observer: UnsafeRawPointer) {
      CFNotificationCenterRemoveEveryObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        observer
      )
    }
    
    // MARK: - Bridge Setup (MVP Pattern)
    
    @discardableResult
    static func bridgeToInternal(
      crossApp: CrossAppNotificationName,
      internalNote: InternalNotificationName
    ) -> NSObjectProtocol {
      logger.debug("🌉→📱 Setting up bridge: \(crossApp.rawValue) → \(internalNote.rawValue)")
      
      let observer = UnsafeRawPointer(Unmanaged.passRetained(NSObject()).toOpaque())
      
      CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        observer,
        extensionStatusBridgeCallback as CFNotificationCallback,
        crossApp.rawValue as CFString,
        nil,
        .deliverImmediately
      )
      
      // Return cleanup token
      return BridgeCleanupToken(observer: observer)
    }
  }
}

// MARK: - C Function Pointer (No Capture)

private func extensionStatusBridgeCallback(
  center: CFNotificationCenter?,
  observer: UnsafeMutableRawPointer?,
  name: CFNotificationName?,
  object: UnsafeRawPointer?,
  userInfo: CFDictionary?
) {
  // This specifically handles the statusChanged → extensionStatusChanged bridge
  // Since C function pointers can't capture context, this is hardcoded
  Task { @MainActor in
    Notifications.Internal.post(.extensionStatusChanged)
  }
}

// MARK: - Bridge Cleanup Token

private class BridgeCleanupToken: NSObject {
  private let observer: UnsafeRawPointer
  
  init(observer: UnsafeRawPointer) {
    self.observer = observer
    super.init()
  }
  
  deinit {
    CFNotificationCenterRemoveEveryObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      observer
    )
    Unmanaged<NSObject>.fromOpaque(observer).release()
  }
}

// MARK: - Phase 1.2: Notification Payload Keys

struct NotificationPayloadKeys {
  static let appName = "appName"
  static let processID = "processID"
  static let timestamp = "timestamp"
  static let reason = "reason"
  static let clientCount = "clientCount"
}

// MARK: - Phase 1.2: CrossApp Extension Notifications Helper

final class CrossAppExtensionNotifications {
  private let logger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Extension")
  
  func postAppConnectedNotification(appName: String? = nil, processID: Int? = nil, clientCount: Int) {
    // Save payload to shared defaults
    if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
      var payload: [String: Any] = [
        NotificationPayloadKeys.clientCount: clientCount,
        NotificationPayloadKeys.timestamp: Date().timeIntervalSince1970
      ]
      
      if let appName = appName {
        payload[NotificationPayloadKeys.appName] = appName
      }
      if let processID = processID {
        payload[NotificationPayloadKeys.processID] = processID
      }
      
      sharedDefaults.set(payload, forKey: "LastAppConnected")
      sharedDefaults.synchronize()
    }
    
    // Post notification
    Notifications.CrossApp.post(.appConnected)
    logger.debug("Posted app connected notification - clients: \(clientCount)")
  }
  
  func postAppDisconnectedNotification(appName: String? = nil, processID: Int? = nil, clientCount: Int) {
    // Save payload to shared defaults
    if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
      var payload: [String: Any] = [
        NotificationPayloadKeys.clientCount: clientCount,
        NotificationPayloadKeys.timestamp: Date().timeIntervalSince1970
      ]
      
      if let appName = appName {
        payload[NotificationPayloadKeys.appName] = appName
      }
      if let processID = processID {
        payload[NotificationPayloadKeys.processID] = processID
      }
      
      sharedDefaults.set(payload, forKey: "LastAppDisconnected")
      sharedDefaults.synchronize()
    }
    
    // Post notification
    Notifications.CrossApp.post(.appDisconnected)
    logger.debug("Posted app disconnected notification - clients: \(clientCount)")
  }
  
  func postCameraActivatedNotification(reason: String) {
    // Save payload to shared defaults
    if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
      let payload: [String: Any] = [
        NotificationPayloadKeys.reason: reason,
        NotificationPayloadKeys.timestamp: Date().timeIntervalSince1970
      ]
      sharedDefaults.set(payload, forKey: "CameraActivated")
      sharedDefaults.synchronize()
    }
    
    // Post notification
    Notifications.CrossApp.post(.cameraActivated)
    logger.debug("Posted camera activated notification - reason: \(reason)")
  }
  
  func postCameraDeactivatedNotification(reason: String) {
    // Save payload to shared defaults
    if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
      let payload: [String: Any] = [
        NotificationPayloadKeys.reason: reason,
        NotificationPayloadKeys.timestamp: Date().timeIntervalSince1970
      ]
      sharedDefaults.set(payload, forKey: "CameraDeactivated")
      sharedDefaults.synchronize()
    }
    
    // Post notification
    Notifications.CrossApp.post(.cameraDeactivated)
    logger.debug("Posted camera deactivated notification - reason: \(reason)")
  }
}

// MARK: - DEPRECATED - Legacy System (Phase 1)

@available(*, deprecated, message: "Use Notifications.Internal or Notifications.CrossApp instead")
enum NotificationName: String, CaseIterable {
  case startStream
  case stopStream
  case setCameraDevice
  case updateOverlaySettings
  case overlayUpdated
  case requestStart
  case requestStop
  case requestSwitchDevice
  case statusChanged
  
  var rawValue: String {
    switch self {
    case .startStream:
      return "\(Identifiers.notificationPrefix).startStream"
    case .stopStream:
      return "\(Identifiers.notificationPrefix).stopStream"
    case .setCameraDevice:
      return "\(Identifiers.notificationPrefix).setCameraDevice"
    case .updateOverlaySettings:
      return "\(Identifiers.notificationPrefix).updateOverlaySettings"
    case .overlayUpdated:
      return "\(Identifiers.notificationPrefix).overlayUpdated"
    case .requestStart:
      return "\(Identifiers.notificationPrefix).request.start"
    case .requestStop:
      return "\(Identifiers.notificationPrefix).request.stop"
    case .requestSwitchDevice:
      return "\(Identifiers.notificationPrefix).request.switchDevice"
    case .statusChanged:
      return "\(Identifiers.notificationPrefix).status.changed"
    }
  }
  
  static var allCases: [NotificationName] {
    [.startStream, .stopStream, .setCameraDevice, .updateOverlaySettings, .overlayUpdated,
     .requestStart, .requestStop, .requestSwitchDevice, .statusChanged]
  }
  
  init?(rawValue: String) {
    for notification in NotificationName.allCases {
      if notification.rawValue == rawValue {
        self = notification
        return
      }
    }
    return nil
  }
}

@available(*, deprecated, message: "Use Notifications.CrossApp instead")
final class NotificationManager {
  private static let logger = HeadlinerLogger.logger(for: .notifications)

  class func postNotification(named notificationName: String) {
    let completeNotificationName = Identifiers.appGroup + "." + notificationName
    logger.debug("Posting notification \(completeNotificationName)")
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(completeNotificationName as NSString),
      nil,
      nil,
      true
    )
  }

  class func postNotification(named notificationName: NotificationName) {
    logger.debug("Posting notification \(notificationName.rawValue)")
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(notificationName.rawValue as NSString),
      nil,
      nil,
      true
    )
  }

  class func postNotification(named notificationName: NotificationName, overlaySettings: OverlaySettings) {
    logger.debug("Posting notification \(notificationName.rawValue) with overlay settings")
    
    // Save settings directly to shared app group defaults
    if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup),
       let encoded = try? JSONEncoder().encode(overlaySettings) {
      sharedDefaults.set(encoded, forKey: OverlayUserDefaultsKeys.overlaySettings)
      sharedDefaults.synchronize()
    }
    
    // Post the notification to tell the extension to reload from shared defaults
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(notificationName.rawValue as NSString),
      nil,
      nil,
      true
    )
  }
}



