//
//  HeadlinerApp.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI

@main
struct HeadlinerApp: App {
  @StateObject private var appCoordinator = AppCoordinator()  // Real service-based coordinator
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  init() {
    if !AppLifecycleManager.enforcesSingleInstance() {
      fatalError("Another instance is already running")
    }
  }
  
  var body: some Scene {
    MenuBarExtra("Headliner", systemImage: isRunning ? "dot.radiowaves.left.and.right" : "video") {
      MenuContent(appCoordinator: appCoordinator)
        .withAppCoordinator(appCoordinator)  // Inject services
        .onAppear {
          appCoordinator.initializeApp()
        }
    }
    .menuBarExtraStyle(.window)
    
    Settings {
      SettingsView(appCoordinator: appCoordinator)
        .withAppCoordinator(appCoordinator)  // Inject services
    }
  }
  
  // TODO: This should observe CameraService directly, not through coordinator
  private var isRunning: Bool {
    appCoordinator.camera.cameraStatus == .running
  }
}
