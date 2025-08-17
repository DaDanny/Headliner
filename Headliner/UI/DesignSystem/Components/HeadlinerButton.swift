//
//  HeadlinerButton.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

// MARK: - Headliner Button

struct HeadlinerButton: View {
  let title: String
  let icon: String?
  let variant: Variant
  let size: Size
  let isLoading: Bool
  let isDisabled: Bool
  let action: () -> Void
  
  @State private var isHovered = false
  @State private var isPressed = false
  @State private var showSuccessAnimation = false
  
  enum Variant {
    case primary
    case secondary
    case ghost
    case danger
    
    var config: ButtonConfig {
      switch self {
      case .primary:
        return ButtonConfig(
          background: DesignTokens.Colors.brandPrimary, // Will use gradient in effectiveBackgroundStyle
          foreground: DesignTokens.Colors.onAccent,
          height: DesignTokens.Components.Button.Primary.height,
          radius: DesignTokens.Components.Button.Primary.radius
        )
      case .secondary:
        return ButtonConfig(
          background: DesignTokens.Colors.glass,
          foreground: DesignTokens.Colors.textPrimary,
          height: DesignTokens.Components.Button.Secondary.height,
          radius: DesignTokens.Components.Button.Secondary.radius,
          stroke: DesignTokens.Colors.glassStroke
        )
      case .ghost:
        return ButtonConfig(
          background: Color.clear,
          foreground: DesignTokens.Colors.textSecondary,
          height: DesignTokens.Components.Button.Ghost.height,
          radius: DesignTokens.Components.Button.Ghost.radius,
          hoverBackground: DesignTokens.Colors.hoverOverlay
        )
      case .danger:
        return ButtonConfig(
          background: DesignTokens.Colors.danger,
          foreground: Color.white,
          height: DesignTokens.Components.Button.Primary.height,
          radius: DesignTokens.Components.Button.Primary.radius
        )
      }
    }
  }
  
  enum Size {
    case compact
    case regular
    case large
    
    var paddingHorizontal: CGFloat {
      switch self {
      case .compact: return DesignTokens.Spacing.lg
      case .regular: return DesignTokens.Spacing.xl
      case .large: return DesignTokens.Spacing.xxl
      }
    }
    
    var paddingVertical: CGFloat {
      switch self {
      case .compact: return DesignTokens.Spacing.sm
      case .regular: return DesignTokens.Spacing.md
      case .large: return DesignTokens.Spacing.lg
      }
    }
    
    var fontSize: CGFloat {
      switch self {
      case .compact: return DesignTokens.Typography.Sizes.sm
      case .regular: return DesignTokens.Typography.Sizes.md
      case .large: return DesignTokens.Typography.Sizes.lg
      }
    }
    
    var iconSize: CGFloat {
      switch self {
      case .compact: return 12
      case .regular: return 16
      case .large: return 18
      }
    }
  }
  
  init(
    _ title: String,
    icon: String? = nil,
    variant: Variant = .primary,
    size: Size = .regular,
    isLoading: Bool = false,
    isDisabled: Bool = false,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.icon = icon
    self.variant = variant
    self.size = size
    self.isLoading = isLoading
    self.isDisabled = isDisabled
    self.action = action
  }
  
  var body: some View {
    Button(action: handleAction) {
      HStack(spacing: DesignTokens.Spacing.sm) {
        // Loading or Icon
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: effectiveForegroundColor))
            .scaleEffect(0.8)
            .animation(DesignTokens.Animations.loadingBounce, value: isLoading)
        } else if let icon {
          Image(systemName: showSuccessAnimation ? "checkmark" : icon)
            .font(.system(size: size.iconSize, weight: .medium))
            .scaleEffect(showSuccessAnimation ? 1.2 : 1.0)
            .animation(DesignTokens.Animations.successPop, value: showSuccessAnimation)
        }
        
