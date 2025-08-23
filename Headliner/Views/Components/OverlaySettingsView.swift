//
//  OverlaySettingsView.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//
//  ⚠️ TEMPORARILY DISABLED FOR BIG BANG MIGRATION ⚠️
//  This view is heavily dependent on AppState and used in windowed interface.
//  Re-enable after migration complete by removing #if false wrapper.
//

#if false // 🚧 DISABLED DURING BIG BANG MIGRATION - RE-ENABLE LATER

import SwiftUI

struct OverlaySettingsView: View {
  @ObservedObject var appState: AppState
  @State private var selectedPresetId: String = ""
  @State private var displayName: String = ""
  @State private var tagline: String = ""
  @State private var accentColorHex: String = "#007AFF"
  @State private var selectedAspect: OverlayAspect = .widescreen
  @State private var selectedSafeAreaMode: SafeAreaMode = .balanced
  @State private var selectedSurfaceStyle: SurfaceStyle = .rounded
  @State private var showColorPicker = false
  
  init(appState: AppState) {
    self.appState = appState
    // Initialize state from current settings
    self._selectedPresetId = State(initialValue: appState.currentPresetId)
    self._displayName = State(initialValue: appState.overlaySettings.overlayTokens?.displayName ?? appState.overlaySettings.userName)
    self._tagline = State(initialValue: appState.overlaySettings.overlayTokens?.tagline ?? "")
    self._accentColorHex = State(initialValue: appState.overlaySettings.overlayTokens?.accentColorHex ?? "#007AFF")
    self._selectedAspect = State(initialValue: appState.currentAspectRatio)
    self._selectedSafeAreaMode = State(initialValue: appState.overlaySettings.safeAreaMode)
    self._selectedSurfaceStyle = State(initialValue: appState.currentSurfaceStyle)
  }
  
  var body: some View {
    VStack(spacing: 20) {
      // Header
      HStack {
        Text("Overlay Settings")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.white)
        
        Spacer()
        
        Button(action: { appState.isShowingOverlaySettings = false }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.white.opacity(0.6))
            .font(.title2)
        }
        .buttonStyle(PlainButtonStyle())
      }
      
      ScrollView {
        VStack(spacing: 16) {
          // Template Selector
          GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
              Text("Overlay Template")
                .font(.headline)
                .foregroundColor(.white)
              
              // Template selection using new SwiftUI registry
              SwiftUIPresetSelectionView(
                selectedPresetId: $selectedPresetId,
                onSelectionChanged: { presetId in
                  selectedPresetId = presetId
                  updateSetting(\.selectedPresetId, to: presetId)
                }
              )
            }
            .padding()
          }
          
          // Aspect Ratio Selector
          GlassmorphicCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Aspect Ratio")
                .font(.headline)
                .foregroundColor(.white)
              
