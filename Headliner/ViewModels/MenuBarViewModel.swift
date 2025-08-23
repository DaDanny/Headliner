//
//  MenuBarViewModel.swift
//  Headliner
//
//  Created by AI Assistant on 8/22/25.
//
//  ⚠️ DEPRECATED: This file is deprecated as of Phase 9 of the Big Bang Migration
//  Views now use AppCoordinator + Services directly via @EnvironmentObject
//  TODO: Delete this file after confirming all legacy usage is removed
//

#if false // DEPRECATED - Remove after migration complete

import SwiftUI
import AVFoundation
import Combine
import ServiceManagement

/// View model for the menu bar app interface.
/// Wraps AppState functionality and provides menu-specific state management.
@MainActor
class MenuBarViewModel: ObservableObject {
  
  // MARK: - Published Properties
  
  /// Whether the virtual camera is currently running
  @Published var isRunning: Bool = false
  
  /// List of available physical cameras
  @Published var cameras: [CameraDevice] = []
  
  /// List of available overlay presets
  @Published var overlays: [SwiftUIPresetInfo] = []
  
  /// ID of the currently selected camera
  @Published var selectedCameraID: String = ""
  
  /// ID of the currently selected overlay preset
  @Published var selectedOverlayID: String = ""
  
  /// Current extension status for error handling
  @Published var extensionStatus: ExtensionStatus = .unknown
  
  /// Whether settings window is showing
  @Published var isShowingSettings: Bool = false
  
  /// Whether preview window is showing
  @Published var isShowingPreview: Bool = false
  
  /// Launch at login setting
  @Published var launchAtLogin: Bool = false
  
  /// Status message for errors or info
  @Published var statusMessage: String = ""
  
  // MARK: - Dependencies
  
  private let appState: AppState
  private let extensionService: ExtensionService
  private let overlayService: OverlayService
  private var cancellables = Set<AnyCancellable>()
  
  // MARK: - Initialization
  
  init(appState: AppState, extensionService: ExtensionService, overlayService: OverlayService) {
    self.appState = appState
    self.extensionService = extensionService
    self.overlayService = overlayService
    setupBindings()
    refreshData()
    loadLaunchAtLoginState()
  }
  
  // Legacy constructor for compatibility during migration
  init(appState: AppState) {
    self.appState = appState
    // Create temporary services for legacy compatibility
    self.extensionService = ExtensionService(
      requestManager: SystemExtensionRequestManager(logText: ""),
      propertyManager: CustomPropertyManager()
    )
    self.overlayService = OverlayService()
    setupBindings()
    refreshData()
    loadLaunchAtLoginState()
  }
  
  // MARK: - Public Actions
  
  /// Start or stop the virtual camera
  func toggleCamera() {
    if isRunning {
      stopCamera()
    } else {
      startCamera()
    }
  }
  
  /// Start the virtual camera
  func startCamera() {
    guard extensionStatus == .installed else {
      statusMessage = "Extension not installed - install from main app"
      return
    }
    
    appState.startCamera()
  }
  
  /// Stop the virtual camera
  func stopCamera() {
    appState.stopCamera()
  }
  
  /// Select a camera device
  func selectCamera(_ camera: CameraDevice) {
    appState.selectCamera(camera)
    selectedCameraID = camera.id
  }
  
  /// Select a camera by ID (for menu integration)
  func selectCamera(id: String) {
    appState.selectedCameraID = id
    selectedCameraID = id
  }
  
  /// Select an overlay preset
  func selectOverlay(_ overlayID: String) {
    overlayService.selectPreset(overlayID)
    selectedOverlayID = overlayID
  }
  
  /// Refresh camera list
  func refreshCameras() {
    appState.refreshCameras()
  }
  
  /// Show settings window (used by environment openWindow)
  func openSettings() {
    isShowingSettings = true
  }
  
  /// Show preview window (used by environment openWindow)
  func openPreview() {
    isShowingPreview = true
  }
  
  /// Toggle launch at login setting
  func toggleLaunchAtLogin() {
    launchAtLogin.toggle()
    setLaunchAtLogin(launchAtLogin)
  }
  
