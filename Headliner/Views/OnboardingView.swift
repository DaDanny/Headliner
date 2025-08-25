//
//  OnboardingView.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//
//  ⚠️ TEMPORARILY DISABLED FOR BIG BANG MIGRATION ⚠️
//  This file contains onboarding flow for windowed interface only.
//  Re-enable after migration complete by removing #if false wrapper.
//

//  🚨 LEGACY ONBOARDING - REFERENCE ONLY 🚨
//  This file contains the original onboarding implementation.
//  It has been replaced by ModernOnboardingView in Views/ModernOnboarding/
//  Wrapped in #if false to prevent compilation conflicts.

#if false // LEGACY CODE - DO NOT COMPILE

import SwiftUI
import CoreLocation

enum LegacyOnboardingStep: Int, CaseIterable {
  case welcome = 1
  case installExtension = 2
  case personalization = 3
  case chooseOverlay = 4
  
  var title: String {
    switch self {
    case .welcome: return "Welcome to Headliner"
    case .installExtension: return "Install Camera Extension"
    case .personalization: return "Personalization"
    case .chooseOverlay: return "Choose Your Style"
    }
  }
}

struct OnboardingView: View {
  let appCoordinator: AppCoordinator
  let onComplete: (() -> Void)?
  
  @EnvironmentObject private var extensionService: ExtensionService
  @EnvironmentObject private var cameraService: CameraService
  @EnvironmentObject private var overlayService: OverlayService
  @EnvironmentObject private var locationManager: LocationPermissionManager
  
  @State private var currentStep: LegacyOnboardingStep = .welcome
  @State private var hasInitialized = false
  @State private var selectedCameraID: String = ""
  @State private var selectedPresetId: String = "professional"
  
  init(appCoordinator: AppCoordinator, onComplete: (() -> Void)? = nil) {
    self.appCoordinator = appCoordinator
    self.onComplete = onComplete
  }

  var body: some View {
    VStack(spacing: 0) {
      // Progress Bar
      if currentStep != .welcome {
        LegacyOnboardingProgressBar(currentStep: currentStep.rawValue, totalSteps: 4)
          .padding(.top, 20)
      }
      
      // Step Content
      Group {
        switch currentStep {
        case .welcome:
          WelcomeStepView {
            nextStep()
          }
        case .installExtension:
          ExtensionStepView(appCoordinator: appCoordinator) {
            nextStep()
          }
        case .personalization:
          PersonalizationStepView(
            appCoordinator: appCoordinator,
            selectedCameraID: $selectedCameraID
          ) {
            nextStep()
          }
        case .chooseOverlay:
          ChooseOverlayStepView(
            appCoordinator: appCoordinator,
            selectedPresetId: $selectedPresetId
          ) {
            completeOnboarding()
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(Color(NSColor.windowBackgroundColor))
    .onAppear {
      if !hasInitialized {
        appCoordinator.initializeApp()
        hasInitialized = true
      }
    }
  }
  
  // MARK: - Actions
  
  private func nextStep() {
    if let nextStep = LegacyOnboardingStep(rawValue: currentStep.rawValue + 1) {
      withAnimation(.easeInOut(duration: 0.3)) {
        currentStep = nextStep
      }
    }
  }
  
  private func completeOnboarding() {
    // Apply selected camera and preset
    if !selectedCameraID.isEmpty {
      if let camera = cameraService.availableCameras.first(where: { $0.id == selectedCameraID }) {
        appCoordinator.selectCamera(camera)
      }
    }
    
    // Convert "clean" to "none" to match the system's preset naming
    let systemPresetId = selectedPresetId == "clean" ? "none" : selectedPresetId
    appCoordinator.selectOverlayPreset(systemPresetId)
    
    // Mark onboarding as complete
    UserDefaults.standard.set(true, forKey: "OnboardingCompleted")
    
    // Call completion handler if provided (for app-level state management)
    if let onComplete = onComplete {
      onComplete()
    } else {
      // Fallback to old approach
      appCoordinator.completeOnboarding()
    }
  }
}

// MARK: - Progress Bar

struct LegacyOnboardingProgressBar: View {
  let currentStep: Int
  let totalSteps: Int
  
  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Text("Step \(currentStep) of \(totalSteps)")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.secondary)
        Spacer()
      }
      
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 4)
            .cornerRadius(2)
          
          Rectangle()
            .fill(Color.blue)
            .frame(width: geometry.size.width * (CGFloat(currentStep) / CGFloat(totalSteps)), height: 4)
            .cornerRadius(2)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
      }
      .frame(height: 4)
    }
    .padding(.horizontal, 40)
  }
}

// MARK: - Step 1: Welcome

struct WelcomeStepView: View {
  let onContinue: () -> Void
  var showStepLabel: Bool = true

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isAnimating = false
  @State private var showFeatures = false

