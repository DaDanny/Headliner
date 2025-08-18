//
//  OverlayProps.swift
//  Headliner
//
//  Properties for SwiftUI overlay rendering system.
//

import Foundation
import SwiftUI

// MARK: - Overlay Properties

/// Properties for SwiftUI overlay rendering
struct OverlayProps: Codable, Hashable {
    /// Unique identifier for this overlay preset
    var id: String
    
    /// Display name for this overlay
    var name: String
    
    /// User's display title (e.g., their name)
    var title: String
    
    /// Subtitle/tagline (optional)
    var subtitle: String?
    
    /// Visual theme
    var theme: OverlayTheme
    
    /// Target resolution for rendering
    var targetResolution: CGSize
    
    /// Aspect ratio bucket for layout decisions
    var aspectBucket: AspectBucket
    
    /// Logical-to-physical scale factor
    var scale: Double
    
    /// Layout version (bump when making breaking changes)
    var version: Int
    
    /// Visual styling properties
    var padding: Double
    var cornerRadius: Double
    
    init(
        id: String,
        name: String = "Overlay",
        title: String = "",
        subtitle: String? = nil,
        theme: OverlayTheme = .professional,
        targetResolution: CGSize = CGSize(width: 1920, height: 1080),
        aspectBucket: AspectBucket = .widescreen,
        scale: Double = 1.0,
        version: Int = 1,
        padding: Double = 16.0,
        cornerRadius: Double = 8.0
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.subtitle = subtitle
        self.theme = theme
        self.targetResolution = targetResolution
        self.aspectBucket = aspectBucket
        self.scale = scale
        self.version = version
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
}

// MARK: - Visual Themes

enum OverlayTheme: String, Codable, CaseIterable, Hashable {
    case professional = "professional"
    case creative = "creative"
    case minimal = "minimal"
    case bold = "bold"
    
    var displayName: String {
        switch self {
        case .professional: return "Professional"
        case .creative: return "Creative"
        case .minimal: return "Minimal"
        case .bold: return "Bold"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .professional: return Color.blue
        case .creative: return Color.purple
        case .minimal: return Color.gray
        case .bold: return Color.orange
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .professional: return Color.black.opacity(0.8)
        case .creative: return Color.black.opacity(0.6)
        case .minimal: return Color.white.opacity(0.9)
        case .bold: return Color.black.opacity(0.7)
        }
    }
    
    var textColor: Color {
        switch self {
        case .professional: return Color.white
        case .creative: return Color.white
        case .minimal: return Color.black
        case .bold: return Color.white
        }
    }
}

// MARK: - Aspect Ratios

enum AspectBucket: String, Codable, CaseIterable, Hashable {
    case widescreen = "16:9"
    case standard = "4:3" 
    case square = "1:1"
    
    var displayName: String {
        switch self {
        case .widescreen: return "16:9 Widescreen"
        case .standard: return "4:3 Standard"
        case .square: return "1:1 Square"
        }
    }
    
    var ratio: Double {
        switch self {
        case .widescreen: return 16.0 / 9.0
        case .standard: return 4.0 / 3.0
        case .square: return 1.0
        }
    }
    
    /// Get the appropriate target resolution for this aspect ratio
    func targetResolution(baseHeight: Double = 1080) -> CGSize {
        let width = baseHeight * ratio
        return CGSize(width: width, height: baseHeight)
    }
}

// MARK: - Codable Support for CGSize

extension CGSize: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(Double.self, forKey: .width)
        let height = try container.decode(Double.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    private enum CodingKeys: String, CodingKey {
        case width, height
    }
}