//
//  LocationInfoView.swift
//  Headliner
//
//  A comprehensive, self-contained location services component that handles
//  permission states, permission requests, and data display.
//

import SwiftUI

/// A comprehensive location services component that handles permissions and data display
struct LocationInfoView: View {
    @EnvironmentObject private var locationManager: LocationPermissionManager
    let coordinator: AppCoordinator?
    let showHeader: Bool
    let showInfoSection: Bool
    let showRefreshButton: Bool
    
    // MARK: - Initialization
    
    init(
        coordinator: AppCoordinator? = nil,
        showHeader: Bool = true,
        showInfoSection: Bool = true,
        showRefreshButton: Bool = false
    ) {
        self.coordinator = coordinator
        self.showHeader = showHeader
        self.showInfoSection = showInfoSection
        self.showRefreshButton = showRefreshButton
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header (optional)
            if showHeader {
                headerSection
            }
            
            // Main Content
            VStack(spacing: 16) {
                // Permission Status Card
                permissionStatusCard
                
                // Current Data Display (if available)
                if locationManager.isLocationAvailable {
                    currentDataSection
                }
                
                // Refresh Button (optional)
                if showRefreshButton {
                    refreshDataSection
                }
            }
            
            // Info Section (optional)
            if showInfoSection {
                infoSection
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Location Services")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Location, time, and weather for overlays")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    // MARK: - Permission Status Card
    
    private var permissionStatusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text("Location Access")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if shouldShowPermissionButton {
                Button(action: {
                    logger.debug("🔵 LocationInfoView: Permission button clicked")
                    logger.debug("🔵 Current status: \(locationManager.authorizationStatus.rawValue)")
                    
                    switch locationManager.authorizationStatus {
                    case .notDetermined:
                        logger.debug("🔵 Calling locationManager.requestLocationPermission()")
                        locationManager.requestLocationPermission()
                    case .denied:
                        logger.debug("🔵 Calling locationManager.openSystemSettings()")
                        locationManager.openSystemSettings()
                    default:
                        logger.debug("🔵 No action for status: \(locationManager.authorizationStatus.rawValue)")
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 11))
                        Text(buttonTitle)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(buttonTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(buttonColor)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Current Data Section
    
    private var currentDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Data Header
            HStack {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Current Location Data")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Live")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            // Data Display
            if let info = loadCurrentPersonalInfo() {
                VStack(alignment: .leading, spacing: 8) {
                    // Location
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        
                        Text(info.city ?? "Location not available")
                            .font(.system(size: 12))
                            .foregroundColor(info.city != nil ? .primary : .secondary)
                        
                        Spacer()
                    }
                    
                    // Time
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        
                        Text(info.localTime ?? "Time not available")
                            .font(.system(size: 12))
                            .foregroundColor(info.localTime != nil ? .primary : .secondary)
                        
                        Spacer()
                    }
                    
                    // Weather
                    HStack(spacing: 8) {
                        if let emoji = info.weatherEmoji {
                            Text(emoji)
                                .font(.system(size: 11))
                                .frame(width: 16)
                        } else {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 16)
                        }
                        
                        Text(info.weatherText ?? "Weather not available")
                            .font(.system(size: 12))
                            .foregroundColor(info.weatherText != nil ? .primary : .secondary)
                        
                        Spacer()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                )
                
                Text("This data appears in your camera overlay")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                // No data yet
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text("No location data available yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 0.5)
                        )
                )
                
                Text("Enable location access to see your data")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    // MARK: - Refresh Data Section
    
    private var refreshDataSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Data Updates")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Refreshes automatically every 15 minutes")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                logger.debug("🔄 LocationInfoView: Refresh Now button clicked")
                coordinator?.personalInfo.refreshNow()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                    Text("Refresh Now")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About Location Services", systemImage: "info.circle")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Location is optional and can be enabled later")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Only used for city name and weather, never tracked")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Uses WeatherKit when available, falls back to OpenMeteo")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.leading, 2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.05))
        )
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentPersonalInfo() -> PersonalInfo? {
        guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
              let data = userDefaults.data(forKey: "overlay.personalInfo.v1"),
              let info = try? JSONDecoder().decode(PersonalInfo.self, from: data) else {
            return nil
        }
        
        logger.debug("LocationInfoView: Loaded - city: \(info.city ?? "nil"), weather: \(info.weatherEmoji ?? "nil")")
        return info
    }
    
    // MARK: - Helper Properties for Permission Status
    
    private var statusColor: Color {
        switch locationManager.authorizationStatus {
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
    
    private var statusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Permission not yet requested"
        case .restricted:
            return "Location access restricted by system"
        case .denied:
            return "Location access denied - enable in System Settings"
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            return "Location access enabled - your city and weather will appear in overlays"
        @unknown default:
            return "Unknown status"
        }
    }
    
    private var shouldShowPermissionButton: Bool {
        switch locationManager.authorizationStatus {
        case .notDetermined, .denied:
            return true
        default:
            return false
        }
    }
    
    private var buttonTitle: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Enable"
        case .denied:
            return "Open Settings"
        default:
            return ""
        }
    }
    
    private var buttonIcon: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "location.fill"
        case .denied:
            return "gear"
        default:
            return ""
        }
    }
    
    private var buttonColor: Color {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return .blue
        case .denied:
            return .orange
        default:
            return .gray
        }
    }
    
    private var buttonTextColor: Color {
        return .white
    }
}

// MARK: - Preview

#if DEBUG
struct LocationInfoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Full version (like in Settings)
            LocationInfoView(
                showHeader: true,
                showInfoSection: true,
                showRefreshButton: true
            )
            .environmentObject(LocationPermissionManager())
            .previewDisplayName("Full LocationInfoView")
            
            // Compact version (like in Onboarding)
            LocationInfoView(
                showHeader: false,
                showInfoSection: false,
                showRefreshButton: false
            )
            .environmentObject(LocationPermissionManager())
            .previewDisplayName("Compact LocationInfoView")
        }
        .frame(width: 500)
        .padding()
    }
}
#endif
