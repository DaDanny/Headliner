//
//  StepMediaComponents.swift
//  Headliner
//
//  Step-specific media components for modern onboarding
//

import SwiftUI
import AVFoundation

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
    @Binding var style: ModernOnboardingViewModel.StyleShape
    
    @EnvironmentObject private var cameraService: CameraService
    
    var body: some View {
        VStack(spacing: 16) {
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
                    Text("Choose your input camera. This will be used in the live preview.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if cameraService.hasCameraPermission {
                        LoomStyleSelector(
                            title: "Camera",
                            items: cameraService.availableCameras,
                            selectedItem: cameraService.availableCameras.first { $0.id == selectedCameraID },
                            onSelectionChange: { camera in
                                if let camera = camera {
                                    selectedCameraID = camera.id
                                    Task {
                                        await cameraService.selectCamera(camera)
                                    }
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
            
            // Overlay Style Section
            PersonalizeSection(
                icon: "rectangle.roundedtop",
                title: "Overlay Style"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        ForEach(ModernOnboardingViewModel.StyleShape.allCases, id: \.self) { shape in
                            StyleSegment(
                                title: shape.rawValue,
                                isSelected: style == shape,
                                shape: shape
                            ) {
                                style = shape
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .frame(maxWidth: 480)
        .onAppear {
            // Set initial camera selection if not already set
            if selectedCameraID.isEmpty,
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
    let style: ModernOnboardingViewModel.StyleShape
    
    @EnvironmentObject private var cameraService: CameraService
    @State private var hasStartedPreview = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Live Preview")
                .font(.headline)
            
            ZStack {
                RoundedRectangle(cornerRadius: style == .rounded ? 16 : 4)
                    .fill(Color.black.opacity(0.05))
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    .frame(width: 480, height: 360)
                
                if let frame = cameraService.currentPreviewFrame {
                    Image(frame, scale: 1.0, label: Text("Camera preview"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 480, height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: style == .rounded ? 16 : 4))
                        .overlay(
                            previewOverlay
                                .allowsHitTesting(false),
                            alignment: .bottomLeading
                        )
                } else if hasStartedPreview {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Starting camera preview...")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("Camera preview will appear here")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Text("This is how you'll appear in video calls")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            Task {
                hasStartedPreview = true
                await cameraService.startOnboardingPreview()
            }
        }
        .onDisappear {
            cameraService.stopOnboardingPreview()
        }
    }
    
    @ViewBuilder
    private var previewOverlay: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Your Name" : name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: style == .rounded ? 8 : 2)
                    .fill(Color.black.opacity(0.7))
            )
            
            Spacer()
        }
        .padding(16)
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
            HStack(spacing: 8) {
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
            .padding(.horizontal, 16)
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
