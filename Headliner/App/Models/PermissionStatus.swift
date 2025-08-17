//
//  PermissionStatus.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import AVFoundation
import Foundation

/// Represents the current camera permission status
enum PermissionStatus: Equatable {
    /// Permission status not yet determined
    case unknown
    
    /// User has granted camera access
    case authorized
    
    /// User has denied camera access
    case denied
    
    /// Camera access is restricted by system policy
    case restricted
    
    /// Initialize from AVFoundation authorization status
    init(from avStatus: AVAuthorizationStatus) {
        switch avStatus {
        case .notDetermined:
            self = .unknown
        case .authorized:
            self = .authorized
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        @unknown default:
            self = .unknown
        }
    }
    
    /// Display-friendly description
    var displayText: String {
        switch self {
        case .unknown:
            return "Not determined"
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        }
    }
    
    /// Whether camera access is granted
    var isAuthorized: Bool {
        return self == .authorized
    }
    
    /// Whether we need to request permission
    var needsRequest: Bool {
        return self == .unknown
    }
    
    /// Whether permission is blocked and needs user intervention
    var requiresUserAction: Bool {
        return self == .denied || self == .restricted
    }
}