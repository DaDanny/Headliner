//
//  AppState.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import AVFoundation
import Combine
import CoreLocation
import SwiftUI
import SystemExtensions
import CoreGraphics

/// Main application state.
///
/// Coordinates UI state with the system extension lifecycle and a local AVCaptureSession
/// used for on-device preview. Owns user selections (camera, overlay settings), persists
/// them, and communicates updates to the extension via Darwin notifications.
@MainActor
class AppState: ObservableObject {
  // MARK: - Published Properties

  /// Current install/run status of the system extension.
  @Published var extensionStatus: ExtensionStatus = .unknown
  /// Current run state of the local preview/virtual camera.
  @Published var cameraStatus: CameraStatus = .stopped
  /// List of selectable physical cameras (excludes the Headliner virtual camera).
  @Published var availableCameras: [CameraDevice] = []
  /// Unique ID of the selected camera (persisted in UserDefaults and shared with extension).
  @Published var selectedCameraID: String = ""
  /// Status text surfaced in onboarding or header.
  @Published var statusMessage: String = ""
  /// Controls presentation of the general settings UI.
  @Published var isShowingSettings: Bool = false
  /// Overlay configuration shared with the extension.
  @Published var overlaySettings: OverlaySettings = .init()
  /// Controls presentation of the overlay settings sheet.
  @Published var isShowingOverlaySettings: Bool = false
  /// Currently selected overlay template ID
  @Published var selectedTemplateId: String = "professional"


  /// Current location authorization status
  @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

  // MARK: - Dependencies

  private let systemExtensionManager: SystemExtensionRequestManager
  private let propertyManager: CustomPropertyManager
  private let outputImageManager: OutputImageManager
  private let notificationManager = NotificationManager.self
  private let logger = HeadlinerLogger.logger(for: .appState)
  private let personalInfoPump = PersonalInfoPump()
  let locationPermissionManager = LocationPermissionManager()


  // MARK: - Private Properties

  private var cancellables = Set<AnyCancellable>()
  private let userDefaults = UserDefaults.standard
  private var captureSessionManager: CaptureSessionManager?
  private var devicePollTimer: Timer?
  private var didBecomeActiveObserver: NSObjectProtocol?
  private var locationPermissionObserver: NSObjectProtocol?
  private let devicePollWindow: TimeInterval = 60 // seconds
  private let devicePollInterval: TimeInterval = 0.5

  // MARK: - App Group Keys

  private enum AppGroupKeys {
    static let extensionProviderReady = "ExtensionProviderReady"
    static let selectedCameraID = "SelectedCameraID"
  }

  // MARK: - Constants

  private enum UserDefaultsKeys {}

  // MARK: - Initialization

  /// Create a new `AppState` instance.
  /// - Parameters:
  ///   - systemExtensionManager: Handles install/uninstall and activation of the system extension.
  ///   - propertyManager: Assists with device/extension detection.
  ///   - outputImageManager: Receives preview frames from the local capture session.
  init(
    systemExtensionManager: SystemExtensionRequestManager,
    propertyManager: CustomPropertyManager,
    outputImageManager: OutputImageManager
  ) {
    self.systemExtensionManager = systemExtensionManager
    self.propertyManager = propertyManager
    self.outputImageManager = outputImageManager

    self.logger.debug("Initializing AppState with lazy loading...")

    setupBindings()
    loadUserPreferences()
    
    // Initialize location permission status without starting services
    locationAuthorizationStatus = locationPermissionManager.authorizationStatus

    self.logger.debug("AppState initialization complete (lazy mode)")
  }

  // MARK: Deinitialization

