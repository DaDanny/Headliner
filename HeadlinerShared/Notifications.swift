import Foundation
import OSLog

enum NotificationName: String, CaseIterable {
  case startStream = "378NGS49HA.com.dannyfrancken.Headliner.startStream"
  case stopStream = "378NGS49HA.com.dannyfrancken.Headliner.stopStream"
  case setCameraDevice = "378NGS49HA.com.dannyfrancken.Headliner.setCameraDevice"
  case updateOverlaySettings = "378NGS49HA.com.dannyfrancken.Headliner.updateOverlaySettings"
}

final class NotificationManager {
  private static let logger = Logger(subsystem: Identifiers.orgIDAndProduct.rawValue, category: "Notify")

  class func postNotification(named notificationName: String) {
    let completeNotificationName = Identifiers.appGroup.rawValue + "." + notificationName
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
}


