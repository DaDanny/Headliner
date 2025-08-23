//
//  HeadlinerApp.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI

@main
struct HeadlinerApp: App {
  @StateObject private var appState = AppCoordinator()  // Just rename to appState for compatibility
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  init() {
    if !AppLifecycleManager.enforcesSingleInstance() {
      fatalError("Another instance is already running")
    }
  }
  
  var body: some Scene {
    MenuBarExtra("Headliner", systemImage: isRunning ? "dot.radiowaves.left.and.right" : "video") {
      MenuContent(appState: appState)
        .onAppear {
          appState.initializeApp()
        }
    }
    .menuBarExtraStyle(.window)
    
    Settings {
      SettingsView(appState: appState)
    }
  }
  
    // TODO: Review if this is needed or should be moved out and into the proper location
    // My gut is telling me that this should be from either the ExtensionService or CameraService
  private var isRunning: Bool {
    appState.isCameraRunning
  }
}
