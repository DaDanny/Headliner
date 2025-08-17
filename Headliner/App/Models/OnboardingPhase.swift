//
//  OnboardingPhase.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation

/// Represents the current phase of the onboarding flow
enum OnboardingPhase: Equatable {
    /// App launched, onboarding not started
    case preflight
    
    /// Extension not present or approved - user needs to install
    case needsExtensionInstall
    
    /// User clicked install; waiting for OS approval/device detection
    case awaitingApproval
    
    /// Extension installed & detected, ready to start camera
    case readyToStart
    
    /// Camera is spinning up
    case startingCamera
    
    /// Preview live, camera running
    case running
    
    /// After running; optional personalization step
    case personalizeOptional
    
    /// Recoverable error with specific message and recovery actions
    case error(String)
    
    /// Display-friendly title for the current phase
    var title: String {
        switch self {
        case .preflight, .needsExtensionInstall:
            return "Install Headliner Camera"
        case .awaitingApproval:
            return "Approve in System Settings"
        case .readyToStart:
            return "Start Your Camera"
        case .startingCamera:
            return "Starting Camera"
        case .running:
            return "Camera Ready"
        case .personalizeOptional:
            return "Personalize Your Overlay"
        case .error:
            return "Setup Issue"
        }
    }
    
    /// Display-friendly subtitle for the current phase
    var subtitle: String {
        switch self {
        case .preflight, .needsExtensionInstall:
            return "One-time setup so Meet/Zoom can see your video."
        case .awaitingApproval:
            return "Look for Headliner under Camera Extensions."
        case .readyToStart:
            return "See your overlays exactly as others will."
        case .startingCamera:
            return "Getting your camera ready..."
        case .running:
            return "Your camera is live and ready to use!"
        case .personalizeOptional:
            return "Add your name and customize your overlay."
        case .error(let message):
            return message
        }
    }
    
    /// Primary action button text
    var primaryActionTitle: String {
        switch self {
        case .preflight, .needsExtensionInstall:
            return "Install & Enable"
        case .awaitingApproval:
            return "Recheck"
        case .readyToStart:
            return "Start Camera"
        case .startingCamera:
            return "" // No button during loading
        case .running:
            return "Personalize Overlay"
        case .personalizeOptional:
            return "Finish"
        case .error(let message):
            if message.contains("Camera access denied") {
                return "Open Privacy Settings"
            } else {
                return "Try Again"
            }
        }
    }
    
    /// Secondary action button text (optional)
    var secondaryActionTitle: String? {
        switch self {
        case .preflight, .needsExtensionInstall:
            return "Open System Settings"
        case .awaitingApproval:
            return nil
        case .readyToStart:
            return "Choose Source Camera"
        case .startingCamera:
            return nil
        case .running:
            return "Finish"
        case .personalizeOptional:
            return nil
        case .error:
            return "Contact Support"
        }
    }
    
    /// Step number for progress indication (1-based)
    var stepNumber: Int {
        switch self {
        case .preflight, .needsExtensionInstall, .awaitingApproval:
            return 1
        case .readyToStart, .startingCamera, .running:
            return 2
        case .personalizeOptional:
            return 3
        case .error:
            return 0 // No step for errors
        }
    }
    
    /// Total number of steps
    static var totalSteps: Int { 2 } // Optional step 3 for personalization
    
    /// Whether this phase shows a loading indicator
    var isLoading: Bool {
        switch self {
        case .awaitingApproval, .startingCamera:
            return true
        default:
            return false
        }
    }
    
    /// Whether this phase allows user interaction
    var isInteractive: Bool {
        switch self {
        case .startingCamera:
            return false
        default:
            return true
        }
    }
}