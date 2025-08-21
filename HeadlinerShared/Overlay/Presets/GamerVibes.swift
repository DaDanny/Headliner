//
//  GamerVibes.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation

extension OverlayPreset {
    static let gamerVibes: OverlayPreset = OverlayPreset(
        id: "gamer-vibes",
        name: "Gamer Vibes",
        nodes: [
            // LIVE indicator background
            .rect(RectNode(colorHex: "#ff0066", cornerRadius: 0.04)),
            // LIVE indicator text
            .text(TextNode(text: "🔴 LIVE", fontSize: 0.035, fontWeight: "bold", colorHex: "#ffffff", alignment: "center")),
            
            // Time chip background  
            .rect(RectNode(colorHex: "#1a1a2e", cornerRadius: 0.04)),
            // Time chip text
            .text(TextNode(text: "{localTime}", fontSize: 0.03, fontWeight: "bold", colorHex: "#00ff88", alignment: "center")),
            
            // Gaming info card
            .rect(RectNode(colorHex: "#16213e", cornerRadius: 0.035)),
            // Neon accent bar
            .gradient(GradientNode(startColorHex: "#00ff88", endColorHex: "#0066ff", angle: 0)),
            // Gamer name
            .text(TextNode(text: "🎮 {displayName}", fontSize: 0.045, fontWeight: "heavy", colorHex: "#ffffff", alignment: "center")),
            // Gamer tagline
            .text(TextNode(text: "{tagline} • Level ∞", fontSize: 0.032, fontWeight: "bold", colorHex: "#00ff88", alignment: "center"))
        ],
        layout: OverlayLayout(
            widescreen: [
                // LIVE indicator background (placement: .topCenter)
                OverlayNodePlacement(index: 0, frame: resolveFrame(placement: .topCenter, aspect: .widescreen16x9, size: .init(width: 0.18, height: 0.08)), zIndex: 1, opacity: 0.95),
                // LIVE indicator text (centered within background)
                OverlayNodePlacement(index: 1, frame: resolveFrame(placement: .topCenter, aspect: .widescreen16x9, size: .init(width: 0.18, height: 0.08)), zIndex: 2, opacity: 1.0),
                
                // Time chip background (placement: .topLeft)
                OverlayNodePlacement(index: 2, frame: resolveFrame(placement: .topLeft, aspect: .widescreen16x9, size: .init(width: 0.20, height: 0.08)), zIndex: 1, opacity: 0.92),
                // Time chip text (centered within background)
                OverlayNodePlacement(index: 3, frame: resolveFrame(placement: .topLeft, aspect: .widescreen16x9, size: .init(width: 0.20, height: 0.08)), zIndex: 2, opacity: 1.0),
                
                // Gaming card background (placement: .center)
                OverlayNodePlacement(index: 4, frame: resolveFrame(placement: .center, aspect: .widescreen16x9, size: .init(width: 0.5, height: 0.25)), zIndex: 0, opacity: 0.95),
                // Neon accent bar (top of card)
                OverlayNodePlacement(index: 5, frame: resolveFrame(placement: .center, aspect: .widescreen16x9, size: .init(width: 0.5, height: 0.015), dy: -0.1175), zIndex: 1, opacity: 1.0),
                // Name text (centered in card)
                OverlayNodePlacement(index: 6, frame: resolveFrame(placement: .center, aspect: .widescreen16x9, size: .init(width: 0.46, height: 0.08), dy: -0.05), zIndex: 2, opacity: 1.0),
                // Tagline text (centered in card, below name)
                OverlayNodePlacement(index: 7, frame: resolveFrame(placement: .center, aspect: .widescreen16x9, size: .init(width: 0.46, height: 0.06), dy: 0.05), zIndex: 2, opacity: 0.9)
            ],
            fourThree: [
                // LIVE indicator background (placement: .topCenter, adjusted for 4:3)
                OverlayNodePlacement(index: 0, frame: resolveFrame(placement: .topCenter, aspect: .fourThree, size: .init(width: 0.28, height: 0.1)), zIndex: 1, opacity: 0.95),
                // LIVE indicator text (centered within background)
                OverlayNodePlacement(index: 1, frame: resolveFrame(placement: .topCenter, aspect: .fourThree, size: .init(width: 0.28, height: 0.1)), zIndex: 2, opacity: 1.0),
                
                // Time chip background (placement: .topLeft, adjusted for 4:3)
                OverlayNodePlacement(index: 2, frame: resolveFrame(placement: .topLeft, aspect: .fourThree, size: .init(width: 0.25, height: 0.1)), zIndex: 1, opacity: 0.92),
                // Time chip text (centered within background)
                OverlayNodePlacement(index: 3, frame: resolveFrame(placement: .topLeft, aspect: .fourThree, size: .init(width: 0.25, height: 0.1)), zIndex: 2, opacity: 1.0),
                
                // Gaming card background (placement: .center, larger for 4:3)
                OverlayNodePlacement(index: 4, frame: resolveFrame(placement: .center, aspect: .fourThree, size: .init(width: 0.7, height: 0.3)), zIndex: 0, opacity: 0.95),
                // Neon accent bar (top of card)
                OverlayNodePlacement(index: 5, frame: resolveFrame(placement: .center, aspect: .fourThree, size: .init(width: 0.7, height: 0.02), dy: -0.14), zIndex: 1, opacity: 1.0),
                // Name text (centered in card)
                OverlayNodePlacement(index: 6, frame: resolveFrame(placement: .center, aspect: .fourThree, size: .init(width: 0.66, height: 0.1), dy: -0.06), zIndex: 2, opacity: 1.0),
                // Tagline text (centered in card, below name)
                OverlayNodePlacement(index: 7, frame: resolveFrame(placement: .center, aspect: .fourThree, size: .init(width: 0.66, height: 0.08), dy: 0.06), zIndex: 2, opacity: 0.9)
            ]
        )
    )
}
