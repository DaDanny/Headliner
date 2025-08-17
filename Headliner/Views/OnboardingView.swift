//
//  OnboardingView.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI
import AppKit

/// Comprehensive onboarding flow for Headliner setup
/// 
/// Implements the requirements from GitHub Issue #11:
/// - Welcome screen with extension status
/// - Camera permissions request  
/// - Camera device selection with live preview
/// - Overlay preset selection
/// - Success screen with app selection instructions
struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @State private var selectedCameraForPreview: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                StepHeader(
                    icon: phaseIcon,
                    title: appState.onboardingPhase.title,
                    subtitle: appState.onboardingPhase.subtitle
                )
                
                // Main content card
                StepCard(
                    title: appState.onboardingPhase.title,
                    body: phaseBody,
                    bullets: phaseBullets,
                    primaryTitle: appState.onboardingPhase.primaryActionTitle,
                    primaryAction: primaryAction,
                    secondaryTitle: appState.onboardingPhase.secondaryActionTitle,
                    secondaryAction: secondaryAction,
                    progressIndex: appState.onboardingPhase.stepNumber,
                    isLoading: appState.onboardingPhase.isLoading,
                    isInteractive: appState.onboardingPhase.isInteractive
                )
                
                // Camera preview for running state
                if appState.onboardingPhase == .running {
                    CameraPreviewSection()
                }
                
                // Camera selector for ready-to-start state
                if appState.onboardingPhase == .readyToStart && !appState.availableCameras.isEmpty {
                    CameraSelectorSection()
                }
                
                // Status notes
                if let noteText = statusNoteText {
                    StatusNote(noteText, style: statusNoteStyle)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $appState.isShowingOverlaySettings) {
            OverlaySettingsView()
                .environmentObject(appState)
        }
        .onAppear {
            if selectedCameraForPreview.isEmpty && !appState.availableCameras.isEmpty {
                selectedCameraForPreview = appState.selectedCameraID.isEmpty 
                    ? appState.availableCameras.first?.id ?? ""
                    : appState.selectedCameraID
            }
        }
    }
    
    // MARK: - Phase-specific Content
    
    private var phaseIcon: String {
        switch appState.onboardingPhase {
        case .preflight, .needsExtensionInstall:
            return "arrow.down.circle"
        case .awaitingApproval:
            return "gearshape.2"
        case .readyToStart:
            return "play.circle"
        case .startingCamera:
            return "camera"
        case .running:
            return "checkmark.circle"
        case .personalizeOptional:
            return "person.crop.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var phaseBody: String? {
        switch appState.onboardingPhase {
        case .preflight, .needsExtensionInstall:
            return nil // Uses bullets instead
        case .awaitingApproval:
            return "Waiting for approval… Finish in System Settings → Login Items & Extensions → Camera Extensions"
        case .readyToStart:
            return "Start your virtual camera and see a live preview."
        case .startingCamera:
            return "Getting your camera ready..."
        case .running:
            return "Your camera is live and ready to use in Zoom, Meet, or any video app!"
        case .personalizeOptional:
            return "Customize your overlay with your name and style preferences."
        case .error:
            return nil // Subtitle contains the error message
        }
    }
    
    private var phaseBullets: [String]? {
        switch appState.onboardingPhase {
        case .preflight, .needsExtensionInstall:
            return [
                "Lets apps like Zoom/Meet use Headliner's video",
                "You'll approve it in System Settings",
                "One-time setup for all your video calls"
            ]
        default:
            return nil
        }
    }
    
    private var statusNoteText: String? {
        switch appState.onboardingPhase {
        case .preflight, .needsExtensionInstall:
            return "This may momentarily reload audio/video services."
        case .running:
            return "Look for 'Headliner' in your video app's camera selection menu."
        default:
            return nil
        }
    }
    
    private var statusNoteStyle: StatusNote.Style {
        switch appState.onboardingPhase {
        case .error:
            return .warning
        case .running:
            return .success
        default:
            return .info
        }
    }
    
    // MARK: - Actions
    
    private func primaryAction() {
        switch appState.onboardingPhase {
        case .preflight, .needsExtensionInstall:
            appState.installExtension()
            
        case .awaitingApproval:
            appState.refreshCameras()
            
        case .readyToStart:
            appState.startCamera()
            
        case .running:
            // Show personalization sheet
            appState.isShowingOverlaySettings = true
            appState.onboardingPhase = .personalizeOptional
            
        case .personalizeOptional:
            // Finish onboarding - close overlay settings and complete onboarding
            appState.isShowingOverlaySettings = false
            appState.completeOnboarding()
            
        case .completed:
            // Navigate to main app
            appState.completeOnboarding()
            
        case .error(let message):
            if message.contains("Camera access denied") {
                openPrivacySettings()
            } else {
                // Try again - restart the flow
                appState.beginOnboarding()
            }
            
        case .startingCamera:
            break // No action during loading
        }
    }
    
    private var secondaryAction: (() -> Void)? {
        switch appState.onboardingPhase {
        case .preflight, .needsExtensionInstall:
            return { openSystemSettings() }
            
        case .readyToStart:
            return nil // Camera selector is shown instead
            
        case .running:
            return {
                // Finish without personalization
                appState.completeOnboarding()
            }
            
        case .error:
            return {
                // Contact support - could open email or support page
                if let url = URL(string: "mailto:support@headliner.app?subject=Setup%20Help") {
                    NSWorkspace.shared.open(url)
                }
            }
            
        default:
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Extensions.prefPane") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback to general System Settings
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
        }
    }
    
    private func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback to general System Settings
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
        }
    }
    
    // MARK: - Specialized Sections
    
    @ViewBuilder
    private func CameraPreviewSection() -> some View {
        VStack(spacing: 16) {
            Text("Live Preview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            CameraPreviewCard(appState: appState)
                .frame(height: 200)
                .padding(.horizontal, 32)
        }
    }
    
    @ViewBuilder
    private func CameraSelectorSection() -> some View {
        VStack(spacing: 16) {
            Text("Choose Source Camera")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            CameraSelector(appState: appState)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 32)
    }
}
