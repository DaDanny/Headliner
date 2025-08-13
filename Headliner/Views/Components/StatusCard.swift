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

// MARK: - Preview

struct StatusCard_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 16) {
      StatusCard(
        title: "Extension Status",
        status: "Installed",
        icon: "checkmark.circle.fill",
        color: .green
      )

      StatusCard(
        title: "Camera Status",
        status: "Running",
        icon: "video.circle.fill",
        color: .blue
      )

      StatusCard(
        title: "Extension Status",
        status: "Not Installed",
        icon: "exclamationmark.circle.fill",
        color: .orange
      )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }
}
