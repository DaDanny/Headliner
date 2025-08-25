//
//  StepMediaComponents.swift
//  Headliner
//
//  Step-specific media components for modern onboarding
//

import SwiftUI
import AVFoundation
import CoreLocation

// MARK: - Welcome Media

struct WelcomeMedia: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            VStack(spacing: 8) {
                Text("Let's set you up in a minute")
                    .font(.title2.bold())
                
                Text("Quick and easy virtual camera setup")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Install Media

struct InstallMedia: View {
    let state: ModernOnboardingViewModel.InstallState
    let onInstall: () -> Void
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bolt.badge.a")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .rotationEffect(.degrees(state == .installing ? rotationAngle : 0))
                .animation(
                    state == .installing ?
                        .linear(duration: 2).repeatForever(autoreverses: false) :
                        .default,
                    value: rotationAngle
                )
            
            VStack(spacing: 16) {
                Label("Virtual Camera Extension", systemImage: "camera.fill")
                    .font(.title3.bold())
                
                statusView
            }
        }
        .onAppear {
            if state == .installing {
                rotationAngle = 360
            }
        }
        .onChange(of: state) { _, newState in
            if newState == .installing {
                rotationAngle = 360
            } else {
                rotationAngle = 0
            }
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        switch state {
        case .installed:
            Label("Extension installed successfully!", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .font(.body.weight(.medium))
            
        case .installing:
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Installing extension…")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Text("Look for the security prompt")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
        case .error(let message):
            VStack(spacing: 12) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.body)
                
                Button("Retry Install", action: onInstall)
                    .buttonStyle(.borderedProminent)
            }
            
        case .notInstalled, .unknown:
            VStack(spacing: 12) {
                Text("Ready to install the camera extension")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Button("Install Extension", action: onInstall)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
    }
}

// MARK: - Personalize Media

struct PersonalizeMedia: View {
    @Binding var displayName: String
    @Binding var displayTitle: String
    @Binding var selectedCameraID: String
    let onCameraSelect: ((String) -> Void)?
    
    @EnvironmentObject private var cameraService: CameraService
    
    // Preview detection
    private var isInPreviewMode: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Your Info Section
            PersonalizeSection(
                icon: "person.text.rectangle",
                title: "Your Info"
            ) {
                VStack(spacing: 12) {
                    StyledTextField(
                        text: $displayName,
                        placeholder: "Your name",
                        icon: "person.fill"
                    )
                    
                    StyledTextField(
                        text: $displayTitle,
                        placeholder: "Your title (optional)",
                        icon: "briefcase.fill"
                    )
                }
            }
            
