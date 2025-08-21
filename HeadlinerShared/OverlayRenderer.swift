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

// Import for OverlayUserDefaultsKeys

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
    
    /// Notify renderer that aspect ratio is changing (for smooth transitions)
    func notifyAspectChanged()
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
        guard let data = userDefaults?.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
              let settings = try? JSONDecoder().decode(OverlaySettings.self, from: data),
              let preset = OverlayPresets.preset(withId: settings.selectedPresetId) else {
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
        guard let data = userDefaults?.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
              let settings = try? JSONDecoder().decode(OverlaySettings.self, from: data) else {
            // Return default tokens with user's name
            return OverlayTokens(
                displayName: NSUserName(),
                tagline: nil,
                accentColorHex: "#007AFF"
            )
        }
        
        // Use custom tokens if available, otherwise create default ones
        if let customTokens = settings.overlayTokens {
            return customTokens
        } else {
            return OverlayTokens(
                displayName: settings.userName.isEmpty ? NSUserName() : settings.userName,
                tagline: nil,
                accentColorHex: "#007AFF"
            )
        }
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
        guard let data = userDefaults?.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
              let settings = try? JSONDecoder().decode(OverlaySettings.self, from: data) else {
            return .widescreen
        }
        return settings.overlayAspect
    }
    
    /// Set aspect ratio
    func setAspect(_ aspect: OverlayAspect) {
        userDefaults?.set(aspect.rawValue, forKey: Keys.overlayAspect)
        userDefaults?.synchronize()
        
        // Note: aspect is now a computed property in OverlayTokens, no need to set it
    }
}
