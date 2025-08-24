//
//  MenuContent.swift
//  Headliner
//
//  Created by AI Assistant on 8/22/25.
//

import SwiftUI

/// Navigation destination for menu bar views
enum MenuDestination {
  case main
  case overlaySettings
  case settings
}

/// Main content view for the menu bar popup with navigation
struct MenuContent: View {
  let appCoordinator: AppCoordinator  // Just hold reference, don't observe
  @Environment(\.openURL) private var openURL
  @State private var showingPreview = false
  @State private var currentDestination: MenuDestination = .main
  
  // Main constructor
  init(appCoordinator: AppCoordinator) {
    self.appCoordinator = appCoordinator
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Group {
        switch currentDestination {
        case .main:
          MainMenuView(
            appCoordinator: appCoordinator,
            showingPreview: $showingPreview,
            navigateTo: { destination in
              withAnimation(.easeInOut(duration: 0.3)) {
                currentDestination = destination
              }
            }
          )
          .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
          ))
          
        case .overlaySettings:
          OverlaySettingsMenu(
            appCoordinator: appCoordinator,
            onBack: {
              withAnimation(.easeInOut(duration: 0.3)) {
                currentDestination = .main
              }
            }
          )
          .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
          ))
          
        case .settings:
          SettingsMenuView(
            appCoordinator: appCoordinator,
            onBack: {
              withAnimation(.easeInOut(duration: 0.3)) {
                currentDestination = .main
              }
            }
          )
          .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
          ))
        }
      }
    }
    .frame(width: 320) // Fixed width for consistent appearance
    .background(Color(.controlBackgroundColor))
    .clipped() // Ensure transitions don't go outside bounds
  }
}

// MARK: - Main Menu View

/// The main menu content (what you see first)
struct MainMenuView: View {
  let appCoordinator: AppCoordinator  // Just hold reference for delegation
  @EnvironmentObject private var cameraService: CameraService
  @EnvironmentObject private var extensionService: ExtensionService
  @EnvironmentObject private var overlayService: OverlayService
  @Environment(\.openURL) private var openURL
  @Environment(\.openWindow) private var openWindow
  @Binding var showingPreview: Bool
  let navigateTo: (MenuDestination) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header with close button and mode switcher
      headerSection
      
      Divider()
        .padding(.horizontal)
      
      // Main content
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          // Start/Stop section
          startStopSection
          
          // Main controls - pill cards
          mainControlsSection
          
          // Action buttons
          actionButtonsSection
          
