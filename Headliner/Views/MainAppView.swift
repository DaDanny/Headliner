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
                        Color(NSColor.controlBackgroundColor).opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                AnimatedBackground()
                    .opacity(0.03)
            }
        )
        .onAppear {
            // Basic setup
        }
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
    
    private func statusIcon(for status: ExtensionStatus) -> String {
        switch status {
        case .installed: return "checkmark.circle.fill"
        case .installing: return "arrow.down.circle"
        case .notInstalled: return "exclamationmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    private func statusColor(for status: ExtensionStatus) -> Color {
        switch status {
        case .installed: return .green
        case .installing: return .blue
        case .notInstalled: return .orange
        case .error: return .red
        case .unknown: return .gray
        }
    }
    
    private func cameraStatusIcon(for status: CameraStatus) -> String {
        switch status {
        case .running: return "video.circle.fill"
        case .starting: return "play.circle"
        case .stopped: return "stop.circle"
        case .stopping: return "pause.circle"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private func cameraStatusColor(for status: CameraStatus) -> Color {
        switch status {
        case .running: return .green
        case .starting, .stopping: return .blue
        case .stopped: return .gray
        case .error: return .red
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