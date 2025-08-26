//
//  InternalNotifications.swift
//  Headliner
//
//  Created by Danny Francken on 8/26/25.
//

import Foundation
import Combine

// MARK: - Internal Notification Names

enum InternalNotificationName: String, CaseIterable {
  case extensionStatusChanged
  case locationPermissionGranted
  case appStateChanged
  // Add other in-app notifications as needed
  
  var rawValue: String {
    switch self {
    case .extensionStatusChanged:
      return "\(Identifiers.notificationPrefix).internal.extensionStatusChanged"
    case .locationPermissionGranted:
      return "\(Identifiers.notificationPrefix).internal.locationPermissionGranted"
    case .appStateChanged:
      return "\(Identifiers.notificationPrefix).internal.appStateChanged"
    }
  }
  
  var notificationName: NSNotification.Name {
    NSNotification.Name(self.rawValue)
  }
  
  // Required for CaseIterable when we override rawValue
  static var allCases: [InternalNotificationName] {
    [.extensionStatusChanged, .locationPermissionGranted, .appStateChanged]
  }
  
  // Support for initialization from string
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

// MARK: - Internal Notifications Manager

final class InternalNotifications {
  
  private init() {} // Prevent instantiation
  
  // Focused logging for internal notifications only
  private static let logger = HeadlinerLogger.logger(for: .internalNotifications)
  
  // MARK: - Posting
  
  static func post(_ name: InternalNotificationName, userInfo: [AnyHashable: Any]? = nil) {
    logger.debug("📱 Internal notification: \(name.rawValue)")
    NotificationCenter.default.post(
      name: name.notificationName,
      object: nil,
      userInfo: userInfo
    )
  }
  
  // MARK: - Observing (Combine)
  
  static func publisher(for name: InternalNotificationName) -> NotificationCenter.Publisher {
    NotificationCenter.default.publisher(for: name.notificationName)
  }
}