          // System preferences
          systemSection
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
      }
      .frame(minHeight: 400, maxHeight: 480) // Ensure minimum spacious height with reasonable max
    }
  }
  
  // MARK: - Header Section
  
  private var headerSection: some View {
    HStack {
      // App icon and title
      HStack(spacing: 8) {
        Image(systemName: "video.fill")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.accentColor)
        
        Text("Headliner")
          .font(.headline)
          .fontWeight(.semibold)
      }
      
      Spacer()
      
      // Status indicator
      HStack(spacing: 6) {
        Circle()
          .fill(cameraService.cameraStatus.isRunning ? Color.green : Color.gray)
          .frame(width: 8, height: 8)
        
        Text(cameraService.cameraStatus.isRunning ? "Live" : "Idle")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }
  
  // MARK: - Start/Stop Section
  
  private var startStopSection: some View {
    VStack(spacing: 8) {
      Button(action: { 
        withAnimation(.easeInOut(duration: 0.3)) {
          appCoordinator.toggleCamera()
        }
      }) {
        HStack {
          Image(systemName: cameraService.cameraStatus.isRunning ? "stop.circle.fill" : "play.circle.fill")
            .font(.system(size: 18))
            .foregroundColor(.white)
            .animation(.easeInOut(duration: 0.2), value: cameraService.cameraStatus.isRunning)
          
          Text(cameraService.cameraStatus.isRunning ? "Stop Virtual Camera" : "Start Virtual Camera")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
          
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(cameraService.cameraStatus.isRunning ? Color.red : Color.accentColor)
            .animation(.easeInOut(duration: 0.3), value: cameraService.cameraStatus.isRunning)
        )
      }
      .buttonStyle(PlainButtonStyle())
      
      // Show actionable message if extension not installed
      if extensionService.status != .installed {
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
              .font(.caption)
            
            Text("Extension not installed")
              .font(.caption)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.leading)
            
            Spacer()
          }
          
          // Action button to launch onboarding
          Button(action: {
            launchOnboarding()
          }) {
            HStack(spacing: 6) {
              Image(systemName: "gear")
                .font(.system(size: 12, weight: .medium))
              Text("Install Extension")
                .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange)
            .cornerRadius(6)
          }
          .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
      }
    }
  }
  
  // MARK: - Main Controls Section
  
  private var mainControlsSection: some View {
    VStack(spacing: 8) {
      // Camera selector with LoomStyleSelector - always show for consistent UI
      LoomStyleSelector(
        title: "Camera",
        items: cameraService.availableCameras,
        selectedItem: cameraService.selectedCamera,
        onSelectionChange: { camera in
          if let camera = camera {
            Task {
              await appCoordinator.selectCamera(camera)
            }
          }
        },
        itemIcon: { camera in
          guard let camera = camera else { return "video.slash.fill" }
          return cameraIcon(for: camera)
        },
        itemTitle: { camera in
          camera?.name ?? "No Camera Available"
        },
        itemSubtitle: { camera in
            camera?.deviceType
        },
        statusBadge: { _ in
          if cameraService.availableCameras.isEmpty {
            return ("Error", .orange)
          } else {
            return nil
          }
        }
      )
      
      // Overlay selector with LoomStyleSelector
      LoomStyleSelector<CameraDevice, EmptyView>(
        title: "Overlay",
        selectedTitle: currentOverlayName,
        selectedSubtitle: nil,
        icon: "rectangle.on.rectangle",
        onTap: { navigateTo(.overlaySettings) }
      )
    }
  }
  
  
  private var isOverlayEnabled: Bool {
    overlayService.settings.isEnabled
  }
  
  private var selectedCameraName: String {
    cameraService.selectedCamera?.name ?? "No Camera Selected"
  }
  
  private var currentOverlayName: String {
    if isOverlayEnabled {
      if let currentPreset = overlayService.currentPreset {
        return currentPreset.name
      } else {
        return "Unknown Overlay"
      }
    } else {
      return "Clean (No Overlay)"
    }
  }
  
  private var overlayOptions: [SwiftUIPresetInfo] {
    return overlayService.availablePresets
  }
  
  private func cameraIcon(for camera: CameraDevice) -> String {
    if camera.deviceType.contains("iPhone") || camera.deviceType.contains("Continuity") { return "iphone" }
    if camera.deviceType.contains("External") { return "camera.on.rectangle" }
    if camera.deviceType.contains("Desk View") { return "camera.macro" }
    return "camera.fill"
  }
  
  // MARK: - Action Buttons Section
  
  private var actionButtonsSection: some View {
    VStack(spacing: 6) {
      Divider()
      
      // Preview button with popover
      InteractiveMenuButton(
        icon: "eye",
        title: "Preview",
        action: { showingPreview.toggle() }
      )
      .popover(isPresented: $showingPreview, arrowEdge: .trailing) {
        PreviewPopover(appCoordinator: appCoordinator)
      }
      
      // Settings button
      InteractiveMenuButton(
        icon: "gearshape",
        title: "Settings…",
        action: { navigateTo(.settings) }
      )
    }
  }
  
  // MARK: - System Section
  
  private var systemSection: some View {
    VStack(spacing: 6) {
      Divider()
      
      // Launch at login toggle
      InteractiveMenuButton(
        icon: "power",
        title: "Launch at Login",
        action: { appCoordinator.toggleLaunchAtLogin() },
        accessory: {
          if appCoordinator.launchAtLogin {
            Image(systemName: "checkmark")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.accentColor)
          }
        }
      )
      
      Divider()
      
      #if DEBUG
      // Debug section - only in debug builds
      InteractiveMenuButton(
        icon: "trash.fill",
        title: "🛠 Reset App State (Debug)",
        action: { 
          resetAppState()
        }
      )
      
      Divider()
      #endif
      
      // Quit button
      InteractiveMenuButton(
        icon: "power",
        title: "Quit Headliner",
        action: { appCoordinator.quitApp() }
      )
    }
  }
  
  // MARK: - Debug Functions
  
  // MARK: - Action Functions
  
  /// Launch the onboarding window to install the extension
  private func launchOnboarding() {
    // Use the OnboardingWindowManager to prevent duplicate windows
    appCoordinator.onboardingManager.showOnboarding(appCoordinator: appCoordinator)
    
    // Clear onboarding completion flag so user can go through flow again
    if let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
      appGroupDefaults.removeObject(forKey: "HL.hasCompletedOnboarding")
      appGroupDefaults.synchronize()
    }
    
    // Clear local onboarding completion flag
    UserDefaults.standard.removeObject(forKey: "OnboardingCompleted")
    
    print("🛠 [DEBUG] App state reset - onboarding will show")
  }
  
  #if DEBUG
  /// Reset app state for debugging - clears UserDefaults and related state
  private func resetAppState() {
    // Clear App Group UserDefaults
    if let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
      // Clear onboarding completion flag
      appGroupDefaults.removeObject(forKey: "HL.hasCompletedOnboarding")
      
      // Clear any other app group settings
      appGroupDefaults.removeObject(forKey: "ExtensionProviderReady")
      appGroupDefaults.removeObject(forKey: "SelectedCameraDeviceID")
      
      appGroupDefaults.synchronize()
    }
    
    // Clear standard UserDefaults (in case there are any legacy settings)
    UserDefaults.standard.removeObject(forKey: "OnboardingCompleted")
    UserDefaults.standard.synchronize()
    
    // Optional: You could also reset other state here
    // For example: clear selected camera, reset overlay settings, etc.
    
    print("🛠 [DEBUG] App state reset - onboarding will show on next launch")
    
    // Optional: Show a brief confirmation
    // Since we're in a menu, we could add a subtle animation or log message
  }
  #endif
}