              HStack(spacing: 12) {
                ForEach(OverlayAspect.allCases, id: \.self) { aspect in
                  Button(action: {
                    selectedAspect = aspect
                    updateSetting(\.overlayAspect, to: aspect)
                  }) {
                    VStack(spacing: 4) {
                      Image(systemName: aspect == .widescreen ? "rectangle.ratio.16.to.9" : "rectangle.ratio.4.to.3")
                        .font(.title2)
                      Text(aspect.displayName)
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                      selectedAspect == aspect
                        ? Color.white.opacity(0.2)
                        : Color.white.opacity(0.05)
                    )
                    .cornerRadius(8)
                    .overlay(
                      RoundedRectangle(cornerRadius: 8)
                        .stroke(
                          selectedAspect == aspect ? Color.white : Color.clear,
                          lineWidth: 1
                        )
                    )
                  }
                  .buttonStyle(PlainButtonStyle())
                  .foregroundColor(.white)
                }
              }
            }
            .padding()
          }
          
          // Safe Area Layout Settings
          GlassmorphicCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Layout")
                .font(.headline)
                .foregroundColor(.white)
              
              Text("Choose how overlays are positioned to ensure visibility across video platforms")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.leading)
              
              Picker("Layout Mode", selection: $selectedSafeAreaMode) {
                ForEach(SafeAreaMode.allCases, id: \.self) { mode in
                  Text(mode.displayName).tag(mode)
                }
              }
              .pickerStyle(SegmentedPickerStyle())
              .background(Color.white.opacity(0.1))
              .cornerRadius(8)
              .onChange(of: selectedSafeAreaMode) { _, newMode in
                updateSetting(\.safeAreaMode, to: newMode)
              }
              
              Text(selectedSafeAreaMode.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.leading)
                .padding(.top, 4)
            }
            .padding()
          }
          
          // Surface Style Settings
          GlassmorphicCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Surface Style")
                .font(.headline)
                .foregroundColor(.white)
              
              Text("Choose between rounded and square corner styles for overlay elements")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.leading)
              
              HStack(spacing: 12) {
                ForEach(SurfaceStyle.allCases, id: \.self) { style in
                  Button(action: {
                    selectedSurfaceStyle = style
                    appState.selectSurfaceStyle(style)
                  }) {
                    VStack(spacing: 8) {
                      // Preview of the style
                      RoundedRectangle(cornerRadius: style == .rounded ? 12 : 0)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 60, height: 40)
                        .overlay(
                          RoundedRectangle(cornerRadius: style == .rounded ? 12 : 0)
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                      
                      Text(style.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                      selectedSurfaceStyle == style
                        ? Color.white.opacity(0.2)
                        : Color.white.opacity(0.05)
                    )
                    .cornerRadius(8)
                    .overlay(
                      RoundedRectangle(cornerRadius: 8)
                        .stroke(
                          selectedSurfaceStyle == style ? Color.white : Color.clear,
                          lineWidth: 1
                        )
                    )
                  }
                  .buttonStyle(PlainButtonStyle())
                  .foregroundColor(.white)
                }
              }
            }
            .padding()
          }
          
          // Customization Options (based on selected preset)
          if selectedPresetId != "none" {
            GlassmorphicCard {
              VStack(alignment: .leading, spacing: 16) {
                Text("Customization")
                  .font(.headline)
                  .foregroundColor(.white)
                
                // Display Name
                VStack(alignment: .leading, spacing: 8) {
                  Text("Display Name")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                  
                  TextField("Enter your name", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Tagline (Available for all presets)
                VStack(alignment: .leading, spacing: 8) {
                  Text("Tagline")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                  
                  TextField("e.g., Senior Developer, Product Manager", text: $tagline)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Accent Color
                VStack(alignment: .leading, spacing: 8) {
                  HStack {
                    Text("Accent Color")
                      .font(.subheadline)
                      .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // Color preview
                    RoundedRectangle(cornerRadius: 4)
                      .fill(Color(hex: accentColorHex) ?? Color.blue)
                      .frame(width: 60, height: 24)
                      .overlay(
                        RoundedRectangle(cornerRadius: 4)
                          .stroke(Color.white.opacity(0.3), lineWidth: 1)
                      )
                  }
                  
                  // Quick color presets
                  HStack(spacing: 8) {
                    ColorButton(hex: "#007AFF", label: "Blue") { accentColorHex = $0 }
                    ColorButton(hex: "#34C759", label: "Green") { accentColorHex = $0 }
                    ColorButton(hex: "#FF3B30", label: "Red") { accentColorHex = $0 }
                    ColorButton(hex: "#FF9500", label: "Orange") { accentColorHex = $0 }
                    ColorButton(hex: "#AF52DE", label: "Purple") { accentColorHex = $0 }
                  }
                }
              }
              .padding()
            }
          }
          
          // Preview Info
          if selectedPresetId != "none" {
            GlassmorphicCard {
              HStack {
                Image(systemName: "info.circle")
                  .foregroundColor(.white.opacity(0.6))
                Text("Your overlay will appear in video conferencing apps when using the Headliner camera")
                  .font(.caption)
                  .foregroundColor(.white.opacity(0.6))
                  .multilineTextAlignment(.leading)
              }
              .padding()
            }
          }
          
          // Action Buttons
          HStack(spacing: 16) {
            ModernButton(
              "Cancel",
              icon: "xmark",
              style: .secondary,
              action: {
                appState.isShowingOverlaySettings = false
              }
            )
            
            ModernButton(
              "Apply",
              icon: "checkmark",
              style: .primary,
              action: {
                applySettings()
                appState.isShowingOverlaySettings = false
              }
            )
          }
          .padding(.top)
        }
        .padding()
      }
    }
    .padding()
    .background(
      AnimatedBackground()
        .clipShape(RoundedRectangle(cornerRadius: 20))
    )
    .onAppear {
      // Refresh state from current settings
      selectedPresetId = appState.currentPresetId
      displayName = appState.overlaySettings.overlayTokens?.displayName ?? appState.overlaySettings.userName
      tagline = appState.overlaySettings.overlayTokens?.tagline ?? ""
      accentColorHex = appState.overlaySettings.overlayTokens?.accentColorHex ?? "#007AFF"
      selectedAspect = appState.currentAspectRatio
      selectedSafeAreaMode = appState.overlaySettings.safeAreaMode
      selectedSurfaceStyle = appState.currentSurfaceStyle
    }
  }
  
  private func applySettings() {
    // Note: Preset selection, aspect ratio, and safe area mode are now applied immediately
    // when changed, so we only need to handle token updates here
    
    // Update tokens if not "none" preset
    if selectedPresetId != "none" {
      let tokens = OverlayTokens(
        displayName: displayName.isEmpty ? NSUserName() : displayName,
        tagline: tagline.isEmpty ? appState.overlaySettings.overlayTokens?.tagline : tagline,  // Preserve existing tagline if field empty
        accentColorHex: accentColorHex
      )
      appState.updateOverlayTokens(tokens)
    }
  }
  
  // MARK: - Helper Functions
  
  /// Update a specific setting property and apply changes immediately
  private func updateSetting<T>(_ keyPath: WritableKeyPath<OverlaySettings, T>, to value: T) {
    var updatedSettings = appState.overlaySettings
    updatedSettings[keyPath: keyPath] = value
    appState.updateOverlaySettings(updatedSettings)
  }

}

// MARK: - Supporting Views



struct ColorButton: View {
  let hex: String
  let label: String
  let onSelect: (String) -> Void
  
  var body: some View {
    Button(action: { onSelect(hex) }) {
      VStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 4)
          .fill(Color(hex: hex) ?? Color.gray)
          .frame(height: 30)
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color.white.opacity(0.3), lineWidth: 1)
          )
        
        Text(label)
          .font(.caption2)
          .foregroundColor(.white.opacity(0.6))
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Note: Color+Hex extension is now in shared Extensions/Color+Hex.swift

#if DEBUG
struct OverlaySettingsView_Previews: PreviewProvider {
  static var previews: some View {
    OverlaySettingsView(appState: AppState(
      systemExtensionManager: SystemExtensionRequestManager(logText: ""),
      propertyManager: CustomPropertyManager(),
      outputImageManager: OutputImageManager()
    ))
    .frame(width: 600, height: 700)
    .background(Color.black)
  }
}
#endif

#endif // 🚧 END DISABLED SECTION - Re-enable after Big Bang Migration complete
