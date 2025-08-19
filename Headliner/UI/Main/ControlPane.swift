//
//  ControlPane.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

// MARK: - Control Pane

struct ControlPane: View {
  @ObservedObject var appState: AppState
  @ObservedObject var propertyManager: CustomPropertyManager
  
  @State private var isCameraSettingsExpanded = false
  @State private var isAdvancedExpanded = false
  
  var body: some View {
    ScrollView {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Quick Start Card
        quickStartCard
        
        // Look Preset Card
        lookPresetCard
        
        // Position and Branding Card
        positionAndBrandingCard
        
        // Camera Settings (Collapsible)
        cameraSettingsCard
        
        // Advanced Settings (Collapsible)
        advancedSettingsCard
        
        Spacer(minLength: DesignTokens.Spacing.xxl)
      }
    }
  }
  
  // MARK: - Quick Start Card
  
  private var quickStartCard: some View {
    SectionedCard(title: "Quick Start") {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Camera Source
        cameraSourceSelector
        
        // Primary Start/Stop Button
        startStopButton
        
        // Stream Status
        CameraStatusBadge(status: appState.cameraStatus)
      }
    }
  }
  
  private var cameraSourceSelector: some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
      Text("Camera Source")
        .font(DesignTokens.Typography.bodyFont)
        .foregroundColor(DesignTokens.Colors.textSecondary)
      
      Menu {
        ForEach(appState.availableCameras) { camera in
          Button(action: { appState.selectCamera(camera) }) {
            HStack {
              Text(camera.name)
              if camera.id == appState.selectedCameraID {
                Spacer()
                Image(systemName: "checkmark")
              }
            }
          }
        }
        
        if appState.availableCameras.isEmpty {
          Text("No cameras found")
            .foregroundColor(DesignTokens.Colors.textTertiary)
        }
      } label: {
        HStack {
          Text(selectedCameraName)
            .font(DesignTokens.Typography.bodyFont)
            .foregroundColor(DesignTokens.Colors.textPrimary)
          
          Spacer()
          
          Image(systemName: "chevron.down")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(DesignTokens.Colors.textTertiary)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
          RoundedRectangle(cornerRadius: DesignTokens.Components.Field.radius)
            .fill(DesignTokens.Components.Field.background)
            .overlay(
              RoundedRectangle(cornerRadius: DesignTokens.Components.Field.radius)
                .stroke(DesignTokens.Components.Field.stroke, lineWidth: 1)
            )
        )
      }
      .menuStyle(BorderlessButtonMenuStyle())
    }
  }
  
  private var startStopButton: some View {
    HeadlinerButton(
      appState.cameraStatus.isRunning ? "Stop Camera" : "Start Camera",
      icon: appState.cameraStatus.isRunning ? "stop.fill" : "video",
      variant: appState.cameraStatus.isRunning ? .danger : .primary,
      isLoading: appState.cameraStatus == .starting || appState.cameraStatus == .stopping
    ) {
      if appState.cameraStatus.isRunning {
        appState.stopCamera()
      } else {
        appState.startCamera()
      }
    }
  }
  
  // MARK: - Look Preset Card
  
  private var lookPresetCard: some View {
    SectionedCard(title: "Look Preset") {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Preset Selector
        presetSegmentedControl
        
        // Customize Button
        HeadlinerButton(
          "Customize…",
          icon: "slider.horizontal.3",
          variant: .secondary,
          size: .regular
        ) {
          appState.isShowingOverlaySettings = true
        }
      }
    }
  }
  
  private var presetSegmentedControl: some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
      Text("Style")
        .font(DesignTokens.Typography.bodyFont)
        .foregroundColor(DesignTokens.Colors.textSecondary)
      
      VStack(spacing: DesignTokens.Spacing.xs) {
        HStack(spacing: DesignTokens.Spacing.xs) {
          presetButton("clean", "Clean")
          presetButton("nameTag", "Name Tag")
          presetButton("nameTitle", "Name+Title")
        }
        
        HStack(spacing: DesignTokens.Spacing.xs) {
          presetButton("lowerThird", "Lower Third")
          presetButton("minimal", "Minimal")
          Spacer()
        }
      }
    }
  }
  
  private func presetButton(_ presetId: String, _ title: String) -> some View {
    let isSelected = appState.currentPresetId == presetId
    
    return Button(action: { appState.selectPreset(presetId) }) {
      Text(title)
        .font(.system(size: DesignTokens.Typography.Sizes.sm, weight: .medium))
        .foregroundColor(isSelected ? DesignTokens.Colors.onAccent : DesignTokens.Colors.textSecondary)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
          RoundedRectangle(cornerRadius: DesignTokens.Components.Segmented.radius)
            .fill(isSelected ? DesignTokens.Components.Segmented.highlight : Color.clear)
        )
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
  
  // MARK: - Position and Branding Card
  
  private var positionAndBrandingCard: some View {
    SectionedCard(title: "Position & Branding") {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Position Grid
        positionGrid
        
        // Brand Colors
        brandColorSwatches
      }
    }
  }
  
  private var positionGrid: some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
      Text("Position")
        .font(DesignTokens.Typography.bodyFont)
        .foregroundColor(DesignTokens.Colors.textSecondary)
      
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
        ForEach(OverlayPosition.allCases, id: \.self) { position in
          positionGridButton(position)
        }
      }
    }
  }
  
  private func positionGridButton(_ position: OverlayPosition) -> some View {
    let isSelected = appState.overlaySettings.namePosition == position
    
    return Button(action: { updatePosition(position) }) {
      RoundedRectangle(cornerRadius: DesignTokens.Spacing.sm)
        .fill(isSelected ? DesignTokens.Colors.accent.opacity(0.2) : DesignTokens.Components.Field.background)
        .overlay(
          RoundedRectangle(cornerRadius: DesignTokens.Spacing.sm)
            .stroke(
              isSelected ? DesignTokens.Colors.accent : DesignTokens.Components.Field.stroke,
              lineWidth: isSelected ? 2 : 1
            )
        )
        .frame(height: 32)
        .overlay(
          Circle()
            .fill(isSelected ? DesignTokens.Colors.accent : DesignTokens.Colors.textTertiary)
            .frame(width: 8, height: 8)
            .position(position.gridPosition)
        )
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityLabel(position.displayName)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
  
  private var brandColorSwatches: some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
      Text("Brand Color")
        .font(DesignTokens.Typography.bodyFont)
        .foregroundColor(DesignTokens.Colors.textSecondary)
      
      HStack(spacing: DesignTokens.Spacing.sm) {
        colorSwatch(DesignTokens.Colors.brandPrimary, "#118342")
        colorSwatch(DesignTokens.Colors.accent, "#7C8CF8")
        colorSwatch(DesignTokens.Colors.success, "#2BD17E")
        
        // Custom color picker
        ColorPicker("", selection: .constant(Color.blue))
          .labelsHidden()
          .frame(width: 32, height: 32)
          .clipShape(Circle())
          .overlay(
            Circle()
              .stroke(DesignTokens.Colors.stroke, lineWidth: 1)
          )
          .accessibilityLabel("Custom color")
      }
    }
  }
  
  private func colorSwatch(_ color: Color, _ hex: String) -> some View {
    let isSelected = appState.overlaySettings.overlayTokens?.accentColorHex == hex
    
    return Button(action: { updateBrandColor(hex) }) {
      Circle()
        .fill(color)
        .frame(width: 32, height: 32)
        .overlay(
          Circle()
            .stroke(isSelected ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.stroke, lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(DesignTokens.Animations.spring, value: isSelected)
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityLabel("Color swatch")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
  
  // MARK: - Camera Settings Card
  
  private var cameraSettingsCard: some View {
    CollapsibleCard(title: "Camera Settings", isExpanded: $isCameraSettingsExpanded) {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Device Settings Button
        HeadlinerButton(
          "Device Settings",
          icon: "gear",
          variant: .secondary,
          size: .compact
        ) {
          // TODO: Open device settings
        }
        
        // Mirror Toggle
        mirrorToggle
        
        // Zoom Slider (placeholder)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
          Text("Zoom")
            .font(DesignTokens.Typography.bodyFont)
            .foregroundColor(DesignTokens.Colors.textSecondary)
          
          Slider(value: .constant(1.0), in: 1.0...3.0)
            .accentColor(DesignTokens.Colors.accent)
        }
      }
    }
  }
  
  private var mirrorToggle: some View {
    HStack {
      Text("Mirror Video")
        .font(DesignTokens.Typography.bodyFont)
        .foregroundColor(DesignTokens.Colors.textSecondary)
      
      Spacer()
      
      Toggle("", isOn: .constant(false))
        .toggleStyle(SwitchToggleStyle(tint: DesignTokens.Colors.accent))
    }
  }
  
  // MARK: - Advanced Settings Card
  
  private var advancedSettingsCard: some View {
    CollapsibleCard(title: "Advanced", isExpanded: $isAdvancedExpanded) {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Frame Rate Selector
        settingsRow("Frame Rate", value: "30 fps")
        
        // Resolution Selector
        settingsRow("Resolution", value: "1080p")
        
        // Background Blur Toggle
        HStack {
          Text("Background Blur")
            .font(DesignTokens.Typography.bodyFont)
            .foregroundColor(DesignTokens.Colors.textSecondary)
          
          Spacer()
          
          Toggle("", isOn: .constant(false))
            .toggleStyle(SwitchToggleStyle(tint: DesignTokens.Colors.accent))
        }
      }
    }
  }
  
  private func settingsRow(_ title: String, value: String) -> some View {
    HStack {
      Text(title)
        .font(DesignTokens.Typography.bodyFont)
        .foregroundColor(DesignTokens.Colors.textSecondary)
      
      Spacer()
      
      Text(value)
        .font(DesignTokens.Typography.bodyFont)
        .foregroundColor(DesignTokens.Colors.textPrimary)
    }
  }
  
  // MARK: - Helper Properties
  
  private var selectedCameraName: String {
    if let selectedCamera = appState.availableCameras.first(where: { $0.id == appState.selectedCameraID }) {
      return selectedCamera.name
    }
    return appState.availableCameras.first?.name ?? "No Camera"
  }
  
  // MARK: - Actions
  
  private func updatePosition(_ position: OverlayPosition) {
    var newSettings = appState.overlaySettings
    newSettings.namePosition = position
    appState.updateOverlaySettings(newSettings)
  }
  
  private func updateBrandColor(_ hex: String) {
    var newSettings = appState.overlaySettings
    if newSettings.overlayTokens == nil {
      newSettings.overlayTokens = OverlayTokens(
        displayName: newSettings.userName.isEmpty ? NSUserName() : newSettings.userName,
        accentColorHex: hex,
        aspect: newSettings.overlayAspect
      )
    } else {
      newSettings.overlayTokens?.accentColorHex = hex
    }
    appState.updateOverlaySettings(newSettings)
  }
}

