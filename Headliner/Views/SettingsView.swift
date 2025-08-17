import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var personalInfoVM = PersonalInfoSettingsVM()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Settings")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Configure app preferences and features")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                
                Divider()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                
                // Settings Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Personal Info Section
                        GlassmorphicCard {
                            personalInfoSection
                        }
                        .padding(.horizontal, 24)
                        
                        // Future settings sections can go here
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    AnimatedBackground()
                        .opacity(0.05)
                    
                    LinearGradient(
                        colors: [
                            Color(NSColor.controlBackgroundColor),
                            Color(NSColor.controlBackgroundColor).opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .navigationBarHidden(true)
        }
        .frame(width: 500, height: 400)
        .onAppear {
            personalInfoVM.onAppear()
        }
        .onDisappear {
            personalInfoVM.onDisappear()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Personal Info")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Show your location, time, and weather in overlays")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
                .opacity(0.3)
            
            // Settings Controls
            VStack(spacing: 12) {
                // Use Location Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use Location")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Enable location services for city and weather")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $personalInfoVM.useLocation)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // Refresh Now Button
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Update Now")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Manually refresh location and weather data")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        personalInfoVM.refreshNowTapped()
                        // Also refresh via AppState for immediate feedback
                        appState.refreshPersonalInfoNow()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                            Text("Refresh")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Info Text
            VStack(alignment: .leading, spacing: 4) {
                Text("ℹ️ Personal Info Features:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("• Updates every 15 minutes automatically\n• Uses WeatherKit when available, OpenMeteo as fallback\n• Data is shared with camera extension for overlays")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            .padding(.top, 8)
        }
        .padding(16)
    }
}