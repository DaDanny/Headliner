//
//  SettingsContentView.swift
//  Headliner
//
//  Settings window for macOS app menu
//

import SwiftUI
import Sparkle

struct SettingsContentView: View {
    @EnvironmentObject private var updaterService: UpdaterService
    @EnvironmentObject private var cameraService: CameraService
    @EnvironmentObject private var overlayService: OverlayService
    
    var body: some View {
        TabView {
            // General Tab
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            // Camera Tab
            CameraSettingsView()
                .environmentObject(cameraService)
                .tabItem {
                    Label("Camera", systemImage: "video")
                }
            
            // Overlay Tab
            OverlaySettingsView()
                .environmentObject(overlayService)
                .tabItem {
                    Label("Overlays", systemImage: "rectangle.on.rectangle")
                }
            
            // Updates Tab with Sparkle UI
            UpdatesSettingsView()
                .environmentObject(updaterService)
                .tabItem {
                    Label("Updates", systemImage: "arrow.down.circle")
                }
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .toggleStyle(.checkbox)
            }
            .padding()
        }
        .formStyle(.grouped)
    }
}

// MARK: - Camera Settings Tab

struct CameraSettingsView: View {
    @EnvironmentObject private var cameraService: CameraService
    @State private var selectedCamera: CameraDevice?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Camera Settings")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            Form {
                Section {
                    if cameraService.availableCameras.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("No cameras available")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        Picker("Active Camera:", selection: Binding<CameraDevice?>(
                            get: { cameraService.selectedCamera },
                            set: { newCamera in
                                if let camera = newCamera {
                                    Task {
                                        await cameraService.selectCamera(camera)
                                    }
                                }
                            }
                        )) {
                            Text("None").tag(nil as CameraDevice?)
                            ForEach(cameraService.availableCameras, id: \.id) { camera in
                                HStack {
                                    Image(systemName: cameraIcon(for: camera))
                                    Text(camera.name)
                                }
                                .tag(camera as CameraDevice?)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        if let camera = cameraService.selectedCamera {
                            HStack {
                                Text("Type:")
                                    .foregroundColor(.secondary)
                                Text(camera.deviceType)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                }
                
                Section("Camera Status") {
                    HStack {
                        Text("Virtual Camera:")
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(cameraService.cameraStatus.isRunning ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(cameraService.cameraStatus.isRunning ? "Live" : "Idle")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Spacer()
        }
    }
    
    private func cameraIcon(for camera: CameraDevice) -> String {
        if camera.deviceType.contains("iPhone") || camera.deviceType.contains("Continuity") { 
            return "iphone" 
        }
        if camera.deviceType.contains("External") { 
            return "camera.on.rectangle" 
        }
        if camera.deviceType.contains("Desk View") { 
            return "camera.macro" 
        }
        return "camera.fill"
    }
}

// MARK: - Overlay Settings Tab

struct OverlaySettingsView: View {
    @EnvironmentObject private var overlayService: OverlayService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Overlay Settings")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            Form {
                Section {
                    Toggle("Enable Overlays", isOn: Binding<Bool>(
                        get: { overlayService.settings.isEnabled },
                        set: { newValue in
                            var updatedSettings = overlayService.settings
                            updatedSettings.isEnabled = newValue
                            overlayService.updateSettings(updatedSettings)
                        }
                    ))
                    .toggleStyle(.checkbox)
                }
                
                if overlayService.settings.isEnabled {
                    Section("Active Preset") {
                        Picker("Preset:", selection: Binding<String>(
                            get: { overlayService.currentPreset?.id ?? "" },
                            set: { presetId in
                                overlayService.selectPreset(presetId)
                            }
                        )) {
                            ForEach(overlayService.availablePresets, id: \.id) { preset in
                                VStack(alignment: .leading) {
                                    Text(preset.name)
                                    if !preset.description.isEmpty {
                                        Text(preset.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tag(preset.id)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        if let currentPreset = overlayService.currentPreset {
                            HStack {
                                Text("Category:")
                                    .foregroundColor(.secondary)
                                Text(currentPreset.category.rawValue.capitalized)
                                    .font(.system(.body))
                            }
                        }
                    }
                    
                    Section("Personal Information") {
                        if let tokens = overlayService.settings.overlayTokens {
                            HStack {
                                Text("Display Name:")
                                    .foregroundColor(.secondary)
                                Text(tokens.displayName.isEmpty ? "Not set" : tokens.displayName)
                            }
                            
                            if let tagline = tokens.tagline {
                                HStack {
                                    Text("Tagline:")
                                        .foregroundColor(.secondary)
                                    Text(tagline)
                                }
                            }
                        } else {
                            Text("Configure in menu bar settings")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Spacer()
        }
    }
}

// MARK: - Updates Settings Tab

struct UpdatesSettingsView: View {
    @EnvironmentObject private var updaterService: UpdaterService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Sparkle's built-in settings UI
            VStack(alignment: .leading, spacing: 16) {
                Text("Update Settings")
                    .font(.headline)
                
                Toggle("Automatically check for updates", isOn: Binding<Bool>(
                    get: { updaterService.controller.updater.automaticallyChecksForUpdates },
                    set: { updaterService.controller.updater.automaticallyChecksForUpdates = $0 }
                ))
                .toggleStyle(.checkbox)
                
                HStack {
                    Button("Check for Updates…") {
                        updaterService.checkForUpdates()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!updaterService.canCheckForUpdates)
                    
                    Spacer()
                }
            }
            .padding()
            
            Spacer()
            
            // Version info at bottom
            HStack {
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
struct SettingsContentView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsContentView()
            .environmentObject(UpdaterService())
    }
}
#endif