  var body: some View {
    VStack(spacing: 0) {
      // Optional step label
      if showStepLabel {
        Text("Step 1 • Welcome")
          .font(.callout.weight(.semibold))
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
          .padding(.top, 12)
      }

      Spacer(minLength: 24)

      VStack(spacing: 32) {
        // App Icon with animated gradient background
        ZStack {
          // Animated gradient background
          RoundedRectangle(cornerRadius: 28)
            .fill(
              LinearGradient(
                colors: [Color.blue, Color.purple, Color.blue.opacity(0.8)],
                startPoint: isAnimating ? .topLeading : .bottomTrailing,
                endPoint: isAnimating ? .bottomTrailing : .topLeading
              )
            )
            .frame(width: 140, height: 140)
            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
            .animation(
              .easeInOut(duration: 3).repeatForever(autoreverses: true),
              value: isAnimating
            )

          // Icon with subtle float animation
          Image(systemName: "video.circle.fill")
            .font(.system(size: 72, weight: .light))
            .foregroundStyle(.white)
            .scaleEffect(reduceMotion ? 1.0 : (isAnimating ? 1.05 : 1.0))
            .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
            .animation(
              reduceMotion ? .none : .easeInOut(duration: 2).repeatForever(autoreverses: true),
              value: isAnimating
            )
        }
        .accessibilityHidden(true)

        // Welcome Text
        VStack(spacing: 16) {
          Text("Welcome to Headliner")
            .font(.system(size: 38, weight: .bold))
            .foregroundStyle(.primary)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)

          Text("Your virtual camera companion for meetings")
            .font(.title2.weight(.medium))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 560)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: isAnimating)
        }

        // Feature highlights
        VStack(spacing: 20) {
          FeatureRow(
            icon: "bolt.fill",
            color: .green,
            title: "Quick Setup",
            description: "Ready in 2 minutes"
          )
          .opacity(showFeatures ? 1 : 0)
          .offset(y: showFeatures ? 0 : 20)
          .animation(.easeOut(duration: 0.4).delay(0.4), value: showFeatures)

          FeatureRow(
            icon: "rectangle.3.group.bubble.left.fill",
            color: .blue,
            title: "Works Everywhere",
            description: "Zoom, Meet, Slack & more"
          )
          .opacity(showFeatures ? 1 : 0)
          .offset(y: showFeatures ? 0 : 20)
          .animation(.easeOut(duration: 0.4).delay(0.5), value: showFeatures)

          FeatureRow(
            icon: "slider.horizontal.3",
            color: .purple,
            title: "Better Meetings & Interactions",
            description: "Look polished, feel confident, every call."
          )
          .opacity(showFeatures ? 1 : 0)
          .offset(y: showFeatures ? 0 : 20)
          .animation(.easeOut(duration: 0.4).delay(0.6), value: showFeatures)
        }
        .padding(.vertical, 8)

        // Get Started Button
        ModernButton("Get Started", style: .primary) {
          onContinue()
        }
        .keyboardShortcut(.defaultAction)
        .accessibilityLabel("Get Started")
        .accessibilityHint("Begin setup for the Headliner virtual camera.")
        .opacity(showFeatures ? 1 : 0)
        .scaleEffect(showFeatures ? 1 : 0.9)
        .animation(.easeOut(duration: 0.4).delay(0.7), value: showFeatures)
      }
      .padding(.horizontal, 32)

      Spacer(minLength: 32)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .onAppear {
      // Start animations
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isAnimating = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        showFeatures = true
      }
    }
  }
}

// Feature row component for welcome screen
private struct FeatureRow: View {
  let icon: String
  let color: Color
  let title: String
  let description: String

  var body: some View {
    HStack(spacing: 16) {
      // Icon
      ZStack {
        Circle()
          .fill(color.opacity(0.15))
          .frame(width: 36, height: 36)
        
        Image(systemName: icon)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(color)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.primary)
        
        Text(description)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
    .frame(maxWidth: 360)
  }
}

// MARK: - Step 2: Extension Installation

struct ExtensionStepView: View {
  let appCoordinator: AppCoordinator
  let onContinue: () -> Void
  
  @EnvironmentObject private var extensionService: ExtensionService

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isAnimating = false
  @State private var showSteps = false

  // Derived state
  private var isInstalling: Bool { extensionService.status == .installing }
  private var isInstalled: Bool { extensionService.status == .installed }
  
  private var canContinue: Bool { isInstalled }

