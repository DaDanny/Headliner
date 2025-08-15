//
//  StatusCard.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct StatusCard: View {
  let title: String
  let status: String
  let icon: String
  let color: Color

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 24, weight: .medium))
        .foregroundColor(color)
        .frame(width: 32, height: 32)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.secondary)

        Text(status)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.primary)
      }

      Spacer()
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.background)
        .stroke(color.opacity(0.3), lineWidth: 1)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
  }
}

// Intentionally no PreviewProvider to reduce compile surface for tooling.
