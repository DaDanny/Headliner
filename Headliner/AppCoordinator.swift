//
//  AppCoordinator.swift
//  Headliner
//
//  Coordinates between services and provides a clean interface for the UI layer
//

import SwiftUI
import Combine
import AVFoundation
import CoreLocation

/// Service coordinator - THIN orchestration layer only
/// NOT ObservableObject - views observe services directly
@MainActor
final class AppCoordinator {
  // MARK: - Services
  
  let camera: CameraService
  let extensionService: ExtensionService  // Can't use 'extension' - it's a keyword!
  let overlay: OverlayService
  let location: LocationPermissionManager
  let personalInfo: PersonalInfoPump
  
  // MARK: - Services (for view injection)
  // Views observe these directly, not the coordinator
  
  // MARK: - Shared utilities  
  let themeManager = ThemeManager()
  
  // MARK: - Private Properties
  private var cancellables = Set<AnyCancellable>()
  private let logger = HeadlinerLogger.logger(for: .application)
  private let analytics = AnalyticsManager.shared
  
  // MARK: - Initialization
  
  init() {
    let captureManager = CaptureSessionManager(capturingHeadliner: false)
    let outputManager = OutputImageManager()
    let extensionRequestManager = SystemExtensionRequestManager(logText: "")
    let propertyManager = CustomPropertyManager()
    
    // Initialize services
    self.camera = CameraService(
      captureSessionManager: captureManager,
      outputImageManager: outputManager
    )
    
    self.extensionService = ExtensionService(
      requestManager: extensionRequestManager,
      propertyManager: propertyManager
    )
    
    self.overlay = OverlayService()
    self.location = LocationPermissionManager() 
    self.personalInfo = PersonalInfoPump()
    
    setupBindings()
  }
  
  // MARK: - App Lifecycle
  
  func initializeApp() {
    logger.debug("Initializing app coordinator...")
    
    // Track app launch
    analytics.trackAppLaunch()
    
    // Check extension status
    extensionService.checkStatus()
    
    // Load cameras if we have permission
    if camera.hasCameraPermission {
      camera.refreshCameras()
    }
    
    // Start personal info if location permitted
    if location.isLocationAvailable {
      personalInfo.start()
    }
  }
  
  // MARK: - App Actions (delegate to appropriate services)
  
  /// Start the camera and virtual device
  func startCamera() {
    guard extensionService.isInstalled else {
      logger.debug("Cannot start - extension not installed")
      return
    }
    
    Task {
      do {
        // Send overlay settings first
        // TODO: overlay.notifyExtension() - make this method public"
        
        // Start camera
        try await camera.startCamera()
        
        // Track analytics
        analytics.trackCameraStart(duration: 1.0) // TODO: Get actual duration
      } catch {
        logger.error("Failed to start camera: \(error)")
        analytics.trackError(error, context: "camera_start")
      }
    }
  }
  
  /// Stop the camera
  func stopCamera() {
    camera.stopCamera()
    analytics.track(.cameraStopped)
  }
  
  // Removed duplicate toggleCamera - see legacy compatibility section
  
  /// Install the system extension
  func installExtension() {
    extensionService.install()
    analytics.track(.extensionInstalled)
  }
  
  /// Select a camera device - delegate to CameraService
  func selectCamera(_ device: CameraDevice) {
    Task {
      await camera.selectCamera(device)
      analytics.trackCameraSwitch(
        cameraId: device.id,
        duration: 0.5 // TODO: Get actual duration
      )
    }
  }
  
  /// Select an overlay preset - delegate to OverlayService
  func selectOverlayPreset(_ presetId: String) {
    overlay.selectPreset(presetId)
    analytics.trackOverlaySelection(presetId: presetId)
  }
  
  /// Update overlay tokens - delegate to OverlayService
  func updateOverlayTokens(_ tokens: OverlayTokens) {
    overlay.updateTokens(tokens)
    analytics.trackOverlaySettingChange(setting: "tokens", value: tokens.displayName)
  }
  
  /// Request location permission - delegate to LocationPermissionManager
  func requestLocationPermission() {
    location.requestLocationPermission()
  }
  
  /// Toggle launch at login
  func toggleLaunchAtLogin() {
    // TODO: Implement actual launch at login logic with ServiceManagement
  }
  
  /// Quit the application
  func quitApp() {
    NSApplication.shared.terminate(nil)
  }
  
  // MARK: - Private Methods
  
  private func setupBindings() {
    // Coordinate between services
    
    // When extension installs, refresh cameras
    extensionService.$status
      .removeDuplicates()
      .sink { [weak self] status in
        if status == .installed {
          self?.camera.refreshCameras()
        }
        self?.analytics.trackExtensionStatus(status.displayText)
      }
      .store(in: &cancellables)
    
    // When location permission granted, start personal info
    NotificationCenter.default.publisher(for: .locationPermissionGranted)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.personalInfo.start()
        self?.analytics.track(.locationPermissionGranted)
      }
      .store(in: &cancellables)
    
    // Track overlay changes
    overlay.$settings
      .sink { [weak self] settings in
        if settings.isEnabled {
          self?.analytics.track(.overlayEnabled)
        } else {
          self?.analytics.track(.overlayDisabled)
        }
      }
      .store(in: &cancellables)
  }
  
  // MARK: - Legacy compatibility (to be removed after migration)
  
  /// Legacy methods for MenuContent compatibility - TEMPORARY
  /// TODO: Remove these after views observe services directly
  func toggleCamera() {
    if camera.cameraStatus == .running {
      stopCamera()
    } else {
      startCamera()
    }
  }
  
  // Legacy properties - views should observe services directly instead
  var isRunning: Bool { camera.cameraStatus == .running }
  var cameras: [CameraDevice] { camera.availableCameras }
  var selectedCameraID: String { camera.selectedCamera?.id ?? "" }
  var extensionStatus: ExtensionStatus { extensionService.status }
  var overlays: [SwiftUIPresetInfo] { overlay.availablePresets }
  var selectedOverlayID: String { overlay.currentPreset?.id ?? "" }
  var overlaySettings: OverlaySettings { overlay.settings }
  var launchAtLogin: Bool { false } // TODO: Implement properly
  
  func getAppState() -> Any { self } // Legacy hack
}

// MARK: - SwiftUI Environment Setup

extension View {
  /// Inject services into the environment for direct observation
  /// Views observe services directly, NOT the coordinator
  func withAppCoordinator(_ coordinator: AppCoordinator) -> some View {
    self
      .environmentObject(coordinator.camera)           // Views observe CameraService
      .environmentObject(coordinator.extensionService) // Views observe ExtensionService  
      .environmentObject(coordinator.overlay)          // Views observe OverlayService
      .environmentObject(coordinator.location)         // Views observe LocationPermissionManager
      .environmentObject(coordinator.themeManager)     // Views observe ThemeManager
      // Coordinator itself available via environment for delegation
      .environment(\.appCoordinator, coordinator)
  }
}

// Environment key for coordinator access
private struct AppCoordinatorKey: EnvironmentKey {
  static let defaultValue: AppCoordinator? = nil
}

extension EnvironmentValues {
  var appCoordinator: AppCoordinator? {
    get { self[AppCoordinatorKey.self] }
    set { self[AppCoordinatorKey.self] = newValue }
  }
}