  var body: some View {
    VStack(spacing: 0) {
      // Step label
      Text("Step 2 • Install Virtual Camera")
        .font(.callout.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.top, 12)
        .accessibilityHidden(true)

      Spacer(minLength: 24)

      // Main content
      VStack(spacing: 32) {
        // Animated icon
        ZStack {
          // Background glow
          Circle()
            .fill(Color.blue.opacity(0.15))
            .frame(width: 160, height: 160)
            .scaleEffect(isAnimating ? 1.1 : 0.9)
            .opacity(isAnimating ? 0.8 : 0.4)
            .animation(
              .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
              value: isAnimating
            )

          // Icon
          Image(systemName: "gear.circle.fill")
            .font(.system(size: 80))
            .foregroundStyle(
              LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
            .rotationEffect(.degrees(isInstalling ? 360 : 0))
            .animation(
              isInstalling ? 
                .linear(duration: 2).repeatForever(autoreverses: false) : 
                .default,
              value: isInstalling
            )
        }
        .opacity(isAnimating ? 1 : 0)
        .scaleEffect(isAnimating ? 1 : 0.8)
        .animation(.easeOut(duration: 0.6), value: isAnimating)

        // Title and description
        VStack(spacing: 12) {
          Text("Install Camera Extension")
            .font(.system(size: 32, weight: .bold))
            .foregroundStyle(.primary)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.1), value: isAnimating)

          Text("We need to install a system extension to enable virtual camera functionality.")
            .font(.title3.weight(.medium))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 480)
            .padding(.horizontal)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
        }

        // Installation steps
        VStack(spacing: 16) {
          InstallationStep(
            number: 1,
            title: "System Settings",
            description: "You'll be taken to System Settings to approve the extension",
            isActive: !isInstalled && !isInstalling
          )
          .opacity(showSteps ? 1 : 0)
          .offset(y: showSteps ? 0 : 20)
          .animation(.easeOut(duration: 0.4).delay(0.3), value: showSteps)

          InstallationStep(
            number: 2,
            title: "Approve Extension",
            description: "Click 'Allow' in the security prompt to enable the extension",
            isActive: isInstalling
          )
          .opacity(showSteps ? 1 : 0)
          .offset(y: showSteps ? 0 : 20)
          .animation(.easeOut(duration: 0.4).delay(0.4), value: showSteps)

          InstallationStep(
            number: 3,
            title: "Ready to Use",
            description: "The extension will be installed and ready to use",
            isActive: isInstalled
          )
          .opacity(showSteps ? 1 : 0)
          .offset(y: showSteps ? 0 : 20)
          .animation(.easeOut(duration: 0.4).delay(0.5), value: showSteps)
        }
        .padding(.horizontal, 32)

        // Action buttons
        VStack(spacing: 16) {
          if isInstalling {
            VStack(spacing: 12) {
              ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.3)
              Text("Installing virtual camera…")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
              Text("Look for the security prompt to approve the extension")
                .font(.footnote)
                .foregroundStyle(.tertiary)
            }
          } else if isInstalled {
            VStack(spacing: 12) {
              Label("Extension installed successfully!", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.body.weight(.semibold))
              ModernButton("Continue", style: .primary) {
                onContinue()
              }
              .keyboardShortcut(.defaultAction)
              .accessibilityLabel("Continue to next step")
            }
          } else {
            ModernButton("Install Extension", style: .primary) {
              appCoordinator.installExtension()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(isInstalling)
            .accessibilityLabel("Install the Headliner virtual camera")
            .accessibilityHint("Opens System Settings to approve the camera extension.")
          }

          // Status message
          if !extensionService.statusMessage.isEmpty {
            Text(extensionService.statusMessage)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .frame(maxWidth: 480)
              .padding(.horizontal)
          }
        }
        .opacity(showSteps ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.6), value: showSteps)
      }
      .padding(.horizontal, 24)

      Spacer(minLength: 32)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isAnimating = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        showSteps = true
      }
    }
  }
}

// Installation step component
private struct InstallationStep: View {
  let number: Int
  let title: String
  let description: String
  let isActive: Bool

