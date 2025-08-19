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
    
    // MARK: - Modern Enhanced Presets
    
    static let modernProfessional = OverlayPreset(
        id: "modern_professional",
        name: "Professional (Modern)",
        nodes: [
            // Subtle gradient background with rounded corners
            .gradient(GradientNode(
                startColorHex: "{accentColor}20", // 12% opacity
                endColorHex: "{accentColor}80",   // 50% opacity
                angle: 0
            )),
            
            // Glass overlay effect
            .gradient(GradientNode(
                startColorHex: "#FFFFFF15", // Subtle white overlay
                endColorHex: "#FFFFFF05",
                angle: 90
            )),
            
            // Display name with modern typography
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.055,  // Slightly larger
                fontWeight: "semibold", // Modern weight
                colorHex: "#FFFFFF",
                alignment: "center"
            )),
            
            // Tagline with lighter weight
            .text(TextNode(
                text: "{tagline}",
                fontSize: 0.032,
                fontWeight: "medium",
                colorHex: "#FFFFFFDD", // 87% opacity
                alignment: "center"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Main background with rounded corners
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.08, y: 0.06, w: 0.84, h: 0.16),
                    zIndex: 0,
                    opacity: 0.9
                ),
                // Glass overlay
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.08, y: 0.06, w: 0.84, h: 0.08),
                    zIndex: 1,
                    opacity: 0.6
                ),
                // Display name
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.08, y: 0.14, w: 0.84, h: 0.06),
                    zIndex: 2,
                    opacity: 1.0
                ),
                // Tagline
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.08, y: 0.08, w: 0.84, h: 0.04),
                    zIndex: 2,
                    opacity: 1.0
                )
            ],
            fourThree: [
                // Adjusted for 4:3 aspect ratio
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.12, y: 0.06, w: 0.76, h: 0.18),
                    zIndex: 0,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.12, y: 0.06, w: 0.76, h: 0.09),
                    zIndex: 1,
                    opacity: 0.6
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.12, y: 0.15, w: 0.76, h: 0.06),
                    zIndex: 2,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.12, y: 0.09, w: 0.76, h: 0.04),
                    zIndex: 2,
                    opacity: 1.0
                )
            ]
        )
    )
    
    static let modernPersonal = OverlayPreset(
        id: "modern_personal",
        name: "Personal (Modern)",
        nodes: [
            // Main pill background with enhanced styling
            .rect(RectNode(
                colorHex: "{accentColor}70", // 44% opacity
                cornerRadius: 0.03 // More rounded
            )),
            
            // Subtle inner highlight
            .rect(RectNode(
                colorHex: "#FFFFFF20", // White highlight
                cornerRadius: 0.028
            )),
            
            // City text with emoji
            .text(TextNode(
                text: "📍 {city}",
                fontSize: 0.028,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
            
            // Time text with emoji
            .text(TextNode(
                text: "🕒 {localTime}",
                fontSize: 0.028,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
            
            // Weather text with emoji
            .text(TextNode(
                text: "{weatherEmoji} {weatherText}",
                fontSize: 0.028,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Main background
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.02, y: 0.72, w: 0.22, h: 0.16),
                    zIndex: 0,
                    opacity: 0.95
                ),
                // Inner highlight
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.025, y: 0.725, w: 0.21, h: 0.04),
                    zIndex: 1,
                    opacity: 0.7
                ),
                // City
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.035, y: 0.82, w: 0.19, h: 0.035),
                    zIndex: 2,
                    opacity: 1.0
                ),
                // Time
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.035, y: 0.785, w: 0.19, h: 0.035),
                    zIndex: 2,
                    opacity: 1.0
                ),
                // Weather
                OverlayNodePlacement(
                    index: 4,
                    frame: NRect(x: 0.035, y: 0.75, w: 0.19, h: 0.035),
                    zIndex: 2,
                    opacity: 1.0
                )
            ],
            fourThree: [
                // Adjusted for 4:3
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.02, y: 0.68, w: 0.26, h: 0.18),
                    zIndex: 0,
                    opacity: 0.95
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.025, y: 0.685, w: 0.25, h: 0.045),
                    zIndex: 1,
                    opacity: 0.7
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.035, y: 0.80, w: 0.23, h: 0.04),
                    zIndex: 2,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.035, y: 0.76, w: 0.23, h: 0.04),
                    zIndex: 2,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 4,
                    frame: NRect(x: 0.035, y: 0.72, w: 0.23, h: 0.04),
                    zIndex: 2,
                    opacity: 1.0
                )
            ]
        )
    )
    
    static let modernMinimal = OverlayPreset(
        id: "modern_minimal",
        name: "Minimal (Modern)",
        nodes: [
            // Subtle background blur effect
            .rect(RectNode(
                colorHex: "#00000060", // Dark background
                cornerRadius: 0.025
            )),
            
            // Display name only
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.04,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "center"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Background capsule
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.35, y: 0.04, w: 0.3, h: 0.08),
                    zIndex: 0,
                    opacity: 0.8
                ),
                // Name text
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.35, y: 0.05, w: 0.3, h: 0.06),
                    zIndex: 1,
                    opacity: 1.0
                )
            ],
            fourThree: [
                // Adjusted for 4:3
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.25, y: 0.04, w: 0.5, h: 0.09),
                    zIndex: 0,
                    opacity: 0.8
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.25, y: 0.05, w: 0.5, h: 0.07),
                    zIndex: 1,
                    opacity: 1.0
                )
            ]
        )
    )
    
    static let modernSideAccent = OverlayPreset(
        id: "modern_side_accent",
        name: "Side Accent",
        nodes: [
            // Accent bar
            .rect(RectNode(
                colorHex: "{accentColor}",
                cornerRadius: 0.008
            )),
            
            // Main background
            .rect(RectNode(
                colorHex: "#00000070", // Semi-transparent background
                cornerRadius: 0.015
            )),
            
            // Display name
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.045,
                fontWeight: "semibold",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
            
            // Tagline
            .text(TextNode(
                text: "{tagline}",
                fontSize: 0.028,
                fontWeight: "regular",
                colorHex: "#FFFFFFCC",
                alignment: "left"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Accent bar
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.03, y: 0.05, w: 0.008, h: 0.12),
                    zIndex: 2,
                    opacity: 1.0
                ),
                // Main background
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.04, y: 0.05, w: 0.35, h: 0.12),
                    zIndex: 0,
                    opacity: 0.9
                ),
                // Display name
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.055, y: 0.11, w: 0.32, h: 0.05),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Tagline
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.055, y: 0.07, w: 0.32, h: 0.04),
                    zIndex: 1,
                    opacity: 1.0
                )
            ],
            fourThree: [
                // Adjusted for 4:3
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.03, y: 0.05, w: 0.01, h: 0.14),
                    zIndex: 2,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.045, y: 0.05, w: 0.4, h: 0.14),
                    zIndex: 0,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.06, y: 0.12, w: 0.37, h: 0.06),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.06, y: 0.07, w: 0.37, h: 0.04),
                    zIndex: 1,
                    opacity: 1.0
                )
            ]
        )
    )
    
    // MARK: - All Presets
    
    static let all = [
        // Modern enhanced presets (Core Graphics based but with modern styling)
        modernProfessional, modernPersonal, modernMinimal, modernSideAccent,
        // Classic presets
        professional, personal, none
    ]
    
    static let modernPresets = [
        modernProfessional, modernPersonal, modernMinimal, modernSideAccent
    ]
    
    static func preset(withId id: String) -> OverlayPreset? {
        return all.first { $0.id == id }
    }
    
    static var defaultPreset: OverlayPreset {
        return modernProfessional // Default to modern professional preset
    }
}
