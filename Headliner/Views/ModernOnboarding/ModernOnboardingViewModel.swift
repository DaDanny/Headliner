//
//  ModernOnboardingViewModel.swift
//  Headliner
//
//  State management for modern onboarding flow
//

import SwiftUI
import Combine

@MainActor
final class ModernOnboardingViewModel: ObservableObject {
    // MARK: - Step Management
    
    @AppStorage("HL.onboarding.step") private var savedStepIndex: Int = 0
    @AppStorage("HL.hasCompletedOnboarding",
                store: UserDefaults(suiteName: Identifiers.appGroup))
    private var hasCompletedOnboarding: Bool = false
    
    @Published var currentStep: OnboardingStep = .welcome {
        didSet { savedStepIndex = currentStep.rawValue }
    }
    
    // MARK: - Install State
    
    enum InstallState: Equatable {
        case unknown
        case notInstalled
        case installing
        case installed
        case error(String)
    }
    
    @Published var installState: InstallState = .unknown
    
    // MARK: - Personalization
    
    @Published var displayName: String = ""
    @Published var displayTitle: String = ""
    @Published var selectedCameraID: String = ""
    
    enum StyleShape: String, CaseIterable {
        case rounded = "Rounded"
        case square = "Square"
    }
    
    @Published var styleShape: StyleShape = .rounded
    
    // MARK: - Service References
    
    private weak var appCoordinator: AppCoordinator?
    private weak var extensionService: ExtensionService?
    private weak var cameraService: CameraService?
    private weak var overlayService: OverlayService?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Restore saved step
        if let step = OnboardingStep(rawValue: savedStepIndex) {
            currentStep = step
        }
        
        // Load saved personalization data if available
        if let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
            if let savedName = appGroupDefaults.string(forKey: "HL.displayName") {
                displayName = savedName
            }
            if let savedTitle = appGroupDefaults.string(forKey: "HL.tagline") {
                displayTitle = savedTitle
            }
        }
    }
    
    func configure(
        appCoordinator: AppCoordinator,
        extensionService: ExtensionService,
        cameraService: CameraService,
        overlayService: OverlayService
    ) {
        self.appCoordinator = appCoordinator
        self.extensionService = extensionService
        self.cameraService = cameraService
        self.overlayService = overlayService
        
        setupBindings()
    }
    
    // MARK: - Navigation
    
    func next() {
        guard let idx = OnboardingStep.allCases.firstIndex(of: currentStep),
              idx + 1 < OnboardingStep.allCases.count else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = OnboardingStep.allCases[idx + 1]
        }
    }
    
    func back() {
        guard let idx = OnboardingStep.allCases.firstIndex(of: currentStep),
              idx - 1 >= 0 else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = OnboardingStep.allCases[idx - 1]
        }
    }
    
    func complete() {
        // Save personalization data
        if let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) {
            appGroupDefaults.set(displayName, forKey: "HL.displayName")
            appGroupDefaults.set(displayTitle, forKey: "HL.tagline")
            appGroupDefaults.synchronize()
        }
        
        // Update overlay tokens
        let tokens = OverlayTokens(
            displayName: displayName.isEmpty ? "Your Name" : displayName,
            tagline: displayTitle.isEmpty ? "Your Title" : displayTitle
        )
        appCoordinator?.updateOverlayTokens(tokens)
        
        // Mark as completed
        hasCompletedOnboarding = true
        appCoordinator?.completeOnboarding()
    }
    
    // MARK: - Service Integration
    
    func checkInstall() {
        extensionService?.checkStatus()
    }
    
    func beginInstall() {
        appCoordinator?.installExtension()
    }
    
    func startVirtualCamera() async {
        // Select camera if one was chosen
        if !selectedCameraID.isEmpty,
           let camera = cameraService?.availableCameras.first(where: { $0.id == selectedCameraID }) {
            await cameraService?.selectCamera(camera)
        }
        
        // Start onboarding preview
        await cameraService?.startOnboardingPreview()
    }
    
    func stopVirtualCamera() {
        cameraService?.stopOnboardingPreview()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor extension status and map to install state
        extensionService?.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.mapExtensionStatus(status)
            }
            .store(in: &cancellables)
        
        // Monitor camera selection
        cameraService?.$selectedCamera
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] camera in
                self?.selectedCameraID = camera.id
            }
            .store(in: &cancellables)
    }
    
    private func mapExtensionStatus(_ status: ExtensionStatus) {
        switch status {
        case .unknown:
            installState = .unknown
        case .notInstalled:
            installState = .notInstalled
        case .installing:
            installState = .installing
        case .installed:
            installState = .installed
        case .error(let appError):
            installState = .error(appError.localizedDescription)
        }
    }
}

// MARK: - Computed Properties

extension ModernOnboardingViewModel {
    var canContinue: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .install:
            return installState == .installed
        case .personalize:
            return !displayName.isEmpty && !selectedCameraID.isEmpty
        case .preview:
            return true
        case .done:
            return true
        }
    }
    
    var nextButtonTitle: String {
        switch currentStep {
        case .welcome:
            return "Continue"
        case .install:
            return installButtonTitle
        case .personalize:
            return "Continue"
        case .preview:
            return "Start Virtual Camera"
        case .done:
            return "Finish"
        }
    }
    
    private var installButtonTitle: String {
        switch installState {
        case .installed:
            return "Continue"
        case .installing:
            return "Installing…"
        case .error:
            return "Retry Install"
        default:
            return "Install"
        }
    }
    
    var isNextButtonPrimary: Bool {
        switch currentStep {
        case .preview, .done:
            return true
        default:
            return false
        }
    }
}
