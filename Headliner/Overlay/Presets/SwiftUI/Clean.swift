//
//  Clean.swift
//  Headliner
//
//  Created by AI Assistant on 8/22/25.
//

import SwiftUI

/// Clean overlay preset - completely transparent with no elements
/// Provides a way for users to disable overlays while keeping the app active
struct Clean: OverlayViewProviding {
    static var presetId: String { "swiftui.clean" }
    static var defaultSize: CGSize { CGSize(width: 1280, height: 720) }
    
    func makeView(tokens: OverlayTokens) -> some View {
        // Completely transparent view with no content
        // This allows users to effectively "disable" overlays while maintaining app engagement
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
struct Clean_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIPresetPreview(
            preset: SwiftUIPresetInfo(
                id: "swiftui.clean",
                name: "Clean",
                description: "No overlay elements - completely transparent",
                category: .minimal,
                provider: Clean()
            ),
            tokens: OverlayTokens.previewDanny,
            size: CGSize(width: 320, height: 180)
        )
        .previewDisplayName("Clean Overlay")
    }
}
#endif