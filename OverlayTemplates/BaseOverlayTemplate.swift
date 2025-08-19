//
//  BaseOverlayTemplate.swift
//  OverlayTemplates
//
//  Base class for all overlay templates. This provides the structure
//  that templates implement to define their design and compile into
//  the OverlayPreset format used by the camera extension.
//

import Foundation
import SwiftUI
import CoreGraphics

/// Protocol that all overlay templates must implement
protocol OverlayTemplate {
    /// Unique identifier for this template
    static var templateId: String { get }
    
    /// Display name shown in the app UI
    static var displayName: String { get }
    
    /// Brief description of the template
    static var description: String { get }
    
    /// SwiftUI preview view for visual design in Xcode
    static var previewView: AnyView { get }
    
    /// Compile this template into an OverlayPreset for the camera extension
    static func compile() -> OverlayPreset
}

/// Base template class with common utilities
class BaseOverlayTemplate {
    
    // MARK: - Common Colors
    
    struct Colors {
        static let white = "#ffffff"
        static let black = "#000000"
        static let blue = "#007AFF"
        static let purple = "#8b5cf6"
        static let green = "#34C759"
        static let orange = "#FF9500"
        static let red = "#FF3B30"
        static let gray = "#8E8E93"
        static let lightGray = "#C7C7CC"
        static let darkGray = "#48484A"
    }
    
    // MARK: - Common Gradients
    
    struct Gradients {
        static let blueToBlack = (start: "#007AFF", end: "#000000")
        static let purpleToBlue = (start: "#8b5cf6", end: "#3b82f6")
        static let oceanBlue = (start: "#667eea", end: "#764ba2")
        static let sunset = (start: "#ff7e5f", end: "#feb47b")
        static let forest = (start: "#134e5e", end: "#71b280")
    }
    
    // MARK: - Common Layouts
    
    /// Create a full-screen background placement
    static func fullScreenBackground(nodeIndex: Int, zIndex: Int = 0, opacity: Double = 1.0) -> OverlayNodePlacement {
        return OverlayNodePlacement(
            index: nodeIndex,
            frame: NRect(x: 0, y: 0, w: 1, h: 1),
            zIndex: zIndex,
            opacity: opacity
        )
    }
    
    /// Create a bottom accent bar placement
    static func bottomAccentBar(nodeIndex: Int, height: Double = 0.02, zIndex: Int = 1, opacity: Double = 0.9) -> OverlayNodePlacement {
        return OverlayNodePlacement(
            index: nodeIndex,
            frame: NRect(x: 0, y: 0.05, w: 1, h: height),
            zIndex: zIndex,
            opacity: opacity
        )
    }
    
    /// Create a text placement in the lower left
    static func lowerLeftText(nodeIndex: Int, x: Double = 0.08, y: Double = 0.15, width: Double = 0.6, height: Double = 0.12, zIndex: Int = 2) -> OverlayNodePlacement {
        return OverlayNodePlacement(
            index: nodeIndex,
            frame: NRect(x: x, y: y, w: width, h: height),
            zIndex: zIndex,
            opacity: 1.0
        )
    }
    
    /// Create a decorative element placement in the upper right
    static func upperRightDecoration(nodeIndex: Int, size: Double = 0.15, zIndex: Int = 1, opacity: Double = 0.8) -> OverlayNodePlacement {
        return OverlayNodePlacement(
            index: nodeIndex,
            frame: NRect(x: 0.75, y: 0.15, w: size, h: size),
            zIndex: zIndex,
            opacity: opacity
        )
    }
    
    // MARK: - Common Nodes
    
    /// Create a gradient background node
    static func gradientBackground(startColor: String, endColor: String, angle: Double = 135) -> OverlayNode {
        return .gradient(GradientNode(
            startColorHex: startColor,
            endColorHex: endColor,
            angle: angle
        ))
    }
    
    /// Create a solid color rectangle node
    static func solidRect(color: String, cornerRadius: Double = 0.02) -> OverlayNode {
        return .rect(RectNode(
            colorHex: color,
            cornerRadius: cornerRadius
        ))
    }
    
