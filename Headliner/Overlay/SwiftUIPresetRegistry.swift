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
        // (Standard Lower Third removed - outdated component)
        
        // Branded Category  
        // (Brand Ribbon removed - outdated component)
        
        // Creative Category
        // (Metric Chip Bar removed - outdated component)
        
        // Neo Lower Third
        // (Neo Lower Third removed - outdated component)
        
        // Company Cropped - Optimized for 4:3 presentations
        // (Company Cropped removed - outdated component)
        
        // (Company Cropped V2 removed - outdated component)
        
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
        // (Professional removed - uses outdated components)
        
        // (Modern Professional removed - uses outdated components)
        
        // (Creator Mode removed - uses outdated components)
        
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
        ),
        SwiftUIPresetInfo(
            id: "swiftui.modern.personal",
            name: "Modern Personal",
            description: "Modern Personal",
            category: .standard,
            provider: ModernPersonal()
        ),
        
        // Professional Corner - Company branding and time in top-right
        SwiftUIPresetInfo(
            id: "swiftui.professional.corner",
            name: "Professional Corner",
            description: "Company branding and time in top-right corner",
            category: .branded,
            provider: ProfessionalCorner()
        ),
        
        // Status Bar - Weather, time, and location in top bar
        SwiftUIPresetInfo(
            id: "swiftui.status.bar",
            name: "Status Bar",
            description: "Weather, time, and location in top bar",
            category: .standard,
            provider: StatusBar()
        ),
        
        // Identity Strip - Name, role, and company mark in bottom strip
        SwiftUIPresetInfo(
            id: "swiftui.identity.strip",
            name: "Identity Strip",
            description: "Name, role, and company mark in bottom strip",
            category: .branded,
            provider: IdentityStrip()
        ),
        
        // Info Corner - Weather and location in bottom-right
        SwiftUIPresetInfo(
            id: "swiftui.info.corner",
            name: "Info Corner",
            description: "Weather and location in bottom-right corner",
            category: .standard,
            provider: InfoCorner()
        ),
        
        // Social Corner - Social media handles in top-left
        SwiftUIPresetInfo(
            id: "swiftui.social.corner",
            name: "Social Corner",
            description: "Social media handles in top-left corner",
            category: .creative,
            provider: SocialCorner()
        ),
        
        // Company Fun - Company logo top right, location top left, weather bottom
        SwiftUIPresetInfo(
            id: "swiftui.company.fun",
            name: "Company Fun",
            description: "Professional company branding with logo, location, and weather",
            category: .branded,
            provider: CompanyFun()
        ),
        
        // Modern Company Branded - Company branding with personal info
        SwiftUIPresetInfo(
            id: "swiftui.modern.company.branded",
            name: "Modern Company Branded",
            description: "Company branding with personal info and location/weather",
            category: .branded,
            provider: ModernCompanyBranded()
        ),
        
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