  deinit {
    devicePollTimer?.invalidate()
    personalInfoPump.stop()
    if let token = didBecomeActiveObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(token)
    }
    if let token = locationPermissionObserver {
      NotificationCenter.default.removeObserver(token)
    }
  }

  // MARK: - Public Methods

  /// Initialize app state for first time use - checks extension status and loads cameras
  func initializeForUse() {
    self.logger.debug("Initializing app state for first use...")
    checkExtensionStatus()
    loadAvailableCameras()
    setupCaptureSession()
  }

  /// Begin installation flow for the system extension and start device detection polling.
  func installExtension() {
    extensionStatus = .installing
    statusMessage = "Installing system extension..."
    systemExtensionManager.install()
    // start watching for the device to appear
    waitForExtensionDeviceAppear()
  }

  /// Start the virtual camera and local preview.
  ///
  /// Requests camera permission if needed, propagates settings to the extension,
  /// and starts the local `AVCaptureSession` when ready.
  func startCamera() {
    guard extensionStatus == .installed else {
      self.logger.debug("Cannot start camera - extension not installed")
      return
    }

    // Check camera permission before starting
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch authStatus {
    case .authorized:
      // Permission granted, proceed with starting camera
      proceedWithCameraStart()
    case .notDetermined:
      // Request permission
      self.logger.debug("Requesting camera permission...")
      statusMessage = "Requesting camera permission..."
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            self?.logger.debug("Camera permission granted, retrying capture session setup...")
            // Retry capture session setup with new permissions
            self?.retryCaptureSession()
            self?.proceedWithCameraStart()
          } else {
            self?.cameraStatus = .error("Camera permission denied")
            self?.statusMessage = "Camera access denied - enable in System Settings > Privacy & Security > Camera"
            self?.logger.error("Camera permission denied by user")
          }
        }
      }
    case .denied:
      cameraStatus = .error("Camera permission denied")
      statusMessage = "Camera access denied - enable in System Settings > Privacy & Security > Camera"
      self.logger.error("Camera access denied - user needs to enable in System Settings")
    case .restricted:
      cameraStatus = .error("Camera access restricted")
      statusMessage = "Camera access restricted by system policy"
      self.logger.error("Camera access restricted by system policy")
    @unknown default:
      cameraStatus = .error("Unknown camera permission status")
      statusMessage = "Camera permission issue"
      self.logger.error("Unknown camera authorization status")
    }
  }

  /// Complete startup once permissions are satisfied; idempotent if already running.
  private func proceedWithCameraStart() {
    guard cameraStatus != .running && cameraStatus != .starting else { return }
    self.logger.debug("Starting camera...")
    cameraStatus = .starting
    statusMessage = "Starting camera..."
    notificationManager.postNotification(named: .startStream)

    // Send current overlay settings to extension when camera starts
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: overlaySettings)

    // Start the capture session for preview
    if let manager = captureSessionManager, !manager.captureSession.isRunning {
      manager.captureSession.startRunning()
      self.logger.debug("Started preview capture session")
    }

    // Simulate camera start completion
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.cameraStatus = .running
      self.statusMessage = "Camera is running"
      self.logger.debug("Camera status updated to running")
    }
  }

  /// Stop the virtual camera and local preview.
  func stopCamera() {
    cameraStatus = .stopping
    statusMessage = "Stopping camera..."
    notificationManager.postNotification(named: .stopStream)

    // Stop the capture session for preview
    if let manager = captureSessionManager, manager.captureSession.isRunning {
      manager.captureSession.stopRunning()
      self.logger.debug("Stopped preview capture session")
    }

    // Clear the preview image
    outputImageManager.videoExtensionStreamOutputImage = nil

    // Simulate camera stop completion
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.cameraStatus = .stopped
      self.statusMessage = "Camera stopped"
    }
  }

  /// Persist and apply a newly selected camera.
  /// - Parameter camera: The selected physical camera device.
  func selectCamera(_ camera: CameraDevice) {
    selectedCameraID = camera.id
    userDefaults.set(camera.id, forKey: AppGroupKeys.selectedCameraID)
    statusMessage = "Selected camera: \(camera.name)"

    // Notify extension about camera device change
    if let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
      appGroupDefaults.set(camera.id, forKey: AppGroupKeys.selectedCameraID)
      notificationManager.postNotification(named: .setCameraDevice)
    }

    // Update capture session with new camera
    updateCaptureSessionCamera(deviceID: camera.id)

    // If camera is running, restart with new device
    if cameraStatus == .running {
      stopCamera()
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.startCamera()
      }
    }
  }

  /// Refresh the available camera list and recheck extension status.
  func refreshCameras() {
    loadAvailableCameras()
    // Also refresh extension status when refreshing cameras
    checkExtensionStatus()
  }

  /// Update and persist overlay settings, then notify the extension.
  func updateOverlaySettings(_ newSettings: OverlaySettings) {
    overlaySettings = newSettings
    saveOverlaySettings()

    // Notify extension about overlay settings change with the actual settings data
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: newSettings)
    
    // Trigger SwiftUI rendering if needed
    triggerSwiftUIRenderingIfNeeded()
  }
  
  // MARK: - Preset Management (Reusable by any view)
  
  /// Switch to a different overlay preset
  func selectPreset(_ presetId: String) {
    overlaySettings.selectedPresetId = presetId
    
    // Preserve existing tokens if they exist, especially the tagline
    let existingTokens = overlaySettings.overlayTokens
    
    // If switching to Personal preset and no tokens exist, populate with defaults
    if presetId == "personal" && overlaySettings.overlayTokens == nil {
      overlaySettings.overlayTokens = OverlayTokens(
        displayName: overlaySettings.userName.isEmpty ? NSUserName() : overlaySettings.userName,
        tagline: existingTokens?.tagline,  // Preserve tagline
        accentColorHex: "#34C759"
      )
    } else if overlaySettings.overlayTokens == nil {
      // Initialize tokens for other presets
      overlaySettings.overlayTokens = OverlayTokens(
        displayName: overlaySettings.userName.isEmpty ? NSUserName() : overlaySettings.userName,
        tagline: existingTokens?.tagline ?? (presetId == "professional" ? "Senior Developer" : ""),
        accentColorHex: "#007AFF"
      )
    }
    // Note: If tokens already exist, they are preserved (including tagline)
    
    saveOverlaySettings()
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: overlaySettings)
    
    // Trigger SwiftUI rendering if needed
    triggerSwiftUIRenderingIfNeeded()
  }
  
  /// Update overlay tokens (display name, tagline, colors, etc.)
  func updateOverlayTokens(_ tokens: OverlayTokens) {
    overlaySettings.overlayTokens = tokens
    overlaySettings.userName = tokens.displayName // Keep legacy field in sync
    saveOverlaySettings()
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: overlaySettings)
    
    // Trigger SwiftUI rendering if needed
    triggerSwiftUIRenderingIfNeeded()
  }
  
  /// Switch aspect ratio
  func selectAspectRatio(_ aspect: OverlayAspect) {
    overlaySettings.overlayAspect = aspect
    if overlaySettings.overlayTokens == nil {
      overlaySettings.overlayTokens = OverlayTokens(
        displayName: overlaySettings.userName.isEmpty ? NSUserName() : overlaySettings.userName,
        accentColorHex: "#007AFF"
      )
    }
    saveOverlaySettings()
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: overlaySettings)
    

  }
  
  // MARK: - SwiftUI Overlay Rendering
  
  /// Trigger SwiftUI overlay rendering if the current preset is SwiftUI-based
  private func triggerSwiftUIRenderingIfNeeded() {
    let presetId = self.overlaySettings.selectedPresetId
    
    guard let tokens = self.overlaySettings.overlayTokens else { 
      self.logger.debug("🔍 [SwiftUI] No overlay tokens available for preset '\(presetId)' - skipping SwiftUI rendering")
      return 
    }
    
    self.logger.debug("🔍 [SwiftUI] Triggering SwiftUI rendering for preset '\(presetId)' with tokens: \(tokens.displayName), safeAreaMode: \(self.overlaySettings.safeAreaMode.displayName)")
    
    // Check if this is a SwiftUI preset and get the appropriate provider
    if let provider = swiftUIProvider(for: presetId) {
      self.logger.debug("🎨 [SwiftUI] Rendering SwiftUI overlay with safeAreaMode: \(self.overlaySettings.safeAreaMode.rawValue)")
      Task { @MainActor in
        let renderTokens = RenderTokens(safeAreaMode: self.overlaySettings.safeAreaMode)
        let personalInfo = self.getCurrentPersonalInfo()
        await OverlayRenderBroker.shared.updateOverlay(
          provider: provider,
          tokens: tokens,
          renderTokens: renderTokens,
          personalInfo: personalInfo
        )
      }
    } else {
      self.logger.debug("⚠️ [SwiftUI] No SwiftUI provider found for preset '\(presetId)'")
    }
  }
  
  /// Map preset IDs to SwiftUI view providers
  private func swiftUIProvider(for presetId: String) -> (any OverlayViewProviding)? {
    // Look up the SwiftUI preset in the registry
    return SwiftUIPresetRegistry.preset(withId: presetId)?.provider
  }
  
  /// Get current PersonalInfo from App Group storage
  private func getCurrentPersonalInfo() -> PersonalInfo? {
    guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let data = userDefaults.data(forKey: "overlay.personalInfo.v1"),
          let info = try? JSONDecoder().decode(PersonalInfo.self, from: data) else {
      return nil
    }
    return info
  }
  
  /// Get all available SwiftUI presets (new system)
  var availableSwiftUIPresets: [SwiftUIPresetInfo] {
    return SwiftUIPresetRegistry.allPresets
  }
  
  /// Get current preset ID
  var currentPresetId: String {
    overlaySettings.selectedPresetId.isEmpty ? "professional" : overlaySettings.selectedPresetId
  }
  
  /// Get current aspect ratio
  var currentAspectRatio: OverlayAspect {
    overlaySettings.overlayAspect
  }
  
  /// Start personal info pump for weather and location updates
  func startPersonalInfoPump() {
    self.logger.debug("Starting personal info pump for location and weather data")
    personalInfoPump.start()
  }
  
  /// Stop personal info pump
  func stopPersonalInfoPump() {
    personalInfoPump.stop()
  }
  
  /// Manually refresh personal info immediately
  func refreshPersonalInfoNow() {
    personalInfoPump.refreshNow()
  }
  
  /// Request location permission from the user
  /// This can be called from any UI button or view
  func requestLocationPermission() {
      self.logger.debug("🟢 AppState: requestLocationPermission called")
    self.logger.info("🟢 AppState: requestLocationPermission called")
    self.logger.info("🟢 Current authorization status: \(self.locationPermissionManager.authorizationStatus.rawValue)")
    self.logger.info("🟢 Is main thread: \(Thread.isMainThread)")
    locationPermissionManager.requestLocationPermission()
  }
  
  /// Get current location permission status
  var locationPermissionStatus: CLAuthorizationStatus {
    locationAuthorizationStatus
  }
  
  /// Check if location is available
  var isLocationAvailable: Bool {
    locationPermissionManager.isLocationAvailable
  }
  
  /// Check if camera permission is granted
  var hasCameraPermission: Bool {
    AVCaptureDevice.authorizationStatus(for: .video) == .authorized
  }
  
  /// Check if we need any permissions for basic functionality
  var needsPermissions: Bool {
    !hasCameraPermission
  }
  
  /// Open system settings for location permission
  func openLocationSettings() {
    locationPermissionManager.openSystemSettings()
  }
  


  /// Persist `overlaySettings` to the shared app group so the extension can load them.
  private func saveOverlaySettings() {
    // Save to app group defaults for extension access
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) else {
      self.logger.error("Failed to access app group UserDefaults for saving overlay settings")
      return
    }

    do {
      let overlayData = try JSONEncoder().encode(self.overlaySettings)
      appGroupDefaults.set(overlayData, forKey: OverlayUserDefaultsKeys.overlaySettings)
      appGroupDefaults.synchronize() // Force immediate sync

      logger
        .debug(
          "✅ Saved overlay settings: enabled=\(self.overlaySettings.isEnabled), userName='\(self.overlaySettings.userName)', position=\(self.overlaySettings.namePosition.rawValue), fontSize=\(self.overlaySettings.fontSize)"
        )

      // Verify the save worked by reading it back
      if let savedData = appGroupDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
         let verificationSettings = try? JSONDecoder().decode(OverlaySettings.self, from: savedData) {
        logger
          .debug(
            "✅ Verified saved settings: userName='\(verificationSettings.userName)', position=\(verificationSettings.namePosition.rawValue)"
          )
      } else {
        self.logger.error("❌ Failed to verify saved overlay settings")
      }

    } catch {
      self.logger.error("Failed to encode overlay settings: \(error)")
    }
  }

  // MARK: - Private Methods

  /// Wire up Combine bindings and app lifecycle observers.
  private func setupBindings() {
    systemExtensionManager.$logText
      .receive(on: DispatchQueue.main)
      .sink { [weak self] logText in
        Task { @MainActor in
          self?.updateExtensionStatus(from: logText)
        }
      }
      .store(in: &cancellables)

    systemExtensionManager.$phase
      .receive(on: DispatchQueue.main)
      .sink { [weak self] phase in
        Task { @MainActor in
          guard let self else { return }
          switch phase {
          case .needsApproval:
            self.extensionStatus = .installing
            self.statusMessage = "Approve the extension in System Settings…"
          case .installed:
            self.extensionStatus = .installed
            self.statusMessage = "Extension installed. Finalizing…"
            self.waitForExtensionDeviceAppear()
          default:
            break
          }
        }
      }
      .store(in: &cancellables)

    // Recheck when app comes to foreground (user just approved in Settings)
    didBecomeActiveObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        self.checkExtensionStatus()
        if self.extensionStatus != .installed {
          self.waitForExtensionDeviceAppear()
        }
      }
    }
    
    // Listen for location permission granted
    locationPermissionObserver = NotificationCenter.default.addObserver(
      forName: .locationPermissionGranted,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      // Start personal info services and refresh when location permission is granted
      Task { @MainActor in
        self?.startPersonalInfoPump()
        self?.refreshPersonalInfoNow()
        self?.logger.debug("Location permission granted - starting personal info services")
      }
    }
    
    // Sync location permission status
    locationPermissionManager.$authorizationStatus
      .receive(on: DispatchQueue.main)
      .sink { [weak self] status in
        self?.locationAuthorizationStatus = status
      }
      .store(in: &cancellables)
      
    // Note: PersonalInfoPump doesn't have $lastUpdate property
    // Overlay regeneration will happen when settings change instead
  }

  /// Load persisted selections (camera ID, overlays) into memory.
  private func loadUserPreferences() {
    selectedCameraID = userDefaults.string(forKey: AppGroupKeys.selectedCameraID) ?? ""
    loadOverlaySettings()
  }

  /// Load overlay settings from the shared app group, or set sensible defaults.
  private func loadOverlaySettings() {
    // Load from app group defaults for extension access
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) else {
      self.logger.debug("Failed to access app group UserDefaults for overlay settings")
      return
    }

    if let overlayData = appGroupDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
       let decodedSettings = try? JSONDecoder().decode(OverlaySettings.self, from: overlayData) {
      self.overlaySettings = decodedSettings
      self.logger.debug("Loaded overlay settings: enabled=\(self.overlaySettings.isEnabled)")
    } else {
      // Set default name from system if available
      self.overlaySettings.userName = NSUserName()
      self.logger.debug("Using default overlay settings with user name: \(self.overlaySettings.userName)")
    }
  }

  /// Inspect extension readiness via a fast readiness flag, then fall back to device scan.
  private func checkExtensionStatus() {
    self.logger.debug("Checking extension status...")

    // Prefer fast readiness check to avoid noisy device scans
    let providerReady = UserDefaults(suiteName: Identifiers.appGroup)?
      .bool(forKey: "ExtensionProviderReady") ?? false
    if providerReady {
      self.logger.debug("Extension detected via provider readiness - setting status to installed")
      extensionStatus = .installed
      statusMessage = "Extension is installed and ready"
      self.logger.debug("Final extension status: \(String(describing: self.extensionStatus))")
      return
    }

    // Fallback to device scan when provider readiness hasn't been set yet
    propertyManager.refreshExtensionStatus()
    if propertyManager.deviceObjectID != nil {
      self.logger.debug("Extension detected - setting status to installed")
      extensionStatus = .installed
      statusMessage = "Extension is installed and ready"
    } else {
      self.logger.debug("Extension not detected - setting status to not installed")
      extensionStatus = .notInstalled
      statusMessage = "Extension needs to be installed"
    }

    self.logger.debug("Final extension status: \(String(describing: self.extensionStatus))")
  }

  /// Discover all physical cameras (excluding the Headliner virtual camera) for selection.
  private func loadAvailableCameras() {
    // Check if we have camera permissions before attempting to discover devices
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    
    guard authStatus == .authorized else {
      self.logger.debug("Camera permission not granted (\(authStatus.rawValue)), skipping camera discovery")
      availableCameras = []
      return
    }
    
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera],
      mediaType: .video,
      position: .unspecified
    )

    availableCameras = discoverySession.devices
      .filter { !$0.localizedName.contains("Headliner") } // Exclude our virtual camera
      .map { device in
        CameraDevice(
          id: device.uniqueID,
          name: device.localizedName,
          deviceType: device.deviceType.displayName
        )
      }

    // Set default selection if none exists
    if selectedCameraID.isEmpty, !availableCameras.isEmpty {
      selectedCameraID = availableCameras.first?.id ?? ""
      // Update the capture session with the default camera
      if let firstCamera = availableCameras.first {
        updateCaptureSessionCamera(deviceID: firstCamera.id)
      }
    }
  }

  /// Configure the local preview capture session and start it if possible.
  private func setupCaptureSession() {
    // Check camera permissions before attempting to set up capture session
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    
    guard authStatus == .authorized else {
      self.logger.debug("Camera permission not granted (\(authStatus.rawValue)), skipping capture session setup")
      captureSessionManager = nil
      return
    }
    
    self.logger.debug("Setting up capture session for camera preview...")
    captureSessionManager = CaptureSessionManager(capturingHeadliner: false)

    if let manager = captureSessionManager, manager.configured {
      self.logger.debug("Capture session configured successfully")

      // Set the output image manager as the video output delegate
      manager.videoOutput?.setSampleBufferDelegate(
        outputImageManager,
        queue: manager.dataOutputQueue
      )

      // Start the capture session for preview only if we have cameras available
      if !manager.captureSession.isRunning && !availableCameras.isEmpty {
        manager.captureSession.startRunning()
        self.logger.debug("Started preview capture session")
      }
    } else {
      self.logger.warning("Failed to configure capture session - likely due to no camera found")
      statusMessage = "No suitable camera found for preview"
    }
  }

  /// Request camera permission explicitly
  func requestCameraPermission() async -> Bool {
    return await withCheckedContinuation { continuation in
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          if granted {
            self.logger.debug("Camera permission granted")
            // Reload cameras and setup capture session now that we have permission
            self.loadAvailableCameras()
            self.setupCaptureSession()
          } else {
            self.logger.error("Camera permission denied")
          }
          continuation.resume(returning: granted)
        }
      }
    }
  }
  
  /// Retry capture session configuration after permissions change.
  func retryCaptureSession() {
    self.logger.debug("Retrying capture session setup...")
    loadAvailableCameras()
    setupCaptureSession()
  }

  /// Reconfigure the local preview capture input for a newly selected camera.
  private func updateCaptureSessionCamera(deviceID: String) {
    guard let manager = captureSessionManager else { return }

    // Find the camera device by ID
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera],
      mediaType: .video,
      position: .unspecified
    )

    guard let device = discoverySession.devices.first(where: { $0.uniqueID == deviceID }) else {
      self.logger.error("Camera device with ID \(deviceID) not found")
      return
    }

    // Update the capture session with the new camera
    manager.captureSession.beginConfiguration()

    // Remove current inputs
    for input in manager.captureSession.inputs {
      if let v = input as? AVCaptureDeviceInput, v.device.hasMediaType(.video) {
        manager.captureSession.removeInput(v)
      }
    }

    // Add new input
    do {
      let newInput = try AVCaptureDeviceInput(device: device)
      if manager.captureSession.canAddInput(newInput) {
        manager.captureSession.addInput(newInput)
        self.logger.debug("Updated preview capture session with camera: \(device.localizedName)")
      }
    } catch {
      self.logger.error("Failed to create camera input for preview: \(error)")
    }

    manager.captureSession.commitConfiguration()
  }

  /// Update extension status heuristically from installer log messages.
  private func updateExtensionStatus(from logText: String) {
    statusMessage = logText

    if logText.contains("success") {
      extensionStatus = .installed
      // Refresh property manager to detect newly installed extension
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.checkExtensionStatus()
      }
    } else if logText.contains("fail") || logText.contains("error") {
      extensionStatus = .notInstalled
    }
  }

  /// Poll for extension device readiness with a time-bounded timer.
  private func waitForExtensionDeviceAppear() {
    devicePollTimer?.invalidate()

    let deadline = Date().addingTimeInterval(devicePollWindow)

    // ensure timer is created on the main run loop
    let t = Timer(timeInterval: devicePollInterval, repeats: true) { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }

        // Prefer provider readiness to avoid noisy device scans once the extension has signaled readiness
        let providerReady = UserDefaults(suiteName: Identifiers.appGroup)?
          .bool(forKey: AppGroupKeys.extensionProviderReady) ?? false
        if providerReady {
          self.devicePollTimer?.invalidate()
          self.extensionStatus = .installed
          self.statusMessage = "Extension installed and ready"
          self.logger.debug("✅ Virtual camera detected after activation")
          return
        }

        // Only scan devices if provider readiness hasn't been signaled yet
        self.propertyManager.refreshExtensionStatus()
        if self.propertyManager.deviceObjectID != nil {
          self.devicePollTimer?.invalidate()
          self.extensionStatus = .installed
          self.statusMessage = "Extension installed and ready"
          self.logger.debug("✅ Virtual camera detected after activation")
        } else if Date() > deadline {
          self.devicePollTimer?.invalidate()
          self.logger.debug("⌛ Timed out waiting for device; user may still be approving or camera is in-use")
        }
      }
    }

    // keep firing while UI is interacting (scroll/menus)
    devicePollTimer = t
    t.tolerance = 0.1
    RunLoop.main.add(t, forMode: .common)
  }
}