            // Camera Section
            PersonalizeSection(
                icon: "camera.fill",
                title: "Camera"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    
                    if isInPreviewMode {
                        // Mock camera selector for previews
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                
                                Text("Built-in Camera (Preview Mode)")
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Text("Preview mode - camera access disabled")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else if cameraService.hasCameraPermission {
                        LoomStyleSelector(
                            title: "Camera",
                            items: cameraService.availableCameras,
                            selectedItem: cameraService.availableCameras.first { $0.id == selectedCameraID },
                            onSelectionChange: { camera in
                                if let camera = camera {
                                    selectedCameraID = camera.id
                                    onCameraSelect?(camera.id)
                                }
                            },
                            itemIcon: { _ in "camera.fill" },
                            itemTitle: { $0?.name ?? "Choose a camera" },
                            itemSubtitle: { _ in nil }
                        )
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.slash")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            
                            Text("Camera permission required")
                                .font(.headline)
                            
                            Button("Grant Permission") {
                                Task {
                                    _ = await cameraService.requestPermission()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
            
            // Location Services Section
            PersonalizeSection(
                icon: "location.fill",
                title: "Location Services"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    LocationPermissionView()
                }
            }
        }
        .padding()
        .frame(maxWidth: 480)
        .onAppear {
            // Set initial camera selection if not already set
            if !isInPreviewMode,
               selectedCameraID.isEmpty,
               let firstCamera = cameraService.availableCameras.first {
                selectedCameraID = firstCamera.id
            }
        }
    }
}

// MARK: - Preview Media

struct PreviewMedia: View {
    let name: String
    let title: String
    @Binding var style: ModernOnboardingViewModel.StyleShape
    let availablePresets: [SwiftUIPresetInfo]
    @Binding var selectedPresetID: String?
    let onPresetSelect: (SwiftUIPresetInfo) -> Void
    
    @EnvironmentObject private var cameraService: CameraService
    @EnvironmentObject private var overlayService: OverlayService
    @State private var hasStartedPreview = false
    
    // Preview detection
    private var isInPreviewMode: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Preset Rail with Style Selector
            VStack(spacing: 0) {
                PresetRail(
                    presets: availablePresets,
                    selectedID: $selectedPresetID,
                    onSelect: onPresetSelect
                )
                .frame(height: 280) // Reduced height
                
                Spacer(minLength: 8)
                
                // Style Selector at bottom
                StyleSelectorView(
                    selectedStyle: $style
                )
            }
            
            // Center: Live Preview with Real Overlay
            LivePreviewPane(
                title: "Live Preview",
                targetAspect: 16.0/9.0
            ) {
                ZStack {
                    // Camera feed or mock preview for Xcode previews
                    if isInPreviewMode {
                        // Mock camera feed for previews
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white.opacity(0.8))
                                    
                                    Text("Mock Camera Preview")
                                        .font(.callout.weight(.medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                    
                                    Text("(Xcode Preview Mode)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            )
                    } else if let frame = cameraService.currentPreviewFrame {
                        Image(frame, scale: 1.0, label: Text("Camera preview"))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if hasStartedPreview {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Starting camera preview...")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 42))
                                .foregroundStyle(.secondary)
                            
                            Text("Camera preview will appear here")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .background(Color.black)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .onAppear {
            if !isInPreviewMode {
                Task {
                    hasStartedPreview = true
                    await cameraService.startOnboardingPreview()
                }
            }
        }
        .onDisappear {
            if !isInPreviewMode {
                cameraService.stopOnboardingPreview()
            }
        }
    }
}

// MARK: - Supporting Components

struct PersonalizeSection<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            Label {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: icon)
                    .imageScale(.medium)
                    .foregroundStyle(.tint)
            }

            // Card
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading) // ← fill
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StyledTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            
            TextField("", text: $text, prompt: Text(placeholder))
                .textFieldStyle(.plain)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

struct StyleSegment: View {
    let title: String
    let isSelected: Bool
    let shape: ModernOnboardingViewModel.StyleShape
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Mini thumbnail showing the style
                RoundedRectangle(cornerRadius: shape == .rounded ? 4 : 1)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 16, height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: shape == .rounded ? 4 : 1)
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 0.5)
                    )
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Supporting Components for Location and Style

struct LocationPermissionView: View {
    @EnvironmentObject private var locationManager: LocationPermissionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: locationStatusIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(locationStatusColor)
                    .frame(width: 16)
                
                Text(locationStatusText)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if locationManager.authorizationStatus == .notDetermined {
                    Button("Enable") {
                        locationManager.requestLocationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            
            if locationManager.authorizationStatus == .denied {
                Text("You can enable location services in System Settings > Privacy & Security > Location Services.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var locationStatusIcon: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "location.fill"
        case .denied, .restricted:
            return "location.slash.fill"
        default:
            return "location"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .green
        case .denied, .restricted:
            return .orange
        default:
            return .secondary
        }
    }
    
    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Location services enabled"
        case .denied:
            return "Location access denied"
        case .restricted:
            return "Location access restricted"
        default:
            return "Enable location for city and weather"
        }
    }
}

struct StyleSelectorView: View {
    @Binding var selectedStyle: ModernOnboardingViewModel.StyleShape
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.roundedtop")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 16)
                
                Text("Style")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(ModernOnboardingViewModel.StyleShape.allCases, id: \.self) { shape in
                        StyleSegment(
                            title: shape.rawValue,
                            isSelected: selectedStyle == shape,
                            shape: shape
                        ) {
                            selectedStyle = shape
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 220)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
}

// MARK: - Done Media

struct DoneMedia: View {
    @State private var checkmarkScale: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .scaleEffect(checkmarkScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: checkmarkScale)
            
            VStack(spacing: 8) {
                Text("You're ready to go!")
                    .font(.title2.bold())
                
                Text("Your virtual camera is set up and ready")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("Open any video app and select")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("Headliner", systemImage: "camera.fill")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                checkmarkScale = 1.0
            }
        }
    }
}
