import Foundation

enum Identifiers {
  // MARK: - Base Components
  static let teamID = "378NGS49HA"
  static let organizationID = "com.dannyfrancken"
  static let appName = "Headliner"
  
  // MARK: - Computed Identifiers
  static var bundleID: String {
    "\(organizationID).\(appName)"
  }
  
  static var appGroup: String {
    "group.\(teamID).\(bundleID)"
  }
  
  static var orgIDAndProduct: String {
    bundleID
  }
  
  // MARK: - Notification Base
  static var notificationPrefix: String {
    "\(teamID).\(bundleID)"
  }
}


