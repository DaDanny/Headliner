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
  
  enum Variant {
    case primary
    case secondary
    case ghost
    case danger
    
    var config: ButtonConfig {
      switch self {
      case .primary:
        return ButtonConfig(
          background: DesignTokens.Components.Button.Primary.background,
          foreground: DesignTokens.Components.Button.Primary.foreground,
          height: DesignTokens.Components.Button.Primary.height,
          radius: DesignTokens.Components.Button.Primary.radius
        )
      case .secondary:
        return ButtonConfig(
          background: DesignTokens.Components.Button.Secondary.background,
          foreground: DesignTokens.Components.Button.Secondary.foreground,
          height: DesignTokens.Components.Button.Secondary.height,
          radius: DesignTokens.Components.Button.Secondary.radius,
          stroke: DesignTokens.Components.Button.Secondary.stroke
        )
      case .ghost:
        return ButtonConfig(
          background: DesignTokens.Components.Button.Ghost.background,
          foreground: DesignTokens.Components.Button.Ghost.foreground,
          height: DesignTokens.Components.Button.Ghost.height,
          radius: DesignTokens.Components.Button.Ghost.radius,
          hoverBackground: DesignTokens.Components.Button.Ghost.hoverBackground
        )
      case .danger:
        return ButtonConfig(
          background: DesignTokens.Colors.danger,
          foreground: .white,
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
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: config.foreground))
            .scaleEffect(0.8)
        } else if let icon {
          Image(systemName: icon)
            .font(.system(size: size.iconSize, weight: .medium))
        }
        
        Text(title)
          .font(.system(size: size.fontSize, weight: .semibold))
      }
      .foregroundColor(effectiveForegroundColor)
      .padding(.horizontal, size.paddingHorizontal)
      .padding(.vertical, size.paddingVertical)
      .frame(minHeight: config.height)
      .background(
        RoundedRectangle(cornerRadius: config.radius)
          .fill(effectiveBackgroundColor)
          .overlay(
            RoundedRectangle(cornerRadius: config.radius)
              .stroke(config.stroke ?? Color.clear, lineWidth: 1)
          )
      )
      .scaleEffect(isPressed ? 0.96 : 1.0)
      .animation(DesignTokens.Animations.spring, value: isPressed)
      .animation(DesignTokens.Animations.transition, value: isHovered)
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(isDisabled || isLoading)
    .onHover { hovering in
      isHovered = hovering
    }
    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
      isPressed = pressing
    }, perform: {})
    .accessibilityLabel(title)
    .accessibilityHint(isLoading ? "Loading" : nil)
    .accessibilityAddTraits(isDisabled ? .notEnabled : [])
  }
  
  private var config: ButtonConfig {
    variant.config
  }
  
  private var effectiveBackgroundColor: Color {
    if isDisabled {
      return config.background.opacity(0.5)
    }
    
    if variant == .ghost && isHovered {
      return config.hoverBackground ?? config.background
    }
    
    if isHovered && variant != .ghost {
      return config.background.opacity(0.9)
    }
    
    return config.background
  }
  
  private var effectiveForegroundColor: Color {
    if isDisabled {
      return config.foreground.opacity(0.6)
    }
    return config.foreground
  }
  
  private func handleAction() {
    if !isDisabled && !isLoading {
      // Add haptic feedback
      NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
      action()
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
    VStack(spacing: DesignTokens.Spacing.lg) {
      // Primary variants
      HStack(spacing: DesignTokens.Spacing.md) {
        HeadlinerButton("Start Camera", icon: "video", variant: .primary) {}
        HeadlinerButton("Loading", variant: .primary, isLoading: true) {}
        HeadlinerButton("Disabled", variant: .primary, isDisabled: true) {}
      }
      
      // Secondary variants
      HStack(spacing: DesignTokens.Spacing.md) {
        HeadlinerButton("Settings", icon: "gear", variant: .secondary) {}
        HeadlinerButton("Select Camera", variant: .secondary) {}
      }
      
      // Ghost variants
      HStack(spacing: DesignTokens.Spacing.md) {
        HeadlinerButton("Cancel", variant: .ghost) {}
        HeadlinerButton("Help", icon: "questionmark", variant: .ghost) {}
      }
      
      // Sizes
      HStack(spacing: DesignTokens.Spacing.md) {
        HeadlinerButton("Compact", variant: .secondary, size: .compact) {}
        HeadlinerButton("Regular", variant: .secondary, size: .regular) {}
        HeadlinerButton("Large", variant: .secondary, size: .large) {}
      }
      
      // Danger
      HeadlinerButton("Stop Camera", icon: "stop.fill", variant: .danger) {}
    }
    .padding(DesignTokens.Spacing.xxl)
    .background(DesignTokens.Colors.surface)
    .previewLayout(.sizeThatFits)
  }
}
#endif