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

/// Main app state manager that coordinates between UI, system extension, and camera management
@MainActor
class AppState: ObservableObject {
  // MARK: - Published Properties

  @Published var extensionStatus: ExtensionStatus = .unknown
  @Published var cameraStatus: CameraStatus = .stopped
  @Published var availableCameras: [CameraDevice] = []
  @Published var selectedCameraID: String = ""
  @Published var statusMessage: String = ""
  @Published var isShowingSettings: Bool = false
  @Published var overlaySettings: OverlaySettings = .init()
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
  private let devicePollWindow: TimeInterval = 60 // seconds
  private let devicePollInterval: TimeInterval = 0.5

  // MARK: - Constants

  private enum UserDefaultsKeys {
    static let selectedCameraID = "SelectedCameraID"
    static let hasCompletedOnboarding = "HasCompletedOnboarding"
    static let overlaySettings = "OverlaySettings"
  }

  // MARK: - Initialization

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
  }

  // MARK: - Public Methods

  func installExtension() {
    extensionStatus = .installing
    statusMessage = "Installing system extension..."
    systemExtensionManager.install()
    // start watching for the device to appear
    waitForExtensionDeviceAppear()
  }

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
            self?.statusMessage = "Camera access denied - enable in System Preferences > Privacy & Security > Camera"
            logger.error("Camera permission denied by user")
          }
        }
      }
    case .denied:
      cameraStatus = .error("Camera permission denied")
      statusMessage = "Camera access denied - enable in System Preferences > Privacy & Security > Camera"
      logger.error("Camera access denied - user needs to enable in System Preferences")
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

  private func proceedWithCameraStart() {
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

  func selectCamera(_ camera: CameraDevice) {
    selectedCameraID = camera.id
    userDefaults.set(camera.id, forKey: UserDefaultsKeys.selectedCameraID)
    statusMessage = "Selected camera: \(camera.name)"

    // Notify extension about camera device change
    if let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup.rawValue) {
      appGroupDefaults.set(camera.id, forKey: "SelectedCameraID")
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

  func refreshCameras() {
    loadAvailableCameras()
    // Also refresh extension status when refreshing cameras
    checkExtensionStatus()
  }

  func updateOverlaySettings(_ newSettings: OverlaySettings) {
    overlaySettings = newSettings
    saveOverlaySettings()

    // Notify extension about overlay settings change with the actual settings data
    notificationManager.postNotification(named: .updateOverlaySettings, overlaySettings: newSettings)
  }

  private func saveOverlaySettings() {
    // Save to app group defaults for extension access
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup.rawValue) else {
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
         let verificationSettings = try? JSONDecoder().decode(OverlaySettings.self, from: savedData) {
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
    NSWorkspace.shared.notificationCenter.addObserver(
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

  private func loadUserPreferences() {
    selectedCameraID = userDefaults.string(forKey: UserDefaultsKeys.selectedCameraID) ?? ""
    loadOverlaySettings()
  }

  private func loadOverlaySettings() {
    // Load from app group defaults for extension access
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup.rawValue) else {
      logger.debug("Failed to access app group UserDefaults for overlay settings")
      return
    }

    if let overlayData = appGroupDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
       let decodedSettings = try? JSONDecoder().decode(OverlaySettings.self, from: overlayData) {
      self.overlaySettings = decodedSettings
      logger.debug("Loaded overlay settings: enabled=\(self.overlaySettings.isEnabled)")
    } else {
      // Set default name from system if available
      self.overlaySettings.userName = NSUserName()
      logger.debug("Using default overlay settings with user name: \(self.overlaySettings.userName)")
    }
  }

  private func checkExtensionStatus() {
    logger.debug("Checking extension status...")

    // Prefer fast readiness check to avoid noisy device scans
    let providerReady = UserDefaults(suiteName: Identifiers.appGroup.rawValue)?
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
        statusMessage = "Camera access denied - enable in System Preferences > Privacy & Security > Camera"
      case .restricted:
        statusMessage = "Camera access restricted"
      case .authorized:
        statusMessage = "No suitable camera found for preview"
      @unknown default:
        statusMessage = "Camera permission issue"
      }
    }
  }

  func retryCaptureSession() {
    logger.debug("Retrying capture session setup...")
    setupCaptureSession()
  }

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
      manager.captureSession.removeInput(input)
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

  private func waitForExtensionDeviceAppear() {
    devicePollTimer?.invalidate()

    let deadline = Date().addingTimeInterval(devicePollWindow)

    // ensure timer is created on the main run loop
    devicePollTimer = Timer.scheduledTimer(withTimeInterval: devicePollInterval, repeats: true) { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }

        // Prefer provider readiness to avoid noisy device scans once the extension has signaled readiness
        let providerReady = UserDefaults(suiteName: Identifiers.appGroup.rawValue)?
          .bool(forKey: "ExtensionProviderReady") ?? false
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
    devicePollTimer?.tolerance = 0.1
    RunLoop.main.add(devicePollTimer!, forMode: .common)
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
