import Foundation
import AppKit

struct OverlaySettings: Codable {
  var isEnabled: Bool = true
  var userName: String = ""
  var showUserName: Bool = true
  var namePosition: OverlayPosition = .bottomLeft
  var nameBackgroundColor: OverlayColor = .blackTransparent
  var nameTextColor: OverlayColor = .white
  var fontSize: CGFloat = 24
  var cornerRadius: CGFloat = 8
  var padding: CGFloat = 12
  var margin: CGFloat = 20
  var showVersion: Bool = true
  var versionPosition: OverlayPosition = .bottomRight
  var versionBackgroundColor: OverlayColor = .blackTransparent
  var versionTextColor: OverlayColor = .white
  var versionFontSize: CGFloat = 16
  
  // Preset system fields
  var selectedPresetId: String = "professional"
  var overlayTokens: OverlayTokens?
  var overlayAspect: OverlayAspect = .widescreen
  
  // Camera dimensions (cached from extension)
  var cameraDimensions: CGSize = CGSize(width: 1920, height: 1080)
  
  // Safe area system
  var safeAreaMode: SafeAreaMode = .balanced
}

enum OverlayPosition: String, Codable, CaseIterable {
  case topLeft, topCenter, topRight
  case centerLeft, center, centerRight
  case bottomLeft, bottomCenter, bottomRight

  var displayName: String {
    switch self {
    case .topLeft: return "Top Left"
    case .topCenter: return "Top Center"
    case .topRight: return "Top Right"
    case .centerLeft: return "Center Left"
    case .center: return "Center"
    case .centerRight: return "Center Right"
    case .bottomLeft: return "Bottom Left"
    case .bottomCenter: return "Bottom Center"
    case .bottomRight: return "Bottom Right"
    }
  }
}

enum OverlayColor: String, Codable, CaseIterable {
  case white, black, blackTransparent, blue, green, red, purple, orange

  var nsColor: NSColor {
    switch self {
    case .white: return .white
    case .black: return .black
    case .blackTransparent: return .black.withAlphaComponent(0.7)
    case .blue: return .systemBlue
    case .green: return .systemGreen
    case .red: return .systemRed
    case .purple: return .systemPurple
    case .orange: return .systemOrange
    }
  }

  var displayName: String {
    switch self {
    case .white: return "White"
    case .black: return "Black"
    case .blackTransparent: return "Black (Transparent)"
    case .blue: return "Blue"
    case .green: return "Green"
    case .red: return "Red"
    case .purple: return "Purple"
    case .orange: return "Orange"
    }
  }
}

enum OverlayUserDefaultsKeys {
  static let overlaySettings = "OverlaySettings"
}


