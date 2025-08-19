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
    // Brand & Primary - More vibrant and Mac-native
    static let brandPrimary = Color(hex: "#00D2FF") // Vibrant cyan-blue
    static let brandSecondary = Color(hex: "#3A7BD5") // Complementary blue
    static let brandGradient = LinearGradient(
      colors: [brandPrimary, brandSecondary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    
    // Surfaces with more depth
    static let surface = Color(hex: "#0A0B0F") // Deeper black
    static let surfaceAlt = Color(hex: "#16171D") // Rich dark
    static let surfaceRaised = Color(hex: "#1E1F26") // Elevated surface
    static let stroke = Color.white.opacity(0.12) // More visible strokes
    
    // Text with better hierarchy
    static let textPrimary = Color.white.opacity(0.98)
    static let textSecondary = Color.white.opacity(0.78)
    static let textTertiary = Color.white.opacity(0.58)
    static let textQuaternary = Color.white.opacity(0.38)
    
    // Fun, energetic semantic colors
    static let success = Color(hex: "#00E676") // Electric green
    static let warning = Color(hex: "#FFB300") // Warm amber
    static let danger = Color(hex: "#FF3D71") // Vibrant red
    static let info = Color(hex: "#2196F3") // Material blue
    
    // Modern accent system
    static let accent = Color(hex: "#7C4DFF") // Deep purple
    static let accentLight = Color(hex: "#B39DDB") // Light purple
    static let accentMuted = Color(hex: "#7C4DFF").opacity(0.2)
    static let onAccent = Color.white
    
    // Glass and blur effects
    static let glass = Color.white.opacity(0.08)
    static let glassStroke = Color.white.opacity(0.16)
    static let overlayBg = Color.black.opacity(0.6)
    
    // Interactive states
    static let hoverOverlay = Color.white.opacity(0.04)
    static let pressedOverlay = Color.white.opacity(0.08)
    static let selectedOverlay = Color.white.opacity(0.12)
    
    // Mac-native system colors
    static let systemBlue = Color.accentColor
    static let systemGreen = Color(NSColor.systemGreen)
    static let systemRed = Color(NSColor.systemRed)
    static let systemOrange = Color(NSColor.systemOrange)
    static let systemPurple = Color(NSColor.systemPurple)
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
        static let background = Colors.brandGradient
        static let foreground = Colors.onAccent
        static let radius = Radius.lg
        static let height: CGFloat = 40
        static let shadow = Colors.brandPrimary.opacity(0.3)
      }
      
      struct Secondary {
        static let background = Colors.glass
        static let stroke = Colors.glassStroke
        static let foreground = Colors.textPrimary
        static let radius = Radius.lg
        static let height: CGFloat = 36
      }
      
      struct Ghost {
        static let background = Color.clear
        static let foreground = Colors.textSecondary
        static let hoverBackground = Colors.hoverOverlay
        static let radius = Radius.md
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
    // Bouncy, delightful springs
    static let bouncySpring = Animation.interactiveSpring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)
    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let snappySpring = Animation.spring(response: 0.2, dampingFraction: 0.9)
    
    // Smooth easing curves
    static let smoothEase = Animation.easeInOut(duration: 0.25)
    static let quickEase = Animation.easeOut(duration: 0.15)
    static let slowEase = Animation.easeInOut(duration: 0.4)
    
    // Playful animations
    static let wiggle = Animation.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    static let breathe = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    
    // UI-specific animations
    static let buttonPress = Animation.spring(response: 0.15, dampingFraction: 0.8)
    static let cardHover = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let overlayFade = Animation.easeInOut(duration: 0.2)
    static let sheetTransition = Animation.spring(response: 0.5, dampingFraction: 0.85)
    
    // Fun micro-interactions
    static let successPop = Animation.spring(response: 0.2, dampingFraction: 0.5)
    static let errorShake = Animation.easeInOut(duration: 0.05).repeatCount(4, autoreverses: true)
    static let loadingBounce = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
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