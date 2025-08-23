//
//  SettingsView.swift
//  Headliner
//
//  Main settings interface that uses reusable components
//

import SwiftUI

struct SettingsView: View {
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
                    // Personal Info Editing Section
                    PersonalInfoView()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Location Services Section
                    LocationInfoView(
                        showHeader: true,
                        showInfoSection: true,
                        showRefreshButton: true
                    )
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 20)
                    
                    // Theme Selection Section
                    ThemePickerView()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 20)
                    
                    // Overlay Layout Settings Section
                    OverlayLayoutSettingsView()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 20)
                    
                    // Surface Style Settings Section
                    SurfaceStyleSettingsView()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 650)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            logger.debug("📋 SettingsView: View appeared")
            personalInfoVM.onAppear()
        }
        .onDisappear {
            logger.debug("📋 SettingsView: View disappearing")
            personalInfoVM.onDisappear()
        }
    }
}

// MARK: - Overlay Layout Settings Component

struct OverlayLayoutSettingsView: View {
    @EnvironmentObject private var overlayService: OverlayService
    @State private var selectedSafeAreaMode: SafeAreaMode = .balanced
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Overlay Layout")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
            }
            
            Text("Choose how overlays are positioned to ensure visibility across video platforms")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Picker("Layout Mode", selection: $selectedSafeAreaMode) {
                ForEach(SafeAreaMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedSafeAreaMode) { _, newMode in
                updateSetting(\.safeAreaMode, to: newMode)
            }
            
            Text(selectedSafeAreaMode.description)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.top, 4)
        }
        .padding(16)
        .onAppear {
            selectedSafeAreaMode = overlayService.settings.safeAreaMode
        }
    }
    
    /// Update a specific setting property and apply changes immediately
    private func updateSetting<T>(_ keyPath: WritableKeyPath<OverlaySettings, T>, to value: T) {
        var updatedSettings = overlayService.settings
        updatedSettings[keyPath: keyPath] = value
        overlayService.updateSettings(updatedSettings)
    }
}

// MARK: - Surface Style Settings Component

struct SurfaceStyleSettingsView: View {
    @EnvironmentObject private var overlayService: OverlayService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "rectangle.roundedtop")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Surface Style")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
            }
            
            Text("Choose between rounded and square corner styles for overlay elements")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 16) {
                ForEach(SurfaceStyle.allCases, id: \.self) { style in
                    Button(action: {
                        overlayService.selectSurfaceStyle(style)
                    }) {
                        VStack(spacing: 8) {
                            // Preview of the style
                            RoundedRectangle(cornerRadius: style == .rounded ? 8 : 0)
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 50, height: 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: style == .rounded ? 8 : 0)
                                        .stroke(Color.accentColor, lineWidth: overlayService.currentSurfaceStyle == style ? 2 : 1)
                                )
                            
                            Text(style.rawValue.capitalized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(overlayService.currentSurfaceStyle == style ? Color.accentColor.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(OverlayService())
            .environmentObject(LocationPermissionManager())
            .environmentObject(ThemeManager())
            .previewDisplayName("Settings View")
    }
}
#endif
