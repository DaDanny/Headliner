//
//  LocationPermissionView.swift
//  Headliner
//
//  Reusable view component for managing location permissions.
//  Can be embedded in any view that needs location permission controls.
//

import SwiftUI
import CoreLocation

/// A reusable view for displaying and managing location permission status
struct LocationPermissionView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text("Location Access")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(statusColor.opacity(0.3), lineWidth: 8)
                            .scaleEffect(appState.isLocationAvailable ? 1.5 : 1.0)
                            .opacity(appState.isLocationAvailable ? 0 : 1)
                            .animation(
                                appState.isLocationAvailable ?
                                    Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false) :
                                    .default,
                                value: appState.isLocationAvailable
                            )
                    )
            }
            
            // Status text
            Text(statusText)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
            
            // Action button (if needed)
            if shouldShowButton {
                Button(action: buttonAction) {
                    HStack(spacing: 6) {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 12, weight: .medium))
                        Text(buttonTitle)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(buttonColor)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        switch appState.locationPermissionStatus {
        case .notDetermined:
            return "Location access not yet requested. Grant permission to show your city and weather in overlays."
        case .restricted:
            return "Location access is restricted by system settings."
        case .denied:
            return "Location access denied. Open System Settings to enable location for Headliner."
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            return "Location access granted. Your city and weather will appear in overlays."
        @unknown default:
            return "Unknown location permission status."
        }
    }
    
    private var shouldShowButton: Bool {
        switch appState.locationPermissionStatus {
        case .notDetermined, .denied:
            return true
        default:
            return false
        }
    }
    
    private var buttonTitle: String {
        switch appState.locationPermissionStatus {
        case .notDetermined:
            return "Request Permission"
        case .denied:
            return "Open Settings"
        default:
            return ""
        }
    }
    
    private var buttonIcon: String {
        switch appState.locationPermissionStatus {
        case .notDetermined:
            return "location.fill"
        case .denied:
            return "gear"
        default:
            return ""
        }
    }
    
    private var buttonColor: Color {
        switch appState.locationPermissionStatus {
        case .notDetermined:
            return .blue
        case .denied:
            return .orange
        default:
            return .gray
        }
    }
    
    private var buttonAction: () -> Void {
        switch appState.locationPermissionStatus {
        case .notDetermined:
            return { appState.requestLocationPermission() }
        case .denied:
            return { appState.openLocationSettings() }
        default:
            return {}
        }
    }
    
    private var statusColor: Color {
        switch appState.locationPermissionStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var iconColor: Color {
        switch appState.locationPermissionStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            return .blue
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LocationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPermissionView(appState: AppState(
            systemExtensionManager: SystemExtensionRequestManager(logText: ""),
            propertyManager: CustomPropertyManager(),
            outputImageManager: OutputImageManager()
        ))
        .frame(width: 400)
        .padding()
    }
}
#endif
