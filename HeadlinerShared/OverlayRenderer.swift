//
//  OverlayRenderer.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//
//  This file defines the core protocols and shared utilities for the overlay rendering system.
//  The overlay system allows users to add professional text overlays to their virtual camera feed.
//

import Foundation
import CoreImage
import CoreVideo

// MARK: - Overlay Renderer Protocol

/// Protocol for rendering overlays onto video frames.
/// 
/// Implementations of this protocol handle the compositing of overlay graphics
/// onto live video frames from the camera. The renderer must be thread-safe
/// as it may be called from multiple threads in the camera extension.
protocol OverlayRenderer {
    /// Render overlay onto a pixel buffer
    /// - Parameters:
    ///   - pixelBuffer: The video frame to render onto (from the camera)
    ///   - preset: The overlay preset to render (Professional, Personal, None)
    ///   - tokens: The tokens to replace in the preset (user's name, colors, etc.)
    ///   - previousFrame: Optional previous frame for smooth transitions
    /// - Returns: Composited CIImage with overlay applied, ready for output
    func render(pixelBuffer: CVPixelBuffer,
                preset: OverlayPreset,
                tokens: OverlayTokens,
                previousFrame: CIImage?) -> CIImage
}

// MARK: - Personal Info Provider

/// Protocol for providing personal information (location, time, weather).
///
/// This protocol abstracts the source of dynamic personal data used in overlays.
/// The stub implementation provides sample data, but this can be replaced with
/// real data sources (Core Location, Weather APIs) in the future.
protocol PersonalInfoProvider {
    /// Get the user's current city
    func city() -> String?
    
    /// Get the current local time formatted for display
    func localTime() -> String?
    
    /// Get an emoji representing current weather conditions
    func weatherEmoji() -> String?
    
    /// Get a text description of current weather
    func weatherText() -> String?
}

// MARK: - Personal Info Provider Stub

/// Stub implementation returning sample data for personal information.
///
/// This implementation provides static sample data for testing and initial deployment.
/// In production, this can be replaced with real implementations that:
/// - Use Core Location for actual user location
/// - Call weather APIs for real-time weather data
/// - Format time based on user preferences
class PersonalInfoProviderStub: PersonalInfoProvider {
    func city() -> String? {
        // TODO: Replace with Core Location implementation
        return "Pittsburgh"
    }
    
    func localTime() -> String? {
        // Returns actual current time in 12-hour format
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
    
    func weatherEmoji() -> String? {
        // TODO: Replace with weather API integration
        return "☀️"
    }
    
    func weatherText() -> String? {
        // TODO: Replace with weather API integration
        return "Sunny"
    }
}

// MARK: - Overlay Preset Store

/// Manages overlay preset storage and retrieval using shared UserDefaults.
///
/// This class handles persistence of overlay settings between the main app
/// and the camera extension using an app group. It ensures that user preferences
/// are synchronized across both processes.
class OverlayPresetStore {
    // Shared UserDefaults instance for app group communication
    private let userDefaults: UserDefaults?
    private let appGroup = Identifiers.appGroup
    
    // Keys for UserDefaults storage
    private enum Keys {
        static let selectedPresetId = "OverlayPresetId"
        static let overlayTokens = "OverlayTokens"
        static let overlayAspect = "OverlayAspect"
    }
    
    init() {
        self.userDefaults = UserDefaults(suiteName: appGroup)
    }
    
    /// Get the currently selected preset
    var selectedPreset: OverlayPreset {
        guard let presetId = userDefaults?.string(forKey: Keys.selectedPresetId),
              let preset = OverlayPresets.preset(withId: presetId) else {
            return OverlayPresets.defaultPreset
        }
        return preset
    }
    
    /// Set the selected preset
    func selectPreset(_ preset: OverlayPreset) {
        userDefaults?.set(preset.id, forKey: Keys.selectedPresetId)
        userDefaults?.synchronize()
    }
    
    /// Get current overlay tokens
    var overlayTokens: OverlayTokens {
        guard let data = userDefaults?.data(forKey: Keys.overlayTokens),
              let tokens = try? JSONDecoder().decode(OverlayTokens.self, from: data) else {
            // Return default tokens with user's name
            return OverlayTokens(
                displayName: NSUserName(),
                tagline: nil,
                accentColorHex: "#007AFF",
                aspect: .widescreen
            )
        }
        return tokens
    }
    
    /// Save overlay tokens
    func saveTokens(_ tokens: OverlayTokens) {
        if let data = try? JSONEncoder().encode(tokens) {
            userDefaults?.set(data, forKey: Keys.overlayTokens)
            userDefaults?.synchronize()
        }
    }
    
    /// Get current aspect ratio
    var aspect: OverlayAspect {
        guard let aspectString = userDefaults?.string(forKey: Keys.overlayAspect),
              let aspect = OverlayAspect(rawValue: aspectString) else {
            return .widescreen
        }
        return aspect
    }
    
    /// Set aspect ratio
    func setAspect(_ aspect: OverlayAspect) {
        userDefaults?.set(aspect.rawValue, forKey: Keys.overlayAspect)
        userDefaults?.synchronize()
        
        // Also update tokens to keep in sync
        var tokens = overlayTokens
        tokens.aspect = aspect
        saveTokens(tokens)
    }
}
