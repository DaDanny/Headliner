//
//  GlassmorphicCard.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct GlassmorphicCard<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .background(
        ZStack {
          // Background blur effect (simplified to avoid Metal issues)
          RoundedRectangle(cornerRadius: 16)
            .fill(
              LinearGradient(
                colors: [
                  Color.white.opacity(0.2),
                  Color.white.opacity(0.1),
                  Color.black.opacity(0.1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
            )

          // Subtle border
          RoundedRectangle(cornerRadius: 16)
            .stroke(
              LinearGradient(
                colors: [
                  .white.opacity(0.2),
                  .white.opacity(0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 1
            )
        }
      )
      .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
  }
}

struct PulsingButton: View {
  let title: String
  let icon: String?
  let color: Color
  let isActive: Bool
  let action: () -> Void

  @State private var isPulsing = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        if let icon {
          Image(systemName: icon)
            .font(.system(size: 18, weight: .medium))
        }

        Text(title)
          .font(.system(size: 16, weight: .semibold))
      }
      .foregroundColor(.white)
      .padding(.horizontal, 24)
      .padding(.vertical, 14)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 14)
            .fill(color)

          if isActive {
            RoundedRectangle(cornerRadius: 14)
              .stroke(color.opacity(0.6), lineWidth: 2)
              .scaleEffect(isPulsing ? 1.1 : 1.0)
              .opacity(isPulsing ? 0 : 1)
              .animation(
                .easeOut(duration: 1.0)
                  .repeatForever(autoreverses: false),
                value: isPulsing
              )
          }
        }
      )
    }
    .buttonStyle(ScaleButtonStyle())
    .onAppear {
      if isActive {
        isPulsing = true
      }
    }
    .onChange(of: isActive) { _, newValue in
      isPulsing = newValue
    }
  }
}

// Intentionally no PreviewProvider to reduce compile surface for tooling.
