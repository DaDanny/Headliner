//
//  ModernOnboardingView.swift
//  Headliner
//
//  Modern onboarding flow with scaffold layout and animated transitions
//

import SwiftUI

struct ModernOnboardingView: View {
    @StateObject private var viewModel = ModernOnboardingViewModel()
    
    @Environment(\.appCoordinator) private var appCoordinator
    @EnvironmentObject private var extensionService: ExtensionService
    @EnvironmentObject private var cameraService: CameraService
    @EnvironmentObject private var overlayService: OverlayService
    
    let onComplete: (() -> Void)?
    
    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    var body: some View {
        OnboardingScaffold(
            step: viewModel.currentStep,
            onBack: { viewModel.back() },
            onNext: { advance() },
            nextTitle: viewModel.nextButtonTitle,
            isNextPrimary: viewModel.isNextButtonPrimary,
            canGoNext: viewModel.canContinue
        ) {
            HStack(alignment: .top, spacing: 20) {
                // Left: Explainer card
                ExplainerCard(
                    title: viewModel.currentStep.explainerTitle,
                    subtitle: viewModel.currentStep.explainerSubtitle,
                    bullets: viewModel.currentStep.explainerBullets,
                    timeEstimate: viewModel.currentStep.timeEstimate,
                    learnMoreAction: nil
                )
                
                // Center: Media pane
                MediaPane {
                    stepMedia
                        .transition(stepTransition)
                }
                .frame(maxWidth: .infinity)
                .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                )
                
                // Right: Step rail
                StepRail(steps: OnboardingStep.allCases, current: viewModel.currentStep, showsProgressCaption: true)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: viewModel.currentStep)
        }
        .onAppear {
            setupViewModel()
            
            // Check install status when we reach install step
            if viewModel.currentStep == .install {
                viewModel.checkInstall()
            }
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepMedia: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeMedia()
            
        case .install:
            InstallMedia(
                state: viewModel.installState,
                onInstall: viewModel.beginInstall
            )
            
        case .personalize:
            PersonalizeMedia(
                displayName: $viewModel.displayName,
                displayTitle: $viewModel.displayTitle,
                selectedCameraID: $viewModel.selectedCameraID,
                style: $viewModel.styleShape
            )
            
        case .preview:
            PreviewMedia(
                name: viewModel.displayName,
                title: viewModel.displayTitle,
                style: viewModel.styleShape
            )
            
        case .done:
            DoneMedia()
        }
    }
    
    // MARK: - Transitions
    
    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    // MARK: - Actions
    
    private func setupViewModel() {
        guard let coordinator = appCoordinator else { return }
        
        viewModel.configure(
            appCoordinator: coordinator,
            extensionService: extensionService,
            cameraService: cameraService,
            overlayService: overlayService
        )
    }
    
    private func advance() {
        switch viewModel.currentStep {
        case .install:
            handleInstallStep()
            
        case .preview:
            Task {
                await viewModel.startVirtualCamera()
                viewModel.next()
            }
            
        case .done:
            completeOnboarding()
            
        default:
            viewModel.next()
        }
    }
    
    private func handleInstallStep() {
        switch viewModel.installState {
        case .installed:
            viewModel.next()
        case .installing:
            break // Do nothing while installing
        default:
            viewModel.beginInstall()
        }
    }
    
    private func completeOnboarding() {
        viewModel.complete()
        
        // Call the completion handler
        if let onComplete = onComplete {
            onComplete()
        } else {
            // Close the onboarding window if no custom handler
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                window.close()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ModernOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock services
        let coordinator = AppCoordinator()
        
        return ModernOnboardingView()
            .withAppCoordinator(coordinator)
            .frame(width: 900, height: 600)
            .previewDisplayName("Modern Onboarding")
    }
}
#endif
