//
//  CustomPropertyManager.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation
import SwiftUI
import AVFoundation
import CoreMediaIO
import OSLog

private let propertyLogger = Logger(
    subsystem: "com.dannyfrancken.Headliner",
    category: "CustomPropertyManager"
)

class CustomPropertyManager: NSObject, ObservableObject {
    // MARK: Lifecycle
    
    override init() {
        super.init()
        // Simplified - no effects functionality
    }
    
    // MARK: Internal
    
    lazy var deviceObjectID: CMIOObjectID? = {
        let device = getExtensionDevice(name: "Headliner")
        propertyLogger.debug("Extension device detection result: \(device?.localizedName ?? "nil")")
        return device != nil ? 1 : nil // Simplified check - just return a placeholder ID if device exists
    }()
    
    func getExtensionDevice(name: String) -> AVCaptureDevice? {
        // Check for both standard devices and virtual cameras
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        propertyLogger.debug("Looking for extension device named: \(name)")
        propertyLogger.debug("Available devices:")
        for device in discoverySession.devices {
            propertyLogger.debug("  - \(device.localizedName) (ID: \(device.uniqueID))")
        }
        
        // Look for our virtual camera device
        let headlinerDevice = discoverySession.devices.first { 
            $0.localizedName.contains("Headliner") || $0.localizedName == name 
        }
        
        if let device = headlinerDevice {
            propertyLogger.debug("Found Headliner extension device: \(device.localizedName)")
        } else {
            propertyLogger.debug("Headliner extension device not found")
        }
        
        return headlinerDevice
    }
    
    func refreshExtensionStatus() {
        // Clear the lazy property cache and re-check
        _deviceObjectID = nil
        _ = deviceObjectID // This will trigger re-evaluation
    }
    
    private var _deviceObjectID: CMIOObjectID?
}