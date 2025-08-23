//
//  CameraService.swift
//  Headliner
//
//  Manages all camera-related functionality with clean separation of concerns
//

import AVFoundation
import Combine
import SwiftUI

// MARK: - Protocol

protocol CameraServiceProtocol: ObservableObject {
  var availableCameras: [CameraDevice] { get }
  var selectedCamera: CameraDevice? { get }
  var cameraStatus: CameraStatus { get }
  var statusMessage: String { get }
  
  func startCamera() async throws
  func stopCamera()
  func selectCamera(_ camera: CameraDevice) async
  func refreshCameras()
  func requestPermission() async -> Bool
}

// MARK: - Implementation

@MainActor
final class CameraService: ObservableObject {
  // MARK: - Published Properties
  
  @Published private(set) var availableCameras: [CameraDevice] = []
  @Published private(set) var selectedCamera: CameraDevice?
  @Published private(set) var cameraStatus: CameraStatus = .stopped
  @Published private(set) var statusMessage: String = ""
  
  // MARK: - Dependencies
  
  private let captureSessionManager: CaptureSessionManager
  private let outputImageManager: OutputImageManager
  private let notificationManager = NotificationManager.self
  private let logger = HeadlinerLogger.logger(for: .captureSession)
  
  // MARK: - Private Properties
  
  private let userDefaults = UserDefaults.standard
  private var switchStartTime: Date?
  
  // Performance optimization: Lazy discovery session
  private lazy var discoverySession = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera],
    mediaType: .video,
    position: .unspecified
  )
  
  // MARK: - Constants
  
  private enum Keys {
    static let selectedCameraID = "SelectedCameraID"
  }
  
  // MARK: - Initialization
  
  init(captureSessionManager: CaptureSessionManager,
       outputImageManager: OutputImageManager) {
    self.captureSessionManager = captureSessionManager
    self.outputImageManager = outputImageManager
    
    loadSavedCameraSelection()
    setupCaptureSession()
  }
  
  // MARK: - Public Methods
  
  func startCamera() async throws {
    guard hasCameraPermission else {
      throw AppStateError.cameraPermissionDenied
    }
    
    guard cameraStatus != .running && cameraStatus != .starting else { return }
    
    logger.debug("Starting camera...")
    cameraStatus = .starting
    statusMessage = "Starting camera..."
    
    // Notify extension
    notificationManager.postNotification(named: .startStream)
    
    // Start capture session
    if !captureSessionManager.captureSession.isRunning {
      captureSessionManager.captureSession.startRunning()
      logger.debug("Started preview capture session")
    }
    
    // Update status after brief delay
    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    cameraStatus = .running
    statusMessage = "Camera is running"
    logger.debug("Camera status updated to running")
  }
  
  func stopCamera() {
    guard cameraStatus == .running else { return }
    
    cameraStatus = .stopping
    statusMessage = "Stopping camera..."
    
    notificationManager.postNotification(named: .stopStream)
    
    if captureSessionManager.captureSession.isRunning {
      captureSessionManager.captureSession.stopRunning()
      logger.debug("Stopped preview capture session")
    }
    
    outputImageManager.videoExtensionStreamOutputImage = nil
    
    Task {
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      await MainActor.run {
        cameraStatus = .stopped
        statusMessage = "Camera stopped"
      }
    }
  }
  
  func selectCamera(_ camera: CameraDevice) async {
    switchStartTime = Date()
    selectedCamera = camera
    
    // Save selection
    userDefaults.set(camera.id, forKey: Keys.selectedCameraID)
    if let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
      appGroupDefaults.set(camera.id, forKey: Keys.selectedCameraID)
      notificationManager.postNotification(named: .setCameraDevice)
    }
    
    statusMessage = "Selected camera: \(camera.name)"
    
    // Update capture session
    updateCaptureSession(with: camera.id)
    
    // Log performance
    if let startTime = switchStartTime {
      let duration = Date().timeIntervalSince(startTime)
      logger.debug("📊 Camera switch completed in \(String(format: "%.2f", duration))s")
    }
    
    // Restart if running
    if cameraStatus == .running {
      stopCamera()
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      try? await startCamera()
    }
  }
  
  func refreshCameras() {
    loadAvailableCameras()
  }
  
  func requestPermission() async -> Bool {
    await withCheckedContinuation { continuation in
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        Task { @MainActor in
          if granted {
            self?.logger.debug("Camera permission granted")
            self?.loadAvailableCameras()
            self?.setupCaptureSession()
          } else {
            self?.logger.error("Camera permission denied")
            self?.cameraStatus = .error(.cameraPermissionDenied)
          }
          continuation.resume(returning: granted)
        }
      }
    }
  }
  
  // MARK: - Private Methods
  
  private func loadAvailableCameras() {
    guard hasCameraPermission else {
      logger.debug("No camera permission, skipping discovery")
      availableCameras = []
      return
    }
    
    availableCameras = discoverySession.devices
      .filter { !$0.localizedName.contains("Headliner") }
      .map { device in
        CameraDevice(
          id: device.uniqueID,
          name: device.localizedName,
          deviceType: device.deviceType.displayName
        )
      }
    
    // Set default if needed
    if selectedCamera == nil, let first = availableCameras.first {
      selectedCamera = first
      updateCaptureSession(with: first.id)
    }
  }
  
  private func setupCaptureSession() {
    guard hasCameraPermission else {
      logger.debug("No camera permission, skipping setup")
      return
    }
    
    guard captureSessionManager.configured else {
      logger.warning("Failed to configure capture session")
      statusMessage = "No suitable camera found for preview"
      return
    }
    
    captureSessionManager.videoOutput?.setSampleBufferDelegate(
      outputImageManager,
      queue: captureSessionManager.dataOutputQueue
    )
    
    logger.debug("Capture session ready for use")
  }
  
  private func updateCaptureSession(with deviceID: String) {
    guard let device = discoverySession.devices.first(where: { $0.uniqueID == deviceID }) else {
      logger.error("Camera device not found: \(deviceID)")
      statusMessage = "Camera not found"
      return
    }
    
    captureSessionManager.captureSession.beginConfiguration()
    
    // Remove existing inputs
    captureSessionManager.captureSession.inputs
      .compactMap { $0 as? AVCaptureDeviceInput }
      .filter { $0.device.hasMediaType(.video) }
      .forEach { captureSessionManager.captureSession.removeInput($0) }
    
    // Add new input
    do {
      let input = try AVCaptureDeviceInput(device: device)
      if captureSessionManager.captureSession.canAddInput(input) {
        captureSessionManager.captureSession.addInput(input)
        logger.debug("Updated capture session with: \(device.localizedName)")
      }
    } catch {
      logger.error("Failed to create camera input: \(error)")
    }
    
    captureSessionManager.captureSession.commitConfiguration()
  }
  
  private func loadSavedCameraSelection() {
    if let savedID = userDefaults.string(forKey: Keys.selectedCameraID),
       !savedID.isEmpty {
      // Will be matched when cameras load
      logger.debug("Loaded saved camera selection: \(savedID)")
    }
  }
  
  // MARK: - Computed Properties
  
  var hasCameraPermission: Bool {
    AVCaptureDevice.authorizationStatus(for: .video) == .authorized
  }
  
  var needsCameraPermission: Bool {
    AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
  }
}

// MARK: - CameraServiceProtocol Conformance

extension CameraService: CameraServiceProtocol {}