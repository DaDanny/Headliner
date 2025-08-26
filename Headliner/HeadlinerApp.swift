//
//  HeadlinerApp.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI
import Sparkle

@main
struct HeadlinerApp: App {
  // Persisted across launches (App Group so extension can also read/write if needed)
  @AppStorage("HL.hasCompletedOnboarding",
              store: UserDefaults(suiteName: Identifiers.appGroup))
  private var hasCompletedOnboarding: Bool = false

  @State private var appCoordinator = CompositionRoot.makeCoordinator()  // Clean dependency injection
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  init() {
//    if !AppLifecycleManager.enforcesSingleInstance() {
//      fatalError("Another instance is already running")
//    }
  }
  
  var body: some Scene {
    // Settings window - commented out for debugging
    // TODO: Debug why this opens on launch and can't be reopened
//    #if os(macOS)
//    Window("Settings", id: "settings") {
//      SettingsContentView()
//        .environmentObject(appCoordinator.updater)
//        .environmentObject(appCoordinator.camera)
//        .environmentObject(appCoordinator.overlay)
//        .environmentObject(appCoordinator.extensionService)
//    }
//    .windowStyle(.hiddenTitleBar)
//    .windowResizability(.contentSize)
//    .defaultSize(width: 600, height: 500)
//    #endif
    
    // 1) Onboarding scene (only opened programmatically)
    WindowGroup(id: "onboarding") {
      ModernOnboardingView {
        hasCompletedOnboarding = true
        
        // Close the onboarding window and activate menubar
        DispatchQueue.main.async {
          // Close the onboarding window
          if let onboardingWindow = NSApp.windows.first(where: { 
            $0.identifier?.rawValue == "onboarding" || $0.title == "Headliner" 
          }) {
            onboardingWindow.close()
          }
          
          // Switch back to accessory so the app behaves like a menu-bar app
          NSApp.setActivationPolicy(.accessory)
        }
      }
      .withAppCoordinator(appCoordinator)
      .frame(width: 900, height: 600)
      .onAppear {
        // Ensure the onboarding window is visible and focused on first show
        NSApp.setActivationPolicy(.regular)               // show Dock during onboarding
        NSApp.activate(ignoringOtherApps: true)
      }
    }
    .defaultSize(width: 900, height: 600)
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
    .windowToolbarStyle(.unifiedCompact)

    // 2) Bootstrap scene (hidden); decides whether to show onboarding at app launch
    WindowGroup(id: "bootstrap") {
      BootstrapView(
        hasCompletedOnboarding: hasCompletedOnboarding,
        appCoordinator: appCoordinator
      )
      .frame(width: 1, height: 1)                         // tiny & hidden
      .hidden()                                           // keep it invisible
      .onAppear { appCoordinator.initializeApp() }        // init app services
    }
    .defaultSize(width: 1, height: 1)
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)

    // 3) Menu bar UI
    MenuBarExtra("Headliner", systemImage: "video") {
      MenuContent(appCoordinator: appCoordinator)
        .withAppCoordinator(appCoordinator)
    }
    .menuBarExtraStyle(.window)
    .commands {
      // Replace the default app menu commands
      CommandGroup(replacing: .appInfo) {
        Button("About Headliner") {
          NSApplication.shared.orderFrontStandardAboutPanel(nil)
        }
        .keyboardShortcut("a", modifiers: .command)
        
        Divider()
        
        Button("Check for Updates…") {
          appCoordinator.updater.checkForUpdates()
        }
        .disabled(!appCoordinator.updater.canCheckForUpdates)
      }
      
    }
  }
}

/// Minimal bootstrap runner view.
/// Calls onboarding logic exactly once when mounted, then closes itself.
private struct BootstrapView: View {
  let hasCompletedOnboarding: Bool
  let appCoordinator: AppCoordinator
  
  @State private var didAttemptOnboarding = false
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Color.clear
      .task {
        guard !didAttemptOnboarding else { return }
        didAttemptOnboarding = true

        // Give SwiftUI a tick to mount scenes before we act
        try? await Task.sleep(nanoseconds: 150_000_000)
        
        // Check if we need onboarding (extension not installed)
        if !hasCompletedOnboarding || !appCoordinator.extensionService.isInstalled {
          NSApp.setActivationPolicy(.regular)
          NSApp.activate(ignoringOtherApps: true)
          openWindow(id: "onboarding")
        }
        
        // Close the bootstrap window immediately
        NSApp.keyWindow?.close()
      }
  }
}
