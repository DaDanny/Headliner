import AVFoundation
import OSLog

final class CaptureSessionManager: NSObject {
  enum Camera: String {
    case anyCamera = "any"
    case headliner = "Headliner"
  }

  let logger = HeadlinerLogger.logger(for: .captureSession)

  var configured: Bool = false
  var captureHeadliner = false
  var captureSession: AVCaptureSession = .init()
  var videoOutput: AVCaptureVideoDataOutput?

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
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      break
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
          DispatchQueue.main.async { 
            self.configured = self.configureCaptureSession() 
          }
        } else {
          self.logger.error("Camera permission denied by user")
        }
      }
      return false
    case .denied:
      logger.error("Camera access denied - user needs to enable in System Preferences")
      return false
    case .restricted:
      logger.error("Camera access restricted by system policy")
      return false
    @unknown default:
      logger.error("Unknown camera authorization status")
      return false
    }

    captureSession.beginConfiguration()
    
    // Clear existing inputs/outputs to avoid duplication on reconfigure
    captureSession.inputs.forEach { captureSession.removeInput($0) }
    captureSession.outputs.forEach { captureSession.removeOutput($0) }
    
    captureSession.sessionPreset = sessionPreset

    // Phase 2.3: UserDefaults-based device selection instead of "first available"
    let camera: AVCaptureDevice?
    if captureHeadliner {
      // For main app self-preview: find Headliner virtual camera
      camera = getCameraIfAvailable(camera: .headliner)
    } else {
      // For extension: use UserDefaults-selected device
      camera = getSelectedCameraFromUserDefaults() ?? getCameraIfAvailable(camera: .anyCamera)
    }
    
    guard let camera = camera else {
      logger.error("Can't create camera device, returning")
      captureSession.commitConfiguration()
      return false
    }

    do {
      let fallbackPreset = AVCaptureSession.Preset.high
      let input = try AVCaptureDeviceInput(device: camera)
      let supportStandardPreset = input.device.supportsSessionPreset(sessionPreset)
      if !supportStandardPreset {
        let supportFallbackPreset = input.device.supportsSessionPreset(fallbackPreset)
        if supportFallbackPreset {
          captureSession.sessionPreset = fallbackPreset
        } else {
          logger.error("No HD formats supported")
          captureSession.commitConfiguration()
          return false
        }
      }
      if captureSession.canAddInput(input) {
        captureSession.addInput(input)
      } else {
        logger.error("Can't add video input to capture session")
        captureSession.commitConfiguration()
        return false
      }
    } catch {
      logger.error("Can't create AVCaptureDeviceInput: \(error.localizedDescription)")
      captureSession.commitConfiguration()
      return false
    }

    let videoOut = AVCaptureVideoDataOutput()
    videoOut.alwaysDiscardsLateVideoFrames = true
    videoOut.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    
    if captureSession.canAddOutput(videoOut) {
      captureSession.addOutput(videoOut)
      videoOutput = videoOut
      captureSession.commitConfiguration()
      return true
    } else {
      logger.error("Can't add video output to capture session")
    }

    captureSession.commitConfiguration()
    return false
  }

  // Phase 2.3: UserDefaults-based device selection
  private func getSelectedCameraFromUserDefaults() -> AVCaptureDevice? {
    guard let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let selectedDeviceID = sharedDefaults.string(forKey: ExtensionStatusKeys.selectedDeviceID) else {
      logger.debug("No camera device selected in UserDefaults")
      return nil
    }
    
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .deskViewCamera, .external, .continuityCamera],
      mediaType: .video,
      position: .unspecified
    )
    
    // Find device by stable uniqueID, not localized name
    let selectedDevice = discoverySession.devices.first { $0.uniqueID == selectedDeviceID }
    
    if let device = selectedDevice {
      logger.debug("Found selected camera device: \(device.localizedName) (ID: \(selectedDeviceID))")
      return device
    } else {
      logger.error("Selected camera device not found: \(selectedDeviceID)")
      return nil
    }
  }

  private func getCameraIfAvailable(camera: Camera) -> AVCaptureDevice? {
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .deskViewCamera, .external, .continuityCamera],
      mediaType: .video,
      position: .unspecified
    )

    for device in discoverySession.devices {
      switch camera {
      case .anyCamera:
        if !device.localizedName.contains("Headliner") { return device }
      case .headliner:
        if device.localizedName == camera.rawValue { return device }
      }
    }

    if let preferredCamera = AVCaptureDevice.userPreferredCamera { return preferredCamera }
    return nil
  }
}


