//
//  PreviewPane.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI
import AVFoundation

// MARK: - Preview Pane

struct PreviewPane: View {
  @ObservedObject var appState: AppState
  @ObservedObject var outputImageManager: OutputImageManager
  
  @State private var aspectRatio: AspectRatio = .auto
  @State private var isShowingLiveIndicator = false
  
  enum AspectRatio: String, CaseIterable {
    case auto = "Auto"
    case ratio16x9 = "16:9"
    case ratio4x3 = "4:3"
    case square = "Square"
    
    var displayValue: CGFloat? {
      switch self {
      case .auto: return nil
      case .ratio16x9: return 16.0/9.0
      case .ratio4x3: return 4.0/3.0
      case .square: return 1.0
      }
    }
  }
  
  var body: some View {
    VStack(spacing: DesignTokens.Spacing.lg) {
      // Title Row
      HStack {
        Text("Live Preview")
          .font(DesignTokens.Typography.titleFont)
          .foregroundColor(DesignTokens.Colors.textPrimary)
        
        Spacer()
        
        HStack(spacing: DesignTokens.Spacing.lg) {
          // Overlay Toggle
          overlayToggle
          
          // Aspect Ratio Selector
          aspectRatioSelector
        }
      }
      
      // Preview Frame
      previewFrame
        .frame(maxHeight: 480)
    }
  }
  
  // MARK: - Overlay Toggle
  
