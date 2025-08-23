//
//  MenuBarPreviews.swift
//  Headliner
//
//  Preview helpers for menu bar components
//

#if DEBUG

import SwiftUI

/// Preview container for menu bar components
struct MenuBarPreviews: PreviewProvider {
  static var previews: some View {
    // Single, lightweight preview to avoid heavy initialization
    MenuContent(appCoordinator: AppCoordinator())
      .frame(width: 320)
      .environmentObject(ThemeManager())
      .previewDisplayName("Menu Bar")
      .previewLayout(.sizeThatFits)
  }
}


#endif