//
//  NotificationName.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import Foundation
import AppKit
import AVFoundation
import CoreMediaIO
import OSLog

private let sharedLogger = Logger(
    subsystem: "com.dannyfrancken.Headliner",
    category: "Shared"
)

// MARK: CaptureSessionManager
class CaptureSessionManager: NSObject {
    // MARK: Lifecycle
 
    init(capturingHeadliner: Bool) {
        super.init()
        captureHeadliner = capturingHeadliner
        configured = configureCaptureSession()
    }
 
    // MARK: Internal
 
    enum Camera: String {
        case anyCamera = "any"
        case headliner = "Headliner"
    }
 
    var configured: Bool = false
    var captureHeadliner = false
    var captureSession: AVCaptureSession = .init()
 
    var videoOutput: AVCaptureVideoDataOutput?
 
    let dataOutputQueue = DispatchQueue(label: "video_queue",
                                        qos: .userInteractive,
                                        attributes: [],
                                        autoreleaseFrequency: .workItem)
 
    func configureCaptureSession() -> Bool {
        sharedLogger.debug("Configuring capture session...")
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            sharedLogger.debug("Camera access already authorized")
            break
        case .notDetermined:
            sharedLogger.debug("Camera permission not determined, requesting...")
            // For notDetermined, we need to request permission but can't wait for it synchronously
            // The app should call this method again after permission is granted
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    sharedLogger.debug("Camera permission granted")
                    DispatchQueue.main.async {
                        // Trigger reconfiguration after permission is granted
                        _ = self.configureCaptureSession()
                    }
                } else {
                    sharedLogger.error("Camera permission denied by user")
                }
            }
            return false // Return false until permission is actually granted
        case .denied:
            sharedLogger.error("Camera access denied - user needs to enable in System Preferences")
            return false
        case .restricted:
            sharedLogger.error("Camera access restricted by system policy")
            return false
        @unknown default:
            sharedLogger.error("Unknown camera authorization status")
            return false
        }
 
        captureSession.beginConfiguration()
 
        captureSession.sessionPreset = sessionPreset
 
        guard let camera = getCameraIfAvailable(camera: captureHeadliner ? .headliner : .anyCamera) else {
            sharedLogger.error("Can't create default camera, this could be because the extension isn't installed, returning")
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
                    sharedLogger.error("No HD formats used by this code supported, returning.")
                    return false
                }
            }
            captureSession.addInput(input)
        } catch {
            sharedLogger.error("Can't create AVCaptureDeviceInput, returning")
            return false
        }
 
        videoOutput = AVCaptureVideoDataOutput()
        if let videoOutput = videoOutput {
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                captureSession.commitConfiguration()
                return true
            } else {
                sharedLogger.error("Can't add video output, returning")
                return false
            }
        }
        return false
    }
    // MARK: Private
     
    private let sessionPreset = AVCaptureSession.Preset.hd1280x720
 
    private func getCameraIfAvailable(camera: Camera) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .deskViewCamera, .external, .continuityCamera],
            mediaType: .video, position: .unspecified)
        
        sharedLogger.debug("Looking for camera type: \(camera.rawValue)")
        sharedLogger.debug("Available devices:")
        for device in discoverySession.devices {
            sharedLogger.debug("  - \(device.localizedName) (continuity: \(device.isContinuityCamera))")
        }
        
        for device in discoverySession.devices {
            switch camera {
            case .anyCamera:
                // For any camera, accept any available camera device (not the Headliner virtual camera)
                // This allows the main app to use regular cameras for preview
                if !device.localizedName.contains("Headliner") {
                    sharedLogger.debug("Selected camera device: \(device.localizedName)")
                    return device
                }
            case .headliner:
                if device.localizedName == camera.rawValue {
                    sharedLogger.debug("Found Headliner virtual camera: \(device.localizedName)")
                    return device
                }
            }
        }
        
        // Fallback to user preferred camera if available
        if let preferredCamera = AVCaptureDevice.userPreferredCamera {
            sharedLogger.debug("Using user preferred camera: \(preferredCamera.localizedName)")
            return preferredCamera
        }
        
        sharedLogger.error("No suitable camera device found")
        return nil
    }
}

// MARK: Identifiers
enum Identifiers: String {
    case appGroup = "378NGS49HA.com.dannyfrancken.Headliner"
    case orgIDAndProduct = "com.dannyfrancken.Headliner"
}

// MARK: Notificationname
enum NotificationName: String, CaseIterable {
    case startStream = "378NGS49HA.com.dannyfrancken.Headliner.startStream"
    case stopStream = "378NGS49HA.com.dannyfrancken.Headliner.stopStream"
    case setCameraDevice = "378NGS49HA.com.dannyfrancken.Headliner.setCameraDevice"
    case updateOverlaySettings = "378NGS49HA.com.dannyfrancken.Headliner.updateOverlaySettings"
}