  var body: some View {
    HStack(spacing: 16) {
      // Step number
      ZStack {
        Circle()
          .fill(isActive ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
          .frame(width: 32, height: 32)
        
        Text("\(number)")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(isActive ? .blue : .gray)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(isActive ? .primary : .secondary)
        
        Text(description)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Spacer()

      // Status indicator
      if isActive {
        Circle()
          .fill(Color.blue)
          .frame(width: 8, height: 8)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(isActive ? Color(nsColor: .controlBackgroundColor) : Color.clear)
    )
    .animation(.easeInOut(duration: 0.3), value: isActive)
  }
}

// MARK: - Step 4: Choose Your Overlay Style

struct ChooseOverlayStepView: View {
  let appCoordinator: AppCoordinator
  @Binding var selectedPresetId: String
  let onContinue: () -> Void
  
  @EnvironmentObject private var cameraService: CameraService
  @EnvironmentObject private var overlayService: OverlayService
  @State private var isAnimating = false
  @State private var isPreviewActive = false
  
  // Curated presets for onboarding - easily configurable
  private var onboardingPresets: [SwiftUIPresetInfo] {
    let allPresets = overlayService.availablePresets
    
    // Option 1: Show specific curated presets (currently enabled)
    let curatedIds = [
      "swiftui.identity.strip",        // Professional identity
      "swiftui.modern.personal",       // Personal with modern look
      "swiftui.clean",                 // Clean/no overlay
      "swiftui.status.bar",           // Status bar with weather/time
      "swiftui.info.corner"           // Corner info display
    ]
    
    // Option 2: Show all presets (uncomment to enable)
    // return allPresets
    
    // Option 3: Filter by categories (uncomment to enable)
    // return allPresets.filter { preset in
    //   [.standard, .minimal, .branded].contains(preset.category)
    // }
    
    // Option 4: Exclude test presets (uncomment to enable)
    // return allPresets.filter { preset in
    //   !preset.id.contains("test") && !preset.id.contains("validation")
    // }
    
    // Currently using curated list
    return curatedIds.compactMap { id in
      allPresets.first { $0.id == id }
    }
  }
  
  var body: some View {
    VStack(spacing: 0) {
      OverlayStepHeader(isAnimating: isAnimating)
      
      if cameraService.hasCameraPermission {
        OverlaySelectionContent(
          selectedPresetId: $selectedPresetId,
          isAnimating: isAnimating,
          isPreviewActive: isPreviewActive,
          onboardingPresets: onboardingPresets,
          overlayService: overlayService,
          cameraService: cameraService
        )
      } else {
        OverlayCameraPermissionContent(
          isAnimating: isAnimating,
          cameraService: cameraService
        )
      }
      
      Spacer()
      
      OverlayStepActions(
        isAnimating: isAnimating,
        onContinue: onContinue
      )
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
    .onAppear {
      withAnimation(.easeOut(duration: 0.8)) {
        isAnimating = true
      }
      
      // Initialize with first preset if none selected
      if selectedPresetId.isEmpty, let firstPreset = onboardingPresets.first {
        selectedPresetId = firstPreset.id
        overlayService.selectPreset(firstPreset.id)
      }
      
      // Start preview if camera is already selected from previous step
      if cameraService.selectedCamera != nil && cameraService.hasCameraPermission {
        Task {
          isPreviewActive = true
          await cameraService.startOnboardingPreview()
        }
      }
    }
    .onChange(of: cameraService.selectedCamera) { _, newCamera in
      // Start/stop preview when camera selection changes
      if newCamera != nil {
        Task {
          isPreviewActive = true
          await cameraService.startOnboardingPreview()
        }
      } else {
        isPreviewActive = false
        cameraService.stopOnboardingPreview()
      }
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.8)) {
        isAnimating = true
      }
      
      // Initialize with first preset if none selected
      if selectedPresetId.isEmpty, let firstPreset = onboardingPresets.first {
        selectedPresetId = firstPreset.id
        overlayService.selectPreset(firstPreset.id)
      }
      
      // Start preview if camera already selected from previous step
      if cameraService.selectedCamera != nil && cameraService.hasCameraPermission {
        Task {
          isPreviewActive = true
          await cameraService.startOnboardingPreview()
        }
      }
    }
    .onDisappear {
      // Stop preview when leaving this step
      cameraService.stopOnboardingPreview()
      isPreviewActive = false
    }
  }

// MARK: - Overlay Step Components

private struct OverlayStepHeader: View {
  let isAnimating: Bool
  
  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "camera.fill")
        .font(.system(size: 40, weight: .light))
        .foregroundStyle(
          LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
      
      VStack(spacing: 6) {
        Text("Choose Your Style")
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.primary)
        
        Text("Select a preset to see it applied live with your personal information")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity)
    .opacity(isAnimating ? 1.0 : 0.0)
    .offset(y: isAnimating ? 0 : 20)
    .animation(.easeOut(duration: 0.6), value: isAnimating)
    .padding(.bottom, 24)
  }
}

private struct OverlaySelectionContent: View {
  @Binding var selectedPresetId: String
  let isAnimating: Bool
  let isPreviewActive: Bool
  let onboardingPresets: [SwiftUIPresetInfo]
  let overlayService: OverlayService
  let cameraService: CameraService
  
  var body: some View {
    HStack(alignment: .top, spacing: 32) {
      OverlayPresetGrid(
        selectedPresetId: $selectedPresetId,
        isAnimating: isAnimating,
        onboardingPresets: onboardingPresets,
        overlayService: overlayService
      )
      
      OverlayLivePreview(
        isAnimating: isAnimating,
        isPreviewActive: isPreviewActive,
        cameraService: cameraService
      )
    }
  }
}

private struct OverlayPresetGrid: View {
  @Binding var selectedPresetId: String
  let isAnimating: Bool
  let onboardingPresets: [SwiftUIPresetInfo]
  let overlayService: OverlayService
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Choose Your Style")
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.primary)
        
        Text("Select a preset to see it applied live")
          .font(.system(size: 13))
          .foregroundColor(.secondary)
      }
      
      ScrollView(.vertical, showsIndicators: false) {
        LazyVGrid(columns: [
          GridItem(.flexible(), spacing: 10),
          GridItem(.flexible(), spacing: 10)
        ], spacing: 12) {
          ForEach(onboardingPresets, id: \.id) { preset in
            SwiftUIPresetGridCard(
              preset: preset,
              isSelected: selectedPresetId == preset.id,
              action: { 
                selectedPresetId = preset.id
                overlayService.selectPreset(preset.id)
              }
            )
          }
        }
        .padding(.horizontal, 4)
      }
      .frame(height: 320)
    }
    .frame(width: 360)
    .opacity(isAnimating ? 1.0 : 0.0)
    .offset(x: isAnimating ? 0 : -20)
    .animation(.easeOut(duration: 0.6).delay(0.3), value: isAnimating)
  }
}

private struct OverlayLivePreview: View {
  let isAnimating: Bool
  let isPreviewActive: Bool
  let cameraService: CameraService
  
  var body: some View {
    VStack(spacing: 12) {
      Text("Live Preview")
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(.primary)
      
      ZStack {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.secondary.opacity(0.08))
          .frame(width: 480, height: 360)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
          )
        
        if let currentFrame = cameraService.currentPreviewFrame {
          Image(currentFrame, scale: 1.0, label: Text("Camera preview"))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 480, height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        } else if isPreviewActive {
          OverlayPreviewLoading()
        } else {
          OverlayPreviewPlaceholder()
        }
      }
      .opacity(isAnimating ? 1.0 : 0.0)
      .offset(x: isAnimating ? 0 : 20)
      .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
      
      Text("This is exactly how you'll appear in Zoom, Meet, and other apps")
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .opacity(isAnimating ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: isAnimating)
    }
    .frame(width: 480)
  }
}