        // Title
        Text(title)
          .font(.system(size: size.fontSize, weight: .semibold))
          .animation(.none, value: title) // Prevent text animation
      }
      .foregroundColor(effectiveForegroundColor)
      .padding(.horizontal, size.paddingHorizontal)
      .padding(.vertical, size.paddingVertical)
      .frame(minHeight: config.height)
      .background(
        ZStack {
          // Main background with modern styling
          RoundedRectangle(cornerRadius: config.radius)
            .fill(effectiveBackgroundStyle)
            .overlay(
              // Stroke overlay
              RoundedRectangle(cornerRadius: config.radius)
                .strokeBorder(effectiveStrokeColor, lineWidth: strokeWidth)
            )
            .shadow(
              color: effectiveShadowColor,
              radius: effectiveShadowRadius,
              x: 0,
              y: effectiveShadowOffset
            )
          
          // Hover overlay
          if isHovered && !isDisabled {
            RoundedRectangle(cornerRadius: config.radius)
              .fill(hoverOverlayColor)
              .transition(.opacity)
          }
          
          // Press overlay
          if isPressed && !isDisabled {
            RoundedRectangle(cornerRadius: config.radius)
              .fill(pressOverlayColor)
              .transition(.opacity)
          }
        }
      )
      .scaleEffect(buttonScale)
      .animation(DesignTokens.Animations.buttonPress, value: isPressed)
      .animation(DesignTokens.Animations.cardHover, value: isHovered)
      .opacity(isDisabled ? 0.6 : 1.0)
      .animation(DesignTokens.Animations.smoothEase, value: isDisabled)
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(isDisabled || isLoading)
    .onHover { hovering in
      withAnimation(DesignTokens.Animations.quickEase) {
        isHovered = hovering
      }
    }
    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
      withAnimation(DesignTokens.Animations.buttonPress) {
        isPressed = pressing
      }
    }, perform: {})
    .accessibilityLabel(title)
    .accessibilityHint(isLoading ? "Loading" : nil)
    .accessibilityAddTraits(isDisabled ? .notEnabled : [])
  }
  
  private var config: ButtonConfig {
    variant.config
  }
  
  // MARK: - Visual State Computations
  
  private var effectiveBackgroundStyle: AnyShapeStyle {
    if variant == .primary {
      return AnyShapeStyle(DesignTokens.Colors.brandGradient)
    }
    return AnyShapeStyle(config.background)
  }
  
  private var effectiveForegroundColor: Color {
    if isDisabled {
      return config.foreground.opacity(0.5)
    }
    return config.foreground
  }
  
  private var effectiveStrokeColor: Color {
    if isDisabled {
      return (config.stroke ?? Color.clear).opacity(0.5)
    }
    
    if isHovered && variant == .secondary {
      return DesignTokens.Colors.accent.opacity(0.3)
    }
    
    return config.stroke ?? Color.clear
  }
  
  private var strokeWidth: CGFloat {
    return config.stroke != nil ? 1.0 : 0.0
  }
  
  private var effectiveShadowColor: Color {
    if isDisabled { return Color.clear }
    
    switch variant {
    case .primary:
      return DesignTokens.Colors.brandPrimary.opacity(isPressed ? 0.6 : (isHovered ? 0.4 : 0.2))
    case .danger:
      return DesignTokens.Colors.danger.opacity(isPressed ? 0.5 : (isHovered ? 0.3 : 0.1))
    default:
      return Color.black.opacity(isPressed ? 0.2 : (isHovered ? 0.1 : 0.05))
    }
  }
  
  private var effectiveShadowRadius: CGFloat {
    if isDisabled { return 0 }
    
    switch variant {
    case .primary, .danger:
      return isPressed ? 8 : (isHovered ? 12 : 6)
    default:
      return isPressed ? 4 : (isHovered ? 6 : 2)
    }
  }
  
  private var effectiveShadowOffset: CGFloat {
    return isPressed ? 1 : 2
  }
  
  private var hoverOverlayColor: Color {
    switch variant {
    case .ghost: return DesignTokens.Colors.hoverOverlay
    default: return Color.white.opacity(0.08)
    }
  }
  
  private var pressOverlayColor: Color {
    return Color.white.opacity(0.12)
  }
  
  private var buttonScale: CGFloat {
    if isDisabled { return 1.0 }
    return isPressed ? 0.96 : 1.0
  }
  
  private func handleAction() {
    if !isDisabled && !isLoading {
      // Add haptic feedback
      NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
      
      // Success animation for certain actions
      if variant == .primary {
        triggerSuccessAnimation()
      }
      
      action()
    }
  }
  
  private func triggerSuccessAnimation() {
    withAnimation(DesignTokens.Animations.successPop) {
      showSuccessAnimation = true
    }
    
    // Reset after a delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      withAnimation(DesignTokens.Animations.smoothEase) {
        showSuccessAnimation = false
      }
    }
  }
}