// MARK: - Supporting Types

enum ExtensionStatus: Equatable {
  case unknown
  case notInstalled
  case installing
  case installed
  case error(String)

  var displayText: String {
    switch self {
    case .unknown: "Checking..."
    case .notInstalled: "Not Installed"
    case .installing: "Installing..."
    case .installed: "Installed"
    case let .error(message): "Error: \(message)"
    }
  }

  var isInstalled: Bool {
    if case .installed = self { return true }
    return false
  }
}

enum CameraStatus: Equatable {
  case stopped
  case starting
  case running
  case stopping
  case error(String)

  var displayText: String {
    switch self {
    case .stopped: "Stopped"
    case .starting: "Starting..."
    case .running: "Running"
    case .stopping: "Stopping..."
    case let .error(message): "Error: \(message)"
    }
  }

  var isRunning: Bool {
    if case .running = self { return true }
    return false
  }
}

struct CameraDevice: Identifiable, Equatable {
  let id: String
  let name: String
  let deviceType: String
}

// MARK: - AVCaptureDevice Extension

extension AVCaptureDevice.DeviceType {
  var displayName: String {
    switch self {
    case .builtInWideAngleCamera: "Built-in Camera"
    case .external: "External Camera"
    case .continuityCamera: "iPhone Camera"
    case .deskViewCamera: "Desk View Camera"
    default: "Camera"
    }
  }
}
