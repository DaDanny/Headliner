//
//  HeadlinerApp.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI

@main
struct HeadlinerApp: App {
  // Simple, clean initialization
  @StateObject private var appState: AppState
  @StateObject private var menuBarViewModel: MenuBarViewModel
  
  init() {
    // Initialize AppState with dependencies
    let appState = AppState(
      systemExtensionManager: SystemExtensionRequestManager(logText: ""),
      propertyManager: CustomPropertyManager(),
      outputImageManager: OutputImageManager()
    )
    self._appState = StateObject(wrappedValue: appState)
    self._menuBarViewModel = StateObject(wrappedValue: MenuBarViewModel(appState: appState))
  }
  
  var body: some Scene {
    // Menu Bar Scene - The ONLY interface
    MenuBarExtra("Headliner", systemImage: isRunning ? "dot.radiowaves.left.and.right" : "video") {
      MenuContent(viewModel: menuBarViewModel)
        .onAppear {
          // Initialize app state for first use
          appState.initializeForUse()
        }
    }
    .menuBarExtraStyle(.window)
    
    // Settings Window - Only when needed for complex settings
    Settings {
      SettingsView(appState: appState)
        .environmentObject(appState.themeManager)
    }
  }
  
  // MARK: - Computed Properties
  
  private var isRunning: Bool {
    appState.cameraStatus.isRunning
  }
}