// MARK: - Preview Popover Component

/// Preview popover using CameraPreviewCard for full functionality
private struct PreviewPopover: View {
  let appCoordinator: AppCoordinator
  @EnvironmentObject private var cameraService: CameraService
  @EnvironmentObject private var overlayService: OverlayService
  
  var body: some View {
    VStack(spacing: 6) {
      Text("Camera Preview")
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(.primary)
      
      // Use CameraPreviewCard with new self-preview architecture
      CameraPreviewCard(
        previewImage: cameraService.currentPreviewFrame,
        isActive: cameraService.cameraStatus == .running,
        overlayService: overlayService
      )
      .frame(height: 180) // Compact height for popover
      .scaleEffect(0.9) // Slightly less aggressive scaling
      .clipped() // Prevent any overflow/bleeding
      
      if cameraService.selectedCamera != nil && !cameraService.availableCameras.isEmpty {
        Text("Self-preview: exactly what Google Meet sees")
          .font(.system(size: 10))
          .foregroundColor(.secondary)
      } else {
        Text("Select a camera to see preview")
          .font(.system(size: 10))
          .foregroundColor(.secondary)
      }
    }
    .padding(8) // Reduced padding
    .frame(width: 300) // More compact width
    .background(Color(.controlBackgroundColor)) // Explicit background to prevent text bleeding
    .clipShape(RoundedRectangle(cornerRadius: 12)) // Clean edges
  }
}

// MARK: - Overlay Row Component

/// Individual overlay selection row with modern design
private struct OverlayRow: View {
  let overlay: SwiftUIPresetInfo
  let isSelected: Bool
  let onSelect: () -> Void
  
  @State private var isHovering = false
  
  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 10) {
        // Category indicator
        RoundedRectangle(cornerRadius: 2)
          .fill(categoryColor(for: overlay.category))
          .frame(width: 3, height: 16)
        
        VStack(alignment: .leading, spacing: 1) {
          Text(overlay.name)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)
          
          if !overlay.description.isEmpty {
            Text(overlay.description)
              .font(.system(size: 11))
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
        }
        
        Spacer()
        
        // Selection indicator
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 14))
            .foregroundColor(.accentColor)
        } else {
          Circle()
            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            .frame(width: 14, height: 14)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .fill(backgroundColor)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { isHovering = $0 }
  }
  
  private var backgroundColor: Color {
    if isSelected {
      return Color.accentColor.opacity(0.1)
    } else if isHovering {
      return Color.primary.opacity(0.05)
    } else {
      return Color.clear
    }
  }
  
  private func categoryColor(for category: SwiftUIPresetCategory) -> Color {
    switch category {
    case .minimal:
      return .gray
    case .standard:
      return .blue
    case .branded:
      return .purple
    case .creative:
      return .orange
    }
  }
}

// MARK: - Pill Card Component

/// Modern pill-shaped card for camera and overlay selection with hover effects
struct PillCard<DropdownContent: View>: View {
  let icon: String
  let title: String
  let subtitle: String
  let isDropdown: Bool
  let action: () -> Void
  let dropdownContent: () -> DropdownContent
  
  @State private var isHovered = false
  @State private var showingDropdown = false
  
  init(
    icon: String, 
    title: String, 
    subtitle: String, 
    isDropdown: Bool, 
    action: @escaping () -> Void, 
    @ViewBuilder dropdownContent: @escaping () -> DropdownContent = { EmptyView() }
  ) {
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.isDropdown = isDropdown
    self.action = action
    self.dropdownContent = dropdownContent
  }
  
