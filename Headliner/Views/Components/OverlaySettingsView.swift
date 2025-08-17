//
//  OverlaySettingsView.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct OverlaySettingsView: View {
  @EnvironmentObject var appState: AppState
  @State private var selectedPresetId: String = ""
  @State private var displayName: String = ""
  @State private var tagline: String = ""
  @State private var accentColorHex: String = "#007AFF"
  @State private var selectedAspect: OverlayAspect = .widescreen
  @State private var showColorPicker = false
  
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
                PresetButton(
                  preset: OverlayPresets.professional,
                  isSelected: selectedPresetId == "professional",
                  description: "Lower third with name and title",
                  icon: "person.text.rectangle"
                ) {
                  selectedPresetId = "professional"
                }
                
                PresetButton(
                  preset: OverlayPresets.personal,
                  isSelected: selectedPresetId == "personal",
                  description: "Location, time, and weather info",
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
                
                // Tagline (Professional preset only)
                if selectedPresetId == "professional" {
                  VStack(alignment: .leading, spacing: 8) {
                    Text("Tagline")
                      .font(.subheadline)
                      .foregroundColor(.white.opacity(0.8))
                    
                    TextField("e.g., Senior Developer", text: $tagline)
                      .textFieldStyle(RoundedBorderTextFieldStyle())
                      .background(Color.white.opacity(0.1))
                      .cornerRadius(6)
                  }
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
      // Initialize state from current settings
      selectedPresetId = appState.currentPresetId
      displayName = appState.overlaySettings.overlayTokens?.displayName ?? appState.overlaySettings.userName
      tagline = appState.overlaySettings.overlayTokens?.tagline ?? ""
      accentColorHex = appState.overlaySettings.overlayTokens?.accentColorHex ?? "#007AFF"
      selectedAspect = appState.currentAspectRatio
    }
  }
  
  private func applySettings() {
    // Apply preset selection
    appState.selectPreset(selectedPresetId)
    
    // Apply aspect ratio
    appState.selectAspectRatio(selectedAspect)
    
    // Update tokens if not "none" preset
    if selectedPresetId != "none" {
      let tokens = OverlayTokens(
        displayName: displayName.isEmpty ? NSUserName() : displayName,
        tagline: tagline.isEmpty ? nil : tagline,  // Always save tagline if not empty
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