//
//  OverlayDesignerSheet.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

// MARK: - Overlay Designer Sheet

struct OverlayDesignerSheet: View {
  @ObservedObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  
  @State private var workingSettings: OverlaySettings
  @State private var isPreviewMode = false
  
  init(appState: AppState) {
    self.appState = appState
    self._workingSettings = State(initialValue: appState.overlaySettings)
  }
  
  var body: some View {
    VStack(spacing: 0) {
      // Header
      header
      
      // Content Split
      HStack(spacing: 0) {
        // Live Preview
        previewSection
          .frame(maxWidth: .infinity)
        
        // Separator
        Rectangle()
          .fill(DesignTokens.Colors.stroke)
          .frame(width: 1)
        
        // Controls
        controlsSection
          .frame(width: 320)
      }
      .frame(maxHeight: .infinity)
      
      // Footer
      footer
    }
    .background(DesignTokens.Colors.surface)
    .frame(width: 800, height: 600)
    .onAppear {
      workingSettings = appState.overlaySettings
    }
  }
  
  // MARK: - Header
  
  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Overlay Designer")
          .font(DesignTokens.Typography.titleFont)
          .foregroundColor(DesignTokens.Colors.textPrimary)
        
        Text("Customize your overlay appearance")
          .font(DesignTokens.Typography.bodyFont)
          .foregroundColor(DesignTokens.Colors.textSecondary)
      }
      
      Spacer()
      
      HStack(spacing: DesignTokens.Spacing.md) {
        // Preview mode toggle
        HeadlinerButton(
          isPreviewMode ? "Edit" : "Preview",
          icon: isPreviewMode ? "slider.horizontal.3" : "eye",
          variant: .secondary,
          size: .compact
        ) {
          isPreviewMode.toggle()
        }
        
        // Close button
        HeadlinerButton(
          "",
          icon: "xmark",
          variant: .ghost,
          size: .compact
        ) {
          dismiss()
        }
        .accessibilityLabel("Close")
      }
    }
    .padding(.horizontal, DesignTokens.Spacing.xxl)
    .padding(.vertical, DesignTokens.Spacing.lg)
    .background(DesignTokens.Colors.surface)
    .overlay(
      Rectangle()
        .fill(DesignTokens.Colors.stroke)
        .frame(height: 1),
      alignment: .bottom
    )
  }
  
  // MARK: - Preview Section
  
  private var previewSection: some View {
    VStack(spacing: DesignTokens.Spacing.lg) {
      // Preview Header
      HStack {
        Text("Live Preview")
          .font(DesignTokens.Typography.font(size: DesignTokens.Typography.Sizes.lg, weight: .semibold))
          .foregroundColor(DesignTokens.Colors.textPrimary)
        
        Spacer()
        
        if workingSettings.isEnabled {
          HeadlinerBadge("ON", variant: .success, size: .small)
        } else {
          HeadlinerBadge("OFF", variant: .neutral, size: .small)
        }
      }
      
      // Preview Frame
      GeometryReader { geometry in
        ZStack {
          // Background (simulating video)
          RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
            .fill(
              LinearGradient(
                colors: [
                  Color(hex: "#4A90E2"),
                  Color(hex: "#357ABD"),
                  Color(hex: "#2E5984")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
          
          // Sample person silhouette
          VStack {
            Spacer()
            HStack {
              Spacer()
              Image(systemName: "person.fill")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.white.opacity(0.3))
              Spacer()
            }
            Spacer()
          }
          
          // Overlay Preview
          if workingSettings.isEnabled {
            overlayPreview(in: geometry)
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
      }
      .aspectRatio(16/9, contentMode: .fit)
      .frame(maxHeight: 300)
    }
    .padding(DesignTokens.Spacing.xxl)
  }
  
  // MARK: - Overlay Preview
  
  private func overlayPreview(in geometry: GeometryProxy) -> some View {
    VStack {
      if workingSettings.namePosition.isTop {
        overlayContent
        Spacer()
      } else if workingSettings.namePosition.isCenter {
        Spacer()
        overlayContent
        Spacer()
      } else {
        Spacer()
        overlayContent
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  private var overlayContent: some View {
    HStack {
      if workingSettings.namePosition.isLeft {
        overlayCard
        Spacer()
      } else if workingSettings.namePosition.isCenter {
        Spacer()
        overlayCard
        Spacer()
      } else {
        Spacer()
        overlayCard
      }
    }
  }
  
  private var overlayCard: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Display Name
      Text(workingSettings.overlayTokens?.displayName ?? workingSettings.userName)
        .font(.system(size: CGFloat(workingSettings.fontSize), weight: .semibold))
        .foregroundColor(.white)
      
      // Tagline (if present)
      if let tagline = workingSettings.overlayTokens?.tagline, !tagline.isEmpty {
        Text(tagline)
          .font(.system(size: CGFloat(workingSettings.fontSize) * 0.8, weight: .medium))
          .foregroundColor(.white.opacity(0.8))
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.black.opacity(0.7))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(
              Color(hex: workingSettings.overlayTokens?.accentColorHex ?? "#007AFF"),
              lineWidth: 2
            )
        )
    )
  }
  
  // MARK: - Controls Section
  
  private var controlsSection: some View {
    ScrollView {
      VStack(spacing: DesignTokens.Spacing.lg) {
        if !isPreviewMode {
          // Enable/Disable Toggle
          enableToggleSection
          
          // Basic Settings
          basicSettingsSection
          
          // Position Settings
          positionSettingsSection
          
          // Style Settings
          styleSettingsSection
          
          // Advanced Settings
          advancedSettingsSection
        } else {
          // Preview mode - show controls overlay
          VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Preview Mode")
              .font(DesignTokens.Typography.titleFont)
              .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("See how your overlay will appear in the video feed. Click 'Edit' to return to customization.")
              .font(DesignTokens.Typography.bodyFont)
              .foregroundColor(DesignTokens.Colors.textSecondary)
              .multilineTextAlignment(.center)
          }
          .padding(DesignTokens.Spacing.xxl)
        }
      }
    }
    .padding(DesignTokens.Spacing.lg)
  }
  
  // MARK: - Enable Toggle Section
  
  private var enableToggleSection: some View {
    HeadlinerCard {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Enable Overlay")
            .font(DesignTokens.Typography.font(size: DesignTokens.Typography.Sizes.lg, weight: .semibold))
            .foregroundColor(DesignTokens.Colors.textPrimary)
          
          Text("Show overlay on video feed")
            .font(DesignTokens.Typography.bodyFont)
            .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        
        Spacer()
        
        Toggle("", isOn: Binding(
          get: { workingSettings.isEnabled },
          set: { workingSettings.isEnabled = $0; updateSettings() }
        ))
        .toggleStyle(SwitchToggleStyle(tint: DesignTokens.Colors.accent))
      }
    }
  }
  
  // MARK: - Basic Settings Section
  
  private var basicSettingsSection: some View {
    SectionedCard(title: "Basic Settings") {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Display Name
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
          Text("Display Name")
            .font(DesignTokens.Typography.bodyFont)
            .foregroundColor(DesignTokens.Colors.textSecondary)
          
          TextField("Enter your name", text: Binding(
            get: { workingSettings.overlayTokens?.displayName ?? workingSettings.userName },
            set: { newValue in
              if workingSettings.overlayTokens == nil {
                workingSettings.overlayTokens = OverlayTokens(
                  displayName: newValue,
                  accentColorHex: "#007AFF",
                  aspect: workingSettings.overlayAspect
                )
              } else {
                workingSettings.overlayTokens?.displayName = newValue
              }
              workingSettings.userName = newValue
              updateSettings()
            }
          ))
          .textFieldStyle(.roundedBorder)
        }
        
        // Tagline
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
          Text("Tagline (Optional)")
            .font(DesignTokens.Typography.bodyFont)
            .foregroundColor(DesignTokens.Colors.textSecondary)
          
          TextField("e.g., Senior Developer", text: Binding(
            get: { workingSettings.overlayTokens?.tagline ?? "" },
            set: { newValue in
              if workingSettings.overlayTokens == nil {
                workingSettings.overlayTokens = OverlayTokens(
                  displayName: workingSettings.userName,
                  tagline: newValue.isEmpty ? nil : newValue,
                  accentColorHex: "#007AFF",
                  aspect: workingSettings.overlayAspect
                )
              } else {
                workingSettings.overlayTokens?.tagline = newValue.isEmpty ? nil : newValue
              }
              updateSettings()
            }
          ))
          .textFieldStyle(.roundedBorder)
        }
      }
    }
  }
  
  // MARK: - Position Settings Section
  
  private var positionSettingsSection: some View {
    SectionedCard(title: "Position") {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
        ForEach(OverlayPosition.allCases, id: \.self) { position in
          positionButton(position)
        }
      }
    }
  }
  
  private func positionButton(_ position: OverlayPosition) -> some View {
    let isSelected = workingSettings.namePosition == position
    
    return Button(action: {
      workingSettings.namePosition = position
      updateSettings()
    }) {
      VStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 6)
          .fill(isSelected ? DesignTokens.Colors.accent.opacity(0.2) : DesignTokens.Components.Field.background)
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(
                isSelected ? DesignTokens.Colors.accent : DesignTokens.Components.Field.stroke,
                lineWidth: isSelected ? 2 : 1
              )
          )
          .frame(height: 40)
          .overlay(
            Circle()
              .fill(isSelected ? DesignTokens.Colors.accent : DesignTokens.Colors.textTertiary)
              .frame(width: 6, height: 6)
              .position(position.gridPositionForPreview)
          )
        
        Text(position.shortDisplayName)
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(isSelected ? DesignTokens.Colors.accent : DesignTokens.Colors.textSecondary)
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
  
  // MARK: - Style Settings Section
  
  private var styleSettingsSection: some View {
    SectionedCard(title: "Style") {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Font Size
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
          HStack {
            Text("Font Size")
              .font(DesignTokens.Typography.bodyFont)
              .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            Text("\(workingSettings.fontSize)")
              .font(DesignTokens.Typography.bodyFont)
              .foregroundColor(DesignTokens.Colors.textPrimary)
          }
          
          Slider(
            value: Binding(
              get: { Double(workingSettings.fontSize) },
              set: { workingSettings.fontSize = Int($0); updateSettings() }
            ),
            in: 12...32,
            step: 2
          )
          .accentColor(DesignTokens.Colors.accent)
        }
        
        // Accent Color
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
          Text("Accent Color")
            .font(DesignTokens.Typography.bodyFont)
            .foregroundColor(DesignTokens.Colors.textSecondary)
          
          HStack(spacing: DesignTokens.Spacing.sm) {
            colorSwatch(DesignTokens.Colors.brandPrimary, "#118342")
            colorSwatch(DesignTokens.Colors.accent, "#7C8CF8")
            colorSwatch(DesignTokens.Colors.success, "#2BD17E")
            colorSwatch(Color(hex: "#FF6B6B"), "#FF6B6B")
            
            // Custom color picker
            ColorPicker("", selection: Binding(
              get: { Color(hex: workingSettings.overlayTokens?.accentColorHex ?? "#007AFF") },
              set: { color in
                let hex = color.hexString
                if workingSettings.overlayTokens == nil {
                  workingSettings.overlayTokens = OverlayTokens(
                    displayName: workingSettings.userName,
                    accentColorHex: hex,
                    aspect: workingSettings.overlayAspect
                  )
                } else {
                  workingSettings.overlayTokens?.accentColorHex = hex
                }
                updateSettings()
              }
            ))
            .labelsHidden()
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(
              Circle()
                .stroke(DesignTokens.Colors.stroke, lineWidth: 1)
            )
          }
        }
      }
    }
  }
  
  private func colorSwatch(_ color: Color, _ hex: String) -> some View {
    let isSelected = workingSettings.overlayTokens?.accentColorHex == hex
    
    return Button(action: {
      if workingSettings.overlayTokens == nil {
        workingSettings.overlayTokens = OverlayTokens(
          displayName: workingSettings.userName,
          accentColorHex: hex,
          aspect: workingSettings.overlayAspect
        )
      } else {
        workingSettings.overlayTokens?.accentColorHex = hex
      }
      updateSettings()
    }) {
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
  }
  
  // MARK: - Advanced Settings Section
  
  private var advancedSettingsSection: some View {
    SectionedCard(title: "Advanced") {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Background Opacity
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
          HStack {
            Text("Background Opacity")
              .font(DesignTokens.Typography.bodyFont)
              .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            Text("\(Int(workingSettings.backgroundOpacity * 100))%")
              .font(DesignTokens.Typography.bodyFont)
              .foregroundColor(DesignTokens.Colors.textPrimary)
          }
          
          Slider(
            value: Binding(
              get: { workingSettings.backgroundOpacity },
              set: { workingSettings.backgroundOpacity = $0; updateSettings() }
            ),
            in: 0.3...1.0,
            step: 0.1
          )
          .accentColor(DesignTokens.Colors.accent)
        }
        
        // Corner Radius
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
          HStack {
            Text("Corner Radius")
              .font(DesignTokens.Typography.bodyFont)
              .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            Text("\(Int(workingSettings.cornerRadius))")
              .font(DesignTokens.Typography.bodyFont)
              .foregroundColor(DesignTokens.Colors.textPrimary)
          }
          
          Slider(
            value: Binding(
              get: { workingSettings.cornerRadius },
              set: { workingSettings.cornerRadius = $0; updateSettings() }
            ),
            in: 0...20,
            step: 2
          )
          .accentColor(DesignTokens.Colors.accent)
        }
      }
    }
  }
  
  // MARK: - Footer
  
  private var footer: some View {
    HStack {
      // Reset button
      HeadlinerButton(
        "Reset to Defaults",
        icon: "arrow.counterclockwise",
        variant: .ghost
      ) {
        resetToDefaults()
      }
      
      Spacer()
      
      HStack(spacing: DesignTokens.Spacing.md) {
        // Cancel button
        HeadlinerButton(
          "Cancel",
          variant: .secondary
        ) {
          dismiss()
        }
        
        // Apply button
        HeadlinerButton(
          "Apply",
          icon: "checkmark",
          variant: .primary
        ) {
          applyChanges()
        }
      }
    }
    .padding(.horizontal, DesignTokens.Spacing.xxl)
    .padding(.vertical, DesignTokens.Spacing.lg)
    .background(DesignTokens.Colors.surface)
    .overlay(
      Rectangle()
        .fill(DesignTokens.Colors.stroke)
        .frame(height: 1),
      alignment: .top
    )
  }
  
  // MARK: - Actions
  
  private func updateSettings() {
    // Real-time preview update
    appState.updateOverlaySettings(workingSettings)
  }
  
  private func applyChanges() {
    appState.updateOverlaySettings(workingSettings)
    dismiss()
  }
  
  private func resetToDefaults() {
    workingSettings = OverlaySettings()
    updateSettings()
  }
}

