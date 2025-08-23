//
//  ContentView.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//
//  ⚠️ TEMPORARILY DISABLED FOR BIG BANG MIGRATION ⚠️
//  This ContentView switches between MainAppView (windowed) and OnboardingView.
//  Since both are disabled during migration, this is also disabled.
//  Re-enable after migration complete by removing #if false wrapper.
//

#if false // 🚧 DISABLED DURING BIG BANG MIGRATION - RE-ENABLE LATER

import SwiftUI

// MARK: - ContentView

struct ContentView {
  // MARK: Lifecycle

  init(
    systemExtensionRequestManager: SystemExtensionRequestManager,
    propertyManager: CustomPropertyManager,
    outputImageManager: OutputImageManager
  ) {
    self.propertyManager = propertyManager
    self.outputImageManager = outputImageManager

    // Initialize AppState as a StateObject
    self._appState = StateObject(wrappedValue: AppState(
      systemExtensionManager: systemExtensionRequestManager,
      propertyManager: propertyManager,
      outputImageManager: outputImageManager
    ))
  }

  // MARK: Internal

  @StateObject private var appState: AppState
  private let propertyManager: CustomPropertyManager
  private let outputImageManager: OutputImageManager

  // MARK: Private
}

// MARK: View

extension ContentView: View {
  var body: some View {
    Group {
      if appState.extensionStatus.isInstalled {
        MainAppView(
          appState: appState,
          outputImageManager: outputImageManager,
          propertyManager: propertyManager
        )
      } else {
        OnboardingView(appState: appState)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: appState.extensionStatus.isInstalled)
    .environmentObject(appState.themeManager)
    .environment(\.theme, appState.themeManager.current)
  }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    let mgr = SystemExtensionRequestManager(logText: "")
    ContentView(
      systemExtensionRequestManager: mgr,
      propertyManager: CustomPropertyManager(),
      outputImageManager: OutputImageManager()
    )
    .frame(width: 1200, height: 800)
  }
}
#endif

#endif // 🚧 END DISABLED SECTION - Re-enable after Big Bang Migration complete