    /// Create a display name text node
    static func displayNameText(color: String = Colors.white, weight: String = "bold", alignment: String = "left") -> OverlayNode {
        return .text(TextNode(
            text: "{displayName}",
            fontWeight: weight,
            colorHex: color,
            alignment: alignment
        ))
    }
    
    /// Create a tagline text node
    static func taglineText(color: String = "#e2e8f0", weight: String = "medium", alignment: String = "left") -> OverlayNode {
        return .text(TextNode(
            text: "{tagline}",
            fontWeight: weight,
            colorHex: color,
            alignment: alignment
        ))
    }
    
    /// Create a decorative circle
    static func decorativeCircle(color: String = Colors.orange) -> OverlayNode {
        return .rect(RectNode(
            colorHex: color,
            cornerRadius: 0.5 // Makes it a circle
        ))
    }
}

// MARK: - Video Frame Bounds Helper

/// Helper for showing video frame bounds in SwiftUI previews
struct VideoFrameBounds: View {
    let aspectRatio: CGFloat // 16:9 = 1.777, 4:3 = 1.333
    let showGrid: Bool
    
    init(aspectRatio: CGFloat = 16.0/9.0, showGrid: Bool = true) {
        self.aspectRatio = aspectRatio
        self.showGrid = showGrid
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.size.width
            let frameHeight = frameWidth / aspectRatio
            
            ZStack {
                // Video frame background (simulated camera feed)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.8), Color.gray.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: frameWidth, height: frameHeight)
                
                // Grid overlay for positioning guidance
                if showGrid {
                    GridOverlay()
                        .frame(width: frameWidth, height: frameHeight)
                }
                
                // Aspect ratio label
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(aspectRatioLabel)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.trailing, 8)
                            .padding(.bottom, 4)
                    }
                }
                .frame(width: frameWidth, height: frameHeight)
            }
        }
    }
    
    private var aspectRatioLabel: String {
        if abs(aspectRatio - 16.0/9.0) < 0.01 {
            return "16:9 (Widescreen)"
        } else if abs(aspectRatio - 4.0/3.0) < 0.01 {
            return "4:3 (Standard)"
        } else {
            return String(format: "%.2f:1", aspectRatio)
        }
    }
}

/// Grid overlay for positioning guidance
struct GridOverlay: View {
    var body: some View {
        ZStack {
            // Rule of thirds lines
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                Spacer()
            }
            
            HStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1)
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1)
                Spacer()
            }
            
            // Corner guides
            VStack {
                HStack {
                    CornerGuide()
                    Spacer()
                    CornerGuide()
                }
                Spacer()
                HStack {
                    CornerGuide()
                    Spacer()
                    CornerGuide()
                }
            }
            .padding(20)
        }
    }
}

/// Corner positioning guide
struct CornerGuide: View {
    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 20, height: 20)
            
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 16, height: 16)
        }
    }
}

// MARK: - Template Preview Container

/// Container view for template previews with video frame bounds
struct TemplatePreviewContainer<Content: View>: View {
    let aspectRatio: CGFloat
    let showGrid: Bool
    let content: Content
    
    init(
        aspectRatio: CGFloat = 16.0/9.0,
        showGrid: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.aspectRatio = aspectRatio
        self.showGrid = showGrid
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Video frame bounds
            VideoFrameBounds(aspectRatio: aspectRatio, showGrid: showGrid)
            
            // Template content
            content
        }
        .frame(width: 800, height: 800 / aspectRatio)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

// MARK: - Template Registry

/// Registry of all available overlay templates
class OverlayTemplateRegistry {
    
    /// Get all registered templates
    static func allTemplates() -> [any OverlayTemplate.Type] {
        return [
            ProfessionalTemplate.self,
            PersonalTemplate.self,
        ]
    }
    
    /// Get template by ID
    static func template(withId id: String) -> (any OverlayTemplate.Type)? {
        return allTemplates().first { $0.templateId == id }
    }
    
    /// Compile all templates into OverlayPresets
    static func compileAllTemplates() -> [OverlayPreset] {
        return allTemplates().map { $0.compile() }
    }
}
