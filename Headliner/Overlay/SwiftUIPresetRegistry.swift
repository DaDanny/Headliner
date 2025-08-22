//
//  SwiftUIPresetRegistry.swift
//  Headliner
//
//  Registry for all SwiftUI overlay presets with metadata and live previews
//

import SwiftUI

/// Metadata for a SwiftUI overlay preset
public struct SwiftUIPresetInfo {
    let id: String
    let name: String
    let description: String
    let category: SwiftUIPresetCategory
    let provider: any OverlayViewProviding
    
    public init(
        id: String,
        name: String,
        description: String,
        category: SwiftUIPresetCategory,
        provider: any OverlayViewProviding
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.provider = provider
    }
}

/// Categories for organizing SwiftUI presets
public enum SwiftUIPresetCategory: String, CaseIterable {
    case standard = "Standard"
    case branded = "Branded"
    case creative = "Creative"
    case minimal = "Minimal"
    
    var icon: String {
        switch self {
            case .standard: return "text.below.photo"
            case .branded: return "building.2.fill"
            case .creative: return "paintbrush.fill"
            case .minimal: return "minus"
        }
    }
    
    var color: Color {
        switch self {
            case .standard: return .blue
            case .branded: return .green
            case .creative: return .purple
            case .minimal: return .gray
        }
    }
}

/// Central registry for all SwiftUI overlay presets
public enum SwiftUIPresetRegistry {
    
    /// All available SwiftUI presets
    public static let allPresets: [SwiftUIPresetInfo] = [
        // Standard Category
        SwiftUIPresetInfo(
            id: "swiftui.standard.lowerthird",
            name: "Standard Lower Third",
            description: "Clean professional lower third with glassmorphic styling",
            category: .standard,
            provider: StandardLowerThird()
        ),
        
        // Branded Category  
        SwiftUIPresetInfo(
            id: "swiftui.branded.ribbon",
            name: "Brand Ribbon",
            description: "Company branding with accent ribbon and logo placement",
            category: .branded,
            provider: BrandRibbon()
        ),
        
        // Creative Category
        SwiftUIPresetInfo(
            id: "swiftui.creative.metrics",
            name: "Metric Chip Bar",
            description: "Dynamic metrics display with animated chips",
            category: .creative,
            provider: MetricChipBar()
        ),
        
        // Neo Lower Third
        SwiftUIPresetInfo(
            id: "swiftui.neo.lowerthird",
            name: "Neo Lower Third",
            description: "Cut clean lower third with sharp edges",
            category: .creative,
            provider: NeoLowerThird()
        ),
        
        // Company Cropped - Optimized for 4:3 presentations
        SwiftUIPresetInfo(
            id: "company-cropped",
            name: "Company Cropped",
            description: "4:3 optimized overlay perfect for meeting presentations",
            category: .branded,
            provider: CompanyCropped()
        ),
        
        SwiftUIPresetInfo(
            id: "company-cropped-v2",
            name: "Company Cropped V2",
            description: "V2 4:3 optimized overlay perfect for meeting presentations",
            category: .branded,
            provider: CompanyCroppedV2()
        ),
        
        SwiftUIPresetInfo(
            id: "swiftui.aspectratio.test",
            name: "Aspect Ratio Test",
            description: "Aspect Ratio Test",
            category: .branded,
            provider: AspectRatioTest()
        ),
        
        SwiftUIPresetInfo(
            id: "swiftui.aspectratio.test-v2",
            name: "Aspect Ratio Test V2",
            description: "Aspect Ratio Test V2",
            category: .branded,
            provider: AspectRatioTestV2()
        ),
        
        // Safe Area Component-Based Presets
        SwiftUIPresetInfo(
            id: "swiftui.professional",
            name: "Professional",
            description: "Professional overlay with safe area support using component library",
            category: .standard,
            provider: Professional()
        ),
        
        SwiftUIPresetInfo(
            id: "swiftui.modern.professional",
            name: "Modern Professional",
            description: "Modern professional with profile circle and enhanced styling",
            category: .standard,
            provider: ModernProfessional()
        ),
        
        SwiftUIPresetInfo(
            id: "swiftui.creator.mode",
            name: "Creator Mode",
            description: "Creator mode with social badges and live metrics",
            category: .creative,
            provider: CreatorMode()
        ),
        
        // Validation and Testing
        SwiftUIPresetInfo(
            id: "swiftui.safearea.validation",
            name: "Safe Area Validation",
            description: "Validation overlay showing safe area boundaries vs AspectRatioTestV2",
            category: .standard,
            provider: SafeAreaValidation()
        ),
        
        SwiftUIPresetInfo(
            id: "swiftui.safearea.test",
            name: "Safe Area Test",
            description: "Simple test showing SafeAreaCalculator result vs AspectRatioTestV2",
            category: .standard,
            provider: SafeAreaTest()
        ),
        
        SwiftUIPresetInfo(
            id: "swiftui.safearea.live",
            name: "Safe Area Live",
            description: "Live safe area testing with actual camera dimensions and selected mode",
            category: .standard,
            provider: SafeAreaLive()
        )
        
        // Add new presets here! 🎨
        // Just create a new SwiftUIPresetInfo with your OverlayViewProviding implementation
    ]
    
    /// Get preset by ID
    public static func preset(withId id: String) -> SwiftUIPresetInfo? {
        return allPresets.first { $0.id == id }
    }
    
    /// Get presets by category
    public static func presets(in category: SwiftUIPresetCategory) -> [SwiftUIPresetInfo] {
        return allPresets.filter { $0.category == category }
    }
    
    /// Get all preset IDs
    public static var allPresetIds: [String] {
        return allPresets.map { $0.id }
    }
}

/// Preview helper for SwiftUI presets  
public struct SwiftUIPresetPreview: View {
    let preset: SwiftUIPresetInfo
    let tokens: OverlayTokens
    let size: CGSize
    
    public init(preset: SwiftUIPresetInfo, tokens: OverlayTokens, size: CGSize = CGSize(width: 300, height: 200)) {
        self.preset = preset
        self.tokens = tokens
        self.size = size
    }
    
    public var body: some View {
        OverlayCanvas(size: size) {
            AnyView(preset.provider.makeView(tokens: tokens))
        }
        .frame(width: size.width, height: size.height)
        .background(Color.black) // Simulate video background
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