// MARK: - Extensions

extension OverlayPosition {
  var shortDisplayName: String {
    switch self {
    case .topLeft: return "TL"
    case .topCenter: return "TC"
    case .topRight: return "TR"
    case .centerLeft: return "CL"
    case .center: return "CC"
    case .centerRight: return "CR"
    case .bottomLeft: return "BL"
    case .bottomCenter: return "BC"
    case .bottomRight: return "BR"
    }
  }
  
  var gridPositionForPreview: CGPoint {
    let width: CGFloat = 40
    let height: CGFloat = 40
    let padding: CGFloat = 6
    
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
  
  var isTop: Bool {
    switch self {
    case .topLeft, .topCenter, .topRight: return true
    default: return false
    }
  }
  
  var isCenter: Bool {
    switch self {
    case .centerLeft, .center, .centerRight: return true
    default: return false
    }
  }
  
  var isLeft: Bool {
    switch self {
    case .topLeft, .centerLeft, .bottomLeft: return true
    default: return false
    }
  }
}

extension Color {
  var hexString: String {
    let components = self.cgColor?.components ?? [0, 0, 0, 1]
    let r = Int(components[0] * 255)
    let g = Int(components[1] * 255)
    let b = Int(components[2] * 255)
    return String(format: "#%02X%02X%02X", r, g, b)
  }
}

// MARK: - Preview

#if DEBUG
struct OverlayDesignerSheet_Previews: PreviewProvider {
  static var previews: some View {
    OverlayDesignerSheet(appState: PreviewsSupport.mockAppState)
  }
}
#endif