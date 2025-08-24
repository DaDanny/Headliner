//
//  HeadlinerApp.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI

@main
struct HeadlinerApp: App {
  // Persisted across launches (App Group so extension can also read/write if needed)
  @AppStorage("HL.hasCompletedOnboarding",
              store: UserDefaults(suiteName: Identifiers.appGroup))
  private var hasCompletedOnboarding: Bool = false

  @State private var appCoordinator = CompositionRoot.makeCoordinator()  // Clean dependency injection
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  init() {
    if !AppLifecycleManager.enforcesSingleInstance() {
      fatalError("Another instance is already running")
    }
  }
  
  var body: some Scene {
    // 1) Onboarding scene (only opened programmatically)
    WindowGroup(id: "onboarding") {
      OnboardingView(appCoordinator: appCoordinator) {
        hasCompletedOnboarding = true
        appCoordinator.completeOnboarding()
        
        // Close the onboarding window
        DispatchQueue.main.async {
          NSApp.keyWindow?.close()
        }
        
        // Switch back to accessory so the app behaves like a menu-bar app
        NSApp.setActivationPolicy(.accessory)
      }
      .withAppCoordinator(appCoordinator)
      .frame(minWidth: 1000, idealWidth: 1100, minHeight: 700, idealHeight: 800)
      .onAppear {
        // Ensure the onboarding window is visible and focused on first show
        NSApp.setActivationPolicy(.regular)               // show Dock during onboarding
        NSApp.activate(ignoringOtherApps: true)
      }
    }
    .defaultSize(width: 1100, height: 800)
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
