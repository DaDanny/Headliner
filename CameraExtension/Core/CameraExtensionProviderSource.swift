//
//  CameraExtensionProviderSource.swift
//  CameraExtension
//
//  Extracted from CameraExtensionProvider.swift on 2025-01-28. No functional changes.
//

import Foundation
import CoreMediaIO
import OSLog

// MARK: - Shared Logger

private let extensionLogger = Logger(subsystem: "com.dannyfrancken.Headliner", category: "Extension")

// MARK: - CameraExtensionProviderSource

class CameraExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
	
	private(set) var provider: CMIOExtensionProvider!
	
	private var deviceSource: CameraExtensionDeviceSource!
    
    private var notificationListenerStarted = false

	
	// CMIOExtensionProviderSource protocol methods (all are required)
	
	init(clientQueue: DispatchQueue?) {
		
		super.init()
        startNotificationListeners()
        
		provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
		deviceSource = CameraExtensionDeviceSource(localizedName: "Headliner")
		
		do {
			try provider.addDevice(deviceSource.device)
		} catch let error {
			fatalError("Failed to add device: \(error.localizedDescription)")
		}

		// Signal readiness to the container app via shared defaults
        if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
			sharedDefaults.set(true, forKey: "ExtensionProviderReady")
			sharedDefaults.synchronize()
			extensionLogger.debug("✅ Marked ExtensionProviderReady in shared defaults")
		}
	}
    
    deinit {
        stopNotificationListeners()
    }
	
    // MARK: Internal
    
	// UNUSED: Empty method stubs - can be removed
	func connect(to client: CMIOExtensionClient) throws {
		
		// Handle client connect
	}
	
	// UNUSED: Empty method stub - can be removed
	func disconnect(from client: CMIOExtensionClient) {
		
		// Handle client disconnect
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		// See full list of CMIOExtensionProperty choices in CMIOExtensionProperties.h
		return [.providerManufacturer]
	}
	
	func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
		
		let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
		if properties.contains(.providerManufacturer) {
			providerProperties.manufacturer = "Headliner Manufacturer"
		}
		return providerProperties
	}
	
	// UNUSED: Empty method stub - can be removed
	func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
		
		// Handle settable properties here.
	}
    
    // MARK: Private
    
    private func notificationReceived(notificationName: String) {
        extensionLogger.debug("📡 Received notification: \(notificationName)")
        
        guard let name = CrossAppNotificationName(rawValue: notificationName) else {
            extensionLogger.debug("❌ Unknown notification name: \(notificationName)")
            return
        }

        switch name {
        case .startStream:
            extensionLogger.debug("📡 startStream notification ignored - using pure client-based streaming")
        case .stopStream:
            extensionLogger.debug("📡 stopStream notification ignored - using pure client-based streaming")
        case .setCameraDevice:
            extensionLogger.debug("📡 Camera device selection changed - processing notification")
            handleCameraDeviceChange()
        case .updateOverlaySettings:
            extensionLogger.debug("🎨 Overlay settings changed - updating now")
            deviceSource.updateOverlaySettings()
        case .overlayUpdated:
            extensionLogger.debug("📡 Pre-rendered overlay updated - will be refreshed on next frame")
        // Phase 2: New enhanced notifications
        case .requestStart:
            extensionLogger.debug("📡 requestStart notification ignored - using pure client-based streaming")
        case .requestStop:
            extensionLogger.debug("📡 requestStop notification ignored - using pure client-based streaming")
        case .requestSwitchDevice:
            extensionLogger.debug("📡 Request switch device - same as setCameraDevice")
            handleCameraDeviceChange()
        case .statusChanged:
            extensionLogger.debug("📡 Status changed notification - no action needed (app-side notification)")
        // Phase 1.2: New typed notifications for auto-start
        case .appConnected:
            extensionLogger.debug("📡 App connected notification - no action needed in extension")
        case .appDisconnected:
            extensionLogger.debug("📡 App disconnected notification - no action needed in extension")
        case .cameraActivated:
            extensionLogger.debug("📡 Camera activated notification - no action needed in extension")
        case .cameraDeactivated:
            extensionLogger.debug("📡 Camera deactivated notification - no action needed in extension")
        }
    }

    private func startNotificationListeners() {
        for notificationName in CrossAppNotificationName.allCases {
            let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

            // Use raw CFNotificationCenter calls in extension - it runs in separate process
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                observer,
                { _, observer, name, _, _ in
                    if let observer = observer, let name = name {
                        let extensionProviderSourceSelf = Unmanaged<CameraExtensionProviderSource>.fromOpaque(observer).takeUnretainedValue()
                        extensionProviderSourceSelf.notificationReceived(notificationName: name.rawValue as String)
                    }
                },
                notificationName.rawValue as CFString,
                nil,
                .deliverImmediately
            )
        }
        
        notificationListenerStarted = true
        extensionLogger.debug("✅ Started notification listeners for \(CrossAppNotificationName.allCases.count) notifications")
    }

    private func stopNotificationListeners() {
        if notificationListenerStarted {
            let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
            CFNotificationCenterRemoveEveryObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                observer
            )
            notificationListenerStarted = false
        }
    }
    
    private func handleCameraDeviceChange() {
        // Read camera device ID from UserDefaults
        if let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
           let deviceID = userDefaults.string(forKey: ExtensionStatusKeys.selectedDeviceID) {
            extensionLogger.debug("📡 Camera device change notification - setting device to: \(deviceID)")
            
            // Add a small delay to ensure UserDefaults are fully written
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Re-read to ensure we have the latest value
                if let latestDeviceID = userDefaults.string(forKey: ExtensionStatusKeys.selectedDeviceID),
                   latestDeviceID == deviceID {
                    extensionLogger.debug("✅ Confirmed device selection: \(latestDeviceID)")
                    self.deviceSource.setCameraDevice(latestDeviceID)
                } else {
                    extensionLogger.warning("⚠️ Device ID changed during processing - expected: \(deviceID)")
                }
            }
        } else {
            extensionLogger.warning("⚠️ No device ID found in UserDefaults for camera change")
        }
    }
}