//
//  Color+Hex.swift
//  Headliner
//
//  Shared Color utilities for hex parsing and color manipulation
//

import SwiftUI

// MARK: - Color Hex & Manipulation Extensions

extension Color {
    /// Create a Color from a hex string
    /// Supports 6-character (#RRGGBB) and 8-character (#RRGGBBAA) hex codes
    /// Returns nil if the hex string is invalid
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        
        guard Scanner(string: cleaned).scanHexInt64(&int) else {
            return nil
        }

        let a, r, g, b: UInt64
        switch cleaned.count {
        case 8:
            a = (int & 0xFF00_0000) >> 24
            r = (int & 0x00FF_0000) >> 16
            g = (int & 0x0000_FF00) >> 8
            b = (int & 0x0000_00FF)
        case 6:
            a = 255
            r = (int & 0xFF00_00) >> 16
            g = (int & 0x00FF_00) >> 8
            b = (int & 0x0000_FF)
        default:
            return nil
        }
        
        self = Color(.sRGB,
                     red: Double(r) / 255,
                     green: Double(g) / 255,
                     blue: Double(b) / 255,
                     opacity: Double(a) / 255)
    }
    
    /// Create a Color from a hex string with a fallback default
    /// Never returns nil - uses the provided default if hex parsing fails
    init(hex: String, default defaultColor: Color = Color(red: 0.067, green: 0.514, blue: 0.259)) {
        self = Color(hex: hex) ?? defaultColor
    }
    
    /// Lighten the color by mixing with white
    /// - Parameter amount: 0.0 = no change, 1.0 = pure white
    func lighten(_ amount: CGFloat) -> Color {
        mix(with: .white, amount: amount)
    }
    
    /// Darken the color by mixing with black
    /// - Parameter amount: 0.0 = no change, 1.0 = pure black
    func darken(_ amount: CGFloat) -> Color {
        mix(with: .black, amount: amount)
    }
    
    /// Mix this color with another color
    /// - Parameters:
    ///   - other: The color to mix with
    ///   - amount: Mix ratio (0.0 = all this color, 1.0 = all other color)
    func mix(with other: Color, amount: CGFloat) -> Color {
        let a = max(0, min(1, amount))
        let (r1, g1, b1) = self.rgb()
        let (r2, g2, b2) = other.rgb()
        return Color(.sRGB,
                     red: Double(r1 + (r2 - r1) * a),
                     green: Double(g1 + (g2 - g1) * a),
                     blue: Double(b1 + (b2 - b1) * a),
                     opacity: 1.0)
    }
    
    /// Extract RGB components (private helper)
    private func rgb() -> (CGFloat, CGFloat, CGFloat) {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, &g, &b, &a)
        return (r, g, b)
        #else
        // macOS/SwiftUI-only fallback - extract from description or use approximation
        // This is a fallback for when UIKit is not available
        return (0.5, 0.5, 0.5) // neutral gray fallback
        #endif
    }
}

// MARK: - Legacy Support

extension Color {
    /// Legacy initializer for backwards compatibility
    /// This matches the old OverlaySettingsView pattern
    static func fromHex(_ hex: String) -> Color? {
        return Color(hex: hex)
    }
}

