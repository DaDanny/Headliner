//
//  CameraPreviewCard.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct CameraPreviewCard: View {
  let previewImage: CGImage?
  let isActive: Bool

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .fill(.black)
        .frame(height: 300)

      if let previewImage {
        Image(previewImage, scale: 1.0, label: Text("Camera Preview"))
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(height: 300)
          .clipped()
          .cornerRadius(20)
      } else {
        VStack(spacing: 16) {
          Image(systemName: isActive ? "video" : "video.slash")
            .font(.system(size: 48, weight: .light))
            .foregroundColor(.white.opacity(0.6))

          Text(isActive ? "Camera Starting..." : "No Video Feed")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
        }
      }

      // Overlay for status indicator
      VStack {
        HStack {
          Spacer()

          HStack(spacing: 6) {
            Circle()
              .fill(isActive ? .green : .red)
              .frame(width: 8, height: 8)

            Text(isActive ? "LIVE" : "OFF")
              .font(.system(size: 12, weight: .bold))
              .foregroundColor(.white)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(.black.opacity(0.6))
          )
        }

        Spacer()
      }
      .padding(16)
    }
    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
  }
}

// MARK: - Preview

struct CameraPreviewCard_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      CameraPreviewCard(previewImage: nil, isActive: true)
      CameraPreviewCard(previewImage: nil, isActive: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }
}
