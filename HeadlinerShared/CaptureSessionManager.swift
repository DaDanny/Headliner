import AVFoundation
import OSLog

final class CaptureSessionManager: NSObject {
  enum Camera: String {
    case anyCamera = "any"
    case headliner = "Headliner"
  }
  
  // Phase 3.2: Enhanced error handling
  enum CaptureError: Error, LocalizedError {
    case permissionDenied
    case deviceNotFound(String)
    case deviceBusy
    case presetNotSupported
    case inputCreationFailed(Error)
    case outputCreationFailed
    
    var errorDescription: String? {
      switch self {
      case .permissionDenied:
        return "Camera permission denied"
      case .deviceNotFound(let deviceID):
        return "Camera device not found: \(deviceID)"
      case .deviceBusy:
        return "Camera device is busy"
      case .presetNotSupported:
        return "No supported HD formats available"
      case .inputCreationFailed(let error):
        return "Failed to create camera input: \(error.localizedDescription)"
      case .outputCreationFailed:
        return "Failed to create video output"
      }
    }
  }

  let logger = HeadlinerLogger.logger(for: .captureSession)

  var configured: Bool = false
  var captureHeadliner = false
  var captureSession: AVCaptureSession = .init()
  var videoOutput: AVCaptureVideoDataOutput?
  
  // Phase 3.2: Serialized permission handling
  private let permissionQueue = DispatchQueue(label: "com.headliner.permissions", qos: .userInitiated)
  private var permissionRequestInProgress = false
  