  /// Quit the application
  func quitApp() {
    // Stop camera if running
    if isRunning {
      stopCamera()
    }
    
    // Quit after a brief delay to allow cleanup
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      NSApplication.shared.terminate(nil)
    }
  }
  
  /// Get the underlying AppState for components that need it
  func getAppState() -> AppState {
    return appState
  }
  
  // MARK: - Private Methods
  
  /// Set up Combine bindings with AppState
  private func setupBindings() {
    // Bind camera status to isRunning
    appState.$cameraStatus
      .map { status in
        if case .running = status { return true }
        return false
      }
      .receive(on: DispatchQueue.main)
      .assign(to: &$isRunning)
    
    // Bind available cameras
    appState.$availableCameras
      .receive(on: DispatchQueue.main)
      .assign(to: &$cameras)
    
    // Bind selected camera ID
    appState.$selectedCameraID
      .receive(on: DispatchQueue.main)
      .assign(to: &$selectedCameraID)
    
    // Bind extension status from ExtensionService instead of AppState
    extensionService.$status
      .receive(on: DispatchQueue.main)
      .assign(to: &$extensionStatus)
    
    // Bind status message
    appState.$statusMessage
      .receive(on: DispatchQueue.main)
      .assign(to: &$statusMessage)
    
    // Bind overlay preset ID from OverlayService instead of AppState
    overlayService.$settings
      .map { $0.selectedPresetId }
      .receive(on: DispatchQueue.main)
      .assign(to: &$selectedOverlayID)
  }
  
  /// Load initial data
  private func refreshData() {
    // Check extension status
    extensionService.checkStatus()
    
    // Load overlay presets from OverlayService
    overlays = overlayService.availablePresets
    
    // Set initial values
    selectedCameraID = appState.selectedCameraID
    selectedOverlayID = overlayService.currentPresetId
    isRunning = appState.cameraStatus.isRunning
  }
  
  /// Load launch at login state
  private func loadLaunchAtLoginState() {
    if #available(macOS 13.0, *) {
      let service = SMAppService.mainApp
      launchAtLogin = service.status == .enabled
    } else {
      // Fallback for older macOS versions
      launchAtLogin = false
    }
  }
  
  /// Set launch at login preference
  private func setLaunchAtLogin(_ enabled: Bool) {
    if #available(macOS 13.0, *) {
      let service = SMAppService.mainApp
      do {
        if enabled {
          try service.register()
        } else {
          try service.unregister()
        }
      } catch {
        print("Failed to set launch at login: \(error)")
        // Revert the toggle state on error
        launchAtLogin = !enabled
      }
    }
  }
}

#if DEBUG
// MARK: - Preview Support

extension MenuBarViewModel {
  /// Create a minimal mock view model for previews (reduced complexity)
  static func createMinimalMock() -> MenuBarViewModel {
    let systemExtensionManager = SystemExtensionRequestManager(logText: "")
    let propertyManager = CustomPropertyManager()
    let outputImageManager = OutputImageManager()
    let appState = AppState(
      systemExtensionManager: systemExtensionManager,
      propertyManager: propertyManager,
      outputImageManager: outputImageManager
    )
    
    let viewModel = MenuBarViewModel(appState: appState)
    
    // Minimal mock data for faster previews
    viewModel.isRunning = false
    viewModel.extensionStatus = .installed
    viewModel.cameras = [
      CameraDevice(id: "builtin", name: "Built-in Camera", deviceType: "Built-in Camera")
    ]
    viewModel.selectedCameraID = "builtin"
    
    viewModel.overlays = [
      SwiftUIPresetInfo(
        id: "swiftui.clean", 
        name: "Clean", 
        description: "No overlay elements",
        category: .minimal,
        provider: Clean()
      )
    ]
    viewModel.selectedOverlayID = "swiftui.clean"
    
    viewModel.launchAtLogin = false
    viewModel.statusMessage = "Ready"
    
    return viewModel
  }
  
  /// Create a full mock view model for previews
  static func createMock(isRunning: Bool = false, extensionStatus: ExtensionStatus = .installed) -> MenuBarViewModel {
    let systemExtensionManager = SystemExtensionRequestManager(logText: "")
    let propertyManager = CustomPropertyManager()
    let outputImageManager = OutputImageManager()
    let appState = AppState(
      systemExtensionManager: systemExtensionManager,
      propertyManager: propertyManager,
      outputImageManager: outputImageManager
    )
    
    let viewModel = MenuBarViewModel(appState: appState)
    
    // Set mock data
    viewModel.isRunning = isRunning
    viewModel.extensionStatus = extensionStatus
    viewModel.cameras = [
      CameraDevice(id: "builtin", name: "Built-in FaceTime HD Camera", deviceType: "Built-in Camera"),
      CameraDevice(id: "iphone", name: "iPhone Camera", deviceType: "iPhone Camera"),
      CameraDevice(id: "external", name: "Logitech C920", deviceType: "External Camera"),
      CameraDevice(id: "deskview", name: "iPhone Desk View", deviceType: "Desk View Camera")
    ]
    viewModel.selectedCameraID = "builtin"
    
    viewModel.overlays = [
      SwiftUIPresetInfo(
        id: "swiftui.professional.corner", 
        name: "Professional Corner", 
        description: "Clean professional overlay",
        category: .standard,
        provider: ProfessionalCorner()
      ),
      SwiftUIPresetInfo(
        id: "swiftui.modern.personal", 
        name: "Modern Personal", 
        description: "Personal info with modern design",
        category: .standard,
        provider: ModernPersonal()
      ),
      SwiftUIPresetInfo(
        id: "swiftui.modern.company.branded",
        name: "Company Branded",
        description: "Company branding overlay",
        category: .branded,
        provider: ModernCompanyBranded()
      )
    ]
    viewModel.selectedOverlayID = "swiftui.professional.corner"
    
    viewModel.launchAtLogin = false
    viewModel.statusMessage = extensionStatus == .installed ? "Ready" : "Extension needs installation"
    
    return viewModel
  }
}
#endif

#endif // DEPRECATED - Remove after migration complete