import Foundation

// MARK: - SwiftUI Demo Presets
// NOTE: This file should only be included in the main app target, not CameraExtension

extension OverlayPreset {
    /// Demo preset that will be rendered using SwiftUI
    static let swiftUIDemo: OverlayPreset = {
        // Empty nodes array since we're not using the Core Graphics pipeline
        let nodes: [OverlayNode] = []
        
        // Empty layout since SwiftUI handles positioning
        let layout = OverlayLayout(
            widescreen: [],
            fourThree: []
        )
        
        return OverlayPreset(
            id: "swiftui-demo",
            name: "SwiftUI Demo",
            nodes: nodes,
            layout: layout
        )
    }()
    
    /// Flashy Bonusly-branded SwiftUI preset
    static let swiftUIDemo2: OverlayPreset = {
        // Empty nodes array since we're not using the Core Graphics pipeline
        let nodes: [OverlayNode] = []
        
        // Empty layout since SwiftUI handles positioning
        let layout = OverlayLayout(
            widescreen: [],
            fourThree: []
        )
        
        return OverlayPreset(
            id: "swiftui-demo-2",
            name: "SwiftUI Flashy",
            nodes: nodes,
            layout: layout
        )
    }()
}
