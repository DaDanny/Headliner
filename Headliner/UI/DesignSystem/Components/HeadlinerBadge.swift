//
//  HeadlinerBadge.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

// MARK: - Headliner Badge

struct HeadlinerBadge: View {
  let text: String
  let icon: String?
  let variant: Variant
  let size: Size
  
  enum Variant {
    case success
    case danger
    case info
    case warning
    case neutral
    
    var colors: BadgeColors {
      switch self {
      case .success:
        return BadgeColors(
          background: DesignTokens.Components.Badge.Success.background,
          foreground: DesignTokens.Components.Badge.Success.foreground
        )
      case .danger:
        return BadgeColors(
          background: DesignTokens.Components.Badge.Danger.background,
          foreground: DesignTokens.Components.Badge.Danger.foreground
        )
      case .info:
        return BadgeColors(
          background: DesignTokens.Components.Badge.Info.background,
          foreground: DesignTokens.Components.Badge.Info.foreground
        )
      case .warning:
        return BadgeColors(
          background: DesignTokens.Colors.warning.opacity(0.16),
          foreground: DesignTokens.Colors.warning
        )
      case .neutral:
        return BadgeColors(
          background: DesignTokens.Colors.textSecondary.opacity(0.16),
          foreground: DesignTokens.Colors.textSecondary
        )
      }
    }
  }
  
  enum Size {
    case small
    case medium
    case large
    
    var font: Font {
      switch self {
      case .small: return DesignTokens.Typography.font(size: DesignTokens.Typography.Sizes.xs, weight: .medium)
      case .medium: return DesignTokens.Typography.font(size: DesignTokens.Typography.Sizes.sm, weight: .medium)
      case .large: return DesignTokens.Typography.font(size: DesignTokens.Typography.Sizes.md, weight: .medium)
      }
    }
    
    var padding: EdgeInsets {
      switch self {
      case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
      case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
      case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
      }
    }
    
    var iconSize: CGFloat {
      switch self {
      case .small: return 10
      case .medium: return 12
      case .large: return 14
      }
    }
    
    var spacing: CGFloat {
      switch self {
      case .small: return 3
      case .medium: return 4
      case .large: return 6
      }
    }
  }
  
  init(
    _ text: String,
    icon: String? = nil,
    variant: Variant = .neutral,
    size: Size = .medium
  ) {
    self.text = text
    self.icon = icon
    self.variant = variant
    self.size = size
  }
  
  var body: some View {
    HStack(spacing: size.spacing) {
      if let icon {
        Image(systemName: icon)
          .font(.system(size: size.iconSize, weight: .medium))
      }
      
      Text(text)
        .font(size.font)
    }
    .foregroundColor(variant.colors.foreground)
    .padding(size.padding)
    .background(
      Capsule()
        .fill(variant.colors.background)
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel(text)
  }
}

// MARK: - Badge Colors

private struct BadgeColors {
  let background: Color
  let foreground: Color
}

// MARK: - Live Indicator Badge

/// Special badge with pulsing animation for "live" status
struct LiveIndicatorBadge: View {
  let text: String
  @State private var isPulsing = false
  
  init(_ text: String = "LIVE") {
    self.text = text
  }
  
  var body: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(DesignTokens.Colors.danger)
        .frame(width: 8, height: 8)
        .scaleEffect(isPulsing ? 1.2 : 1.0)
        .opacity(isPulsing ? 0.7 : 1.0)
        .animation(
          .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
          value: isPulsing
        )
      
      Text(text)
        .font(DesignTokens.Typography.font(size: DesignTokens.Typography.Sizes.xs, weight: .bold))
    }
    .foregroundColor(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      Capsule()
        .fill(Color.black.opacity(0.7))
    )
    .onAppear {
      isPulsing = true
    }
  }
}

// MARK: - Extension Status Badge

/// Specialized badge for extension status with proper icons and colors
struct ExtensionStatusBadge: View {
  let status: ExtensionStatus
  
  var body: some View {
    switch status {
    case .unknown:
      HeadlinerBadge("Checking...", icon: "ellipsis", variant: .neutral, size: .small)
    case .notInstalled:
      HeadlinerBadge("Not Installed", icon: "exclamationmark.triangle", variant: .warning, size: .small)
    case .installing:
      HeadlinerBadge("Installing...", icon: "arrow.down.circle", variant: .info, size: .small)
    case .installed:
      HeadlinerBadge("Installed", icon: "checkmark.circle.fill", variant: .success, size: .small)
    case .error:
      HeadlinerBadge("Error", icon: "xmark.circle.fill", variant: .danger, size: .small)
    }
  }
}

// MARK: - Camera Status Badge

/// Specialized badge for camera status
struct CameraStatusBadge: View {
  let status: CameraStatus
  
  var body: some View {
    switch status {
    case .stopped:
      HeadlinerBadge("Stopped", icon: "pause.circle", variant: .neutral, size: .small)
    case .starting:
      HeadlinerBadge("Starting...", icon: "play.circle", variant: .info, size: .small)
    case .running:
      HeadlinerBadge("Running", icon: "dot.radiowaves.left.and.right", variant: .success, size: .small)
    case .stopping:
      HeadlinerBadge("Stopping...", icon: "stop.circle", variant: .warning, size: .small)
    case .error:
      HeadlinerBadge("Error", icon: "exclamationmark.triangle.fill", variant: .danger, size: .small)
    }
  }
}

// MARK: - Preview

#if DEBUG
struct HeadlinerBadge_Previews: PreviewProvider {
  static var previews: some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
      // Variants
      HStack(spacing: DesignTokens.Spacing.md) {
        HeadlinerBadge("Success", icon: "checkmark", variant: .success)
        HeadlinerBadge("Danger", icon: "xmark", variant: .danger)
        HeadlinerBadge("Info", icon: "info", variant: .info)
        HeadlinerBadge("Warning", icon: "exclamationmark", variant: .warning)
        HeadlinerBadge("Neutral", variant: .neutral)
      }
      
      // Sizes
      HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
        VStack(spacing: DesignTokens.Spacing.sm) {
          HeadlinerBadge("Small", variant: .info, size: .small)
          HeadlinerBadge("Medium", variant: .info, size: .medium)
          HeadlinerBadge("Large", variant: .info, size: .large)
        }
      }
      
      // Special badges
      VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
        LiveIndicatorBadge()
        ExtensionStatusBadge(status: .installed)
        CameraStatusBadge(status: .running)
      }
    }
    .padding(DesignTokens.Spacing.xxl)
    .background(DesignTokens.Colors.surface)
    .previewLayout(.sizeThatFits)
  }
}
#endif