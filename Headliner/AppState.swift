//
//  AppState.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import AVFoundation
import Combine
import SwiftUI
import SystemExtensions

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

  // MARK: - Dependencies

  private let systemExtensionManager: SystemExtensionRequestManager
  private let propertyManager: CustomPropertyManager
  private let outputImageManager: OutputImageManager
  private let notificationManager = NotificationManager.self

  // MARK: - Private Properties

  private var cancellables = Set<AnyCancellable>()
  private let userDefaults = UserDefaults.standard
  private var captureSessionManager: CaptureSessionManager?
  private var devicePollTimer: Timer?
  private var didBecomeActiveObserver: NSObjectProtocol?
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

    logger.debug("Initializing AppState...")

    setupBindings()
    loadUserPreferences()
    checkExtensionStatus()
    loadAvailableCameras()
    setupCaptureSession()

    logger.debug("AppState initialization complete")
  }

  // MARK: Deinitialization

  deinit {
    devicePollTimer?.invalidate()
    if let token = didBecomeActiveObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(token)
    }
  }

  // MARK: - Public Methods

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
      logger.debug("Cannot start camera - extension not installed")
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
      logger.debug("Requesting camera permission...")
      statusMessage = "Requesting camera permission..."
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            logger.debug("Camera permission granted, retrying capture session setup...")
            // Retry capture session setup with new permissions
            self?.retryCaptureSession()
            self?.proceedWithCameraStart()
          } else {
            self?.cameraStatus = .error("Camera permission denied")
            self?.statusMessage = "Camera access denied - enable in System Settings > Privacy & Security > Camera"
            logger.error("Camera permission denied by user")
          }
        }
      }
    case .denied:
      cameraStatus = .error("Camera permission denied")
      statusMessage = "Camera access denied - enable in System Settings > Privacy & Security > Camera"
      logger.error("Camera access denied - user needs to enable in System Settings")
    case .restricted:
      cameraStatus = .error("Camera access restricted")
      statusMessage = "Camera access restricted by system policy"
      logger.error("Camera access restricted by system policy")
    @unknown default:
      cameraStatus = .error("Unknown camera permission status")
      statusMessage = "Camera permission issue"
      logger.error("Unknown camera authorization status")
    }
  }

  /// Complete startup once permissions are satisfied; idempotent if already running.
  private func proceedWithCameraStart() {
    guard cameraStatus != .running && cameraStatus != .starting else { return }
    logger.debug("Starting camera...")
    cameraStatus = .starting
    statusMessage = "Starting camera..."
    notificationManager.postNotification(named: .startStream)

    // Send current overlay settings to extension when camera starts
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: overlaySettings)

    // Start the capture session for preview
    if let manager = captureSessionManager, !manager.captureSession.isRunning {
      manager.captureSession.startRunning()
      logger.debug("Started preview capture session")
    }

    // Simulate camera start completion
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.cameraStatus = .running
      self.statusMessage = "Camera is running"
      logger.debug("Camera status updated to running")
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
      logger.debug("Stopped preview capture session")
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
  }
  
  // MARK: - Preset Management (Reusable by any view)
  
  /// Switch to a different overlay preset
  func selectPreset(_ presetId: String) {
    overlaySettings.selectedPresetId = presetId
    
    // If switching to Personal preset and no tokens exist, populate with defaults
    if presetId == "personal" && overlaySettings.overlayTokens == nil {
      overlaySettings.overlayTokens = OverlayTokens(
        displayName: overlaySettings.userName.isEmpty ? NSUserName() : overlaySettings.userName,
        accentColorHex: "#34C759",
        aspect: overlaySettings.overlayAspect
      )
    } else if overlaySettings.overlayTokens == nil {
      // Initialize tokens for other presets
      overlaySettings.overlayTokens = OverlayTokens(
        displayName: overlaySettings.userName.isEmpty ? NSUserName() : overlaySettings.userName,
        tagline: presetId == "professional" ? "Senior Developer" : nil,
        accentColorHex: "#007AFF",
        aspect: overlaySettings.overlayAspect
      )
    }
    
    saveOverlaySettings()
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: overlaySettings)
  }
  
  /// Update overlay tokens (display name, tagline, colors, etc.)
  func updateOverlayTokens(_ tokens: OverlayTokens) {
    overlaySettings.overlayTokens = tokens
    overlaySettings.userName = tokens.displayName // Keep legacy field in sync
    saveOverlaySettings()
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: overlaySettings)
  }
  
  /// Switch aspect ratio
  func selectAspectRatio(_ aspect: OverlayAspect) {
    overlaySettings.overlayAspect = aspect
    if overlaySettings.overlayTokens != nil {
      overlaySettings.overlayTokens?.aspect = aspect
    } else {
      overlaySettings.overlayTokens = OverlayTokens(
        displayName: overlaySettings.userName.isEmpty ? NSUserName() : overlaySettings.userName,
        accentColorHex: "#007AFF",
        aspect: aspect
      )
    }
    saveOverlaySettings()
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: overlaySettings)
  }
  
  /// Get current preset ID
  var currentPresetId: String {
    overlaySettings.selectedPresetId.isEmpty ? "professional" : overlaySettings.selectedPresetId
  }
  
  /// Get current aspect ratio
  var currentAspectRatio: OverlayAspect {
    overlaySettings.overlayAspect
  }

  /// Persist `overlaySettings` to the shared app group so the extension can load them.
  private func saveOverlaySettings() {
    // Save to app group defaults for extension access
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) else {
      logger.error("Failed to access app group UserDefaults for saving overlay settings")
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
         let verificationSettings = try? JSONDecoder().decode(OverlaySettings.self, from: savedData)
      {
        logger
          .debug(
            "✅ Verified saved settings: userName='\(verificationSettings.userName)', position=\(verificationSettings.namePosition.rawValue)"
          )
      } else {
        logger.error("❌ Failed to verify saved overlay settings")
      }
    } catch {
      logger.error("Failed to encode overlay settings: \(error)")
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
      logger.debug("Failed to access app group UserDefaults for overlay settings")
      return
    }

    if let overlayData = appGroupDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
       let decodedSettings = try? JSONDecoder().decode(OverlaySettings.self, from: overlayData)
    {
      self.overlaySettings = decodedSettings
      logger.debug("Loaded overlay settings: enabled=\(self.overlaySettings.isEnabled)")
    } else {
      // Set default name from system if available
      self.overlaySettings.userName = NSUserName()
      logger.debug("Using default overlay settings with user name: \(self.overlaySettings.userName)")
    }
  }

  /// Inspect extension readiness via a fast readiness flag, then fall back to device scan.
  private func checkExtensionStatus() {
    logger.debug("Checking extension status...")

    // Prefer fast readiness check to avoid noisy device scans
    let providerReady = UserDefaults(suiteName: Identifiers.appGroup)?
      .bool(forKey: "ExtensionProviderReady") ?? false
    if providerReady {
      logger.debug("Extension detected via provider readiness - setting status to installed")
      extensionStatus = .installed
      statusMessage = "Extension is installed and ready"
      logger.debug("Final extension status: \(String(describing: self.extensionStatus))")
      return
    }

    // Fallback to device scan when provider readiness hasn't been set yet
    propertyManager.refreshExtensionStatus()
    if propertyManager.deviceObjectID != nil {
      logger.debug("Extension detected - setting status to installed")
      extensionStatus = .installed
      statusMessage = "Extension is installed and ready"
    } else {
      logger.debug("Extension not detected - setting status to not installed")
      extensionStatus = .notInstalled
      statusMessage = "Extension needs to be installed"
    }

    logger.debug("Final extension status: \(String(describing: self.extensionStatus))")
  }

  /// Discover all physical cameras (excluding the Headliner virtual camera) for selection.
  private func loadAvailableCameras() {
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
    logger.debug("Setting up capture session for camera preview...")
    captureSessionManager = CaptureSessionManager(capturingHeadliner: false)

    if let manager = captureSessionManager, manager.configured {
      logger.debug("Capture session configured successfully")

      // Set the output image manager as the video output delegate
      manager.videoOutput?.setSampleBufferDelegate(
        outputImageManager,
        queue: manager.dataOutputQueue
      )

      // Start the capture session for preview
      if !manager.captureSession.isRunning {
        manager.captureSession.startRunning()
        logger.debug("Started preview capture session")
      }
    } else {
      logger.warning("Failed to configure capture session - likely due to permissions or no camera found")

      // Check authorization status and provide user feedback
      let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
      switch authStatus {
      case .notDetermined:
        statusMessage = "Camera permission needed for preview"
      case .denied:
        statusMessage = "Camera access denied - enable in System Settings > Privacy & Security > Camera"
      case .restricted:
        statusMessage = "Camera access restricted"
      case .authorized:
        statusMessage = "No suitable camera found for preview"
      @unknown default:
        statusMessage = "Camera permission issue"
      }
    }
  }

  /// Retry capture session configuration after permissions change.
  func retryCaptureSession() {
    logger.debug("Retrying capture session setup...")
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
      logger.error("Camera device with ID \(deviceID) not found")
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
        logger.debug("Updated preview capture session with camera: \(device.localizedName)")
      }
    } catch {
      logger.error("Failed to create camera input for preview: \(error)")
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
          logger.debug("✅ Virtual camera detected after activation")
          return
        }

        // Only scan devices if provider readiness hasn't been signaled yet
        self.propertyManager.refreshExtensionStatus()
        if self.propertyManager.deviceObjectID != nil {
          self.devicePollTimer?.invalidate()
          self.extensionStatus = .installed
          self.statusMessage = "Extension installed and ready"
          logger.debug("✅ Virtual camera detected after activation")
        } else if Date() > deadline {
          self.devicePollTimer?.invalidate()
          logger.debug("⌛ Timed out waiting for device; user may still be approving or camera is in-use")
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
