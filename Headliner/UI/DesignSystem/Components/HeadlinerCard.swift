//
//  HeadlinerCard.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

// MARK: - Headliner Card

struct HeadlinerCard<Content: View>: View {
  let content: Content
  let variant: Variant
  let padding: EdgeInsets?
  let isClickable: Bool
  let action: (() -> Void)?
  
  @State private var isHovered = false
  
  enum Variant {
    case standard
    case elevated
    case flat
    
    var shadow: DesignTokens.Shadows.Shadow {
      switch self {
      case .standard, .elevated: return DesignTokens.Shadows.soft
      case .flat: return DesignTokens.Shadows.hard
      }
    }
    
    var shadowOpacity: Double {
      switch self {
      case .standard: return 1.0
      case .elevated: return 1.2
      case .flat: return 0.3
      }
    }
    
    var borderOpacity: Double {
      switch self {
      case .standard: return 1.0
      case .elevated: return 0.8
      case .flat: return 0.5
      }
    }
  }
  
  init(
    variant: Variant = .standard,
    padding: EdgeInsets? = nil,
    isClickable: Bool = false,
    action: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.variant = variant
    self.padding = padding
    self.isClickable = isClickable
    self.action = action
  }
  
  var body: some View {
    Group {
      if isClickable {
        Button(action: action ?? {}) {
          cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
          isHovered = hovering
        }
      } else {
        cardContent
      }
    }
  }
  
  private var cardContent: some View {
    content
      .padding(effectivePadding)
      .background(cardBackground)
      .scaleEffect(isHovered && isClickable ? 1.02 : 1.0)
      .animation(DesignTokens.Animations.spring, value: isHovered)
  }
  
  private var effectivePadding: EdgeInsets {
    padding ?? EdgeInsets(
      top: DesignTokens.Spacing.lg,
      leading: DesignTokens.Spacing.lg,
      bottom: DesignTokens.Spacing.lg,
      trailing: DesignTokens.Spacing.lg
    )
  }
  
  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: DesignTokens.Components.Card.radius)
      .fill(DesignTokens.Components.Card.background)
      .overlay(
        RoundedRectangle(cornerRadius: DesignTokens.Components.Card.radius)
          .stroke(
            DesignTokens.Components.Card.insetBorder.opacity(variant.borderOpacity),
            lineWidth: 1
          )
      )
      .shadow(
        color: variant.shadow.color.opacity(variant.shadowOpacity),
        radius: variant.shadow.radius,
        x: variant.shadow.x,
        y: variant.shadow.y
      )
  }
}

// MARK: - Sectioned Card

/// A card with a title and optional subtitle
struct SectionedCard<Content: View>: View {
  let title: String
  let subtitle: String?
  let titleAction: (() -> Void)?
  let content: Content
  let variant: HeadlinerCard<Content>.Variant
  
  init(
    title: String,
    subtitle: String? = nil,
    titleAction: (() -> Void)? = nil,
    variant: HeadlinerCard<Content>.Variant = .standard,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.subtitle = subtitle
    self.titleAction = titleAction
    self.variant = variant
    self.content = content()
  }
  
  var body: some View {
    HeadlinerCard(variant: variant) {
      VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
        // Header
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            if let titleAction = titleAction {
              Button(action: titleAction) {
                titleText
              }
              .buttonStyle(PlainButtonStyle())
            } else {
              titleText
            }
            
            if let subtitle = subtitle {
              Text(subtitle)
                .font(DesignTokens.Typography.captionFont)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            }
          }
          
          Spacer()
          
          if titleAction != nil {
            Image(systemName: "chevron.right")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(DesignTokens.Colors.textTertiary)
          }
        }
        
        // Content
        content
      }
    }
  }
  
  private var titleText: some View {
    Text(title)
      .font(DesignTokens.Typography.titleFont)
      .foregroundColor(DesignTokens.Colors.textPrimary)
  }
}

// MARK: - Collapsible Card

/// A card that can be expanded/collapsed
struct CollapsibleCard<Content: View>: View {
  let title: String
  let isExpanded: Binding<Bool>
  let content: Content
  
  init(
    title: String,
    isExpanded: Binding<Bool>,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.isExpanded = isExpanded
    self.content = content()
  }
  
