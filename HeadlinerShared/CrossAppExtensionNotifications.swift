//
//  CrossAppExtensionNotifications.swift
//  Headliner
//
//  Created by Danny Francken on 8/26/25.
//

import Foundation
import OSLog

// MARK: - Cross-App Extension Notification Names

enum CrossAppNotificationName: String, CaseIterable {
  case startStream
  case stopStream
  case setCameraDevice
  case updateOverlaySettings
  case overlayUpdated
  // Phase 2: Enhanced bidirectional notifications
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
    // Phase 2: Enhanced bidirectional notifications
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
  
  // Required for CaseIterable when we override rawValue
  static var allCases: [CrossAppNotificationName] {
    [.startStream, .stopStream, .setCameraDevice, .updateOverlaySettings, .overlayUpdated,
     .requestStart, .requestStop, .requestSwitchDevice, .statusChanged]
  }
  
  // Support for initialization from string (used in CameraExtension)
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

// MARK: - Cross-App Extension Notifications Manager

final class CrossAppExtensionNotifications {
  
  private init() {} // Prevent instantiation
  
  // Focused logging for cross-app notifications only
  private static let logger = HeadlinerLogger.logger(for: .crossAppNotifications)
  
  // MARK: - Posting (From Main App)
  
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
  
  // MARK: - Listening (From Extension)
  
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
}