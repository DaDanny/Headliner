//
//  OverlaySettingsView.swift
//  Headliner
//
//  Modern overlay settings with live preview
//

import SwiftUI

struct OverlaySettingsView: View {
  @ObservedObject var appState: AppState
  @State private var selectedPresetId: String = ""
  @State private var displayName: String = ""
  @State private var tagline: String = ""
  @State private var accentColorHex: String = "#007AFF"
  @State private var selectedAspect: OverlayAspect = .widescreen
  
  init(appState: AppState) {
    self.appState = appState
    self._selectedPresetId = State(initialValue: appState.currentPresetId)
    self._displayName = State(initialValue: appState.overlaySettings.overlayTokens?.displayName ?? appState.overlaySettings.userName)
    self._tagline = State(initialValue: appState.overlaySettings.overlayTokens?.tagline ?? "")
    self._accentColorHex = State(initialValue: appState.overlaySettings.overlayTokens?.accentColorHex ?? "#007AFF")
    self._selectedAspect = State(initialValue: appState.currentAspectRatio)
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
          // Preset Selector
          GlassmorphicCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Overlay Preset")
                .font(.headline)
                .foregroundColor(.white)
              
              VStack(spacing: 8) {
                // Modern Presets
                Group {
                  Text("Modern Overlays")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                  
                  PresetButton(
                    preset: OverlayPresets.modernProfessional,
                    isSelected: selectedPresetId == "modern_professional",
                    description: "Enhanced lower third with modern styling",
                    icon: "person.text.rectangle.fill"
                  ) {
                    selectedPresetId = "modern_professional"
                  }
                  
                  PresetButton(
                    preset: OverlayPresets.modernPersonal,
                    isSelected: selectedPresetId == "modern_personal",
                    description: "Elegant info pill with enhanced design",
                    icon: "location.circle.fill"
                  ) {
                    selectedPresetId = "modern_personal"
                  }
                  
                  PresetButton(
                    preset: OverlayPresets.modernSideAccent,
                    isSelected: selectedPresetId == "modern_side_accent",
                    description: "Side accent bar with modern typography",
                    icon: "rectangle.leadinghalf.filled"
                  ) {
                    selectedPresetId = "modern_side_accent"
                  }
                  
                  PresetButton(
                    preset: OverlayPresets.modernMinimal,
                    isSelected: selectedPresetId == "modern_minimal",
                    description: "Clean minimal design with subtle background",
                    icon: "capsule.fill"
                  ) {
                    selectedPresetId = "modern_minimal"
                  }
                }
                
                // Classic Presets
                Group {
                  Text("Classic Overlays")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                  
                  PresetButton(
                    preset: OverlayPresets.professional,
                    isSelected: selectedPresetId == "professional",
                    description: "Classic lower third design",
                    icon: "person.text.rectangle"
                  ) {
                    selectedPresetId = "professional"
                  }
                  
                  PresetButton(
                    preset: OverlayPresets.personal,
                    isSelected: selectedPresetId == "personal",
                    description: "Basic location and weather info",
                    icon: "location.circle"
                  ) {
                    selectedPresetId = "personal"
                  }
                  
                  PresetButton(
                    preset: OverlayPresets.none,
                    isSelected: selectedPresetId == "none",
                    description: "Clean video without overlays",
                    icon: "video"
                  ) {
                    selectedPresetId = "none"
                  }
                }
              }
            }
            .padding()
          }
          
          // Customization Options
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
                }
                
                // Tagline (for professional presets)
                if selectedPresetId == "professional" || selectedPresetId == "modern_professional" || selectedPresetId == "modern_side_accent" {
                  VStack(alignment: .leading, spacing: 8) {
                    Text("Tagline")
                      .font(.subheadline)
                      .foregroundColor(.white.opacity(0.8))
                    
                    TextField("e.g., Senior Developer", text: $tagline)
                      .textFieldStyle(RoundedBorderTextFieldStyle())
                  }
                }
                
                // Accent Color
                VStack(alignment: .leading, spacing: 8) {
                  Text("Accent Color")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                  
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
      selectedPresetId = appState.currentPresetId
      displayName = appState.overlaySettings.overlayTokens?.displayName ?? appState.overlaySettings.userName
      tagline = appState.overlaySettings.overlayTokens?.tagline ?? ""
      accentColorHex = appState.overlaySettings.overlayTokens?.accentColorHex ?? "#007AFF"
      selectedAspect = appState.currentAspectRatio
    }
  }
  
  private func applySettings() {
    appState.selectPreset(selectedPresetId)
    appState.selectAspectRatio(selectedAspect)
    
    if selectedPresetId != "none" {
      let tokens = OverlayTokens(
        displayName: displayName.isEmpty ? NSUserName() : displayName,
        tagline: tagline.isEmpty ? nil : tagline,
        accentColorHex: accentColorHex,
        aspect: selectedAspect
      )
      appState.updateOverlayTokens(tokens)
    }
  }
}

// MARK: - Supporting Views

struct PresetButton: View {
  let preset: OverlayPreset
  let isSelected: Bool
  let description: String
  let icon: String
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.title2)
          .foregroundColor(isSelected ? .white : .white.opacity(0.6))
          .frame(width: 32)
        
        VStack(alignment: .leading, spacing: 2) {
          Text(preset.name)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(.white)
          
          Text(description)
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))
        }
        
        Spacer()
        
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.white)
        }
      }
      .padding()
      .background(
        isSelected
          ? Color.white.opacity(0.15)
          : Color.white.opacity(0.05)
      )
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

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

// MARK: - Color Extension

extension Color {
  init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
    
    var rgb: UInt64 = 0
    
    guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
    
    let length = hexSanitized.count
    if length == 6 {
      let r = Double((rgb & 0xFF0000) >> 16) / 255.0
      let g = Double((rgb & 0x00FF00) >> 8) / 255.0
      let b = Double(rgb & 0x0000FF) / 255.0
      self.init(red: r, green: g, blue: b)
    } else if length == 8 {
      let r = Double((rgb & 0xFF000000) >> 24) / 255.0
      let g = Double((rgb & 0x00FF0000) >> 16) / 255.0
      let b = Double((rgb & 0x0000FF00) >> 8) / 255.0
      let a = Double(rgb & 0x000000FF) / 255.0
      self.init(red: r, green: g, blue: b, opacity: a)
    } else {
      return nil
    }
  }
}

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