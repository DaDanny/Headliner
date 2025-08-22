import SwiftUI

// MARK: - Core Theme System

struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let colors: ThemeColors
    let typography: ThemeTypography
    let effects: ThemeEffects
}

struct ThemeColors: Equatable {
    // Semantic naming (not descriptive)
    let surface: Color           // glass backgrounds (pills, bars)
    let surfaceStroke: Color     // border/stroke lines
    let surfaceAccent: Color     // accent overlay tints
    let textPrimary: Color       // main text color
    let textSecondary: Color     // secondary/dimmed text
    let accent: Color            // brand/highlight color
    let shadow: Color            // drop shadows
}

struct ThemeTypography: Equatable {
    // Base sizes at 1080p for scaling
    let baseSmall: CGFloat      // 20pt - pills, tickers, small text
    let baseBody: CGFloat       // 22pt - body text, descriptions
    let baseTitle: CGFloat      // 28pt - names, titles, headers
    let baseDisplay: CGFloat    // 40pt - large display text, hero
    let baseEmoji: CGFloat      // 22pt - emojis

    // Scaling function for different render sizes
    func scale(for size: CGSize, base: CGFloat = 1080) -> CGFloat {
        let r = size.height / base
        // easeOut-ish curve so smaller canvases don’t get too tiny
        let eased = 0.6 + (1.6 - 0.6) * (1 - pow(1 - min(max(r, 0.6), 1.6), 1.2))
        return eased
    }
    
    // Hard minimums to protect legibility (measured in points @1x render)
    private func minSize(_ v: CGFloat, floor: CGFloat) -> CGFloat { max(v, floor) }

    // Semantic font getters
    func pillFont(for size: CGSize) -> Font {
        .system(size: minSize(baseSmall * scale(for: size), floor: 18), weight: .semibold, design: .rounded)
    }
    func emojiFont(for size: CGSize) -> Font {
        .system(size: minSize(baseEmoji * scale(for: size), floor: 22))
    }
    
    func numericFont(for size: CGSize) -> Font {
        .system(size: minSize(baseBody * scale(for: size), floor: 22), weight: .semibold, design: .monospaced)
    }
    
    func bodyFont(for size: CGSize) -> Font {
        .system(size: minSize(baseBody * scale(for: size), floor: 20), weight: .medium)
    }
    func titleFont(for size: CGSize) -> Font {
        .system(size: minSize(baseTitle * scale(for: size), floor: 32), weight: .bold, design: .rounded)
    }
    func displayFont(for size: CGSize) -> Font {
        .system(size: minSize(baseDisplay * scale(for: size), floor: 38), weight: .bold, design: .rounded)
    }
    
    var nameBase: CGFloat { baseTitle * 0.85 }
    var subtitleBase: CGFloat { baseBody * 0.90 }
    func nameFont(for size: CGSize) -> Font { .system(size: nameBase * scale(for: size), weight: .semibold, design: .rounded) }
    func subtitleFont(for size: CGSize) -> Font { .system(size: subtitleBase * scale(for: size), weight: .medium) }
    
}

struct ThemeEffects: Equatable {
    let blurRadius: CGFloat         // glass blur amount
    let shadowRadius: CGFloat       // drop shadow blur
    let cornerRadius: CGFloat       // rounded corners
    let strokeWidth: CGFloat        // border width
    let insetSmall: CGFloat   // e.g., 8
    let insetMedium: CGFloat  // e.g., 12
    let insetLarge: CGFloat   // e.g., 16
    var insetSlim: CGFloat { insetSmall * 0.75 }
    var insetCozy: CGFloat  { insetMedium * 0.90 }
    var insetRoomy: CGFloat { insetLarge }
    var insetTight: CGFloat { insetSmall }       // rename as you like
    var insetMicro: CGFloat { insetSmall * 0.20 }
    
    // NEW: Square style corner radius (derived from rounded)
    var squareRadius: CGFloat { 0 }
    
    func s(for size: CGSize, base: CGFloat = 1080) -> CGFloat {
        max(0.6, min(2.0, size.height / base))
    }
}
