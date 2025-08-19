//
//  HeadlinerAppShell.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

// MARK: - Headliner App Shell

struct HeadlinerAppShell: View {
  @ObservedObject var appState: AppState
  @ObservedObject var outputImageManager: OutputImageManager
  @ObservedObject var propertyManager: CustomPropertyManager
  
  var body: some View {
    VStack(spacing: 0) {
      // Header Bar
      HeaderBar(appState: appState)
      
      // Content Split
      ContentSplit(
        appState: appState,
        outputImageManager: outputImageManager,
        propertyManager: propertyManager
      )
      
      // Footer Actions
      FooterActions(appState: appState)
    }
    .background(
      ZStack {
        // Rich gradient background
        LinearGradient(
          colors: [
            DesignTokens.Colors.surface,
            DesignTokens.Colors.surfaceAlt,
            DesignTokens.Colors.surfaceRaised
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        
        // Subtle animated particles
        ModernAnimatedBackground()
          .opacity(0.6)
        
        // Accent gradient overlay when camera is running
        if appState.cameraStatus.isRunning {
          RadialGradient(
            colors: [
              DesignTokens.Colors.brandPrimary.opacity(0.08),
              Color.clear
            ],
            center: .topLeading,
            startRadius: 100,
            endRadius: 400
          )
          .transition(.opacity)
          .animation(DesignTokens.Animations.gentleSpring, value: appState.cameraStatus.isRunning)
        }
      }
    )
    .frame(
      minWidth: DesignTokens.Layout.windowMinWidth,
      minHeight: DesignTokens.Layout.windowMinHeight
    )
    .sheet(isPresented: $appState.isShowingOverlaySettings) {
      OverlayDesignerSheet(appState: appState)
    }
  }
}

// MARK: - Header Bar

struct HeaderBar: View {
  @ObservedObject var appState: AppState
  @State private var logoRotation: Double = 0
  @State private var showWelcomeGlow = false
  
  var body: some View {
    HStack {
      // Left - App branding with personality
      HStack(spacing: DesignTokens.Spacing.lg) {
        // Fun animated logo area
        ZStack {
          // Glowing background when camera is running
          if appState.cameraStatus.isRunning {
            Circle()
              .fill(DesignTokens.Colors.brandPrimary.opacity(0.15))
              .frame(width: 50, height: 50)
              .scaleEffect(showWelcomeGlow ? 1.2 : 1.0)
              .animation(DesignTokens.Animations.breathe, value: showWelcomeGlow)
          }
          
          // App icon/symbol
          ZStack {
            Image(systemName: "video.circle.fill")
              .font(.system(size: 28, weight: .medium))
              .foregroundStyle(DesignTokens.Colors.brandGradient)
              .rotationEffect(.degrees(logoRotation))
              .shadow(color: DesignTokens.Colors.brandPrimary.opacity(0.3), radius: 4)
          }
        }
        .onTapGesture {
          withAnimation(DesignTokens.Animations.bouncySpring) {
            logoRotation += 360
          }
        }
        .onAppear {
          showWelcomeGlow = appState.cameraStatus.isRunning
        }
        .onChange(of: appState.cameraStatus.isRunning) { isRunning in
          withAnimation(DesignTokens.Animations.gentleSpring) {
            showWelcomeGlow = isRunning
          }
        }
        
        // Title with personality
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 8) {
            Text("Headliner")
              .font(.system(size: 24, weight: .bold, design: .rounded))
              .foregroundStyle(
                LinearGradient(
                  colors: [DesignTokens.Colors.textPrimary, DesignTokens.Colors.textSecondary],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
            
            // Fun status indicator
            if appState.cameraStatus.isRunning {
              Text("LIVE")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                  Capsule()
                    .fill(DesignTokens.Colors.danger)
                )
                .transition(.scale.combined(with: .opacity))
            }
          }
          
          Text("Virtual Camera Studio")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(DesignTokens.Colors.textSecondary)
        }
      }
      
      Spacer()
      
      // Right - Modern control bar
      HStack(spacing: DesignTokens.Spacing.lg) {
        // Status indicator with more personality
        statusIndicator
        
        // Modern button bar
        HStack(spacing: DesignTokens.Spacing.sm) {
          // Settings button
          ControlBarButton(
            icon: "gear",
            label: "Settings",
            isActive: appState.isShowingSettings
          ) {
            appState.isShowingSettings.toggle()
          }
          
          // Help menu
          Menu {
            Button("🚀 Quick Tour") {
              // TODO: Show quick tour
            }
            
            Button("🔧 Troubleshoot Camera") {
              // TODO: Show troubleshooting
            }
            
            Divider()
            
            Button("🐛 Report a Bug...") {
              // TODO: Open bug report
            }
            
            Button("⌨️ Keyboard Shortcuts") {
              // TODO: Show keyboard shortcuts
            }
          } label: {
            ControlBarButton(
              icon: "questionmark.circle",
              label: "Help",
              isActive: false
            ) {}
          }
          .menuStyle(BorderlessButtonMenuStyle())
        }
      }
    }
    .padding(.horizontal, DesignTokens.Spacing.xxl)
    .padding(.vertical, DesignTokens.Spacing.xl)
    .frame(height: DesignTokens.Layout.headerHeight)
    .background(
      ZStack {
        // Base background
        DesignTokens.Colors.surface
        
        // Subtle gradient overlay
        LinearGradient(
          colors: [
            DesignTokens.Colors.surfaceRaised.opacity(0.8),
            DesignTokens.Colors.surface
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        
        // Live indicator glow
        if appState.cameraStatus.isRunning {
          LinearGradient(
            colors: [
              DesignTokens.Colors.brandPrimary.opacity(0.05),
              Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
          )
        }
      }
    )
    .overlay(
      Rectangle()
        .fill(DesignTokens.Colors.stroke)
        .frame(height: 1),
      alignment: .bottom
    )
  }
  
  // MARK: - Status Indicator
  
  private var statusIndicator: some View {
    HStack(spacing: DesignTokens.Spacing.sm) {
      // Extension status
      ExtensionStatusBadge(status: appState.extensionStatus)
      
      // Camera status with animation
      Group {
        switch appState.cameraStatus {
        case .running:
          HStack(spacing: 4) {
            Circle()
              .fill(DesignTokens.Colors.success)
              .frame(width: 8, height: 8)
              .scaleEffect(showWelcomeGlow ? 1.3 : 1.0)
              .animation(DesignTokens.Animations.pulse, value: showWelcomeGlow)
            
            Text("Ready")
              .font(.system(size: 11, weight: .medium))
              .foregroundColor(DesignTokens.Colors.success)
          }
        case .starting:
          HStack(spacing: 4) {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(0.6)
            
            Text("Starting")
              .font(.system(size: 11, weight: .medium))
              .foregroundColor(DesignTokens.Colors.textSecondary)
          }
        case .error:
          HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 10))
              .foregroundColor(DesignTokens.Colors.danger)
            
            Text("Error")
              .font(.system(size: 11, weight: .medium))
              .foregroundColor(DesignTokens.Colors.danger)
          }
        default:
          HStack(spacing: 4) {
            Circle()
              .fill(DesignTokens.Colors.textTertiary)
              .frame(width: 6, height: 6)
            
            Text("Stopped")
              .font(.system(size: 11, weight: .medium))
              .foregroundColor(DesignTokens.Colors.textTertiary)
          }
        }
      }
      .transition(.asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .opacity
      ))
    }
  }
}

