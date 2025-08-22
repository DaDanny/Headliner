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
public enum OverlayAspect: String, Codable, CaseIterable {
    case widescreen = "widescreen" // 16:9
    case fourThree = "fourThree"    // 4:3
    
    public var displayName: String {
        switch self {
        case .widescreen: return "16:9 Widescreen"
        case .fourThree: return "4:3 Standard"
        }
    }
    
    public var ratio: CGFloat {
        switch self {
        case .widescreen: return 16.0 / 9.0
        case .fourThree: return 4.0 / 3.0
        }
    }
}

/// Configuration for how overlays should be rendered
public struct RenderTokens: Hashable, Codable {
    public var safeAreaMode: SafeAreaMode
    public var surfaceStyle: String
    // Future rendering settings can be added here:
    // public var animation: AnimationMode?
    // public var theme: ThemeMode?
    
    public init(safeAreaMode: SafeAreaMode = .balanced, surfaceStyle: String = "rounded") {
        self.safeAreaMode = safeAreaMode
        self.surfaceStyle = surfaceStyle
    }
}

/// Tokens that get replaced in overlay templates
public struct OverlayTokens: Hashable, Codable {
    public var displayName: String
    public var tagline: String?
    public var accentColorHex: String
    public var localTime: String?
    public var logoText: String?     // optional brand text
    public var extras: [String:String]?

    public init(displayName: String,
                tagline: String? = nil,
                accentColorHex: String = "#118342",
                localTime: String? = nil,
                logoText: String? = nil,
                extras: [String:String]? = nil) {
        self.displayName = displayName
        self.tagline = tagline
        self.accentColorHex = accentColorHex
        self.localTime = localTime
        self.logoText = logoText
        self.extras = extras
    }
    
    // Legacy support for existing overlay system
    public var aspect: OverlayAspect {
        return .widescreen
    }
    
    public var city: String? {
        return extras?["location"]
    }
    
    public var weatherEmoji: String? {
        return extras?["weatherEmoji"]
    }
    
    public var weatherText: String? {
        return extras?["weatherText"]
    }
}

public extension OverlayTokens {
    static let previewDanny = OverlayTokens(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColorHex: "#118342",
        localTime: "8:04 PM",
        logoText: "BONUSLY",
        extras: ["location":"Pittsburgh, PA", "weatherEmoji": "☁️", "weatherText": "Cloudy"]
    )
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

/// Image node configuration
struct ImageNode: Codable, Equatable {
    var imageName: String     // Name of image in app bundle
    var contentMode: String   // "fit", "fill", "stretch"
    var opacity: CGFloat      // 0.0-1.0
    var cornerRadius: CGFloat // 0.0-0.5 (0.5 = circle)
    
    init(imageName: String,
         contentMode: String = "fit",
         opacity: CGFloat = 1.0,
         cornerRadius: CGFloat = 0.0) {
        self.imageName = imageName
        self.contentMode = contentMode
        self.opacity = opacity
        self.cornerRadius = cornerRadius
    }
}

/// Union type for overlay nodes
enum OverlayNode: Codable, Equatable {
    case text(TextNode)
    case rect(RectNode)
    case gradient(GradientNode)
    case image(ImageNode)
    