private struct OverlayPreviewLoading: View {
  var body: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.8)
      Text("Starting your camera...")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.secondary)
    }
  }
}

private struct OverlayPreviewPlaceholder: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "video.circle")
        .font(.system(size: 56))
        .foregroundStyle(.secondary)
      
      VStack(spacing: 6) {
        Text("Your Camera Preview")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(.primary)
        
        Text("Camera already selected from previous step")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
  }
}

private struct OverlayCameraPermissionContent: View {
  let isAnimating: Bool
  let cameraService: CameraService
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      
      CameraPermissionView(onRequestPermission: {
        Task {
          _ = await cameraService.requestPermission()
        }
      })
      .frame(maxWidth: 600)
      
      Spacer()
    }
    .opacity(isAnimating ? 1.0 : 0.0)
    .offset(y: isAnimating ? 0 : 20)
    .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
  }
}

private struct OverlayStepActions: View {
  let isAnimating: Bool
  let onContinue: () -> Void
  
  var body: some View {
    VStack(spacing: 16) {
      ModernButton(
        "Finish Setup",
        icon: "checkmark",
        style: .primary
      ) {
        onContinue()
      }
      .opacity(isAnimating ? 1.0 : 0.0)
      .offset(y: isAnimating ? 0 : 20)
      .animation(.easeOut(duration: 0.6).delay(0.6), value: isAnimating)
    }
    .frame(maxWidth: .infinity)
  }
}

private struct OverlayWarningMessage: View {
  let isAnimating: Bool
  
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
        .font(.system(size: 16))
      
      Text("Continue to finish setup with your selected overlay")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.orange)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.orange.opacity(0.1))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
    )
    .opacity(isAnimating ? 1.0 : 0.0)
    .offset(y: isAnimating ? 0 : 20)
    .animation(.easeOut(duration: 0.6).delay(0.5), value: isAnimating)
  }
}

// Camera permission view component
private struct CameraPermissionView: View {
  let onRequestPermission: () -> Void
  
  var body: some View {
    VStack(spacing: 20) {
      // Permission icon
      ZStack {
        Circle()
          .fill(Color.orange.opacity(0.15))
          .frame(width: 80, height: 80)
        
        Image(systemName: "lock.shield")
          .font(.system(size: 36))
          .foregroundStyle(.orange)
      }
      
      VStack(spacing: 12) {
        Text("Camera Access Required")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.primary)
        
        Text("We need camera access to show you available devices and enable the virtual camera.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: 400)
      }
      
      ModernButton("Enable Camera Access", style: .primary) {
        onRequestPermission()
      }
      .accessibilityLabel("Enable camera access")
      .accessibilityHint("Opens system settings to grant camera permission")
    }
    .padding(.vertical, 24)
    .padding(.horizontal, 32)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
  }
}

// MARK: - Step 3: Personalization  

struct PersonalizationStepView: View {
  let appCoordinator: AppCoordinator
  @Binding var selectedCameraID: String
  let onContinue: () -> Void
  
  @EnvironmentObject private var cameraService: CameraService
  @EnvironmentObject private var locationManager: LocationPermissionManager
  @State private var isAnimating = false
  
  var body: some View {
    VStack(spacing: 0) {
      // Header - Centered
      VStack(spacing: 20) {
        Image(systemName: "person.circle.fill")
          .font(.system(size: 48, weight: .light))
          .foregroundStyle(
            LinearGradient(
              colors: [.orange, .blue],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .scaleEffect(isAnimating ? 1.1 : 1.0)
          .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
        
        VStack(spacing: 12) {
          Text("Set Up Your Profile")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.primary)
          
          Text("Choose your camera, add your name and tagline, and optionally enable location to show your city and weather.")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 600)
        }
      }
      .frame(maxWidth: .infinity)
      .opacity(isAnimating ? 1.0 : 0.0)
      .offset(y: isAnimating ? 0 : 20)
      .padding(.bottom, 40)
      
      // Content Container - Centered with fixed width
      VStack(spacing: 28) {
        // Camera Selection Section
        VStack(spacing: 16) {
          HStack {
            Text("Camera Device")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(.primary)
            Spacer()
            
            // Camera selection confirmation
            if let selectedCamera = cameraService.selectedCamera {
              HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundStyle(.green)
                  .font(.system(size: 16))
                
                Text("Selected: \(selectedCamera.name)")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(.secondary)
              }
            }
          }
          
          if cameraService.hasCameraPermission {
            CameraSelector()
              .frame(maxWidth: 500)
          } else {
            VStack(spacing: 12) {
              Image(systemName: "video.slash")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
              
              Text("Camera access required")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
              
              Text("Please grant camera permission to continue")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
              
              Button("Grant Permission") {
                cameraService.requestCameraPermission()
              }
              .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
            )
          }
        }
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(nsColor: .controlBackgroundColor))
        )
        .padding()
        .opacity(isAnimating ? 1.0 : 0.0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: isAnimating)
        
        // Personal Info Section
        PersonalInfoView()
           .background(
             RoundedRectangle(cornerRadius: 10)
               .fill(Color(NSColor.controlBackgroundColor))
               .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
           )
           .opacity(isAnimating ? 1.0 : 0.0)
           .offset(y: isAnimating ? 0 : 20)
           .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
         
