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
            #if DEBUG
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.yellow.opacity(0.6), lineWidth: 1)
                )
            #endif
        }
    }
}

// MARK: - Helper Functions

/// Read overlay settings from UserDefaults (App Group)
func getOverlaySettings() -> OverlaySettings {
    guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let data = userDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
          let settings = try? JSONDecoder().decode(OverlaySettings.self, from: data) else {
        return OverlaySettings() // Return default settings
    }
    return settings
}

// MARK: - Extensions

/// Helper extension to safely convert camera dimensions to aspect ratio
extension CGSize {
    var nonZeroAspect: CGSize? {
        guard width > 0 && height > 0 else { return nil }
        return self
    }
}