    // Custom coding to handle enum with associated values
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    enum NodeType: String, Codable {
        case text, rect, gradient, image
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
        case .image:
            let node = try container.decode(ImageNode.self, forKey: .data)
            self = .image(node)
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
        case .image(let node):
            try container.encode(NodeType.image, forKey: .type)
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

// MARK: - Safe Area System

/// Safe area modes for overlay positioning
public enum SafeAreaMode: String, Codable, CaseIterable {
    case none = "none"              // Full frame (no safe area)
    case aggressive = "aggressive"   // Minimal safe area (more space, slight risk)
    case balanced = "balanced"       // Proven yellow zone (default)
    case conservative = "conservative" // Extra safe area (guaranteed visible)
    case compact = "compact"           // macOS optimized (conservative height, balanced width)

    public var displayName: String {
        switch self {
            case .none: return "Full Frame"
            case .aggressive: return "Expanded"
            case .balanced: return "Tile-Safe (Recommended)"
            case .conservative: return "Ultra-Safe"
            case .compact: return "Compact"
        }
    }

    public var description: String {
        switch self {
            case .none: return "Use entire frame (may crop in grids)"
            case .aggressive: return "More space, works in most video apps"
            case .balanced: return "Guaranteed visible in Meet/Zoom tiles"
            case .conservative: return "Maximum compatibility, all platforms"
            case .compact: return "Balanced width, conservative height (perfect for macOS)"
        }
    }
}

/// Safe area calculator based on real-world platform testing
public struct SafeAreaCalculator {
    
    /// Calculate safe area for overlay positioning
    /// - Parameters:
    ///   - mode: Safe area mode (default: balanced)
    ///   - inputAR: Camera input aspect ratio (default: 4:3)
    ///   - outputSize: Output canvas size (default: 1920x1080)
    /// - Returns: Normalized safe area rectangle (0-1 coordinates)
    public static func calculateSafeArea(
        mode: SafeAreaMode = .balanced,
        inputAR: CGSize? = nil,
        outputSize: CGSize = CGSize(width: 1920, height: 1080)
    ) -> CGRect {
        let actualInputAR = inputAR ?? CGSize(width: 4, height: 3)

        switch mode {
        case .none:
            return CGRect(x: 0, y: 0, width: 1, height: 1)

        case .aggressive:
            return calculateWithPlatforms(
                inputAR: actualInputAR,
                platforms: [
                    .init(width: 1, height: 1),    // Square tiles
                    .init(width: 16, height: 9)    // Widescreen tiles
                ],
                titleSafeInset: 0.02,
                outputSize: outputSize
            )

        case .balanced:
            return calculateWithPlatforms(
                inputAR: actualInputAR,
                platforms: [
                    .init(width: 1, height: 1),   // Square tiles
                    .init(width: 5, height: 4),   // 5:4-ish tiles
                    .init(width: 4, height: 3),   // 4:3 tiles
                    .init(width: 3, height: 2),   // 3:2 tiles
                    .init(width: 16, height: 9)   // Widescreen tiles
                ],
                titleSafeInset: 0.04,
                outputSize: outputSize
            )

        case .conservative:
            return calculateWithPlatforms(
                inputAR: actualInputAR,
                platforms: [
                    .init(width: 1, height: 1),   // Square tiles
                    .init(width: 5, height: 4),   // 5:4 tiles
                    .init(width: 4, height: 3),   // 4:3 tiles
                    .init(width: 3, height: 2),   // 3:2 tiles
                    .init(width: 16, height: 9),  // Widescreen tiles
                    .init(width: 9, height: 16)   // Mobile portrait (rare but happens)
                ],
                titleSafeInset: 0.08,
                outputSize: outputSize
            )
            
        case .compact:
            return calculateWithPlatforms(
                inputAR: actualInputAR,
                platforms: [
                    .init(width: 1, height: 1),   // Square tiles
                    .init(width: 5, height: 4),   // 5:4 tiles
                    .init(width: 4, height: 3),   // 4:3 tiles
                    .init(width: 3, height: 2),   // 3:2 tiles
                    .init(width: 16, height: 9)   // Widescreen tiles
                    // NO 9:16 mobile portrait for macOS!
                ],
                titleSafeInset: 0.08,    // Conservative 8% padding
                outputSize: outputSize
            )
        }
    }

    private static func calculateWithPlatforms(
        inputAR: CGSize,
        platforms: [CGSize],
        titleSafeInset: CGFloat,
        outputSize: CGSize
    ) -> CGRect {

        // Step 1: Fit camera input into output canvas
        let contentSafe = fitRect(content: inputAR, into: outputSize)

        // Step 2: Calculate center crops for each platform
        let cropRects = platforms.map { fitRectInRect(content: $0, inRect: contentSafe) }

        // Step 3: Find intersection = always visible area
        let platformSafe = intersectAll(cropRects)

        // Step 4: Add title-safe padding
        let paddedSafe = inset(platformSafe, pct: titleSafeInset)

        // Step 5: Convert to normalized coordinates (0-1)
        return CGRect(
            x: paddedSafe.minX / outputSize.width,
            y: paddedSafe.minY / outputSize.height,
            width: paddedSafe.width / outputSize.width,
            height: paddedSafe.height / outputSize.height
        )
    }

    // MARK: - Helper Functions (copied from AspectRatioTestV2)

    private static func fitRect(content: CGSize, into container: CGSize) -> CGRect {
        let sx = container.width / max(content.width, 1)
        let sy = container.height / max(content.height, 1)
        let s = min(sx, sy)
        let w = content.width * s
        let h = content.height * s
        let x = (container.width - w) * 0.5
        let y = (container.height - h) * 0.5
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private static func fitRectInRect(content: CGSize, inRect r: CGRect) -> CGRect {
        let sx = r.width / max(content.width, 1)
        let sy = r.height / max(content.height, 1)
        let s = min(sx, sy)
        let w = content.width * s
        let h = content.height * s
        let x = r.minX + (r.width - w) * 0.5
        let y = r.minY + (r.height - h) * 0.5
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private static func intersectAll(_ rects: [CGRect]) -> CGRect {
        guard var acc = rects.first else { return .zero }
        for r in rects.dropFirst() { acc = acc.intersection(r) }
        return acc
    }

    private static func inset(_ r: CGRect, pct: CGFloat) -> CGRect {
        let dx = r.width * pct
        let dy = r.height * pct
        return r.insetBy(dx: dx, dy: dy)
    }
}

// MARK: - Face-Avoid Bands

/// Safe bands that avoid the center where faces typically appear
public struct SafeBands {
    public let top: CGRect
    public let bottom: CGRect
    public let left: CGRect
    public let right: CGRect
    public let center: CGRect // Avoid this area for overlays
}

extension SafeAreaCalculator {
    /// Create safe bands within a safe area that avoid covering faces
    public static func makeBands(
        in safeArea: CGRect,
        centerHeightPct: CGFloat = 0.40,
        sideWidthPct: CGFloat = 0.22
    ) -> SafeBands {
        let ch = safeArea.height * max(0, min(1, centerHeightPct))
        let sw = safeArea.width * max(0, min(1, sideWidthPct))

        let center = CGRect(
            x: safeArea.minX,
            y: safeArea.midY - ch/2,
            width: safeArea.width,
            height: ch
        )

        let top = CGRect(
            x: safeArea.minX,
            y: safeArea.minY,
            width: safeArea.width,
            height: center.minY - safeArea.minY
        )

        let bottom = CGRect(
            x: safeArea.minX,
            y: center.maxY,
            width: safeArea.width,
            height: safeArea.maxY - center.maxY
        )

        let left = CGRect(
            x: safeArea.minX,
            y: safeArea.minY,
            width: sw,
            height: safeArea.height
        )

        let right = CGRect(
            x: safeArea.maxX - sw,
            y: safeArea.minY,
            width: sw,
            height: safeArea.height
        )

        return SafeBands(top: top, bottom: bottom, left: left, right: right, center: center)
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
