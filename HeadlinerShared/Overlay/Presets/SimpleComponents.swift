// DEPRECATED: Legacy CoreGraphics overlay path. Prefer SwiftUI overlays.
//@available(*, deprecated, message: "Legacy CoreGraphics overlay path. Prefer SwiftUI overlays.")
// swiftlint:disable file_length
//
//  SimpleComponents.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation

extension OverlayPreset {
    /// Demo of the new high-level component system
    static let simpleComponents: OverlayPreset = {
        var nodes: [OverlayNode] = []
        var widePlacements: [OverlayNodePlacement] = []
        var fourPlacements: [OverlayNodePlacement] = []
        
        // --- Define components declaratively ---
        
        let timeChip = TimeChip(
            placement: .topLeft,
            backgroundColor: "#118342",
            textColor: "#ffffff"
        )
        
        let locationCard = LocationCard(
            placement: .topRight,
            backgroundColor: "#ffffff",
            textAlignment: "right"
        )
        
        let nameCard = NameCard(
            placement: .center,
            width: 0.5,
            height: 0.25,
            backgroundColor: "#ffffff",
            title: "{displayName}",
            subTitle: "{tagline}",
            includeLogo: true,
            logoName: "Bonusly-Logo",
            addAccentBar: true,
            accentColor: "#118342"
        )
        
        // --- Build layouts for both aspects ---
        
        func buildForAspect(_ aspect: Aspect) -> [OverlayNodePlacement] {
            var tempNodes: [OverlayNode] = []
            var placements: [OverlayNodePlacement] = []
            var idx = 0
            
            placements += timeChip.build(nodes: &tempNodes, startIndex: idx, aspect: aspect)
            idx = tempNodes.count
            
            placements += locationCard.build(nodes: &tempNodes, startIndex: idx, aspect: aspect)
            idx = tempNodes.count
            
            placements += nameCard.build(nodes: &tempNodes, startIndex: idx, aspect: aspect)
            idx = tempNodes.count
            
            return placements
        }
        
        // Build widescreen (this populates the nodes array)
        widePlacements = buildForAspect(.widescreen16x9)
        
        // Extract nodes from the build process
        var tempNodes: [OverlayNode] = []
        _ = buildForAspect(.widescreen16x9) // This populates tempNodes
        nodes = tempNodes
        
        // Build 4:3 (reuses same nodes, different placements)
        fourPlacements = buildForAspect(.fourThree)
        
        return OverlayPreset(
            id: "simple-components",
            name: "Simple Components",
            nodes: nodes,
            layout: OverlayLayout(widescreen: widePlacements, fourThree: fourPlacements)
        )
    }()
}