         // Location Services Section
         LocationInfoView(
           coordinator: appCoordinator,
           showHeader: false,
           showInfoSection: false,
           showRefreshButton: false
         )
           .background(
             RoundedRectangle(cornerRadius: 10)
               .fill(Color(NSColor.controlBackgroundColor))
               .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
           )
           .opacity(isAnimating ? 1.0 : 0.0)
           .offset(y: isAnimating ? 0 : 20)
           .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimating)
       }
       .frame(maxWidth: 760)
      
      Spacer()
      
      // Continue Button - Centered
      ModernButton(
        "Finish Setup",
        icon: "checkmark",
        style: .primary
      ) {
        onContinue()
      }
      .opacity(isAnimating ? 1.0 : 0.0)
      .offset(y: isAnimating ? 0 : 20)
      .animation(.easeOut(duration: 0.6).delay(0.6), value: isAnimating)
      .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 24)
    .onAppear {
      withAnimation(.easeOut(duration: 0.8)) {
        isAnimating = true
      }
    }
    .onChange(of: cameraService.selectedCamera) { _, newCamera in
      if let camera = newCamera {
        selectedCameraID = camera.uniqueID
      }
    }
  }
}







// MARK: - Helper Views

/*
#if DEBUG

// MARK: - Preview-Only Mock - Disabled for new architecture

/*
private class PreviewAppState: AppState {
  override init(
    systemExtensionManager: SystemExtensionRequestManager = SystemExtensionRequestManager(logText: "Preview"),
    propertyManager: CustomPropertyManager = CustomPropertyManager(),
    outputImageManager: OutputImageManager = OutputImageManager()
  ) {
    super.init(
      systemExtensionManager: systemExtensionManager,
      propertyManager: propertyManager,
      outputImageManager: outputImageManager
    )
    
    // Set default values for previews
    self.extensionStatus = .notInstalled
    self.availableCameras = []
    self.statusMessage = ""
  }
  
  // Private properties for preview customization
  private var _isLocationAvailable: Bool = false
  private var _locationPermissionStatus: CLAuthorizationStatus = .notDetermined
  
  // Convenience initializer for different preview states
  convenience init(
    extensionStatus: ExtensionStatus,
    statusMessage: String = "",
    availableCameras: [CameraDevice] = [],
    isLocationAvailable: Bool = false
  ) {
    self.init()
    self.extensionStatus = extensionStatus
    self.statusMessage = statusMessage
    self.availableCameras = availableCameras
    self._isLocationAvailable = isLocationAvailable
    self._locationPermissionStatus = isLocationAvailable ? .authorized : .notDetermined
  }
  
  convenience init(
    availableCameras: [CameraDevice],
    isLocationAvailable: Bool = false
  ) {
    self.init()
    self.availableCameras = availableCameras
    self._isLocationAvailable = isLocationAvailable
    self._locationPermissionStatus = isLocationAvailable ? .authorized : .notDetermined
  }
  
  convenience init(
    isLocationAvailable: Bool
  ) {
    self.init()
    self._isLocationAvailable = isLocationAvailable
    self._locationPermissionStatus = isLocationAvailable ? .authorized : .notDetermined
  }
  
  // Override methods to provide preview-specific behavior
  override var hasCameraPermission: Bool { true }
  override var isLocationAvailable: Bool { _isLocationAvailable }
  override var locationPermissionStatus: CLAuthorizationStatus { _locationPermissionStatus }
  override var needsPermissions: Bool { false }
  
  override func initializeForUse() {}
  override func installExtension() {}
  override func startCamera() {}
  override func stopCamera() {}
  override func selectCamera(_ camera: CameraDevice) {}
  override func refreshCameras() {}
  override func updateOverlaySettings(_ newSettings: OverlaySettings) {}
  override func selectPreset(_ presetId: String) {}
  override func updateOverlayTokens(_ tokens: OverlayTokens) {}
  override func selectAspectRatio(_ aspect: OverlayAspect) {}
  override var currentPresetId: String { "professional" }
  override var currentAspectRatio: OverlayAspect { .widescreen }
  override func startPersonalInfoPump() {}
  override func stopPersonalInfoPump() {}
  override func refreshPersonalInfoNow() {}
  override func requestLocationPermission() {}
  override func openLocationSettings() {}
  override func requestCameraPermission() async -> Bool { return true }
  override func retryCaptureSession() {}
}

// MARK: - Complete Onboarding Flow Preview

struct OnboardingFlowPreview: PreviewProvider {
  static var previews: some View {
    Group {
      // Full flow with progress bar
      OnboardingView(appState: PreviewAppState())
        .frame(width: 1200, height: 800)
        .previewDisplayName("Complete Onboarding Flow")
      
      // Individual steps for focused testing
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 1, totalSteps: 4)
          .padding(.top, 20)
        WelcomeStepView {}
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Step 1: Welcome")
      
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 2, totalSteps: 4)
          .padding(.top, 20)
        ExtensionStepView(appState: PreviewAppState(), onContinue: {})
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Step 2: Extension Installation")
      
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 3, totalSteps: 4)
          .padding(.top, 20)
        CameraSetupStepView(
          appState: PreviewAppState(availableCameras: [
            CameraDevice(id: "built-in", name: "Built-in Camera", deviceType: "Built-in Camera"),
            CameraDevice(id: "external", name: "Logitech C920", deviceType: "External Camera"),
            CameraDevice(id: "iphone", name: "iPhone Camera", deviceType: "iPhone Camera")
          ]),
          selectedCameraID: .constant("built-in"),
          selectedPresetId: .constant("professional"),
          onContinue: {}
        )
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Step 3: Camera Setup")
      
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 4, totalSteps: 4)
          .padding(.top, 20)
        PersonalizationStepView(appState: PreviewAppState(), onContinue: {})
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Step 4: Personalization")
    }
  }
}

// MARK: - Individual Step State Previews

struct ExtensionStepStatesPreview: PreviewProvider {
  static var previews: some View {
    Group {
      // Not installed state
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 2, totalSteps: 4)
          .padding(.top, 20)
        ExtensionStepView(
          appState: PreviewAppState(extensionStatus: .notInstalled),
          onContinue: {}
        )
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Extension: Not Installed")
      
      // Installing state
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 2, totalSteps: 4)
          .padding(.top, 20)
        ExtensionStepView(
          appState: PreviewAppState(
            extensionStatus: .installing,
            statusMessage: "Installing system extension..."
          ),
          onContinue: {}
        )
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Extension: Installing")
      
      // Installed state
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 2, totalSteps: 4)
          .padding(.top, 20)
        ExtensionStepView(
          appState: PreviewAppState(extensionStatus: .installed),
          onContinue: {}
        )
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Extension: Installed")
    }
  }
}

struct CameraStepStatesPreview: PreviewProvider {
  static var previews: some View {
    Group {
      // No camera permission
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 3, totalSteps: 4)
          .padding(.top, 20)
        CameraSetupStepView(
          appState: PreviewAppState(availableCameras: []),
          selectedCameraID: .constant(""),
          selectedPresetId: .constant("professional"),
          onContinue: {}
        )
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Camera: No Permission")
      
      // With cameras available
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 3, totalSteps: 4)
          .padding(.top, 20)
        CameraSetupStepView(
          appState: PreviewAppState(availableCameras: [
            CameraDevice(id: "built-in", name: "Built-in Camera", deviceType: "Built-in Camera"),
            CameraDevice(id: "external", name: "Logitech C920", deviceType: "External Camera"),
            CameraDevice(id: "iphone", name: "iPhone Camera", deviceType: "iPhone Camera")
          ]),
          selectedCameraID: .constant("built-in"),
          selectedPresetId: .constant("professional"),
          onContinue: {}
        )
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Camera: With Cameras")
    }
  }
}

struct PersonalizationStepStatesPreview: PreviewProvider {
  static var previews: some View {
    Group {
      // Location not available
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 4, totalSteps: 4)
          .padding(.top, 20)
        PersonalizationStepView(
          appState: PreviewAppState(),
          onContinue: {}
        )
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Personalization: Location Not Available")
      
      // Location available
      VStack(spacing: 0) {
        OnboardingProgressBar(currentStep: 4, totalSteps: 4)
          .padding(.top, 20)
        PersonalizationStepView(
          appState: PreviewAppState(isLocationAvailable: true),
          onContinue: {}
        )
      }
      .frame(width: 1200, height: 800)
      .background(Color(NSColor.windowBackgroundColor))
      .previewDisplayName("Personalization: Location Available")
    }
  }
}

// MARK: - Component Previews

struct ProgressBarPreview: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      OnboardingProgressBar(currentStep: 1, totalSteps: 4)
      OnboardingProgressBar(currentStep: 2, totalSteps: 4)
      OnboardingProgressBar(currentStep: 3, totalSteps: 4)
      OnboardingProgressBar(currentStep: 4, totalSteps: 4)
    }
    .padding()
    .frame(width: 400, height: 200)
    .background(Color(NSColor.windowBackgroundColor))
    .previewDisplayName("Progress Bar States")
  }
}

struct OverlayPresetCardPreview: PreviewProvider {
  static var previews: some View {
    HStack(spacing: 16) {
      ForEach(OverlayPresetOption.allCases, id: \.self) { preset in
        OverlayPresetCardView(
          preset: preset,
          isSelected: preset == .clean, // Show clean as selected for demo
          action: {}
        )
      }
    }
    .padding()
    .frame(width: 400, height: 200)
    .background(Color(NSColor.windowBackgroundColor))
    .previewDisplayName("Overlay Preset Cards")
  }
}

*/

