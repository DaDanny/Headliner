//
//  OverlayPresets.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation

/// Overlay presets for the camera extension
/// Contains all available overlay designs including modern and classic styles.
enum OverlayPresets {
    
    /// Get preset by ID - simple direct lookup
    static func preset(withId id: String) -> OverlayPreset? {
        return builtInPresets.first { $0.id == id }
    }
    
    /// Get default preset
    static var defaultPreset: OverlayPreset {
        return builtInPresets.first ?? fallbackPreset
    }
    
    /// All available presets
    static var allPresets: [OverlayPreset] {
        return builtInPresets
    }
    
    // MARK: - Built-in Fallback Presets
    
    /// Fallback preset when no templates are available
    private static let fallbackPreset = OverlayPreset(
        id: "fallback",
        name: "Fallback",
        nodes: [],
        layout: OverlayLayout(
            widescreen: [],
            fourThree: []
        )
    )
    
    /// Professional preset (lower third)
    private static let professionalPreset = OverlayPreset(
        id: "professional",
        name: "Professional",
        nodes: [
            .gradient(GradientNode(
                startColorHex: "{accentColor}33",
                endColorHex: "{accentColor}CC",
                angle: 0
            )),
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.05,
                fontWeight: "bold",
                colorHex: "#FFFFFF",
                alignment: "center"
            )),
            .text(TextNode(
                text: "{tagline}",
                fontSize: 0.03,
                fontWeight: "medium",
                colorHex: "#FFFFFFCC",
                alignment: "center"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.1, y: 0.08, w: 0.8, h: 0.12),
                    zIndex: 0,
                    opacity: 0.95
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.1, y: 0.13, w: 0.8, h: 0.06),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.1, y: 0.09, w: 0.8, h: 0.04),
                    zIndex: 1,
                    opacity: 1.0
                )
            ],
            fourThree: [
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.15, y: 0.08, w: 0.7, h: 0.14),
                    zIndex: 0,
                    opacity: 0.95
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.15, y: 0.14, w: 0.7, h: 0.06),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.15, y: 0.09, w: 0.7, h: 0.04),
                    zIndex: 1,
                    opacity: 1.0
                )
            ]
        )
    )
    
    /// Personal preset (weather/location pill)
    private static let personalPreset = OverlayPreset(
        id: "personal",
        name: "Personal",
        nodes: [
            .rect(RectNode(
                colorHex: "{accentColor}99",
                cornerRadius: 0.02
            )),
            .text(TextNode(
                text: "📍 {city}",
                fontSize: 0.025,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
            .text(TextNode(
                text: "🕒 {localTime}",
                fontSize: 0.025,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
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
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.02, y: 0.75, w: 0.18, h: 0.12),
                    zIndex: 0,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.03, y: 0.815, w: 0.16, h: 0.03),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.03, y: 0.785, w: 0.16, h: 0.03),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.03, y: 0.755, w: 0.16, h: 0.03),
                    zIndex: 1,
                    opacity: 1.0
                )
            ],
            fourThree: [
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.02, y: 0.72, w: 0.22, h: 0.14),
                    zIndex: 0,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.03, y: 0.795, w: 0.20, h: 0.035),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.03, y: 0.760, w: 0.20, h: 0.035),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.03, y: 0.725, w: 0.20, h: 0.035),
                    zIndex: 1,
                    opacity: 1.0
                )
            ]
        )
    )
    
    /// Professional Custom preset (from compiled template)
    private static let professionalCustomPreset = OverlayPreset(
        id: "professional-custom",
        name: "Professional Custom",
        nodes: [
            .gradient(GradientNode(
                startColorHex: "{accentColor}",
                endColorHex: "{accentColor}CC",
                angle: 135
            )),
            .rect(RectNode(
                colorHex: "#FFFFFF",
                cornerRadius: 0.02
            )),
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.05,
                fontWeight: "bold",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
            .text(TextNode(
                text: "{tagline}",
                fontSize: 0.03,
                fontWeight: "medium",
                colorHex: "#e2e8f0",
                alignment: "left"
            )),
            .rect(RectNode(
                colorHex: "{accentColor}",
                cornerRadius: 0.5
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0, y: 0, w: 1, h: 1),
                    zIndex: 0,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0, y: 0.85, w: 1, h: 0.15),
                    zIndex: 1,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.08, y: 0.15, w: 0.6, h: 0.12),
                    zIndex: 2,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.08, y: 0.28, w: 0.6, h: 0.08),
                    zIndex: 2,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 4,
                    frame: NRect(x: 0.85, y: 0.15, w: 0.1, h: 0.1),
                    zIndex: 2,
                    opacity: 0.8
                )
            ],
            fourThree: [
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0, y: 0, w: 1, h: 1),
                    zIndex: 0,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0, y: 0.85, w: 1, h: 0.15),
                    zIndex: 1,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.08, y: 0.15, w: 0.6, h: 0.12),
                    zIndex: 2,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.08, y: 0.28, w: 0.6, h: 0.08),
                    zIndex: 2,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 4,
                    frame: NRect(x: 0.85, y: 0.15, w: 0.1, h: 0.1),
                    zIndex: 2,
                    opacity: 0.8
                )
            ]
        )
    )
    
    /// Personal Custom preset (from compiled template)
    private static let personalCustomPreset = OverlayPreset(
        id: "personal-custom",
        name: "Personal Custom",
        nodes: [
            .rect(RectNode(
                colorHex: "{accentColor}99",
                cornerRadius: 0.02
            )),
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.04,
                fontWeight: "bold",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
            .text(TextNode(
                text: "📍 {city}",
                fontSize: 0.025,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
            .text(TextNode(
                text: "🕒 {localTime}",
                fontSize: 0.025,
                fontWeight: "medium",
                colorHex: "#FFFFFF",
                alignment: "left"
            )),
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
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.02, y: 0.75, w: 0.25, h: 0.15),
                    zIndex: 0,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.03, y: 0.755, w: 0.23, h: 0.04),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.03, y: 0.795, w: 0.23, h: 0.03),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.03, y: 0.815, w: 0.23, h: 0.03),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 4,
                    frame: NRect(x: 0.03, y: 0.835, w: 0.23, h: 0.03),
                    zIndex: 1,
                    opacity: 1.0
                )
            ],
            fourThree: [
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.02, y: 0.72, w: 0.28, h: 0.16),
                    zIndex: 0,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.03, y: 0.725, w: 0.26, h: 0.04),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.03, y: 0.765, w: 0.26, h: 0.035),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.03, y: 0.790, w: 0.26, h: 0.035),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 4,
                    frame: NRect(x: 0.03, y: 0.815, w: 0.26, h: 0.035),
                    zIndex: 1,
                    opacity: 1.0
                )
            ]
        )
    )
    
    // MARK: - Modern Visual Presets
    
    /// Modern card preset - clean and professional
    private static let modernCardPreset = OverlayPreset(
        id: "modern-card",
        name: "Modern Card",
        nodes: [
            // Card background with soft shadow effect
            .rect(RectNode(
                colorHex: "#ffffff",
                cornerRadius: 0.03
            )),
            // Accent gradient bar at top
            .gradient(GradientNode(
                startColorHex: "{accentColor}",
                endColorHex: "{accentColor}CC",
                angle: 90
            )),
            // Display name
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.04,
                fontWeight: "bold",
                colorHex: "#1f2937",
                alignment: "left"
            )),
            // Tagline
            .text(TextNode(
                text: "{tagline}",
                fontSize: 0.03,
                fontWeight: "medium",
                colorHex: "#6b7280",
                alignment: "left"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Card (bottom left, modern size)
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.03, y: 0.75, w: 0.35, h: 0.2),
                    zIndex: 0,
                    opacity: 0.95
                ),
                // Accent bar
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.03, y: 0.75, w: 0.35, h: 0.015),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Name
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.05, y: 0.78, w: 0.31, h: 0.08),
                    zIndex: 2,
                    opacity: 1.0
                ),
                // Tagline
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.05, y: 0.87, w: 0.31, h: 0.05),
                    zIndex: 2,
                    opacity: 0.9
                )
            ],
            fourThree: [
                // Card (centered for 4:3 - moved from bottom-left to center)
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.3, y: 0.4, w: 0.4, h: 0.25), // CENTERED: x: 0.03→0.3, y: 0.7→0.4
                    zIndex: 0,
                    opacity: 0.95
                ),
                // Accent bar (centered to match card) - THICKER for 4:3 to see difference
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.3, y: 0.4, w: 0.4, h: 0.04), // CENTERED + THICKER: h: 0.02→0.04
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Name (centered)
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.32, y: 0.44, w: 0.36, h: 0.1), // CENTERED: x: 0.05→0.32, y: 0.74→0.44
                    zIndex: 2,
                    opacity: 1.0
                ),
                // Tagline (centered)
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.32, y: 0.55, w: 0.36, h: 0.06), // CENTERED: x: 0.05→0.32, y: 0.85→0.55
                    zIndex: 2,
                    opacity: 0.9
                )
            ]
        )
    )
    
    /// Glass pill preset - modern glassmorphic design
    private static let glassPillPreset = OverlayPreset(
        id: "glass-pill",
        name: "Glass Pill",
        nodes: [
            // Glassmorphic background
            .rect(RectNode(
                colorHex: "#ffffff22",
                cornerRadius: 0.5
            )),
            // Subtle border highlight
            .rect(RectNode(
                colorHex: "#ffffff44",
                cornerRadius: 0.5
            )),
            // Name text
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.035,
                fontWeight: "semibold",
                colorHex: "#ffffff",
                alignment: "center"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Glass pill (top center)
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.3, y: 0.05, w: 0.4, h: 0.08),
                    zIndex: 0,
                    opacity: 1.0
                ),
                // Border (slightly smaller for inset effect)
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.302, y: 0.052, w: 0.396, h: 0.076),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Text
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.32, y: 0.06, w: 0.36, h: 0.06),
                    zIndex: 2,
                    opacity: 1.0
                )
            ],
            fourThree: [
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.25, y: 0.05, w: 0.5, h: 0.1),
                    zIndex: 0,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.252, y: 0.052, w: 0.496, h: 0.096),
                    zIndex: 1,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.27, y: 0.07, w: 0.46, h: 0.06),
                    zIndex: 2,
                    opacity: 1.0
                )
            ]
        )
    )
    
    /// Minimal clean preset - subtle and elegant
    private static let minimalCleanPreset = OverlayPreset(
        id: "minimal-clean",
        name: "Minimal Clean",
        nodes: [
            // Just the name
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.04,
                fontWeight: "medium",
                colorHex: "#ffffff",
                alignment: "left"
            )),
            // Subtle accent line
            .rect(RectNode(
                colorHex: "{accentColor}",
                cornerRadius: 0.0
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Name (bottom left, minimal)
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.05, y: 0.85, w: 0.4, h: 0.08),
                    zIndex: 1,
                    opacity: 0.9
                ),
                // Accent line under name
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.05, y: 0.93, w: 0.15, h: 0.005),
                    zIndex: 0,
                    opacity: 0.8
                )
            ],
            fourThree: [
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.05, y: 0.82, w: 0.5, h: 0.1),
                    zIndex: 1,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.05, y: 0.92, w: 0.2, h: 0.008),
                    zIndex: 0,
                    opacity: 0.8
                )
            ]
        )
    )
    
    /// Vibrant creative preset - bold and artistic
    private static let vibrantCreativePreset = OverlayPreset(
        id: "vibrant-creative",
        name: "Vibrant Creative",
        nodes: [
            // Vibrant gradient background
            .gradient(GradientNode(
                startColorHex: "#ff6b6b",
                endColorHex: "#4ecdc4",
                angle: 45
            )),
            // Creative name
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.05,
                fontWeight: "heavy",
                colorHex: "#ffffff",
                alignment: "center"
            )),
            // Tagline
            .text(TextNode(
                text: "{tagline}",
                fontSize: 0.03,
                fontWeight: "medium",
                colorHex: "#ffffffcc",
                alignment: "center"
            )),
            // Decorative circle 1
            .rect(RectNode(
                colorHex: "#ffbe0b",
                cornerRadius: 0.5
            )),
            // Decorative circle 2
            .rect(RectNode(
                colorHex: "#fb5607",
                cornerRadius: 0.5
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Background (full screen, subtle)
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0, y: 0, w: 1, h: 1),
                    zIndex: 0,
                    opacity: 0.25
                ),
                // Name (center top)
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.2, y: 0.1, w: 0.6, h: 0.1),
                    zIndex: 2,
                    opacity: 1.0
                ),
                // Tagline
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.2, y: 0.21, w: 0.6, h: 0.06),
                    zIndex: 2,
                    opacity: 0.9
                ),
                // Circle 1 (top left)
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.05, y: 0.1, w: 0.08, h: 0.08),
                    zIndex: 1,
                    opacity: 0.8
                ),
                // Circle 2 (bottom right)
                OverlayNodePlacement(
                    index: 4,
                    frame: NRect(x: 0.87, y: 0.8, w: 0.06, h: 0.06),
                    zIndex: 1,
                    opacity: 0.7
                )
            ],
            fourThree: [
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0, y: 0, w: 1, h: 1),
                    zIndex: 0,
                    opacity: 0.25
                ),
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.15, y: 0.1, w: 0.7, h: 0.12),
                    zIndex: 2,
                    opacity: 1.0
                ),
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.15, y: 0.23, w: 0.7, h: 0.08),
                    zIndex: 2,
                    opacity: 0.9
                ),
                OverlayNodePlacement(
                    index: 3,
                    frame: NRect(x: 0.05, y: 0.1, w: 0.08, h: 0.08),
                    zIndex: 1,
                    opacity: 0.8
                ),
                OverlayNodePlacement(
                    index: 4,
                    frame: NRect(x: 0.85, y: 0.8, w: 0.06, h: 0.06),
                    zIndex: 1,
                    opacity: 0.7
                )
            ]
        )
    )

    /// Company branding preset with logo
    private static let companyBrandingPreset = OverlayPreset(
        id: "company-branding",
        name: "Company Branding",
        nodes: [
            // Company logo
            .image(ImageNode(
                imageName: "company-logo", // Add your logo to app bundle as "company-logo.png"
                contentMode: "fit",
                opacity: 0.9,
                cornerRadius: 0.1
            )),
            
            // Company name
            .text(TextNode(
                text: "{displayName}",
                fontSize: 0.04,
                fontWeight: "bold",
                colorHex: "#ffffff",
                alignment: "left"
            )),
            
            // Role/title
            .text(TextNode(
                text: "{tagline}",
                fontSize: 0.03,
                fontWeight: "medium",
                colorHex: "#cccccc",
                alignment: "left"
            ))
        ],
        layout: OverlayLayout(
            widescreen: [
                // Logo (top-right corner)
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.85, y: 0.1, w: 0.12, h: 0.12),
                    zIndex: 2,
                    opacity: 1.0
                ),
                // Name (bottom-left)
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.05, y: 0.8, w: 0.4, h: 0.08),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Title (bottom-left, below name)
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.05, y: 0.88, w: 0.4, h: 0.05),
                    zIndex: 1,
                    opacity: 0.9
                )
            ],
            fourThree: [
                // Logo (top-right corner)
                OverlayNodePlacement(
                    index: 0,
                    frame: NRect(x: 0.8, y: 0.1, w: 0.15, h: 0.15),
                    zIndex: 2,
                    opacity: 1.0
                ),
                // Name (bottom-left)
                OverlayNodePlacement(
                    index: 1,
                    frame: NRect(x: 0.05, y: 0.75, w: 0.5, h: 0.1),
                    zIndex: 1,
                    opacity: 1.0
                ),
                // Title (bottom-left, below name)
                OverlayNodePlacement(
                    index: 2,
                    frame: NRect(x: 0.05, y: 0.85, w: 0.5, h: 0.06),
                    zIndex: 1,
                    opacity: 0.9
                )
            ]
        )
    )

    /// Built-in presets as fallback
    private static let builtInPresets: [OverlayPreset] = [
        modernCardPreset,
        glassPillPreset,
        minimalCleanPreset,
        vibrantCreativePreset,
        companyBrandingPreset,
        professionalPreset,
        personalPreset,
        professionalCustomPreset,
        personalCustomPreset,
        fallbackPreset
    ]
}