  private var overlayToggle: some View {
    Button(action: toggleOverlays) {
      HStack(spacing: DesignTokens.Spacing.sm) {
        Circle()
          .fill(appState.overlaySettings.isEnabled ? DesignTokens.Colors.success : DesignTokens.Colors.textTertiary)
          .frame(width: 8, height: 8)
        
        Text("Overlays")
          .font(DesignTokens.Typography.captionFont)
          .foregroundColor(DesignTokens.Colors.textSecondary)
      }
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityLabel("Toggle overlays")
    .accessibilityValue(appState.overlaySettings.isEnabled ? "On" : "Off")
  }
  
  // MARK: - Aspect Ratio Selector
  
  private var aspectRatioSelector: some View {
    Menu {
      ForEach(AspectRatio.allCases, id: \.self) { ratio in
        Button(ratio.rawValue) {
          aspectRatio = ratio
        }
      }
    } label: {
      HStack(spacing: 4) {
        Text(aspectRatio.rawValue)
          .font(DesignTokens.Typography.captionFont)
          .foregroundColor(DesignTokens.Colors.textSecondary)
        
        Image(systemName: "chevron.down")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(DesignTokens.Colors.textTertiary)
      }
    }
    .menuStyle(BorderlessButtonMenuStyle())
    .accessibilityLabel("Aspect ratio")
  }
  
  // MARK: - Preview Frame
  
  private var previewFrame: some View {
    GeometryReader { geometry in
      ZStack {
        // Background
        RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
          .fill(Color(hex: "#0A0B0C"))
        
        // Content
        Group {
          if let previewImage = outputImageManager.videoExtensionStreamOutputImage {
            livePreview(image: previewImage, in: geometry)
          } else {
            emptyState
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))
        
        // Live indicator overlay
        if isShowingLiveIndicator {
          VStack {
            HStack {
              LiveIndicatorBadge()
              Spacer()
            }
            .padding(DesignTokens.Spacing.lg)
            Spacer()
          }
          .transition(.opacity)
        }
      }
      .aspectRatio(aspectRatio.displayValue, contentMode: .fit)
    }
    .onReceive(appState.$cameraStatus) { status in
      withAnimation(DesignTokens.Animations.fade) {
        isShowingLiveIndicator = status.isRunning
      }
    }
  }
  
  // MARK: - Live Preview
  
  private func livePreview(image: NSImage, in geometry: GeometryProxy) -> some View {
    ZStack {
      Image(nsImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
      
      // Corner scrim for better live indicator visibility
      LinearGradient(
        colors: [
          Color.black.opacity(0.6),
          Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .center
      )
      .allowsHitTesting(false)
    }
  }
  
  // MARK: - Empty State
  
  private var emptyState: some View {
    VStack(spacing: DesignTokens.Spacing.lg) {
      Image(systemName: cameraStatus.icon)
        .font(.system(size: 48, weight: .light))
        .foregroundColor(DesignTokens.Colors.textTertiary)
      
      VStack(spacing: DesignTokens.Spacing.sm) {
        Text(cameraStatus.title)
          .font(DesignTokens.Typography.titleFont)
          .foregroundColor(DesignTokens.Colors.textPrimary)
        
        Text(cameraStatus.subtitle)
          .font(DesignTokens.Typography.bodyFont)
          .foregroundColor(DesignTokens.Colors.textSecondary)
        
        if let action = cameraStatus.action {
          HeadlinerButton(
            action.title,
            icon: action.icon,
            variant: .primary,
            size: .compact,
            action: action.handler
          )
          .padding(.top, DesignTokens.Spacing.sm)
        }
      }
    }
    .multilineTextAlignment(.center)
  }
  
  // MARK: - Camera Status
  
  private var cameraStatus: CameraEmptyState {
    if appState.availableCameras.isEmpty {
      return CameraEmptyState(
        icon: "camera.fill",
        title: "No cameras found",
        subtitle: "Check your camera connections",
        action: CameraEmptyState.Action(
          title: "Refresh",
          icon: "arrow.clockwise",
          handler: { appState.refreshCameras() }
        )
      )
    }
    
    if appState.selectedCameraID.isEmpty {
      return CameraEmptyState(
        icon: "video.slash",
        title: "No camera selected",
        subtitle: "Pick a source to see yourself",
        action: CameraEmptyState.Action(
          title: "Select Camera",
          icon: "camera",
          handler: { /* TODO: Show camera picker */ }
        )
      )
    }
    
    switch appState.cameraStatus {
    case .stopped:
      return CameraEmptyState(
        icon: "play.circle",
        title: "Camera stopped",
        subtitle: "Start streaming to see your camera",
        action: CameraEmptyState.Action(
          title: "Start Camera",
          icon: "video",
          handler: { appState.startCamera() }
        )
      )
    case .starting:
      return CameraEmptyState(
        icon: "ellipsis",
        title: "Starting camera...",
        subtitle: "Please wait while we initialize your camera"
      )
    case .error(let message):
      return CameraEmptyState(
        icon: "exclamationmark.triangle",
        title: "Camera error",
        subtitle: message,
        action: CameraEmptyState.Action(
          title: "Try Again",
          icon: "arrow.clockwise",
          handler: { appState.startCamera() }
        )
      )
    default:
      return CameraEmptyState(
        icon: "camera",
        title: "Initializing",
        subtitle: "Setting up your camera preview"
      )
    }
  }
  
  // MARK: - Actions
  
  private func toggleOverlays() {
    var newSettings = appState.overlaySettings
    newSettings.isEnabled.toggle()
    
    // Add haptic feedback
    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    
    // Animate the toggle
    withAnimation(DesignTokens.Animations.fade) {
      appState.updateOverlaySettings(newSettings)
    }
  }
}

// MARK: - Camera Empty State

private struct CameraEmptyState {
  let icon: String
  let title: String
  let subtitle: String
  let action: Action?
  
  init(
    icon: String,
    title: String,
    subtitle: String,
    action: Action? = nil
  ) {
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.action = action
  }
  
  struct Action {
    let title: String
    let icon: String
    let handler: () -> Void
  }
}

// MARK: - Preview

#if DEBUG
struct PreviewPane_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      PreviewPane(
        appState: PreviewsSupport.mockAppState,
        outputImageManager: PreviewsSupport.mockOutputImageManager
      )
      .frame(maxWidth: 480)
    }
    .padding(DesignTokens.Spacing.xxl)
    .background(DesignTokens.Colors.surface)
  }
}
#endif