import SwiftUI

// Shared mocks for SwiftUI previews. DEBUG-only by build guard at file scope.
#if DEBUG
enum PreviewData {
  static var overlaySettings: OverlaySettings {
    var s = OverlaySettings()
    s.userName = "Danny F"
    s.showUserName = true
    s.namePosition = .bottomLeft
    return s
  }
}
#endif
