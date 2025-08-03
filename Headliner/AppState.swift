//
//  AppState.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI
import SystemExtensions
import AVFoundation
import Combine
import OSLog

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
    
    // MARK: - Dependencies
    
    private let systemExtensionManager: SystemExtensionRequestManager
    private let propertyManager: CustomPropertyManager
    private let outputImageManager: OutputImageManager
    private let notificationManager = NotificationManager.self
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Constants
    
    private enum UserDefaultsKeys {
        static let selectedCameraID = "SelectedCameraID"
        static let hasCompletedOnboarding = "HasCompletedOnboarding"
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
        
        setupBindings()
        loadUserPreferences()
        checkExtensionStatus()
        loadAvailableCameras()
    }
    
    // MARK: - Public Methods
    
    func installExtension() {
        extensionStatus = .installing
        statusMessage = "Installing system extension..."
        systemExtensionManager.install()
    }
    
    func startCamera() {
        guard extensionStatus == .installed else { return }
        
        cameraStatus = .starting
        statusMessage = "Starting camera..."
        notificationManager.postNotification(named: .startStream)
        
        // Simulate camera start completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.cameraStatus = .running
            self.statusMessage = "Camera is running"
        }
    }
    
    func stopCamera() {
        cameraStatus = .stopping
        statusMessage = "Stopping camera..."
        notificationManager.postNotification(named: .stopStream)
        
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
        if let appGroupDefaults = UserDefaults(suiteName: "378NGS49HA.com.dannyfrancken.Headliner") {
            appGroupDefaults.set(camera.id, forKey: "SelectedCameraID")
            notificationManager.postNotification(named: "setCameraDevice")
        }
        
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
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor system extension status changes
        systemExtensionManager.$logText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logText in
                self?.updateExtensionStatus(from: logText)
            }
            .store(in: &cancellables)
    }
    
    private func loadUserPreferences() {
        selectedCameraID = userDefaults.string(forKey: UserDefaultsKeys.selectedCameraID) ?? ""
    }
    
    private func checkExtensionStatus() {
        // Check if extension device is available
        if let _ = propertyManager.deviceObjectID {
            extensionStatus = .installed
            statusMessage = "Extension is installed and ready"
        } else {
            extensionStatus = .notInstalled
            statusMessage = "Extension needs to be installed"
        }
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
        if selectedCameraID.isEmpty && !availableCameras.isEmpty {
            selectedCameraID = availableCameras.first?.id ?? ""
        }
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
        case .unknown: return "Checking..."
        case .notInstalled: return "Not Installed"
        case .installing: return "Installing..."
        case .installed: return "Installed"
        case .error(let message): return "Error: \(message)"
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
        case .stopped: return "Stopped"
        case .starting: return "Starting..."
        case .running: return "Running"
        case .stopping: return "Stopping..."
        case .error(let message): return "Error: \(message)"
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
        case .builtInWideAngleCamera: return "Built-in Camera"
        case .external: return "External Camera"
        case .continuityCamera: return "iPhone Camera"
        case .deskViewCamera: return "Desk View Camera"
        default: return "Camera"
        }
    }
}