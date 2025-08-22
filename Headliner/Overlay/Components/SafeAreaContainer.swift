//
//  SafeAreaContainer.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Container that constrains content to safe areas visible across video platforms
struct SafeAreaContainer<Content: View>: View {
    let mode: SafeAreaMode
    let content: Content

    init(mode: SafeAreaMode = .balanced, @ViewBuilder content: () -> Content) {
        self.mode = mode
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let settings = getOverlaySettings()
            let inputAR = settings.cameraDimensions.nonZeroAspect
            let safeArea = SafeAreaCalculator.calculateSafeArea(
                mode: mode,
                inputAR: inputAR,
                outputSize: geo.size
            )
            let safeFrame = CGRect(
                x: safeArea.minX * geo.size.width,
                y: safeArea.minY * geo.size.height,
                width: safeArea.width * geo.size.width,
                height: safeArea.height * geo.size.height
            )

            content
                .frame(width: safeFrame.width, height: safeFrame.height)
                .position(x: safeFrame.midX, y: safeFrame.midY)
                .clipped()
                .environment(\.overlayRenderSize, safeFrame.size)
            
        }
    }
}

// MARK: - Helper Functions

/// Environment key for surface style
private struct SurfaceStyleKey: EnvironmentKey {
    static let defaultValue: SurfaceStyle = .rounded
}

extension EnvironmentValues {
    var surfaceStyle: SurfaceStyle {
        get { self[SurfaceStyleKey.self] }
        set { self[SurfaceStyleKey.self] = newValue }
    }
}

/// Read overlay settings from UserDefaults (App Group)
func getOverlaySettings() -> OverlaySettings {
    guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let data = userDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
          let settings = try? JSONDecoder().decode(OverlaySettings.self, from: data) else {
        return OverlaySettings() // Return default settings
    }
    return settings
}

/// Combined structure for overlay and render settings
struct OverlayRenderSettings {
    let overlaySettings: OverlaySettings
    let surfaceStyle: SurfaceStyle
}

/// Get overlay settings with current surface style from environment
func getOverlayRenderSettings(environmentSurfaceStyle: SurfaceStyle) -> OverlayRenderSettings {
    let settings = getOverlaySettings()
    return OverlayRenderSettings(
        overlaySettings: settings,
        surfaceStyle: environmentSurfaceStyle
    )
}

/// Get overlay settings with surface style from the settings
func getOverlayRenderSettings() -> OverlayRenderSettings {
    let settings = getOverlaySettings()
    let surfaceStyle = SurfaceStyle(rawValue: settings.selectedSurfaceStyle) ?? .rounded
    return OverlayRenderSettings(
        overlaySettings: settings,
        surfaceStyle: surfaceStyle
    )
}

// MARK: - Extensions

/// Helper extension to safely convert camera dimensions to aspect ratio
extension CGSize {
    var nonZeroAspect: CGSize? {
        guard width > 0 && height > 0 else { return nil }
        return self
    }
}
