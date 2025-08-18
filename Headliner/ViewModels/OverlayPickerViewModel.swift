//
//  OverlayPickerViewModel.swift
//  Headliner
//
//  ViewModel for overlay picker that coordinates rendering and storage.
//

import SwiftUI
import Combine
import Foundation
import OSLog

// MARK: - Overlay Picker View Model

@MainActor
final class OverlayPickerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedPresetID: String = "lower_third"
    @Published var overlayEnabled: Bool = true
    @Published var overlayActive: Bool = false
    @Published var lastUpdateTime: String = "Never"
    @Published var lastError: String? = nil
    @Published var showDebugInfo: Bool = false
    
    // Current overlay configuration
    @Published var currentTitle: String = ""
    @Published var currentSubtitle: String = ""
    @Published var currentTheme: OverlayTheme = .professional
    @Published var currentAspectBucket: AspectBucket = .widescreen
    
    // MARK: - Private Properties
    
    private let logger = HeadlinerLogger.logger(for: .overlayPicker)
    
    /// Render service for converting SwiftUI to images
    private let renderService = OverlayRenderService()
    
    /// Asset store for managing overlay files
    private let assetStore: OverlayAssetStore?
    
    /// Render cache to avoid redundant work
    private let renderCache = OverlayRenderCache()
    
    /// Debounce timer for reducing render calls while user types
    private var debounceTimer: Timer?
    private let debounceDelay: TimeInterval = 0.2
    
    /// UserDefaults for persisting settings
    private let userDefaults: UserDefaults?
    
    // MARK: - Computed Properties
    
    var selectedPresetSupportsSubtitle: Bool {
        OverlayCatalog.availablePresets
            .first(where: { $0.id == selectedPresetID })?
            .supportsSubtitle ?? false
    }
    
    // MARK: - Initialization
    
    init() {
        self.assetStore = OverlayAssetStore()
        self.userDefaults = UserDefaults(suiteName: Identifiers.appGroup)
        
        if assetStore == nil {
            logger.error("Failed to initialize OverlayAssetStore")
            lastError = "Failed to initialize overlay storage"
        }
        
        // Enable debug info in development builds
        #if DEBUG
        showDebugInfo = true
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Load settings from UserDefaults
    func loadSettings() {
        guard let userDefaults = userDefaults else { return }
        
        selectedPresetID = userDefaults.string(forKey: "overlay.selectedPresetID") ?? "lower_third"
        currentTitle = userDefaults.string(forKey: "overlay.currentTitle") ?? ""
        currentSubtitle = userDefaults.string(forKey: "overlay.currentSubtitle") ?? ""
        overlayEnabled = userDefaults.bool(forKey: "overlay.enabled")
        
        if let themeRaw = userDefaults.string(forKey: "overlay.theme"),
           let theme = OverlayTheme(rawValue: themeRaw) {
            currentTheme = theme
        }
        
        if let aspectRaw = userDefaults.string(forKey: "overlay.aspectBucket"),
           let aspect = AspectBucket(rawValue: aspectRaw) {
            currentAspectBucket = aspect
        }
        
        logger.debug("Loaded overlay settings: preset=\(selectedPresetID), enabled=\(overlayEnabled)")
        
        // Update overlay if enabled
        if overlayEnabled {
            updateOverlay()
        }
    }
    
    /// Save settings to UserDefaults
    private func saveSettings() {
        guard let userDefaults = userDefaults else { return }
        
        userDefaults.set(selectedPresetID, forKey: "overlay.selectedPresetID")
        userDefaults.set(currentTitle, forKey: "overlay.currentTitle")
        userDefaults.set(currentSubtitle, forKey: "overlay.currentSubtitle")
        userDefaults.set(overlayEnabled, forKey: "overlay.enabled")
        userDefaults.set(currentTheme.rawValue, forKey: "overlay.theme")
        userDefaults.set(currentAspectBucket.rawValue, forKey: "overlay.aspectBucket")
        userDefaults.synchronize()
    }
    
    /// Select a new overlay preset
    func selectPreset(_ presetID: String) {
        selectedPresetID = presetID
        saveSettings()
        updateOverlayDebounced()
    }
    
    /// Update overlay content (title/subtitle)
    func updateContent(title: String, subtitle: String) {
        currentTitle = title
        currentSubtitle = subtitle
        saveSettings()
        updateOverlayDebounced()
    }
    
    /// Update overlay theme
    func updateTheme(_ theme: OverlayTheme) {
        currentTheme = theme
        saveSettings()
        updateOverlayDebounced()
    }
    
    /// Update aspect bucket
    func updateAspectBucket(_ aspectBucket: AspectBucket) {
        currentAspectBucket = aspectBucket
        saveSettings()
        updateOverlayDebounced()
    }
    
    /// Clear overlay (disable)
    func clearOverlay() {
        overlayEnabled = false
        saveSettings()
        
        guard let assetStore = assetStore else { return }
        
        Task {
            let success = assetStore.clearOverlay()
            if success {
                NotificationManager.postOverlayCleared()
                await updateStatus(active: false, error: nil)
                logger.info("Cleared overlay")
            } else {
                await updateStatus(active: false, error: "Failed to clear overlay")
            }
        }
    }
    
    /// Update overlay (render and store)
    func updateOverlay() {
        // Cancel any pending debounced update
        debounceTimer?.invalidate()
        
        guard overlayEnabled else {
            clearOverlay()
            return
        }
        
        Task {
            await performOverlayUpdate()
        }
    }
    
    // MARK: - Private Methods
    
    /// Debounced overlay update (reduces render calls while user types)
    private func updateOverlayDebounced() {
        debounceTimer?.invalidate()
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.performOverlayUpdate()
            }
        }
    }
    
    /// Perform the actual overlay update
    private func performOverlayUpdate() async {
        guard let assetStore = assetStore else {
            await updateStatus(active: false, error: "Asset store not available")
            return
        }
        
        // Create overlay properties
        let props = OverlayProps(
            id: selectedPresetID,
            name: OverlayCatalog.availablePresets.first(where: { $0.id == selectedPresetID })?.name ?? "Unknown",
            title: currentTitle,
            subtitle: selectedPresetSupportsSubtitle ? currentSubtitle : nil,
            theme: currentTheme,
            targetResolution: currentAspectBucket.targetResolution(),
            aspectBucket: currentAspectBucket
        )
        
        logger.debug("Updating overlay: \(props.id) (\(props.title))")
        
        // Check cache first
        if let cachedPNG = renderCache.getCachedPNG(for: props) {
            logger.debug("Using cached overlay render")
            await storeOverlayAndNotify(pngData: cachedPNG, props: props)
            return
        }
        
        // Render overlay
        guard let pngData = renderService.renderPNGData(props: props) else {
            await updateStatus(active: false, error: "Failed to render overlay")
            return
        }
        
        // Cache the result
        renderCache.cachePNG(pngData, for: props)
        
        // Store and notify
        await storeOverlayAndNotify(pngData: pngData, props: props)
    }
    
    /// Store overlay data and send notification
    private func storeOverlayAndNotify(pngData: Data, props: OverlayProps) async {
        guard let assetStore = assetStore else { return }
        
        // Create metadata
        let metadata = OverlayMetadata(
            version: props.version,
            presetID: props.id,
            aspectBucket: props.aspectBucket.rawValue,
            width: Int(props.targetResolution.width),
            height: Int(props.targetResolution.height),
            hash: pngData.sha256
        )
        
        // Store overlay
        let success = assetStore.writeOverlay(pngData: pngData, metadata: metadata)
        
        if success {
            // Notify extension
            NotificationManager.postOverlayUpdated()
            await updateStatus(active: true, error: nil)
            logger.info("Updated overlay: \(props.id) (\(metadata.hash.prefix(8)))")
        } else {
            await updateStatus(active: false, error: "Failed to store overlay")
        }
    }
    
    /// Update UI status
    private func updateStatus(active: Bool, error: String?) async {
        await MainActor.run {
            overlayActive = active
            lastError = error
            lastUpdateTime = DateFormatter.localizedString(
                from: Date(),
                dateStyle: .none,
                timeStyle: .medium
            )
        }
    }
}

// MARK: - Logger Category Extension

extension HeadlinerLogger.Category {
    static let overlayPicker = HeadlinerLogger.Category("OverlayPicker")
}

// MARK: - Data Extension

extension Data {
    var sha256: String {
        let digest = self.withUnsafeBytes { bytes in
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(self.count), &digest)
            return digest
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// Required import for SHA256
import CommonCrypto