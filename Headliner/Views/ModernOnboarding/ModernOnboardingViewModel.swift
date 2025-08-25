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
    
    @Published var styleShape: StyleShape = .rounded {
        didSet { updateSurfaceStyle() }
    }
    
    // MARK: - Preview Step Support
    
    @Published var availablePresets: [SwiftUIPresetInfo] = []
    @Published var selectedPresetID: String? {
        didSet {
            if let presetID = selectedPresetID {
                overlayService?.selectPreset(presetID)
            }
        }
    }
    
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
        loadAvailablePresets()
        
        // Apply initial settings immediately
        updateOverlayTokens()
        updateSurfaceStyle()
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
        // Save personalization data (already done in real-time, but ensure it's persisted)
        savePersonalizationData()
        
        // Update overlay tokens via coordinator (in addition to service updates)
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
    
    func selectPreset(_ preset: SwiftUIPresetInfo) {
        selectedPresetID = preset.id
    }
    
    func selectCamera(_ cameraID: String) {
        selectedCameraID = cameraID
        if let camera = cameraService?.availableCameras.first(where: { $0.id == cameraID }) {
            Task { @MainActor in
                await cameraService?.selectCamera(camera)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateOverlayTokens() {
        let tokens = OverlayTokens(
            displayName: displayName.isEmpty ? "Your Name" : displayName,
            tagline: displayTitle.isEmpty ? "Your Title" : displayTitle
        )
        overlayService?.updateTokens(tokens)
    }
    
    private func updateSurfaceStyle() {
        let surfaceStyle = convertToSurfaceStyle(styleShape)
        overlayService?.selectSurfaceStyle(surfaceStyle)
    }
    
    private func convertToSurfaceStyle(_ styleShape: StyleShape) -> SurfaceStyle {
        switch styleShape {
        case .rounded:
            return .rounded
        case .square:
            return .square
        }
    }
    
    
    private func savePersonalizationData() {
        guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return }
        appGroupDefaults.set(displayName, forKey: "HL.displayName")
        appGroupDefaults.set(displayTitle, forKey: "HL.tagline")
        appGroupDefaults.synchronize()
    }
    
    private func loadAvailablePresets() {
        guard let overlayService = overlayService else { return }
        
        let curatedIds = [
            "swiftui.identity.strip",
            "swiftui.modern.personal",
            "swiftui.clean",
            "swiftui.modern.company.branded",
            "swiftui.info.corner"
        ]
        
        availablePresets = overlayService.availablePresets.filter {
            curatedIds.contains($0.id)
        }
        
        // Set initial selection to first preset
        if selectedPresetID == nil, let firstPreset = availablePresets.first {
            selectedPresetID = firstPreset.id
        }
    }
    
    private func setupBindings() {
        // Monitor extension status and map to install state
        extensionService?.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.mapExtensionStatus(status)
            }
            .store(in: &cancellables)
        
        // Debounced display name updates
        $displayName
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateOverlayTokens()
                self?.savePersonalizationData()
            }
            .store(in: &cancellables)
        
        // Debounced display title updates
        $displayTitle
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateOverlayTokens()
                self?.savePersonalizationData()
            }
            .store(in: &cancellables)
        
        // Style changes
        $styleShape
            .sink { [weak self] _ in
                self?.updateSurfaceStyle()
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
