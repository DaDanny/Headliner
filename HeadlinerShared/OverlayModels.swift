//
//  OverlayModels.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation
import CoreGraphics

// MARK: - Core Data Models

/// Aspect ratio for overlay layouts
enum OverlayAspect: String, Codable, CaseIterable {
    case widescreen = "widescreen" // 16:9
    case fourThree = "fourThree"    // 4:3
    
    var displayName: String {
        switch self {
        case .widescreen: return "16:9 Widescreen"
        case .fourThree: return "4:3 Standard"
        }
    }
    
    var ratio: CGFloat {
        switch self {
        case .widescreen: return 16.0 / 9.0
        case .fourThree: return 4.0 / 3.0
        }
    }
}

/// Tokens that get replaced in overlay templates
struct OverlayTokens: Codable, Equatable {
    var displayName: String
    var tagline: String?
    var accentColorHex: String   // Store as hex for UserDefaults
    var aspect: OverlayAspect
    
    // Personal preset (optional)
    var city: String?
    var localTime: String?
    var weatherEmoji: String?
    var weatherText: String?
    
    init(displayName: String = "",
         tagline: String? = nil,
         accentColorHex: String = "#007AFF", // Default blue
         aspect: OverlayAspect = .widescreen,
         city: String? = nil,
         localTime: String? = nil,
         weatherEmoji: String? = nil,
         weatherText: String? = nil) {
        self.displayName = displayName
        self.tagline = tagline
        self.accentColorHex = accentColorHex
        self.aspect = aspect
        self.city = city
        self.localTime = localTime
        self.weatherEmoji = weatherEmoji
        self.weatherText = weatherText
    }
}

/// Normalized rectangle (0...1 range for both position and size)
struct NRect: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat
    
    init(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        self.x = x
        self.y = y
        self.w = w
        self.h = h
    }
    
    /// Convert normalized rect to actual CGRect given container size
    func toCGRect(in containerSize: CGSize) -> CGRect {
        return CGRect(
            x: x * containerSize.width,
            y: y * containerSize.height,
            width: w * containerSize.width,
            height: h * containerSize.height
        )
    }
}

/// Placement information for an overlay node
struct OverlayNodePlacement: Codable, Equatable {
    var index: Int         // Index into nodes array
    var frame: NRect      // Normalized position and size
    var zIndex: Int       // Layer order
    var opacity: CGFloat  // 0...1
    
    init(index: Int, frame: NRect, zIndex: Int = 0, opacity: CGFloat = 1.0) {
        self.index = index
        self.frame = frame
        self.zIndex = zIndex
        self.opacity = opacity
    }
}

/// Layout configuration for different aspect ratios
struct OverlayLayout: Codable, Equatable {
    var widescreen: [OverlayNodePlacement]
    var fourThree: [OverlayNodePlacement]
    
    func placements(for aspect: OverlayAspect) -> [OverlayNodePlacement] {
        switch aspect {
        case .widescreen:
            return widescreen
        case .fourThree:
            return fourThree
        }
    }
}

// MARK: - Node Types

/// Text node configuration
struct TextNode: Codable, Equatable {
    var text: String          // Can contain tokens like {displayName}
    var fontSize: CGFloat     // Relative to container height
    var fontWeight: String    // "regular", "medium", "semibold", "bold"
    var colorHex: String      // Hex color or token like {accentColor}
    var alignment: String     // "left", "center", "right"
    
    init(text: String,
         fontSize: CGFloat = 0.04, // 4% of container height
         fontWeight: String = "regular",
         colorHex: String = "#FFFFFF",
         alignment: String = "center") {
        self.text = text
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.colorHex = colorHex
        self.alignment = alignment
    }
}

/// Rectangle/box node configuration
struct RectNode: Codable, Equatable {
    var colorHex: String      // Hex color or token
    var cornerRadius: CGFloat // Relative to container height
    
    init(colorHex: String = "#000000", cornerRadius: CGFloat = 0.01) {
        self.colorHex = colorHex
        self.cornerRadius = cornerRadius
    }
}

/// Gradient node configuration
struct GradientNode: Codable, Equatable {
    var startColorHex: String
    var endColorHex: String
    var angle: CGFloat        // Degrees (0 = horizontal, 90 = vertical)
    
    init(startColorHex: String = "#000000",
         endColorHex: String = "#FFFFFF",
         angle: CGFloat = 0) {
        self.startColorHex = startColorHex
        self.endColorHex = endColorHex
        self.angle = angle
    }
}

/// Union type for overlay nodes
enum OverlayNode: Codable, Equatable {
    case text(TextNode)
    case rect(RectNode)
    case gradient(GradientNode)
    
    // Custom coding to handle enum with associated values
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    enum NodeType: String, Codable {
        case text, rect, gradient
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(NodeType.self, forKey: .type)
        
        switch type {
        case .text:
            let node = try container.decode(TextNode.self, forKey: .data)
            self = .text(node)
        case .rect:
            let node = try container.decode(RectNode.self, forKey: .data)
            self = .rect(node)
        case .gradient:
            let node = try container.decode(GradientNode.self, forKey: .data)
            self = .gradient(node)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let node):
            try container.encode(NodeType.text, forKey: .type)
            try container.encode(node, forKey: .data)
        case .rect(let node):
            try container.encode(NodeType.rect, forKey: .type)
            try container.encode(node, forKey: .data)
        case .gradient(let node):
            try container.encode(NodeType.gradient, forKey: .type)
            try container.encode(node, forKey: .data)
        }
    }
}

// MARK: - Overlay Preset

/// Complete overlay preset definition
struct OverlayPreset: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var nodes: [OverlayNode]  // Ordered list of nodes
    var layout: OverlayLayout  // Placement for each aspect ratio
    
    init(id: String, name: String, nodes: [OverlayNode], layout: OverlayLayout) {
        self.id = id
        self.name = name
        self.nodes = nodes
        self.layout = layout
    }
}

// MARK: - Helper Extensions

extension String {
    /// Replace tokens in string with actual values
    func replacingTokens(with tokens: OverlayTokens) -> String {
        var result = self
        
        // Replace basic tokens
        result = result.replacingOccurrences(of: "{displayName}", with: tokens.displayName)
        result = result.replacingOccurrences(of: "{tagline}", with: tokens.tagline ?? "")
        result = result.replacingOccurrences(of: "{accentColor}", with: tokens.accentColorHex)
        
        // Replace personal tokens
        result = result.replacingOccurrences(of: "{city}", with: tokens.city ?? "")
        result = result.replacingOccurrences(of: "{localTime}", with: tokens.localTime ?? "")
        result = result.replacingOccurrences(of: "{weatherEmoji}", with: tokens.weatherEmoji ?? "")
        result = result.replacingOccurrences(of: "{weatherText}", with: tokens.weatherText ?? "")
        
        return result
    }
    
    /// Check if string contains any tokens
    var containsTokens: Bool {
        return contains("{") && contains("}")
    }
}