// MARK: - Control Bar Button

private struct ControlBarButton: View {
  let icon: String
  let label: String
  let isActive: Bool
  let action: () -> Void
  
  @State private var isHovered = false
  
  var body: some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(effectiveColor)
        .frame(width: 32, height: 32)
        .background(
          Circle()
            .fill(effectiveBackgroundColor)
            .overlay(
              Circle()
                .stroke(effectiveStrokeColor, lineWidth: 1)
            )
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(DesignTokens.Animations.bouncySpring, value: isHovered)
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
    .accessibilityLabel(label)
  }
  
  private var effectiveColor: Color {
    if isActive {
      return DesignTokens.Colors.accent
    }
    return isHovered ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary
  }
  
  private var effectiveBackgroundColor: Color {
    if isActive {
      return DesignTokens.Colors.accentMuted
    }
    return isHovered ? DesignTokens.Colors.hoverOverlay : Color.clear
  }
  
  private var effectiveStrokeColor: Color {
    if isActive {
      return DesignTokens.Colors.accent.opacity(0.3)
    }
    return isHovered ? DesignTokens.Colors.stroke : Color.clear
  }
}

// MARK: - Content Split

struct ContentSplit: View {
  @ObservedObject var appState: AppState
  @ObservedObject var outputImageManager: OutputImageManager
  @ObservedObject var propertyManager: CustomPropertyManager
  
