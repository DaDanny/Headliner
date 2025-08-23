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

#if false // 🚧 DISABLED DURING BIG BANG MIGRATION - RE-ENABLE LATER

import SwiftUI
import CoreLocation

enum OnboardingStep: Int, CaseIterable {
  case welcome = 1
  case installExtension = 2
  case cameraSetup = 3
  case personalization = 4
  
  var title: String {
    switch self {
    case .welcome: return "Welcome to Headliner"
    case .installExtension: return "Install Camera Extension"
    case .cameraSetup: return "Set Up Camera"
    case .personalization: return "Personalization"
    }
  }
}

struct OnboardingView: View {
  @ObservedObject var appState: AppState
  @State private var currentStep: OnboardingStep = .welcome
  @State private var hasInitialized = false
  @State private var selectedCameraID: String = ""
  @State private var selectedPresetId: String = "professional"

  var body: some View {
    VStack(spacing: 0) {
      // Progress Bar
      if currentStep != .welcome {
        OnboardingProgressBar(currentStep: currentStep.rawValue, totalSteps: 4)
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
          ExtensionStepView(appState: appState) {
            nextStep()
          }
        case .cameraSetup:
          CameraSetupStepView(
            appState: appState,
            selectedCameraID: $selectedCameraID,
            selectedPresetId: $selectedPresetId
          ) {
            nextStep()
          }
        case .personalization:
          PersonalizationStepView(appState: appState) {
            completeOnboarding()
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(Color(NSColor.windowBackgroundColor))
    .onAppear {
      if !hasInitialized {
        appState.initializeForUse()
        hasInitialized = true
      }
    }
  }
  
  // MARK: - Actions
  
  private func nextStep() {
    if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
      withAnimation(.easeInOut(duration: 0.3)) {
        currentStep = nextStep
      }
    }
  }
  
  private func completeOnboarding() {
    // Apply selected camera and preset
    if !selectedCameraID.isEmpty {
      if let camera = appState.availableCameras.first(where: { $0.id == selectedCameraID }) {
        appState.selectCamera(camera)
      }
    }
    
    // Convert "clean" to "none" to match the system's preset naming
    let systemPresetId = selectedPresetId == "clean" ? "none" : selectedPresetId
    appState.selectPreset(systemPresetId)
    
    // Onboarding complete - ContentView will switch to MainAppView
  }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
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
  @ObservedObject var appState: AppState
  let onContinue: () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isAnimating = false
  @State private var showSteps = false

  // Derived state
  private var isInstalling: Bool { appState.extensionStatus == .installing }
  private var isInstalled: Bool { appState.extensionStatus.isInstalled }
  
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
              appState.installExtension()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(isInstalling)
            .accessibilityLabel("Install the Headliner virtual camera")
            .accessibilityHint("Opens System Settings to approve the camera extension.")
          }

          // Status message
          if !appState.statusMessage.isEmpty {
            Text(appState.statusMessage)
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

// MARK: - Step 3: Camera Setup

struct CameraSetupStepView: View {
  @ObservedObject var appState: AppState
  @Binding var selectedCameraID: String
  @Binding var selectedPresetId: String
  let onContinue: () -> Void
  
  @State private var isAnimating = false
  
  var body: some View {
    VStack(spacing: 0) {
      // Header - Centered
      VStack(spacing: 16) {
        Image(systemName: "camera.fill")
          .font(.system(size: 48, weight: .light))
          .foregroundStyle(
            LinearGradient(
              colors: [.blue, .purple],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .scaleEffect(isAnimating ? 1.1 : 1.0)
          .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
        
        VStack(spacing: 8) {
          Text("Set Up Camera")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.primary)
          
          Text("Choose your camera and overlay style")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
          
          Text("You can change these settings anytime after setup")
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .frame(maxWidth: .infinity)
      .opacity(isAnimating ? 1.0 : 0.0)
      .offset(y: isAnimating ? 0 : 20)
      .padding(.bottom, 40)
      
      // Content Container - Left aligned with consistent width
      VStack(alignment: .leading, spacing: 32) {
        // Camera Selection (if permission granted)
        if appState.hasCameraPermission {
          VStack(alignment: .leading, spacing: 16) {
            Text("Camera Device")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(.primary)
            
            CameraSelector()
              .frame(maxWidth: 400)
          }
          .opacity(isAnimating ? 1.0 : 0.0)
          .offset(y: isAnimating ? 0 : 20)
          .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
        } else {
          // Camera Permission Request
          CameraPermissionView(onRequestPermission: {
            Task {
              _ = await appState.requestCameraPermission()
            }
          })
            .opacity(isAnimating ? 1.0 : 0.0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
        }
        
        // Overlay Preset Selection
        VStack(alignment: .leading, spacing: 16) {
          Text("Overlay Style")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.primary)
          
          Text("Select a preset that matches your style and needs")
            .font(.system(size: 14))
            .foregroundColor(.secondary)
          
          // Preset Cards - Centered within their container
          HStack {
            Spacer()
            HStack(spacing: 16) {
              ForEach(OverlayPresetOption.allCases, id: \.self) { preset in
                OverlayPresetCardView(
                  preset: preset,
                  isSelected: selectedPresetId == preset.rawValue,
                  action: { selectedPresetId = preset.rawValue }
                )
              }
            }
            Spacer()
          }
        }
        .opacity(isAnimating ? 1.0 : 0.0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimating)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      
      Spacer()
      
      // Bottom Actions - Centered
      VStack(spacing: 16) {
        // Warning if no camera selected
        if selectedCameraID.isEmpty {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
              .font(.system(size: 16))
            
            Text("You haven't chosen a camera yet")
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
        
        // Continue Button
        ModernButton(
          "Continue",
          icon: "arrow.right",
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
    .padding(.horizontal, 32)
    .padding(.vertical, 24)
    .onAppear {
      withAnimation(.easeOut(duration: 0.8)) {
        isAnimating = true
      }
    }
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

// MARK: - Step 4: Personalization

struct PersonalizationStepView: View {
  @ObservedObject var appState: AppState
  let onContinue: () -> Void
  
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
          Text("Personalize")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.primary)
          
          Text("Add your name and an optional title or tagline.\n You can also enable location to show your city and weather.")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 520)
        }
      }
      .frame(maxWidth: .infinity)
      .opacity(isAnimating ? 1.0 : 0.0)
      .offset(y: isAnimating ? 0 : 20)
      .padding(.bottom, 40)
      
             // Content Container - Centered with fixed width
       VStack(spacing: 28) {
         // Personal Info Section
         PersonalInfoView(appState: appState)
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
           appState: appState,
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
  }
}







// MARK: - Helper Views

#if DEBUG

// MARK: - Preview-Only Mock AppState

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

#endif

#endif // 🚧 END DISABLED SECTION - Re-enable after Big Bang Migration complete
