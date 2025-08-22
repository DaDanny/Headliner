//
//  TokenHelpers.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Utility functions for processing overlay tokens and responsive sizing
struct TokenHelpers {
    
    /// Calculate responsive font scale based on container size
    /// - Parameters:
    ///   - containerSize: Current container size
    ///   - designSize: Base design size (default: 1280x720)
    ///   - minScale: Minimum scale factor (default: 0.6)
    /// - Returns: Appropriate scale factor for fonts and spacing
    static func responsiveScale(
        for containerSize: CGSize,
        designSize: CGSize = CGSize(width: 1280, height: 720),
        minScale: CGFloat = 0.6
    ) -> CGFloat {
        let scaleFactor = min(containerSize.width / designSize.width, containerSize.height / designSize.height)
        
        // Apply different scaling rules based on resolution
        if containerSize.width < 800 {
            // Small cameras: scale up fonts more aggressively
            return max(scaleFactor * 1.5, 0.8)
        } else {
            // Normal/large cameras: standard scaling with minimum
            return max(scaleFactor, minScale)
        }
    }
    
    /// Extract social media handles from overlay tokens extras
    /// - Parameter tokens: Overlay tokens containing extras
    /// - Returns: Dictionary of platform to handle mappings
    static func extractSocialHandles(from tokens: OverlayTokens) -> [String: String] {
        guard let extras = tokens.extras else { return [:] }
        
        var handles: [String: String] = [:]
        
        // Common social media platforms
        let platforms = ["twitter", "instagram", "tiktok", "youtube", "linkedin", "github"]
        
        for platform in platforms {
            if let handle = extras[platform], !handle.isEmpty {
                handles[platform] = handle
            }
        }
        
        return handles
    }
    
    /// Check if tokens have weather information
    /// - Parameter tokens: Overlay tokens to check
    /// - Returns: True if weather data is available
    static func hasWeatherData(_ tokens: OverlayTokens) -> Bool {
        return (tokens.city?.isEmpty == false) || 
               (tokens.weatherEmoji?.isEmpty == false) || 
               (tokens.weatherText?.isEmpty == false)
    }
    
    /// Get appropriate accent color from tokens or fallback
    /// - Parameters:
    ///   - tokens: Overlay tokens
    ///   - fallback: Fallback color if token color is invalid
    /// - Returns: Valid accent color
    static func accentColor(from tokens: OverlayTokens, fallback: Color = Color(hex: "#118342")) -> Color {
        return Color(hex: tokens.accentColorHex, default: fallback)
    }
}

/// Extension for responsive component sizing
extension View {
    /// Apply responsive scaling to font sizes and spacing
    /// - Parameters:
    ///   - size: Base size value
    ///   - scale: Scale factor from TokenHelpers.responsiveScale
    /// - Returns: Scaled size
    func scaled(_ size: CGFloat, by scale: CGFloat) -> CGFloat {
        return size * scale
    }
}