// MARK: - Button Config

private struct ButtonConfig {
  let background: Color
  let foreground: Color
  let height: CGFloat
  let radius: CGFloat
  let stroke: Color?
  let hoverBackground: Color?
  
  init(
    background: Color,
    foreground: Color,
    height: CGFloat,
    radius: CGFloat,
    stroke: Color? = nil,
    hoverBackground: Color? = nil
  ) {
    self.background = background
    self.foreground = foreground
    self.height = height
    self.radius = radius
    self.stroke = stroke
    self.hoverBackground = hoverBackground
  }
}

// MARK: - Preview

#if DEBUG
struct HeadlinerButton_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      VStack(spacing: DesignTokens.Spacing.xxl) {
        // Hero Buttons - Primary Actions
        VStack(spacing: DesignTokens.Spacing.lg) {
          Text("Primary Actions")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(DesignTokens.Colors.textPrimary)
          
          HStack(spacing: DesignTokens.Spacing.lg) {
            HeadlinerButton("🚀 Start Camera", icon: "video", variant: .primary) {}
            HeadlinerButton("Loading...", variant: .primary, isLoading: true) {}
            HeadlinerButton("Disabled", variant: .primary, isDisabled: true) {}
          }
        }
        
        // Secondary Actions
        VStack(spacing: DesignTokens.Spacing.lg) {
          Text("Secondary Actions")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(DesignTokens.Colors.textPrimary)
          
          HStack(spacing: DesignTokens.Spacing.lg) {
            HeadlinerButton("⚙️ Settings", icon: "gear", variant: .secondary) {}
            HeadlinerButton("Select Camera", variant: .secondary) {}
            HeadlinerButton("Disabled", variant: .secondary, isDisabled: true) {}
          }
        }
        
        // Ghost Buttons
        VStack(spacing: DesignTokens.Spacing.lg) {
          Text("Ghost Actions")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(DesignTokens.Colors.textPrimary)
          
          HStack(spacing: DesignTokens.Spacing.lg) {
            HeadlinerButton("Cancel", variant: .ghost) {}
            HeadlinerButton("❓ Help", icon: "questionmark.circle", variant: .ghost) {}
            HeadlinerButton("More Options", icon: "ellipsis", variant: .ghost) {}
          }
        }
        
        // Size Variations
        VStack(spacing: DesignTokens.Spacing.lg) {
          Text("Size Variations")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(DesignTokens.Colors.textPrimary)
          
          VStack(spacing: DesignTokens.Spacing.md) {
            HeadlinerButton("Large Button", icon: "star.fill", variant: .primary, size: .large) {}
            HeadlinerButton("Regular Button", icon: "heart.fill", variant: .secondary, size: .regular) {}
            HeadlinerButton("Compact", icon: "plus", variant: .ghost, size: .compact) {}
          }
        }
        
        // Danger Actions
        VStack(spacing: DesignTokens.Spacing.lg) {
          Text("Danger Actions")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(DesignTokens.Colors.textPrimary)
          
          HStack(spacing: DesignTokens.Spacing.lg) {
            HeadlinerButton("🛑 Stop Camera", icon: "stop.fill", variant: .danger) {}
            HeadlinerButton("Delete", icon: "trash", variant: .danger, size: .compact) {}
          }
        }
        
        // Fun Demo Section
        VStack(spacing: DesignTokens.Spacing.lg) {
          Text("✨ Interactive Demo")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(DesignTokens.Colors.textPrimary)
          
          Text("Try hovering and clicking the buttons above!")
            .font(.body)
            .foregroundColor(DesignTokens.Colors.textSecondary)
            .multilineTextAlignment(.center)
        }
      }
      .padding(DesignTokens.Spacing.xxl)
    }
    .background(
      ZStack {
        DesignTokens.Colors.surface
        
        // Subtle animated background
        LinearGradient(
          colors: [
            DesignTokens.Colors.brandPrimary.opacity(0.02),
            DesignTokens.Colors.accent.opacity(0.02),
            Color.clear
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    )
    .frame(minWidth: 600, minHeight: 800)
  }
}
#endif