// MARK: - Overlay Position Extension

extension OverlayPosition {
  var displayName: String {
    switch self {
    case .topLeft: return "Top Left"
    case .topCenter: return "Top Center"
    case .topRight: return "Top Right"
    case .centerLeft: return "Center Left"
    case .center: return "Center"
    case .centerRight: return "Center Right"
    case .bottomLeft: return "Bottom Left"
    case .bottomCenter: return "Bottom Center"
    case .bottomRight: return "Bottom Right"
    }
  }
  
  var gridPosition: CGPoint {
    let width: CGFloat = 32
    let height: CGFloat = 32
    let padding: CGFloat = 4
    
    switch self {
    case .topLeft: return CGPoint(x: padding, y: padding)
    case .topCenter: return CGPoint(x: width/2, y: padding)
    case .topRight: return CGPoint(x: width-padding, y: padding)
    case .centerLeft: return CGPoint(x: padding, y: height/2)
    case .center: return CGPoint(x: width/2, y: height/2)
    case .centerRight: return CGPoint(x: width-padding, y: height/2)
    case .bottomLeft: return CGPoint(x: padding, y: height-padding)
    case .bottomCenter: return CGPoint(x: width/2, y: height-padding)
    case .bottomRight: return CGPoint(x: width-padding, y: height-padding)
    }
  }
}

// MARK: - Preview

#if DEBUG
struct ControlPane_Previews: PreviewProvider {
  static var previews: some View {
    ControlPane(
      appState: PreviewsSupport.mockAppState,
      propertyManager: PreviewsSupport.mockPropertyManager
    )
    .frame(width: DesignTokens.Layout.sidebarWidth)
    .padding(DesignTokens.Spacing.xxl)
    .background(DesignTokens.Colors.surface)
  }
}
#endif