//
//  LocationPermissionManager.swift
//  Headliner
//
//  Manages location permission requests and status for the app.
//

import Foundation
import CoreLocation
import AppKit

/// Manages location permission state and requests
@MainActor
final class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isRequestingPermission = false
    
    /// Human-readable description of current permission status
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Location permission not yet requested"
        case .restricted:
            return "Location access restricted by system"
        case .denied:
            return "Location access denied - enable in System Settings"
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            return "Location access granted"
        @unknown default:
            return "Unknown location permission status"
        }
    }
    
    /// Whether location services are available and authorized
    var isLocationAvailable: Bool {
        switch authorizationStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    /// Whether we should show the request button
    var canRequestPermission: Bool {
        authorizationStatus == .notDetermined
    }
    
    /// Whether we should show settings button (permission was denied)
    var shouldShowSettingsButton: Bool {
        authorizationStatus == .denied
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        // Get initial status
        authorizationStatus = locationManager.authorizationStatus
        logger.info("🔴 LocationPermissionManager: Initialized with status: \(self.authorizationStatus.rawValue)")
        logger.info("🔴 Location services enabled: \(CLLocationManager.locationServicesEnabled())")
        
        // Debug: Check if Info.plist has the required keys
        if let infoPlist = Bundle.main.infoDictionary {
            let hasWhenInUse = infoPlist["NSLocationWhenInUseUsageDescription"] != nil
            let hasAlways = infoPlist["NSLocationAlwaysAndWhenInUseUsageDescription"] != nil
            let hasGeneral = infoPlist["NSLocationUsageDescription"] != nil
            logger.info("🔴 Info.plist location keys - WhenInUse: \(hasWhenInUse), Always: \(hasAlways), General: \(hasGeneral)")
            if let whenInUseDesc = infoPlist["NSLocationWhenInUseUsageDescription"] as? String {
                logger.info("🔴 NSLocationWhenInUseUsageDescription: \(whenInUseDesc)")
            }
        }
    }
    
    /// Request location permission from the user
    /// This can be called from any UI button or view
    func requestLocationPermission() {
        logger.debug("🔴 LocationPermissionManager: requestLocationPermission called")
        logger.debug("🔴 Current authorizationStatus: \(self.authorizationStatus.rawValue)")
        logger.debug("🔴 CLLocationManager.locationServicesEnabled: \(CLLocationManager.locationServicesEnabled())")
        
        // Additional debug info
        logger.debug("🔴 Location manager delegate: \(String(describing: self.locationManager.delegate))")
        logger.debug("🔴 Is main thread: \(Thread.isMainThread)")
        
        guard authorizationStatus == .notDetermined else {
            logger.debug("🔴 LocationPermissionManager: Permission already determined: \(self.authorizationStatus.rawValue)")
            return
        }
        
        logger.debug("🔴 LocationPermissionManager: Calling requestWhenInUseAuthorization...")
        logger.debug("🔴 NOTE: If no prompt appears, check Info.plist for NSLocationWhenInUseUsageDescription key")
        isRequestingPermission = true
        locationManager.requestWhenInUseAuthorization()
        logger.debug("🔴 LocationPermissionManager: requestWhenInUseAuthorization called - waiting for delegate callback")
    }
    
    /// Open System Settings to the app's privacy settings
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Manually refresh permission status
    func checkPermissionStatus() {
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let oldStatus = authorizationStatus
            authorizationStatus = manager.authorizationStatus
            isRequestingPermission = false
            
            logger.info("🔴 LocationPermissionManager: Authorization changed from \(oldStatus.rawValue) to \(self.authorizationStatus.rawValue)")
            
            // If permission was just granted, trigger a location update
            if isLocationAvailable {
                logger.info("🔴 LocationPermissionManager: Location is now available, posting notification")
                // Notify AppState to refresh personal info
                Notifications.Internal.post(.locationPermissionGranted)
            } else {
                logger.info("🔴 LocationPermissionManager: Location not available with status: \(self.authorizationStatus.rawValue)")
            }
        }
    }
}

// MARK: - Notification Names (Migrated to InternalNotifications)

// Removed: extension Notification.Name - now using InternalNotifications.post(.locationPermissionGranted)
