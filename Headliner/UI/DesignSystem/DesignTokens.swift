//
//  DesignTokens.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI
import AppKit

// MARK: - Design Tokens

/// Centralized design system tokens for Headliner
struct DesignTokens {
  
  // MARK: - Colors
  
  struct Colors {
    // Brand & Primary
    static let brandPrimary = Color(hex: "#118342ff") // Danny F brand color
    
    // Surfaces
    static let surface = Color(hex: "#111214")
    static let surfaceAlt = Color(hex: "#1A1C1F")
    static let stroke = Color.white.opacity(0.08)
    
    // Text
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.72)
    static let textTertiary = Color.white.opacity(0.55)
    
    // Semantic
    static let success = Color(hex: "#2BD17E")
    static let warning = Color(hex: "#FFB020")
    static let danger = Color(hex: "#FF5C5C")
    
    // Accent
    static let accent = Color(hex: "#7C8CF8")
    static let accentMuted = Color(hex: "#7C8CF8").opacity(0.18)
    static let onAccent = Color(hex: "#0B1020")
    
    // Overlay
    static let overlayBg = Color.black.opacity(0.55)
  }
  
  // MARK: - Radius
  
  struct Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
  }
  
  // MARK: - Shadows
  
  struct Shadows {
    static let soft = Shadow(
      color: .black.opacity(0.35),
      radius: 12,
      x: 0,
      y: 6
    )
    
    static let hard = Shadow(
      color: .black.opacity(0.45),
      radius: 4,
      x: 0,
      y: 2
    )
    
    struct Shadow {
      let color: Color
      let radius: CGFloat
      let x: CGFloat
      let y: CGFloat
    }
  }
  
  // MARK: - Spacing
  
  struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let xxxxl: CGFloat = 40
    
    // Scale array for programmatic access
    static let scale: [CGFloat] = [4, 8, 12, 16, 20, 24, 32, 40]
  }
  
  // MARK: - Typography
  
  struct Typography {
    static let family = "SF Pro"
    
    struct Sizes {
      static let xs: CGFloat = 11
      static let sm: CGFloat = 12
      static let md: CGFloat = 13
      static let lg: CGFloat = 15
      static let xl: CGFloat = 18
      static let display: CGFloat = 24
    }
    
    struct Weights {
      static let regular: Font.Weight = .regular // 400
      static let medium: Font.Weight = .medium   // 500
      static let semibold: Font.Weight = .semibold // 600
      static let bold: Font.Weight = .bold       // 700
    }
    
    // Convenience font creators
    static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
      .system(size: size, weight: weight)
    }
    
    // Semantic font styles
    static let displayFont = font(size: Sizes.display, weight: Weights.bold)
    static let titleFont = font(size: Sizes.xl, weight: Weights.semibold)
    static let bodyFont = font(size: Sizes.md, weight: Weights.regular)
    static let captionFont = font(size: Sizes.sm, weight: Weights.regular)
    static let labelFont = font(size: Sizes.xs, weight: Weights.medium)
  }
  
  // MARK: - Component Tokens
  
  struct Components {
    
    struct Button {
      struct Primary {
        static let background = Colors.brandPrimary
        static let foreground = Color(hex: "#0B0F0C")
        static let radius = Radius.lg
        static let height: CGFloat = 36
      }
      
      struct Secondary {
        static let background = Colors.surfaceAlt
        static let stroke = Colors.stroke
        static let foreground = Colors.textPrimary
        static let radius = Radius.lg
        static let height: CGFloat = 32
      }
      
      struct Ghost {
        static let background = Color.clear
        static let foreground = Colors.textSecondary
        static let hoverBackground = Color.white.opacity(0.06)
        static let radius = Radius.lg
        static let height: CGFloat = 32
      }
    }
    
    struct Badge {
      struct Success {
        static let background = Colors.success.opacity(0.16)
        static let foreground = Colors.success
      }
      
      struct Danger {
        static let background = Colors.danger.opacity(0.16)
        static let foreground = Colors.danger
      }
      
      struct Info {
        static let background = Colors.accent.opacity(0.16)
        static let foreground = Colors.accent
      }
      
      static let radius = Radius.sm
    }
    
    struct Card {
      static let background = Colors.surfaceAlt
      static let radius = Radius.lg
      static let shadow = Shadows.soft
      static let insetBorder = Colors.stroke
    }
    
    struct Toggle {
      static let radius = Radius.sm
      
      struct On {
        static let track = Colors.brandPrimary
        static let knob = Color(hex: "#0B0F0C")
      }
      
      struct Off {
        static let track = Color.white.opacity(0.14)
        static let knob = Color.white
      }
    }
    
    struct Segmented {
      static let background = Color.white.opacity(0.06)
      static let radius = Radius.md
      static let highlight = Colors.accent
    }
    
    struct Field {
      static let height: CGFloat = 34
      static let radius = Radius.md
      static let background = Color.white.opacity(0.06)
      static let stroke = Color.white.opacity(0.10)
      static let focusStroke = Colors.accent
      static let placeholder = Colors.textTertiary
    }
  }
}

// MARK: - Color Extension

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue:  Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

// MARK: - Animation Constants

extension DesignTokens {
  struct Animations {
    static let springResponse: Double = 0.28
    static let springDamping: Double = 0.9
    static let overlayFadeDuration: Double = 0.18
    static let transitionDuration: Double = 0.15
    
    // Standard spring animation
    static let spring = Animation.spring(response: springResponse, dampingFraction: springDamping)
    
    // Quick fade
    static let fade = Animation.easeInOut(duration: overlayFadeDuration)
    
    // Standard transition
    static let transition = Animation.easeInOut(duration: transitionDuration)
  }
}

// MARK: - Layout Constants

extension DesignTokens {
  struct Layout {
    static let headerHeight: CGFloat = 72
    static let footerHeight: CGFloat = 60
    static let sidebarWidth: CGFloat = 320
    static let previewMaxWidth: CGFloat = 480
    static let windowMinWidth: CGFloat = 880
    static let windowMinHeight: CGFloat = 600
    static let contentGutter: CGFloat = 24
  }
}