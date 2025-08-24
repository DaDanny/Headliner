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
final class CameraService: NSObject, ObservableObject {
  // MARK: - Published Properties
  
  @Published private(set) var availableCameras: [CameraDevice] = []
  @Published private(set) var selectedCamera: CameraDevice?
  @Published private(set) var cameraStatus: CameraStatus = .stopped
  @Published private(set) var statusMessage: String = ""
  
  // MARK: - Dependencies
  
  // NOTE: Removed CaptureSessionManager - main app no longer captures directly
  // Extension owns camera exclusively, app shows self-preview from virtual camera
  private var selfPreviewCaptureSession: AVCaptureSession?
  private var selfPreviewOutput: AVCaptureVideoDataOutput?
  private let selfPreviewQueue = DispatchQueue(label: "com.headliner.selfpreview", qos: .userInitiated)
  private let notificationManager = NotificationManager.self
  private let logger = HeadlinerLogger.logger(for: .captureSession)
  
  // Direct frame handling (replaces OutputImageManager)
  @Published private(set) var currentPreviewFrame: CGImage?
  
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
  
  override init() {
    super.init()
    loadSavedCameraSelection()
    // No longer setup capture session immediately - lazy initialization
  }
  
  // MARK: - Public Methods
  
  func startCamera() async throws {
    guard hasCameraPermission else {
      throw AppStateError.cameraPermissionDenied
    }
    
    guard cameraStatus != .running && cameraStatus != .starting else { return }
    
    logger.debug("Starting camera and self-preview...")
    cameraStatus = .starting
    statusMessage = "Starting camera..."
    
    // Notify extension to start capturing from physical camera
    notificationManager.postNotification(named: .startStream)
    
    // Start self-preview from virtual camera (shows exactly what Google Meet sees)
    setupSelfPreviewFromVirtualCamera()
    
    // Wait for extension to start and virtual camera to be available
    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds for extension startup
    cameraStatus = .running
    statusMessage = "Camera is running"
    logger.debug("Camera and self-preview started")
  }
  
  func stopCamera() {
    guard cameraStatus == .running else { return }
    
    cameraStatus = .stopping
    statusMessage = "Stopping camera..."
    
    // Stop extension camera capture
    notificationManager.postNotification(named: .stopStream)
    
    // Stop self-preview capture session
    selfPreviewCaptureSession?.stopRunning()
    logger.debug("Stopped self-preview capture session")
    
    // Clear current frame
    currentPreviewFrame = nil
    
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
    
    // Save selection to both local and app group UserDefaults
    userDefaults.set(camera.id, forKey: Keys.selectedCameraID)
    if let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
      appGroupDefaults.set(camera.id, forKey: Keys.selectedCameraID)
      logger.debug("Saved camera selection to app group: \(camera.name)")
      
      // Notify extension of camera device change
      notificationManager.postNotification(named: .setCameraDevice)
    }
    
    statusMessage = "Selected camera: \(camera.name)"
    
    // Log performance
    if let startTime = switchStartTime {
      let duration = Date().timeIntervalSince(startTime)
      logger.debug("📊 Camera switch completed in \(String(format: "%.2f", duration))s")
    }
    
    // Restart camera if currently running to apply device change
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
            // No longer setup main app capture session - extension handles camera exclusively
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
      // No longer update capture session - main app doesn't capture directly
    }
  }
  
  // Self-preview setup: captures from virtual camera to show user exactly what Google Meet sees
  private func setupSelfPreviewFromVirtualCamera() {
    guard hasCameraPermission else {
      logger.debug("No camera permission, skipping self-preview setup")
      return
    }
    
    // Find "Headliner" virtual camera device
    let virtualCamera = discoverySession.devices.first { device in
      device.localizedName.contains("Headliner")
    }
    
    guard let virtualCamera = virtualCamera else {
      logger.debug("Headliner virtual camera not found - extension may not be running")
      return
    }
    
    logger.debug("Found Headliner virtual camera: \(virtualCamera.localizedName)")
    
    // Setup capture session for self-preview
    selfPreviewCaptureSession = AVCaptureSession()
    
    do {
      let input = try AVCaptureDeviceInput(device: virtualCamera)
      if selfPreviewCaptureSession?.canAddInput(input) == true {
        selfPreviewCaptureSession?.addInput(input)
      }
      
      selfPreviewOutput = AVCaptureVideoDataOutput()
      selfPreviewOutput?.setSampleBufferDelegate(self, queue: selfPreviewQueue)
      
      if selfPreviewCaptureSession?.canAddOutput(selfPreviewOutput!) == true {
        selfPreviewCaptureSession?.addOutput(selfPreviewOutput!)
      }
      
      selfPreviewCaptureSession?.startRunning()
      logger.debug("Self-preview capture session started from virtual camera")
      
    } catch {
      logger.error("Failed to setup self-preview: \(error)")
      selfPreviewCaptureSession = nil
      selfPreviewOutput = nil
    }
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

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    autoreleasepool {
      guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        logger.debug("Couldn't get image buffer from self-preview")
        return
      }
      
      guard let ioSurface = CVPixelBufferGetIOSurface(cvImageBuffer) else {
        logger.debug("Self-preview pixel buffer had no IOSurface")
        return
      }
      
      let ciImage = CIImage(ioSurface: ioSurface.takeUnretainedValue())
        .oriented(.upMirrored) // Match main app mirroring
      
      let context = CIContext(options: nil)
      
      guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        logger.debug("Failed to create CGImage from self-preview CIImage")
        return
      }
      
      // Update preview frame on main thread
      DispatchQueue.main.async {
        self.currentPreviewFrame = cgImage
      }
    }
  }
}

// MARK: - CameraServiceProtocol Conformance

extension CameraService: @preconcurrency CameraServiceProtocol {}