//
//  ContentView.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

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
        HeadlinerAppShell(
          appState: appState,
          outputImageManager: outputImageManager,
          propertyManager: propertyManager
        )
      } else {
        OnboardingView(appState: appState)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: appState.extensionStatus.isInstalled)
  }
}

// Intentionally no PreviewProvider to reduce compile surface for tooling.