  var body: some View {
    HStack(spacing: DesignTokens.Layout.contentGutter) {
      // Preview Pane - Placeholder (will be replaced by live preview card from other branch)
      PreviewPanePlaceholder()
        .frame(maxWidth: DesignTokens.Layout.previewMaxWidth)
      
      // Control Pane
      ControlPane(
        appState: appState,
        propertyManager: propertyManager
      )
      .frame(width: DesignTokens.Layout.sidebarWidth)
    }
    .padding(.horizontal, DesignTokens.Spacing.xxl)
    .padding(.vertical, DesignTokens.Spacing.xxl)
  }
}

// MARK: - Footer Actions

struct FooterActions: View {
  @ObservedObject var appState: AppState
  @State private var showResetConfirmation = false
  
  var body: some View {
    HStack {
      // Left side - Helpful info
      HStack(spacing: DesignTokens.Spacing.lg) {
        // Version info with style
        VStack(alignment: .leading, spacing: 2) {
          Text("Headliner")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(DesignTokens.Colors.textTertiary)
          
          Text(appVersionString)
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(DesignTokens.Colors.textQuaternary)
        }
        
        // Connection status
        connectionStatusIndicator
      }
      
      Spacer()
      
      // Right side - Action buttons
      HStack(spacing: DesignTokens.Spacing.lg) {
        // Test button with fun copy
        HeadlinerButton(
          "🎬 Test in Zoom",
          icon: "video.badge.checkmark",
          variant: .secondary,
          size: .compact
        ) {
          openZoomTest()
        }
        
        // Reset with confirmation
        HeadlinerButton(
          "Reset to Defaults",
          icon: "arrow.counterclockwise",
          variant: .ghost,
          size: .compact
        ) {
          showResetConfirmation = true
        }
      }
    }
    .padding(.horizontal, DesignTokens.Spacing.xxl)
    .padding(.vertical, DesignTokens.Spacing.lg)
    .frame(height: DesignTokens.Layout.footerHeight)
    .background(
      ZStack {
        // Base background
        DesignTokens.Colors.surface
        
        // Subtle gradient for depth
        LinearGradient(
          colors: [
            DesignTokens.Colors.surface,
            DesignTokens.Colors.surfaceRaised.opacity(0.3)
          ],
          startPoint: .bottom,
          endPoint: .top
        )
      }
    )
    .overlay(
      Rectangle()
        .fill(DesignTokens.Colors.stroke)
        .frame(height: 1),
      alignment: .top
    )
    .alert("Reset to Defaults", isPresented: $showResetConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        resetToDefaults()
      }
    } message: {
      Text("This will reset all overlay settings, camera selection, and stop the current stream. Are you sure?")
    }
  }
  
  // MARK: - Connection Status Indicator
  
  private var connectionStatusIndicator: some View {
    HStack(spacing: 6) {
      // Connection icon with animation
      Group {
        if appState.cameraStatus.isRunning {
          HStack(spacing: 4) {
            Image(systemName: "wifi")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(DesignTokens.Colors.success)
            
            Text("Broadcasting")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(DesignTokens.Colors.success)
          }
        } else if appState.extensionStatus.isInstalled {
          HStack(spacing: 4) {
            Image(systemName: "checkmark.circle")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text("Ready")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(DesignTokens.Colors.textSecondary)
          }
        } else {
          HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(DesignTokens.Colors.warning)
            
            Text("Setup Required")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(DesignTokens.Colors.warning)
          }
        }
      }
      .transition(.asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .opacity
      ))
    }
  }
  
  // MARK: - Actions
  
  private func openZoomTest() {
    // Try to open Zoom test page
    if let url = URL(string: "https://zoom.us/test") {
      NSWorkspace.shared.open(url)
    }
    
    // Show friendly message
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      // Could add a toast notification here
    }
  }
  
  private func resetToDefaults() {
    // Animate the reset with feedback
    withAnimation(DesignTokens.Animations.gentleSpring) {
      // Reset overlay settings to defaults
      let defaultSettings = OverlaySettings()
      appState.updateOverlaySettings(defaultSettings)
      
      // Reset camera to first available
      if let firstCamera = appState.availableCameras.first {
        appState.selectCamera(firstCamera)
      }
      
      // Stop camera if running
      if appState.cameraStatus.isRunning {
        appState.stopCamera()
      }
    }
    
    // Haptic feedback
    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
  }
  
  private var appVersionString: String {
    let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    return "v\(shortVersion) (\(buildNumber))"
  }
}

// MARK: - Preview Pane Placeholder

