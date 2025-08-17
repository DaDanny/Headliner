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
        // Base gradient background
        LinearGradient(
          colors: [
            DesignTokens.Colors.surface,
            DesignTokens.Colors.surfaceAlt
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        
        // Animated background overlay
        AnimatedBackground()
          .opacity(0.03)
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
  @State private var isShowingHelpMenu = false
  
  var body: some View {
    HStack {
      // Left - App title and subtitle
      VStack(alignment: .leading, spacing: 4) {
        Text("Headliner")
          .font(DesignTokens.Typography.displayFont)
          .foregroundColor(DesignTokens.Colors.textPrimary)
        
        Text("Virtual Camera Studio")
          .font(DesignTokens.Typography.font(size: DesignTokens.Typography.Sizes.lg, weight: .medium))
          .foregroundColor(DesignTokens.Colors.textSecondary)
      }
      
      Spacer()
      
      // Right - Status, settings, and help
      HStack(spacing: DesignTokens.Spacing.md) {
        // Extension status badge
        ExtensionStatusBadge(status: appState.extensionStatus)
        
        // Settings button
        HeadlinerButton(
          "",
          icon: "gear",
          variant: .ghost,
          size: .compact
        ) {
          appState.isShowingSettings.toggle()
        }
        .accessibilityLabel("Settings")
        
        // Help menu button
        Menu {
          Button("Quick Tour") {
            // TODO: Show quick tour
          }
          
          Button("Troubleshoot Camera") {
            // TODO: Show troubleshooting
          }
          
          Divider()
          
          Button("Report a Bug...") {
            // TODO: Open bug report
          }
          
          Button("Keyboard Shortcuts") {
            // TODO: Show keyboard shortcuts
          }
        } label: {
          Image(systemName: "questionmark.circle")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .accessibilityLabel("Help")
      }
    }
    .padding(.horizontal, DesignTokens.Spacing.xxl)
    .padding(.vertical, DesignTokens.Spacing.xl)
    .frame(height: DesignTokens.Layout.headerHeight)
    .background(DesignTokens.Colors.surface)
    .overlay(
      Rectangle()
        .fill(DesignTokens.Colors.stroke)
        .frame(height: 1),
      alignment: .bottom
    )
  }
}

// MARK: - Content Split

struct ContentSplit: View {
  @ObservedObject var appState: AppState
  @ObservedObject var outputImageManager: OutputImageManager
  @ObservedObject var propertyManager: CustomPropertyManager
  
  var body: some View {
    HStack(spacing: DesignTokens.Layout.contentGutter) {
      // Preview Pane
      PreviewPane(
        appState: appState,
        outputImageManager: outputImageManager
      )
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
  
  var body: some View {
    HStack {
      Spacer()
      
      HStack(spacing: DesignTokens.Spacing.md) {
        // Test in Zoom button
        HeadlinerButton(
          "Test in Zoom",
          icon: "video.badge.checkmark",
          variant: .secondary,
          size: .compact
        ) {
          // TODO: Open Zoom test URL
          if let url = URL(string: "https://zoom.us/test") {
            NSWorkspace.shared.open(url)
          }
        }
        
        // Reset to defaults button
        HeadlinerButton(
          "Reset to Defaults",
          icon: "arrow.counterclockwise",
          variant: .ghost,
          size: .compact
        ) {
          resetToDefaults()
        }
      }
    }
    .padding(.horizontal, DesignTokens.Spacing.xxl)
    .padding(.vertical, DesignTokens.Spacing.lg)
    .frame(height: DesignTokens.Layout.footerHeight)
    .background(DesignTokens.Colors.surface)
    .overlay(
      Rectangle()
        .fill(DesignTokens.Colors.stroke)
        .frame(height: 1),
      alignment: .top
    )
  }
  
  private func resetToDefaults() {
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
}

// The PreviewPane and ControlPane are now implemented in their own files

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