import Foundation
import OSLog

// MARK: - Darwin Notifications

enum NotificationName: String, CaseIterable {
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
  static var allCases: [NotificationName] {
    [.startStream, .stopStream, .setCameraDevice, .updateOverlaySettings, .overlayUpdated,
     .requestStart, .requestStop, .requestSwitchDevice, .statusChanged]
  }
  
  // Support for initialization from string (used in CameraExtension)
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



