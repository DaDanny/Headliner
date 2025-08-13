//
//  ModernButton.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct ModernButton: View {
  let title: String
  let icon: String?
  let style: ButtonStyle
  let isLoading: Bool
  let action: () -> Void

  enum ButtonStyle {
    case primary
    case secondary
    case danger
    case success

    var backgroundColor: Color {
      switch self {
      case .primary: Color.blue
      case .secondary: Color.gray.opacity(0.2)
      case .danger: Color.red
      case .success: Color.green
      }
    }

    var foregroundColor: Color {
      switch self {
      case .primary, .danger, .success: .white
      case .secondary: .primary
      }
    }
  }

  init(
    _ title: String,
    icon: String? = nil,
    style: ButtonStyle = .primary,
    isLoading: Bool = false,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.icon = icon
    self.style = style
    self.isLoading = isLoading
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
            .scaleEffect(0.8)
        } else if let icon {
          Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
        }

        Text(title)
          .font(.system(size: 16, weight: .semibold))
      }
      .foregroundColor(style.foregroundColor)
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(style.backgroundColor)
          .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
      )
    }
    .buttonStyle(ScaleButtonStyle())
    .disabled(isLoading)
  }
}

struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

// Intentionally no PreviewProvider to reduce compile surface for tooling.
