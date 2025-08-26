//
//  OverlayService.swift
//  Headliner
//
//  Manages overlay settings, presets, and rendering
//

import Foundation
import Combine
import SwiftUI

// MARK: - Protocol

protocol OverlayServiceProtocol: ObservableObject {
  var settings: OverlaySettings { get }
  var currentPreset: SwiftUIPresetInfo? { get }
  var availablePresets: [SwiftUIPresetInfo] { get }
  
  func updateSettings(_ settings: OverlaySettings)
  func selectPreset(_ presetId: String)
  func updateTokens(_ tokens: OverlayTokens)
  func selectAspectRatio(_ aspect: OverlayAspect)
  func selectSurfaceStyle(_ style: SurfaceStyle)
}

// MARK: - Implementation

@MainActor
final class OverlayService: ObservableObject {
  // MARK: - Published Properties
  
  @Published private(set) var settings = OverlaySettings()
  @Published private(set) var currentPreset: SwiftUIPresetInfo?
  @Published var showDebugOverlays: Bool = false
  
  // MARK: - Dependencies
  
  // Removed: private let notificationManager = NotificationManager.self
  private let logger = HeadlinerLogger.logger(for: .overlays)
  
  // MARK: - Private Properties
  
  private var saveTimer: Timer?
  private var renderCount = 0
  private var personalInfoCache: (info: PersonalInfo?, timestamp: Date?)
  
  // MARK: - Initialization
  
  init() {
    loadSettings()
    loadShowDebugSetting()
    updateCurrentPreset()
  }
  
  deinit {
    saveTimer?.invalidate()
  }
  
  // MARK: - Public Methods
  
  func updateSettings(_ newSettings: OverlaySettings) {
    settings = newSettings
    saveSettings()
    notifyExtension()
    triggerRendering()
  }
  
  func selectPreset(_ presetId: String) {
    settings.selectedPresetId = presetId
    
    // Preserve existing tokens
    let existingTokens = settings.overlayTokens
    
    // Initialize tokens if needed
    if settings.overlayTokens == nil {
      settings.overlayTokens = createDefaultTokens(for: presetId, existing: existingTokens)
    }
    
    updateCurrentPreset()
    saveSettings()
    notifyExtension()
    triggerRendering()
  }
  
  func updateTokens(_ tokens: OverlayTokens) {
    settings.overlayTokens = tokens
    settings.userName = tokens.displayName // Legacy sync
    saveSettings()
    notifyExtension()
    triggerRendering()
  }
  
  func selectAspectRatio(_ aspect: OverlayAspect) {
    settings.overlayAspect = aspect
    
    if settings.overlayTokens == nil {
      settings.overlayTokens = createDefaultTokens(for: settings.selectedPresetId, existing: nil)
    }
    
    saveSettings()
    notifyExtension()
  }
  
  func selectSurfaceStyle(_ style: SurfaceStyle) {
    settings.selectedSurfaceStyle = style.rawValue
    saveSettings()
    notifyExtension()
    triggerRendering()
  }
  
  // MARK: - Private Methods
  
  private func loadSettings() {
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let data = appGroupDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
          let decoded = try? JSONDecoder().decode(OverlaySettings.self, from: data) else {
      // Use defaults
      settings.userName = NSUserName()
      logger.debug("Using default overlay settings")
      return
    }
    
    settings = decoded
    logger.debug("Loaded overlay settings: enabled=\(self.settings.isEnabled)")
  }
  
  private func loadShowDebugSetting() {
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return }
    showDebugOverlays = appGroupDefaults.bool(forKey: "overlay.showDebugOverlays")
  }
  
  func saveShowDebugSetting() {
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return }
    appGroupDefaults.set(showDebugOverlays, forKey: "overlay.showDebugOverlays")
  }
  
  private func saveSettings() {
    // Cancel existing timer for debouncing
    saveTimer?.invalidate()
    
    // Schedule debounced save (200ms)
    saveTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
      self?.performSave()
    }
  }
  
  private func performSave() {
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) else {
      logger.error("Failed to access app group for saving")
      return
    }
    
    do {
      let data = try JSONEncoder().encode(settings)
      appGroupDefaults.set(data, forKey: OverlayUserDefaultsKeys.overlaySettings)
      logger.debug("✅ Saved overlay settings")
    } catch {
      logger.error("Failed to encode settings: \(error)")
    }
  }
  
  private func notifyExtension() {
    CrossAppExtensionNotifications.post(.updateOverlaySettings, overlaySettings: settings)
  }
  
  private func triggerRendering() {
    guard let tokens = settings.overlayTokens,
          let provider = currentPreset?.provider else {
      logger.debug("Skipping rendering - missing tokens or provider")
      return
    }
    
    self.renderCount += 1
    logger.debug("🎨 Rendering overlay #\(self.renderCount)")
    
    // Background rendering for performance
    Task.detached { [weak self] in
      guard let self = self else { return }
      
      let renderTokens = RenderTokens(
        safeAreaMode: await self.settings.safeAreaMode,
        surfaceStyle: await self.settings.selectedSurfaceStyle
      )
      
      let personalInfo = await self.getPersonalInfo()
      
      await OverlayRenderBroker.shared.updateOverlay(
        provider: provider,
        tokens: tokens,
        renderTokens: renderTokens,
        personalInfo: personalInfo
      )
    }
  }
  
  private func getPersonalInfo() -> PersonalInfo? {
    // Check cache (5 second validity)
    if let timestamp = personalInfoCache.timestamp,
       Date().timeIntervalSince(timestamp) < 5.0,
       let info = personalInfoCache.info {
      return info
    }
    
    // Load from storage
    guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let data = userDefaults.data(forKey: "overlay.personalInfo.v1"),
          let info = try? JSONDecoder().decode(PersonalInfo.self, from: data) else {
      return nil
    }
    
    // Update cache
    personalInfoCache = (info, Date())
    return info
  }
  
  private func createDefaultTokens(for presetId: String, existing: OverlayTokens?) -> OverlayTokens {
    let displayName = settings.userName.isEmpty ? NSUserName() : settings.userName
    
    switch presetId {
    case "personal":
      return OverlayTokens(
        displayName: displayName,
        tagline: existing?.tagline,
        accentColorHex: "#34C759"
      )
    case "professional":
      return OverlayTokens(
        displayName: displayName,
        tagline: existing?.tagline ?? "Senior Developer",
        accentColorHex: "#007AFF"
      )
    default:
      return OverlayTokens(
        displayName: displayName,
        tagline: existing?.tagline,
        accentColorHex: "#007AFF"
      )
    }
  }
  
  private func updateCurrentPreset() {
    currentPreset = SwiftUIPresetRegistry.preset(withId: settings.selectedPresetId)
  }
  
  // MARK: - Computed Properties
  
  var availablePresets: [SwiftUIPresetInfo] {
    let allPresets = SwiftUIPresetRegistry.allPresets
    if showDebugOverlays {
      return allPresets
    } else {
      return allPresets.filter { $0.category != .debug }
    }
  }
  
  var currentPresetId: String {
    settings.selectedPresetId.isEmpty ? "professional" : settings.selectedPresetId
  }
  
  var currentAspectRatio: OverlayAspect {
    settings.overlayAspect
  }
  
  var currentSurfaceStyle: SurfaceStyle {
    SurfaceStyle(rawValue: settings.selectedSurfaceStyle) ?? .rounded
  }
}

// MARK: - OverlayServiceProtocol Conformance

extension OverlayService: OverlayServiceProtocol {}