// MARK: - NotificationManager
class NotificationManager {
    class func postNotification(named notificationName: String) {
        let completeNotificationName = Identifiers.appGroup.rawValue + "." + notificationName
        sharedLogger
            .debug(
                "Posting notification \(completeNotificationName) from container app"
            )
 
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(completeNotificationName as NSString),
            nil,
            nil,
            true
        )
    }
 
    class func postNotification(named notificationName: NotificationName) {
        sharedLogger
            .debug(
                "Posting notification \(notificationName.rawValue) from container app"
            )
 
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName.rawValue as NSString),
            nil,
            nil,
            true
        )
    }
    
    class func postNotification(named notificationName: NotificationName, overlaySettings: OverlaySettings) {
        sharedLogger
            .debug(
                "Posting notification \(notificationName.rawValue) with overlay settings from container app"
            )
        
        // Create a temporary file to pass the overlay settings data
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("overlay_settings_\(UUID().uuidString).json")
        
        do {
            let overlayData = try JSONEncoder().encode(overlaySettings)
            try overlayData.write(to: tempFile)
            
            // Store the file path in a well-known UserDefaults location that both can access
            let sharedDefaults = UserDefaults(suiteName: "378NGS49HA.com.dannyfrancken.Headliner")
            sharedDefaults?.set(tempFile.path, forKey: "OverlaySettingsFilePath")
            sharedDefaults?.synchronize()
            
            sharedLogger.debug("📂 Saved overlay settings to temp file: \(tempFile.path)")
            
            // Post the notification
            CFNotificationCenterPostNotification(
                CFNotificationCenterGetDarwinNotifyCenter(),
                CFNotificationName(notificationName.rawValue as NSString),
                nil,
                nil,
                true
            )
        } catch {
            sharedLogger.error("❌ Failed to create overlay settings temp file: \(error)")
            // Fallback to regular notification
            postNotification(named: notificationName)
        }
    }
}

// MARK: - MoodName

enum MoodName: String, CaseIterable {
    case bypass = "Bypass"
    case newWave = "New Wave"
    case berlin = "Berlin"
    case oldFilm = "OldFilm"
    case sunset = "Sunset"
    case badEnergy = "BadEnergy"
    case beyondTheBeyond = "BeyondTheBeyond"
    case drama = "Drama"
}
 
// MARK: - PropertyName
 
enum PropertyName: String, CaseIterable {
    case mood
}
 
// MARK: - Overlay Configuration

struct OverlaySettings: Codable {
    var isEnabled: Bool = true
    var userName: String = ""
    var showUserName: Bool = true
    var namePosition: OverlayPosition = .bottomLeft
    var nameBackgroundColor: OverlayColor = .blackTransparent
    var nameTextColor: OverlayColor = .white
    var fontSize: CGFloat = 24
    var cornerRadius: CGFloat = 8
    var padding: CGFloat = 12
    var margin: CGFloat = 20
    var showVersion: Bool = true
    var versionPosition: OverlayPosition = .bottomRight
    var versionBackgroundColor: OverlayColor = .blackTransparent
    var versionTextColor: OverlayColor = .white
    var versionFontSize: CGFloat = 16
}

enum OverlayPosition: String, Codable, CaseIterable {
    case topLeft = "topLeft"
    case topCenter = "topCenter"
    case topRight = "topRight"
    case centerLeft = "centerLeft"
    case center = "center"
    case centerRight = "centerRight"
    case bottomLeft = "bottomLeft"
    case bottomCenter = "bottomCenter"
    case bottomRight = "bottomRight"
    
    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top Center"
        case .topRight: return "Top Right"
        case .centerLeft: return "Center Left"
        case .center: return "Center"
        case .centerRight: return "Center Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom Center"
        case .bottomRight: return "Bottom Right"
        }
    }
}

enum OverlayColor: String, Codable, CaseIterable {
    case white = "white"
    case black = "black"
    case blackTransparent = "blackTransparent"
    case blue = "blue"
    case green = "green"
    case red = "red"
    case purple = "purple"
    case orange = "orange"
    
    var nsColor: NSColor {
        switch self {
        case .white: return NSColor.white
        case .black: return NSColor.black
        case .blackTransparent: return NSColor.black.withAlphaComponent(0.7)
        case .blue: return NSColor.systemBlue
        case .green: return NSColor.systemGreen
        case .red: return NSColor.systemRed
        case .purple: return NSColor.systemPurple
        case .orange: return NSColor.systemOrange
        }
    }
    
    var displayName: String {
        switch self {
        case .white: return "White"
        case .black: return "Black"
        case .blackTransparent: return "Black (Transparent)"
        case .blue: return "Blue"
        case .green: return "Green"
        case .red: return "Red"
        case .purple: return "Purple"
        case .orange: return "Orange"
        }
    }
}

// MARK: - UserDefaults Keys
enum OverlayUserDefaultsKeys {
    static let overlaySettings = "OverlaySettings"
    static let userName = "UserName"
}

extension String {
    func convertedToCMIOObjectPropertySelectorName() -> CMIOObjectPropertySelector {
        let noName: CMIOObjectPropertySelector = 0
        if count == MemoryLayout<CMIOObjectPropertySelector>.size {
            return data(using: .utf8, allowLossyConversion: false)?.withUnsafeBytes { propertySelector in
                propertySelector.load(as: CMIOObjectPropertySelector.self).byteSwapped
            } ?? noName
        } else {
            return noName
        }
    }
}
