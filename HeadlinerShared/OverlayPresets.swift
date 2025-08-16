//
//  OverlayPresets.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation
import CoreGraphics

/// Built-in overlay presets
enum OverlayPresets {
    
    // MARK: - Professional Preset (Lower Third)
    
    static let professional = OverlayPreset(
        id: "professional",
        name: "Professional",
        nodes: [
            // Gradient bar background
            .gradient(GradientNode(
                startColorHex: "{accentColor}33", // 20% opacity
                endColorHex: "{accentColor}CC",   // 80% opacity
                angle: 0 // Horizontal gradient
            )),
            
            // Display name (large, bold)
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.05,  // 5% of container height
                fontWeight: "bold",
                colorHex: "#FFFFFF",
                alignment: "center"
            )),
            
            // Tagline (smaller, medium weight)
            .text(TextNode(
                text: "{tagline}",
                fontSize: 0.03,  // 3% of container height
                fontWeight: "medium",
                colorHex: "#FFFFFFCC", // Slightly transparent
                alignment: "center"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Gradient bar - lower third
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.1, y: 0.08, w: 0.8, h: 0.12),
                    zIndex: 0,
                    opacity: 0.95
                ),
                // Display name
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.1, y: 0.13, w: 0.8, h: 0.06),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Tagline
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.1, y: 0.09, w: 0.8, h: 0.04),
                    zIndex: 1,
                    opacity: 1.0
                )
            ],
            fourThree: [
                // Gradient bar - slightly taller for 4:3
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.15, y: 0.08, w: 0.7, h: 0.14),
                    zIndex: 0,
                    opacity: 0.95
                ),
                // Display name - adjusted for 4:3
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.15, y: 0.14, w: 0.7, h: 0.06),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Tagline - adjusted for 4:3
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.15, y: 0.09, w: 0.7, h: 0.04),
                    zIndex: 1,
                    opacity: 1.0
                )
            ]
        )
    )
    
    // MARK: - Personal Preset (Location/Time/Weather Pill)
    
    static let personal = OverlayPreset(
        id: "personal",
        name: "Personal",
        nodes: [
            // Rounded pill background
            .rect(RectNode(
                colorHex: "{accentColor}99", // 60% opacity
                cornerRadius: 0.02
            )),
            
            // City with pin emoji
            .text(TextNode(
                text: "📍 {city}",
                fontSize: 0.025,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
            
            // Local time with clock emoji
            .text(TextNode(
                text: "🕒 {localTime}",
                fontSize: 0.025,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
            
            // Weather with emoji and text
            .text(TextNode(
                text: "{weatherEmoji} {weatherText}",
                fontSize: 0.025,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Pill background - top left
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.02, y: 0.75, w: 0.18, h: 0.12),
                    zIndex: 0,
                    opacity: 0.9
                ),
                // City text
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.03, y: 0.815, w: 0.16, h: 0.03),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Time text
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.03, y: 0.785, w: 0.16, h: 0.03),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Weather text
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.03, y: 0.755, w: 0.16, h: 0.03),
                    zIndex: 1,
                    opacity: 1.0
                )
            ],
            fourThree: [
                // Pill background - adjusted for 4:3
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.02, y: 0.72, w: 0.22, h: 0.14),
                    zIndex: 0,
                    opacity: 0.9
                ),
                // City text
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.03, y: 0.795, w: 0.20, h: 0.035),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Time text
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.03, y: 0.760, w: 0.20, h: 0.035),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Weather text
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.03, y: 0.725, w: 0.20, h: 0.035),
                    zIndex: 1,
                    opacity: 1.0
                )
            ]
        )
    )
    
    // MARK: - None/Clean Preset (No Overlay)
    
    static let none = OverlayPreset(
        id: "none",
        name: "None",
        nodes: [], // No nodes - passthrough
        layout: OverlayLayout(
            widescreen: [],
            fourThree: []
        )
    )
    
    // MARK: - All Presets
    
    static let all = [professional, personal, none]
    
    static func preset(withId id: String) -> OverlayPreset? {
        return all.first { $0.id == id }
    }
    
    static var defaultPreset: OverlayPreset {
        return professional
    }
}