#endif
*/

// MARK: - SwiftUI Preset Grid Card for Onboarding

private struct SwiftUIPresetGridCard: View {
  let preset: SwiftUIPresetInfo
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      VStack(spacing: 12) {
        // Preview mockup - more compact for grid
        ZStack {
          RoundedRectangle(cornerRadius: 10)
            .fill(preset.category.color.opacity(0.1))
            .frame(height: 80)
          
          // Mock person silhouette
          RoundedRectangle(cornerRadius: 6)
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 60, height: 45)
          
          // Overlay preview based on preset
          overlayPreviewForPreset(preset)
        }
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(isSelected ? preset.category.color : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        
        // Info - Compact
        VStack(spacing: 4) {
          HStack(spacing: 6) {
            Image(systemName: preset.category.icon)
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(preset.category.color)
            
            Text(preset.name)
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(.primary)
              .lineLimit(1)
            
            Spacer()
            
            if isSelected {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(preset.category.color)
                .font(.system(size: 14))
            }
          }
          
          if !isSelected {
            Text(preset.description)
              .font(.system(size: 10))
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
          }
        }
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(isSelected ? preset.category.color.opacity(0.05) : Color(nsColor: .controlBackgroundColor))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? preset.category.color.opacity(0.3) : Color.secondary.opacity(0.1), lineWidth: 1)
      )
      .scaleEffect(isSelected ? 1.02 : 1.0)
      .shadow(color: isSelected ? preset.category.color.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
      .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    .buttonStyle(.plain)
  }
  
  @ViewBuilder
  private func overlayPreviewForPreset(_ preset: SwiftUIPresetInfo) -> some View {
    if preset.id == "swiftui.clean" {
      EmptyView()
    } else if preset.id.contains("identity.strip") || preset.id.contains("modern.personal") {
      VStack {
        Spacer()
        HStack {
          RoundedRectangle(cornerRadius: 2)
            .fill(preset.category.color.opacity(0.8))
            .frame(width: 40, height: 8)
          Spacer()
        }
        .padding(4)
      }
    } else if preset.id.contains("status.bar") {
      VStack {
        HStack {
          RoundedRectangle(cornerRadius: 2)
            .fill(preset.category.color.opacity(0.8))
            .frame(width: 50, height: 6)
          Spacer()
        }
        .padding(4)
        Spacer()
      }
    } else if preset.id.contains("corner") {
      VStack {
        Spacer()
        HStack {
          Spacer()
          RoundedRectangle(cornerRadius: 2)
            .fill(preset.category.color.opacity(0.8))
            .frame(width: 20, height: 6)
        }
        .padding(4)
      }
    } else {
      VStack {
        Spacer()
        HStack {
          RoundedRectangle(cornerRadius: 2)
            .fill(preset.category.color.opacity(0.8))
            .frame(width: 30, height: 6)
          Spacer()
        }
        .padding(4)
      }
    }
  }
}

