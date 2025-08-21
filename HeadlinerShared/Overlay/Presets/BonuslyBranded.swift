@available(*, deprecated, message: "Legacy CoreGraphics overlay path. Prefer SwiftUI overlays.")
// swiftlint:disable file_length
//
//  BonuslyBranded.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation

// MARK: - Bonusly Branded Preset (High-Level Components!)
extension OverlayPreset {
    static let bonuslyBranded: OverlayPreset = {
        var nodes: [OverlayNode] = []
        var widePlacements: [OverlayNodePlacement] = []
        var fourPlacements: [OverlayNodePlacement] = []
        
        // --- Super clean component definitions ---
        
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
        
        let bottomBar = BottomBar(
            backgroundColor: "#118342",
            title: "{displayName}",
            titleSize: 0.06,
            titleWeight: "bold",
            titleColor: "#ffffff",
            subtitle: "{tagline}",
            subtitleSize: 0.04,
            subtitleWeight: "medium",
            subtitleColor: "#ffffff",
            includeLogo: true,
            logoName: "Bonusly-Logo",
            addBrandStrip: true,
            brandStripColor: "#ffffff"
        )
        
        // --- Build for both aspects ---
        
        func buildForAspect(_ aspect: Aspect) -> [OverlayNodePlacement] {
            var tempNodes: [OverlayNode] = []
            var placements: [OverlayNodePlacement] = []
            var idx = 0
            
            placements += timeChip.build(nodes: &tempNodes, startIndex: idx, aspect: aspect)
            idx = tempNodes.count
            
            placements += locationCard.build(nodes: &tempNodes, startIndex: idx, aspect: aspect)
            idx = tempNodes.count
            
            placements += bottomBar.build(nodes: &tempNodes, startIndex: idx, aspect: aspect)
            idx = tempNodes.count
            
            return placements
        }
        
        // Build widescreen (this will populate nodes through the tempNodes reference)
        var tempNodes: [OverlayNode] = []
        widePlacements = {
            var placements: [OverlayNodePlacement] = []
            var idx = 0
            
            placements += timeChip.build(nodes: &tempNodes, startIndex: idx, aspect: .widescreen16x9)
            idx = tempNodes.count
            
            placements += locationCard.build(nodes: &tempNodes, startIndex: idx, aspect: .widescreen16x9)
            idx = tempNodes.count
            
            placements += bottomBar.build(nodes: &tempNodes, startIndex: idx, aspect: .widescreen16x9)
            idx = tempNodes.count
            
            return placements
        }()
        
        // Store the populated nodes
        nodes = tempNodes
        
        // Build 4:3 placements (reuses same nodes, so pass dummy array)
        fourPlacements = {
            var dummyNodes: [OverlayNode] = []
            var placements: [OverlayNodePlacement] = []
            var idx = 0
            
            placements += timeChip.build(nodes: &dummyNodes, startIndex: idx, aspect: .fourThree)
            idx += 2 // timeChip creates 2 nodes
            
            placements += locationCard.build(nodes: &dummyNodes, startIndex: idx, aspect: .fourThree)
            idx += 3 // locationCard creates 3 nodes
            
            placements += bottomBar.build(nodes: &dummyNodes, startIndex: idx, aspect: .fourThree)
            idx += bottomBar.includeLogo ? (bottomBar.addBrandStrip ? 5 : 4) : (bottomBar.addBrandStrip ? 4 : 3)
            
            return placements
        }()
        
        return OverlayPreset(
            id: "bonusly-branded",
            name: "Bonusly Branded",
            nodes: nodes,
            layout: OverlayLayout(widescreen: widePlacements, fourThree: fourPlacements)
        )
    }()
}