  var body: some View {
    if isDropdown {
      // Dropdown version
      VStack(spacing: 0) {
        Button(action: { showingDropdown.toggle() }) {
          pillContent
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
        
        if showingDropdown {
          VStack(alignment: .leading, spacing: 0) {
            dropdownContent()
          }
          .background(Color(.controlBackgroundColor))
          .cornerRadius(8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.primary.opacity(0.1), lineWidth: 1)
          )
          .padding(.top, 4)
          .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
        }
      }
    } else {
      // Simple button version
      Button(action: action) {
        pillContent
      }
      .buttonStyle(PlainButtonStyle())
      .onHover { isHovered = $0 }
    }
  }
  
  private var pillContent: some View {
    HStack(spacing: 12) {
      // Icon
      Image(systemName: icon)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.accentColor)
        .frame(width: 20)
      
      // Content
      VStack(alignment: .leading, spacing: 2) {
        Text(subtitle)
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(.secondary)
          .textCase(.uppercase)
        
        Text(title)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.primary)
          .lineLimit(1)
      }
      
      Spacer()
      
      // Chevron (only for navigation, not dropdown)
      if !isDropdown {
        Image(systemName: "chevron.right")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(.secondary)
      } else {
        Image(systemName: showingDropdown ? "chevron.up" : "chevron.down")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(isHovered ? Color.primary.opacity(0.05) : Color.primary.opacity(0.02))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.primary.opacity(isHovered ? 0.12 : 0.08), lineWidth: 1)
        )
    )
    .scaleEffect(isHovered ? 1.005 : 1.0)
    .animation(.easeInOut(duration: 0.15), value: isHovered)
  }
}

// MARK: - Interactive Menu Button

/// A reusable menu button with hover animations like Loom
struct InteractiveMenuButton<Accessory: View>: View {
  let icon: String
  let title: String
  let action: () -> Void
  let accessory: () -> Accessory
  
  @State private var isHovered = false
  
  init(icon: String, title: String, action: @escaping () -> Void, @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }) {
    self.icon = icon
    self.title = title
    self.action = action
    self.accessory = accessory
  }
  
  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 14))
          .foregroundColor(isHovered ? .primary : .secondary)
        Text(title)
          .font(.system(size: 14))
          .foregroundColor(isHovered ? .primary : .primary)
        Spacer()
        accessory()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
      )
      .scaleEffect(isHovered ? 1.01 : 1.0)
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.15)) {
        isHovered = hovering
      }
    }
  }
}

// MARK: - Settings Menu View

/// The settings view (focused, dedicated settings page)
struct SettingsMenuView: View {
  let appCoordinator: AppCoordinator
  let onBack: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header with back button
      HStack {
        Button(action: onBack) {
          HStack(spacing: 4) {
            Image(systemName: "chevron.left")
              .font(.system(size: 11, weight: .semibold))
            Text("Back")
              .font(.system(size: 12, weight: .medium))
          }
          .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
        
        Spacer()
        
        Text("Settings")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.primary)
        
        Spacer()
        
        // Placeholder for balance
        Color.clear.frame(width: 40)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 4)
      
      Divider()
        .padding(.horizontal, 12)
      
      // Settings content
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // Launch at login setting
          VStack(alignment: .leading, spacing: 8) {
            Text("General")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.secondary)
            
            Button(action: { appCoordinator.toggleLaunchAtLogin() }) {
              HStack {
                Image(systemName: "power")
                  .font(.system(size: 14))
                  .foregroundColor(.secondary)
                Text("Launch at Login")
                  .font(.system(size: 14))
                  .foregroundColor(.primary)
                Spacer()
                
                // Toggle indicator
                // TODO: Get launch at login status from proper service
                if false {  // appCoordinator.launchAtLogin replaced with false for now
                  Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
                }
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Color(.controlBackgroundColor).opacity(0.5))
              .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
          }
          
          // App info section
          VStack(alignment: .leading, spacing: 8) {
            Text("About")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
              Text("Headliner")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
              Text("Professional virtual camera for macOS")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
          }
          
          // Danger zone
          VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.secondary)
            
            Button(action: { appCoordinator.quitApp() }) {
              HStack {
                Image(systemName: "power")
                  .font(.system(size: 14))
                  .foregroundColor(.red)
                Text("Quit Headliner")
                  .font(.system(size: 14))
                  .foregroundColor(.red)
                Spacer()
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Color(.controlBackgroundColor).opacity(0.5))
              .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
      }
    }
    .background(Color(.controlBackgroundColor))
  }
}

#if DEBUG
struct MenuContent_Previews: PreviewProvider {
  static var previews: some View {
    // Single, lightweight preview to avoid heavy initialization
    MenuContent(appCoordinator: AppCoordinator())
      .frame(width: 320)
      .previewDisplayName("Menu Content")
      .previewLayout(.sizeThatFits)
  }
}
#endif
