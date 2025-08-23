//
//  HeadlinerApp.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI

@main
struct HeadlinerApp: App {
  @State private var appCoordinator = CompositionRoot.makeCoordinator()  // Clean dependency injection
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  init() {
    if !AppLifecycleManager.enforcesSingleInstance() {
      fatalError("Another instance is already running")
    }
  }
  
  var body: some Scene {
    MenuBarExtra("Headliner", systemImage: "video") {  // Static icon for now, TODO: observe CameraService
      MenuContent(appCoordinator: appCoordinator)
        .withAppCoordinator(appCoordinator)  // Inject services
        .onAppear {
          appCoordinator.initializeApp()
        }
    }
    .menuBarExtraStyle(.window)
    
    // Settings {
    //   SettingsView(appCoordinator: appCoordinator)
    //     .withAppCoordinator(appCoordinator)  // Inject services
    // }
  }
}