/// Simple placeholder to avoid conflicts with live preview card implementation in other branch
private struct PreviewPanePlaceholder: View {
  var body: some View {
    VStack(spacing: DesignTokens.Spacing.lg) {
      // Title row
      HStack {
        Text("Live Preview")
          .font(DesignTokens.Typography.titleFont)
          .foregroundColor(DesignTokens.Colors.textPrimary)
        
        Spacer()
        
        HStack(spacing: DesignTokens.Spacing.md) {
          // Simple overlay status indicator
          HStack(spacing: DesignTokens.Spacing.sm) {
            Circle()
              .fill(DesignTokens.Colors.textTertiary)
              .frame(width: 8, height: 8)
            
            Text("Overlays")
              .font(DesignTokens.Typography.captionFont)
              .foregroundColor(DesignTokens.Colors.textSecondary)
          }
          
          // Aspect selector placeholder
          Text("16:9")
            .font(DesignTokens.Typography.captionFont)
            .foregroundColor(DesignTokens.Colors.textSecondary)
        }
      }
      
      // Preview frame placeholder
      RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
        .fill(Color(hex: "#0A0B0C"))
        .overlay(
          VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "video.slash")
              .font(.system(size: 48, weight: .light))
              .foregroundColor(DesignTokens.Colors.textTertiary)
            
            Text("Preview card will be implemented in other branch")
              .font(DesignTokens.Typography.bodyFont)
              .foregroundColor(DesignTokens.Colors.textSecondary)
              .multilineTextAlignment(.center)
          }
        )
        .frame(height: 360)
    }
  }
}

// MARK: - Modern Animated Background

/// Subtle animated background with floating particles
private struct ModernAnimatedBackground: View {
  @State private var animateParticles = false
  
  var body: some View {
    ZStack {
      // Floating particles
      ForEach(0..<8, id: \.self) { index in
        Circle()
          .fill(
            RadialGradient(
              colors: [
                Color.white.opacity(0.02),
                Color.clear
              ],
              center: .center,
              startRadius: 0,
              endRadius: 30
            )
          )
          .frame(width: CGFloat.random(in: 40...120))
          .position(
            x: animateParticles ?
              CGFloat.random(in: 100...800) :
              CGFloat.random(in: 200...700),
            y: animateParticles ?
              CGFloat.random(in: 100...600) :
              CGFloat.random(in: 200...500)
          )
          .animation(
            .easeInOut(duration: Double.random(in: 8...15))
              .repeatForever(autoreverses: true)
              .delay(Double.random(in: 0...3)),
            value: animateParticles
          )
      }
      
      // Subtle mesh gradient effect
      MeshGradientEffect()
    }
    .onAppear {
      animateParticles = true
    }
  }
}

/// Mesh gradient background effect
private struct MeshGradientEffect: View {
  @State private var animateGradient = false
  
  var body: some View {
    ZStack {
      // Primary gradient wave
      Ellipse()
        .fill(
          LinearGradient(
            colors: [
              DesignTokens.Colors.accent.opacity(0.03),
              Color.clear
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
          )
        )
        .frame(width: 800, height: 600)
        .offset(
          x: animateGradient ? 100 : -100,
          y: animateGradient ? 50 : -50
        )
        .animation(
          .easeInOut(duration: 12).repeatForever(autoreverses: true),
          value: animateGradient
        )
      
      // Secondary gradient wave
      Ellipse()
        .fill(
          LinearGradient(
            colors: [
              DesignTokens.Colors.brandSecondary.opacity(0.02),
              Color.clear
            ],
            startPoint: animateGradient ? .bottomLeading : .topTrailing,
            endPoint: animateGradient ? .topTrailing : .bottomLeading
          )
        )
        .frame(width: 600, height: 400)
        .offset(
          x: animateGradient ? -80 : 80,
          y: animateGradient ? -60 : 60
        )
        .animation(
          .easeInOut(duration: 16).repeatForever(autoreverses: true),
          value: animateGradient
        )
    }
    .onAppear {
      animateGradient = true
    }
  }
}

// MARK: - Preview

#if DEBUG
struct HeadlinerAppShell_Previews: PreviewProvider {
  static var previews: some View {
    HeadlinerAppShell(
      appState: PreviewsSupport.mockAppState,
      outputImageManager: PreviewsSupport.mockOutputImageManager,
      propertyManager: PreviewsSupport.mockPropertyManager
    )
    .frame(width: 900, height: 700)
  }
}
#endif