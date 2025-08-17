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
      if shouldShowOnboarding {
        OnboardingView(appState: appState)
      } else {
        MainAppView(
          appState: appState,
          outputImageManager: outputImageManager,
          propertyManager: propertyManager
        )
      }
    }
    .animation(.easeInOut(duration: 0.3), value: shouldShowOnboarding)
  }
  
  /// Determine whether to show onboarding based on the current phase
  private var shouldShowOnboarding: Bool {
    // Check UserDefaults flag first - if onboarding was completed before, skip it
    let onboardingCompleted = UserDefaults.standard.bool(forKey: "OnboardingCompleted")
    if onboardingCompleted && appState.extensionStatus.isInstalled {
      return false
    }
    
    switch appState.onboardingPhase {
    case .preflight, .needsExtensionInstall, .awaitingApproval, .readyToStart, .startingCamera, .running, .personalizeOptional, .error:
      return true
    case .completed:
      return false
    }
  }
}

// Intentionally no PreviewProvider to reduce compile surface for tooling.