  var body: some View {
    HeadlinerCard {
      VStack(alignment: .leading, spacing: 0) {
        // Header
        Button(action: { isExpanded.wrappedValue.toggle() }) {
          HStack {
            Text(title)
              .font(DesignTokens.Typography.titleFont)
              .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.down")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(DesignTokens.Colors.textTertiary)
              .rotationEffect(.degrees(isExpanded.wrappedValue ? 180 : 0))
              .animation(DesignTokens.Animations.spring, value: isExpanded.wrappedValue)
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        
        // Collapsible Content
        if isExpanded.wrappedValue {
          content
            .padding(.top, DesignTokens.Spacing.md)
            .transition(.asymmetric(
              insertion: .opacity.combined(with: .move(edge: .top)),
              removal: .opacity.combined(with: .move(edge: .top))
            ))
        }
      }
      .animation(DesignTokens.Animations.spring, value: isExpanded.wrappedValue)
    }
  }
}

// MARK: - Status Card

/// A card specifically for showing status information
struct StatusCard: View {
  let title: String
  let status: String
  let icon: String
  let variant: HeadlinerBadge.Variant
  let action: (() -> Void)?
  
  init(
    title: String,
    status: String,
    icon: String,
    variant: HeadlinerBadge.Variant = .neutral,
    action: (() -> Void)? = nil
  ) {
    self.title = title
    self.status = status
    self.icon = icon
    self.variant = variant
    self.action = action
  }
  
  var body: some View {
    HeadlinerCard(isClickable: action != nil, action: action) {
      HStack(spacing: DesignTokens.Spacing.md) {
        // Icon
        Image(systemName: icon)
          .font(.system(size: 20, weight: .medium))
          .foregroundColor(variant.colors.foreground)
          .frame(width: 32, height: 32)
          .background(
            Circle()
              .fill(variant.colors.background)
          )
        
        // Content
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(DesignTokens.Typography.bodyFont)
            .foregroundColor(DesignTokens.Colors.textSecondary)
          
          Text(status)
            .font(DesignTokens.Typography.font(size: DesignTokens.Typography.Sizes.lg, weight: .semibold))
            .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        
        Spacer()
        
        if action != nil {
          Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(DesignTokens.Colors.textTertiary)
        }
      }
    }
  }
}

// MARK: - Badge Colors Extension

private extension HeadlinerBadge.Variant {
  var colors: (background: Color, foreground: Color) {
    switch self {
    case .success:
      return (DesignTokens.Components.Badge.Success.background, DesignTokens.Components.Badge.Success.foreground)
    case .danger:
      return (DesignTokens.Components.Badge.Danger.background, DesignTokens.Components.Badge.Danger.foreground)
    case .info:
      return (DesignTokens.Components.Badge.Info.background, DesignTokens.Components.Badge.Info.foreground)
    case .warning:
      return (DesignTokens.Colors.warning.opacity(0.16), DesignTokens.Colors.warning)
    case .neutral:
      return (DesignTokens.Colors.textSecondary.opacity(0.16), DesignTokens.Colors.textSecondary)
    }
  }
}

// MARK: - Preview

#if DEBUG
struct HeadlinerCard_Previews: PreviewProvider {
  @State static var isExpanded = true
  
  static var previews: some View {
    ScrollView {
      VStack(spacing: DesignTokens.Spacing.lg) {
        // Basic card
        HeadlinerCard {
          Text("Basic card content")
            .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        
        // Sectioned card
        SectionedCard(title: "Camera Settings", subtitle: "Configure your camera") {
          VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Resolution: 1080p")
            Text("Frame Rate: 30 fps")
          }
          .font(DesignTokens.Typography.bodyFont)
          .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        
        // Clickable sectioned card
        SectionedCard(title: "Advanced", titleAction: {}) {
          Text("Click the title to expand")
            .font(DesignTokens.Typography.bodyFont)
            .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        
        // Collapsible card
        CollapsibleCard(title: "Collapsible Settings", isExpanded: $isExpanded) {
          VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("This content can be collapsed")
            Text("And expanded again")
          }
          .font(DesignTokens.Typography.bodyFont)
          .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        
        // Status cards
        StatusCard(
          title: "Extension Status",
          status: "Installed",
          icon: "checkmark.circle.fill",
          variant: .success
        )
        
        StatusCard(
          title: "Camera Status",
          status: "Running",
          icon: "dot.radiowaves.left.and.right",
          variant: .success,
          action: {}
        )
        
        // Card variants
        HStack {
          HeadlinerCard(variant: .standard) {
            Text("Standard")
              .foregroundColor(DesignTokens.Colors.textPrimary)
          }
          
          HeadlinerCard(variant: .elevated) {
            Text("Elevated")
              .foregroundColor(DesignTokens.Colors.textPrimary)
          }
          
          HeadlinerCard(variant: .flat) {
            Text("Flat")
              .foregroundColor(DesignTokens.Colors.textPrimary)
          }
        }
      }
      .padding(DesignTokens.Spacing.xxl)
    }
    .background(DesignTokens.Colors.surface)
  }
}
#endif