//
//  AppCoordinator.swift
//  Headliner
//
//  Coordinates between services and provides a clean interface for the UI layer
//

import SwiftUI
import Combine
import AVFoundation

/// Drop-in replacement for the old AppState God Object
/// Now properly architected with services
@MainActor
final class AppCoordinator: ObservableObject {
  // MARK: - Services
  
  let camera: CameraService
  let extensionService: ExtensionService  // Can't use 'extension' - it's a keyword!
  let overlay: OverlayService
  let location: LocationPermissionManager
  let personalInfo: PersonalInfoPump
  
  // MARK: - Published Properties (API compatibility with old AppState)
  
  @Published var extensionStatus: ExtensionStatus { 
    didSet { } 
  }
  @Published var cameraStatus: CameraStatus {
    didSet { }
  }
  @Published var availableCameras: [CameraDevice] = []
  @Published var selectedCameraID: String = ""
  @Published var statusMessage: String = ""
  @Published var isShowingSettings = false
  @Published var overlaySettings: OverlaySettings {
    didSet { }
  }
  @Published var isShowingOverlaySettings = false
  @Published var selectedTemplateId = "professional"
  @Published var themeManager = ThemeManager()
  @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
  
  let locationPermissionManager: LocationPermissionManager
  
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
    
    self.extension = ExtensionService(
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
    extension.checkStatus()
    
    // Load cameras if we have permission
    if camera.hasCameraPermission {
      camera.refreshCameras()
    }
    
    // Start personal info if location permitted
    if location.isLocationAvailable {
      personalInfo.start()
    }
  }
  
  // MARK: - User Actions
  
  /// Start the camera and virtual device
  func startCamera() {
    guard extension.isInstalled else {
      logger.debug("Cannot start - extension not installed")
      return
    }
    
    Task {
      do {
        // Send overlay settings first
        overlay.notifyExtension()
        
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
  
  /// Install the system extension
  func installExtension() {
    extension.install()
    analytics.track(.extensionInstalled)
  }
  
  /// Select a camera device
  func selectCamera(_ device: CameraDevice) {
    Task {
      await camera.selectCamera(device)
      analytics.trackCameraSwitch(
        cameraId: device.id,
        duration: 0.5 // TODO: Get actual duration
      )
    }
  }
  
  /// Select an overlay preset
  func selectOverlayPreset(_ presetId: String) {
    overlay.selectPreset(presetId)
    selectedTemplateId = presetId
    analytics.trackOverlaySelection(presetId: presetId)
  }
  
  /// Update overlay tokens
  func updateOverlayTokens(_ tokens: OverlayTokens) {
    overlay.updateTokens(tokens)
    analytics.trackOverlaySettingChange(setting: "tokens", value: tokens.displayName)
  }
  
  /// Request location permission
  func requestLocationPermission() {
    location.requestLocationPermission()
  }
  
  // MARK: - Private Methods
  
  private func setupBindings() {
    // Coordinate between services
    
    // When extension installs, refresh cameras
    extension.$status
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
      .removeDuplicates()
      .sink { [weak self] settings in
        if settings.isEnabled {
          self?.analytics.track(.overlayEnabled)
        } else {
          self?.analytics.track(.overlayDisabled)
        }
      }
      .store(in: &cancellables)
  }
  
  // MARK: - Computed Properties
  
  /// Check if we can start the camera
  var canStartCamera: Bool {
    extension.isInstalled && camera.hasCameraPermission
  }
  
  /// Check if camera is running
  var isCameraRunning: Bool {
    camera.cameraStatus == .running
  }
  
  /// Check if we need any permissions
  var needsPermissions: Bool {
    !camera.hasCameraPermission
  }
  
  /// Get current status message
  var statusMessage: String {
    if !extension.isInstalled {
      return extension.statusMessage
    } else if camera.cameraStatus != .stopped {
      return camera.statusMessage
    } else {
      return "Ready"
    }
  }
}

// MARK: - SwiftUI Environment Setup

extension View {
  /// Inject the coordinator and its services into the environment
  func withAppCoordinator(_ coordinator: AppCoordinator) -> some View {
    self
      .environmentObject(coordinator)
      .environmentObject(coordinator.camera)
      .environmentObject(coordinator.extension)
      .environmentObject(coordinator.overlay)
  }
}