  // Phase 3.2: Performance optimization - shared discovery session
  private lazy var discoverySession = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInWideAngleCamera, .deskViewCamera, .external, .continuityCamera],
    mediaType: .video,
    position: .unspecified
  )

  let dataOutputQueue = DispatchQueue(
    label: "video_queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: .workItem
  )

  init(capturingHeadliner: Bool) {
    super.init()
    captureHeadliner = capturingHeadliner
    configured = configureCaptureSession()
  }

  private let sessionPreset = AVCaptureSession.Preset.hd1920x1080

  func configureCaptureSession() -> Bool {
    do {
      try validatePermissions()
      return try performSessionConfiguration()
    } catch {
      logger.error("Session configuration failed: \(error.localizedDescription)")
      return false
    }
  }
  
  // Phase 3.2: Serialized permission validation
  private func validatePermissions() throws {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      return
    case .notDetermined:
      // Serialize permission requests to avoid race conditions
      guard !permissionRequestInProgress else {
        throw CaptureError.permissionDenied
      }
      
      permissionRequestInProgress = true
      let semaphore = DispatchSemaphore(value: 0)
      var granted = false
      
      AVCaptureDevice.requestAccess(for: .video) { result in
        granted = result
        semaphore.signal()
      }
      
      semaphore.wait()
      permissionRequestInProgress = false
      
      if !granted {
        throw CaptureError.permissionDenied
      }
    case .denied, .restricted:
      throw CaptureError.permissionDenied
    @unknown default:
      throw CaptureError.permissionDenied
    }
  }

  // Phase 3.2: Comprehensive session configuration with error recovery
  private func performSessionConfiguration() throws -> Bool {
    captureSession.beginConfiguration()
    defer { captureSession.commitConfiguration() }
    
    // Clean slate: remove existing inputs/outputs
    captureSession.inputs.forEach { captureSession.removeInput($0) }
    captureSession.outputs.forEach { captureSession.removeOutput($0) }
    
    // Set session preset with fallback handling
    try configureSessionPreset()
    
    // Get and configure camera device
    let camera = try getCameraDevice()
    let input = try createCameraInput(from: camera)
    
    guard captureSession.canAddInput(input) else {
      throw CaptureError.inputCreationFailed(NSError(domain: "CaptureSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot add input to session"]))
    }
    captureSession.addInput(input)
    
    // Configure video output
    let videoOut = createVideoOutput()
    guard captureSession.canAddOutput(videoOut) else {
      throw CaptureError.outputCreationFailed
    }
    captureSession.addOutput(videoOut)
    videoOutput = videoOut
    
    logger.debug("✅ Session configured successfully with device: \(camera.localizedName)")
    return true
  }
  
  // Phase 3.2: Enhanced session preset configuration
  private func configureSessionPreset() throws {
    captureSession.sessionPreset = sessionPreset
  }
  
  // Phase 3.2: Enhanced device selection with better error handling
  private func getCameraDevice() throws -> AVCaptureDevice {
    if captureHeadliner {
      // For main app self-preview: find Headliner virtual camera
      return try getCameraIfAvailable(camera: .headliner)
    } else {
      // For extension: use UserDefaults-selected device with fallback
      if let selectedDevice = getSelectedCameraFromUserDefaults() {
        return selectedDevice
      }
      // Fallback to first available non-Headliner camera
      return try getCameraIfAvailable(camera: .anyCamera)
    }
  }
  
  // Phase 3.2: Enhanced input creation with preset validation
  private func createCameraInput(from camera: AVCaptureDevice) throws -> AVCaptureDeviceInput {
    do {
      let input = try AVCaptureDeviceInput(device: camera)
      
      // Validate and adjust session preset based on device capabilities
      let fallbackPreset = AVCaptureSession.Preset.high
      let supportsStandardPreset = camera.supportsSessionPreset(sessionPreset)
      
      if !supportsStandardPreset {
        let supportsFallbackPreset = camera.supportsSessionPreset(fallbackPreset)
        if supportsFallbackPreset {
          captureSession.sessionPreset = fallbackPreset
          logger.debug("⚠️ Using fallback preset 'high' for device: \(camera.localizedName)")
        } else {
          throw CaptureError.presetNotSupported
        }
      }
      
      return input
    } catch {
      // Check if device is busy (common issue)
      if (error as NSError).code == -11852 {
        throw CaptureError.deviceBusy
      }
      throw CaptureError.inputCreationFailed(error)
    }
  }
  
  // Phase 3.2: Optimized video output creation
  private func createVideoOutput() -> AVCaptureVideoDataOutput {
    let videoOut = AVCaptureVideoDataOutput()
    videoOut.alwaysDiscardsLateVideoFrames = true
    videoOut.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    return videoOut
  }

  // Phase 3.2: Enhanced device selection with better logging
  private func getSelectedCameraFromUserDefaults() -> AVCaptureDevice? {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let selectedDeviceID = sharedDefaults.string(forKey: ExtensionStatusKeys.selectedDeviceID) else {
      logger.debug("No camera device selected in UserDefaults - will use fallback")
      return nil
    }
    
    // Find device by stable uniqueID, not localized name
    let selectedDevice = discoverySession.devices.first { $0.uniqueID == selectedDeviceID }
    
    if let device = selectedDevice {
      logger.debug("✅ Found selected camera device: \(device.localizedName) (ID: \(selectedDeviceID))")
      return device
    } else {
      logger.error("❌ Selected camera device not found: \(selectedDeviceID) - available devices:")
      for device in discoverySession.devices {
        logger.debug("  - \(device.localizedName) (ID: \(device.uniqueID))")
      }
      return nil
    }
  }

  // Phase 3.2: Enhanced device discovery with better error reporting
  private func getCameraIfAvailable(camera: Camera) throws -> AVCaptureDevice {
    for device in discoverySession.devices {
      switch camera {
      case .anyCamera:
        if !device.localizedName.contains("Headliner") { 
          logger.debug("✅ Found fallback camera device: \(device.localizedName)")
          return device 
        }
      case .headliner:
        if device.localizedName.contains("Headliner") { 
          logger.debug("✅ Found Headliner virtual camera: \(device.localizedName)")
          return device 
        }
      }
    }

    // Try user preferred camera as last resort for anyCamera
    if camera == .anyCamera, let preferredCamera = AVCaptureDevice.userPreferredCamera {
      logger.debug("✅ Using user preferred camera: \(preferredCamera.localizedName)")
      return preferredCamera
    }
    
    // Enhanced error reporting
    logger.error("❌ No suitable camera device found for type: \(camera.rawValue)")
    logger.debug("Available devices:")
    for device in discoverySession.devices {
      logger.debug("  - \(device.localizedName) (ID: \(device.uniqueID))")
    }
    
    throw CaptureError.deviceNotFound(camera.rawValue)
  }
  
  // MARK: - Phase 3.2: Device Switching Support
  
  /// Reconfigure session with a new camera device (for live device switching)
  func switchToDevice(deviceID: String) -> Bool {
    logger.debug("🔄 Switching to device: \(deviceID)")
    
    guard let targetDevice = discoverySession.devices.first(where: { $0.uniqueID == deviceID }) else {
      logger.error("❌ Target device not found: \(deviceID)")
      return false
    }
    
    let wasRunning = captureSession.isRunning
    if wasRunning {
      captureSession.stopRunning()
    }
    
    // Reconfigure with new device
    let success = configureCaptureSession()
    
    if success && wasRunning {
      captureSession.startRunning()
      logger.debug("✅ Successfully switched to device: \(targetDevice.localizedName)")
    } else if !success {
      logger.error("❌ Failed to switch to device: \(targetDevice.localizedName)")
    }
    
    return success
  }
  
  // MARK: - Phase 3.2: Session Management
  
  /// Safely start the capture session with error recovery
  func startSession() -> Bool {
    guard configured else {
      logger.error("❌ Cannot start unconfigured session")
      return false
    }
    
    guard !captureSession.isRunning else {
      logger.debug("Session already running")
      return true
    }
    
    captureSession.startRunning()
    let success = captureSession.isRunning
    
    if success {
      logger.debug("✅ Capture session started successfully")
    } else {
      logger.error("❌ Failed to start capture session")
    }
    
    return success
  }
  
  /// Safely stop the capture session
  func stopSession() {
    guard captureSession.isRunning else {
      logger.debug("Session already stopped")
      return
    }
    
    captureSession.stopRunning()
    logger.debug("✅ Capture session stopped")
  }
}


