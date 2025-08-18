import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var personalInfoVM = PersonalInfoSettingsVM()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and close button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Configure app preferences and features")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                        .background(Circle().fill(Color.clear))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close Settings")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Settings Content
            ScrollView {
                VStack(spacing: 16) {
                    // Personal Info Section
                    personalInfoSection
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Future settings sections can go here
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            logger.debug("📋 SettingsView: View appeared")
            logger.debug("📋 Current location status: \(appState.locationPermissionStatus.rawValue)")
            personalInfoVM.onAppear()
        }
        .onDisappear {
            logger.debug("📋 SettingsView: View disappearing")
            personalInfoVM.onDisappear()
        }
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
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
                    Text("Personal Info")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Location, time, and weather for overlays")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, 4)
            
            // Location Permission Status
            VStack(spacing: 16) {
                // Permission Status Card
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
                            logger.debug("🔵 SettingsView: Permission button clicked")
                            logger.debug("🔵 Current status: \(appState.locationPermissionStatus.rawValue)")
                            logger.debug("🔵 Button action type: \(buttonTitle)")
                            logger.debug("🔵 Button will trigger: \(appState.locationPermissionStatus == .notDetermined ? "requestLocationPermission" : "openLocationSettings")")
                            
                            // Call the appropriate method directly instead of using computed property
                            switch appState.locationPermissionStatus {
                            case .notDetermined:
                                logger.debug("🔵 Calling appState.requestLocationPermission()")
                                appState.requestLocationPermission()
                            case .denied:
                                logger.debug("🔵 Calling appState.openLocationSettings()")
                                appState.openLocationSettings()
                            default:
                                logger.debug("🔵 No action for status: \(appState.locationPermissionStatus.rawValue)")
                            }
                            
                            logger.debug("🔵 Button action completed")
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
                
                // Refresh Data Row
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
                        logger.debug("🔄 SettingsView: Refresh Now button clicked")
                        personalInfoVM.refreshNowTapped()
                        appState.refreshPersonalInfoNow()
                        logger.debug("🔄 SettingsView: Refresh triggered")
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
                
                // Current Data Display  
                PersonalInfoView()
                    .padding(.horizontal, 12)
            }
            
            // Info Section
            VStack(alignment: .leading, spacing: 8) {
                Label("About Personal Info", systemImage: "info.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("Uses WeatherKit when available, falls back to OpenMeteo")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("Data is securely shared with camera extension via App Group")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("Location is only used for city name and weather, never tracked")
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
        .padding(16)
    }
    
    // MARK: - Helper Properties for Permission Status
    
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
    
    private var statusText: String {
        switch appState.locationPermissionStatus {
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
            return "Enable"
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
    
    private var buttonTextColor: Color {
        return .white
    }
    
    // Note: buttonAction computed property removed - actions are now called directly in the button handler
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(appState: AppState(
            systemExtensionManager: SystemExtensionRequestManager(logText: ""),
            propertyManager: CustomPropertyManager(),
            outputImageManager: OutputImageManager()
        ))
        .previewDisplayName("Settings View")
    }
}
#endif