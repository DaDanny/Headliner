//
//  MainAppView.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct MainAppView: View {
  @ObservedObject var appState: AppState
  @ObservedObject var outputImageManager: OutputImageManager
  @ObservedObject var propertyManager: CustomPropertyManager

  @State private var showingCameraSettings: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      // Header
      headerView

      // Main Content
      HStack(spacing: 24) {
        // Left Panel - Camera Preview
        VStack(spacing: 20) {
          CameraPreviewCard(
            previewImage: outputImageManager.videoExtensionStreamOutputImage,
            isActive: appState.cameraStatus.isRunning
          )

          // Camera Controls
          cameraControls
        }
        .frame(maxWidth: 480)

        // Right Panel - Settings & Effects
        VStack(spacing: 20) {
          // Status Cards
          VStack(spacing: 12) {
            GlassmorphicCard {
              StatusCard(
                title: "Extension Status",
                status: appState.extensionStatus.displayText,
                icon: statusIcon(for: appState.extensionStatus),
                color: statusColor(for: appState.extensionStatus)
              )
            }

            GlassmorphicCard {
              StatusCard(
                title: "Camera Status",
                status: appState.cameraStatus.displayText,
                icon: cameraStatusIcon(for: appState.cameraStatus),
                color: cameraStatusColor(for: appState.cameraStatus)
              )
            }
          }

          // Camera Selection
          GlassmorphicCard {
            CameraSelector(appState: appState)
          }

          // Camera Settings
          GlassmorphicCard {
            cameraSettingsContent
          }

          // Overlay Settings
          GlassmorphicCard {
            overlaySettingsContent
          }

          Spacer()
        }
        .frame(width: 320)
      }
      .padding(24)
    }
    .background(
      ZStack {
        LinearGradient(
          colors: [
            Color(NSColor.controlBackgroundColor),
            Color(NSColor.controlBackgroundColor).opacity(0.95),
          ],
          startPoint: .top,
          endPoint: .bottom
        )

        AnimatedBackground()
          .opacity(0.03)
      }
    )
    .sheet(isPresented: $appState.isShowingOverlaySettings) {
      OverlaySettingsView(appState: appState)
        .frame(width: 600, height: 700)
    }
    .onAppear {
      // Basic setup
    }
  }

  private var appVersionText: String {
    let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    return "v\(shortVersion) (\(buildNumber))"
  }

  // MARK: - Header View

  private var headerView: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Headliner")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.primary)

        Text("Virtual Camera Studio")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.secondary)
      }

      Spacer()

      HStack(spacing: 12) {
        Text(appVersionText)
          .font(.system(size: 12, weight: .regular))
          .foregroundColor(.secondary)

        Button(action: { appState.isShowingSettings.toggle() }) {
          Image(systemName: "gear")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.secondary)
            .frame(width: 32, height: 32)
            .background(Circle().fill(.background))
            .overlay(Circle().stroke(.separator, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
    .background(.background)
    .overlay(
      Rectangle()
        .fill(.separator)
        .frame(height: 1),
      alignment: .bottom
    )
  }

  // MARK: - Camera Controls

  private var cameraControls: some View {
    HStack(spacing: 16) {
      if appState.cameraStatus.isRunning {
        PulsingButton(
          title: "Stop Camera",
          icon: "stop.circle",
          color: .red,
          isActive: appState.cameraStatus == .stopping
        ) {
          appState.stopCamera()
        }
      } else {
        PulsingButton(
          title: "Start Camera",
          icon: "play.circle",
          color: .green,
          isActive: appState.cameraStatus == .starting
        ) {
          appState.startCamera()
        }
      }

      Spacer()

      Button(action: { showingCameraSettings.toggle() }) {
        HStack(spacing: 8) {
          Image(systemName: "gear")
            .font(.system(size: 16, weight: .medium))

          Text("Settings")
            .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(.blue.opacity(0.1))
            .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
      }
      .buttonStyle(ScaleButtonStyle())
    }
  }

  // MARK: - Camera Settings Panel

  private var cameraSettingsContent: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Camera Settings")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.primary)

        Spacer()

        Button(action: { showingCameraSettings.toggle() }) {
          Image(systemName: showingCameraSettings ? "chevron.up" : "chevron.down")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
      }

      if showingCameraSettings {
        VStack(spacing: 12) {
          Text("Basic camera streaming without effects")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

          Text("Select your camera source above and use Start/Stop Camera to control the stream.")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
      }
    }
    .padding(16)
  }

  // MARK: - Overlay Settings Panel

  private var overlaySettingsContent: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Overlay Settings")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)

          if appState.overlaySettings.isEnabled, !appState.overlaySettings.userName.isEmpty {
            Text("Name: \(appState.overlaySettings.userName)")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        Button(action: { appState.isShowingOverlaySettings = true }) {
          Image(systemName: "gear")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
      }

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(appState.overlaySettings.isEnabled ? "Overlays Enabled" : "Overlays Disabled")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(appState.overlaySettings.isEnabled ? .green : .secondary)

          if appState.overlaySettings.isEnabled, appState.overlaySettings.showUserName {
            Text("Position: \(appState.overlaySettings.namePosition.displayName)")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        Button(action: { appState.isShowingOverlaySettings = true }) {
          Text("Configure")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(16)
  }

  private func statusIcon(for status: ExtensionStatus) -> String {
    switch status {
    case .installed: "checkmark.circle.fill"
    case .installing: "arrow.down.circle"
    case .notInstalled: "exclamationmark.circle.fill"
    case .error: "xmark.circle.fill"
    case .unknown: "questionmark.circle.fill"
    }
  }

  private func statusColor(for status: ExtensionStatus) -> Color {
    switch status {
    case .installed: .green
    case .installing: .blue
    case .notInstalled: .orange
    case .error: .red
    case .unknown: .gray
    }
  }

  private func cameraStatusIcon(for status: CameraStatus) -> String {
    switch status {
    case .running: "video.circle.fill"
    case .starting: "play.circle"
    case .stopped: "stop.circle"
    case .stopping: "pause.circle"
    case .error: "exclamationmark.triangle.fill"
    }
  }

  private func cameraStatusColor(for status: CameraStatus) -> Color {
    switch status {
    case .running: .green
    case .starting, .stopping: .blue
    case .stopped: .gray
    case .error: .red
    }
  }
}

// MARK: - Preview

struct MainAppView_Previews: PreviewProvider {
  static var previews: some View {
    MainAppView(
      appState: AppState(
        systemExtensionManager: SystemExtensionRequestManager(logText: ""),
        propertyManager: CustomPropertyManager(),
        outputImageManager: OutputImageManager()
      ),
      outputImageManager: OutputImageManager(),
      propertyManager: CustomPropertyManager()
    )
    .frame(width: 1200, height: 800)
  }
}
