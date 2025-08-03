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
    private var captureSessionManager: CaptureSessionManager?
    
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
        
        logger.debug("Initializing AppState...")
        
        setupBindings()
        loadUserPreferences()
        checkExtensionStatus()
        loadAvailableCameras()
        setupCaptureSession()
        
        logger.debug("AppState initialization complete")
    }
    
    // MARK: - Public Methods
    
    func installExtension() {
        extensionStatus = .installing
        statusMessage = "Installing system extension..."
        systemExtensionManager.install()
    }
    
    func startCamera() {
        guard extensionStatus == .installed else { 
            logger.debug("Cannot start camera - extension not installed")
            return 
        }
        
        logger.debug("Starting camera...")
        cameraStatus = .starting
        statusMessage = "Starting camera..."
        notificationManager.postNotification(named: .startStream)
        
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
        logger.debug("Checking extension status...")
        
        // Refresh the property manager to check for newly installed extensions
        propertyManager.refreshExtensionStatus()
        
        // Check if extension device is available
        if let _ = propertyManager.deviceObjectID {
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
        if selectedCameraID.isEmpty && !availableCameras.isEmpty {
            selectedCameraID = availableCameras.first?.id ?? ""
            // Update the capture session with the default camera
            if let firstCamera = availableCameras.first {
                updateCaptureSessionCamera(deviceID: firstCamera.id)
            }
        }
    }
    
    private func setupCaptureSession() {
        captureSessionManager = CaptureSessionManager(capturingHeadliner: false)
        
        if let manager = captureSessionManager, manager.configured {
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
            logger.error("Failed to configure capture session for preview")
        }
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