// MARK: - SwiftUI Preset Card for Onboarding Gallery (Legacy - keeping for compatibility)

private struct SwiftUIPresetCard: View {
  let preset: SwiftUIPresetInfo
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      VStack(spacing: 16) {
        // Preview mockup
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(preset.category.color.opacity(0.1))
            .frame(width: 140, height: 105)
          
          // Mock person silhouette
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 100, height: 75)
          
          // Overlay preview based on preset category
          overlayPreviewForPreset(preset)
        }
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? preset.category.color : Color.secondary.opacity(0.2), lineWidth: isSelected ? 3 : 1)
        )
        
        // Info
        VStack(spacing: 6) {
          // Icon and title
          HStack(spacing: 8) {
            Image(systemName: preset.category.icon)
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(preset.category.color)
            
            Text(preset.name)
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(.primary)
            
            Spacer()
          }
          
          // Description
          HStack {
            Text(preset.description)
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
              .lineLimit(2)
            Spacer()
          }
        }
        
        // Selection indicator
        HStack {
          Spacer()
          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(preset.category.color)
              .font(.system(size: 20))
          } else {
            Circle()
              .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
              .frame(width: 20, height: 20)
          }
          Spacer()
        }
      }
      .padding(16)
      .frame(width: 180)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(isSelected ? preset.category.color.opacity(0.05) : Color(nsColor: .controlBackgroundColor))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(isSelected ? preset.category.color.opacity(0.3) : Color.secondary.opacity(0.1), lineWidth: 1)
      )
      .scaleEffect(isSelected ? 1.05 : 1.0)
      .shadow(color: isSelected ? preset.category.color.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
      .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
    .buttonStyle(.plain)
  }
  
  @ViewBuilder
  private func overlayPreviewForPreset(_ preset: SwiftUIPresetInfo) -> some View {
    if preset.id == "swiftui.clean" {
      // No overlay for clean
      EmptyView()
    } else if preset.id.contains("identity.strip") || preset.id.contains("modern.personal") {
      // Bottom strip for identity/personal
      VStack {
        Spacer()
        HStack {
          RoundedRectangle(cornerRadius: 4)
            .fill(preset.category.color.opacity(0.8))
            .frame(width: 80, height: 20)
          Spacer()
        }
        .padding(8)
      }
    } else if preset.id.contains("status.bar") {
      // Top bar for status
      VStack {
        HStack {
          RoundedRectangle(cornerRadius: 4)
            .fill(preset.category.color.opacity(0.8))
            .frame(width: 100, height: 16)
          Spacer()
        }
        .padding(8)
        Spacer()
      }
    } else if preset.id.contains("corner") {
      // Corner element
      VStack {
        Spacer()
        HStack {
          Spacer()
          RoundedRectangle(cornerRadius: 4)
            .fill(preset.category.color.opacity(0.8))
            .frame(width: 40, height: 16)
        }
        .padding(8)
      }
    } else {
      // Default overlay position
      VStack {
        Spacer()
        HStack {
          RoundedRectangle(cornerRadius: 4)
            .fill(preset.category.color.opacity(0.8))
            .frame(width: 60, height: 16)
          Spacer()
        }
        .padding(8)
      }
    }
  }
}



// End OnboardingView implementation
}

#endif // LEGACY CODE - DO NOT COMPILE
