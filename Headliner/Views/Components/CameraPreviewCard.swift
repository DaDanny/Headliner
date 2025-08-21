//
//  CameraPreviewCard.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI
import CoreGraphics

struct CameraPreviewCard: View {
  let previewImage: CGImage?
  let isActive: Bool
  let appState: AppState?  // Optional for overlay preview
  
  @State private var overlayPreviewImage: CGImage?

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .fill(.black)
        .frame(height: 300)

      if let previewImage {
        ZStack {
          // Base camera preview
          Image(previewImage, scale: 1.0, label: Text("Camera Preview"))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 300)
            .clipped()
            .cornerRadius(20)
          
          // Overlay preview (if available)
          if let overlayImage = overlayPreviewImage {
            Image(overlayImage, scale: 1.0, label: Text("Overlay Preview"))
              .resizable()
              .aspectRatio(contentMode: .fit)  // Use .fit to maintain overlay proportions
              .frame(height: 300)
              .clipped()
              .cornerRadius(20)
              .allowsHitTesting(false)  // Don't interfere with camera preview interactions
          } 
          
          // DEBUG: Visual indicator when overlay should be active
          if let presetId = appState?.overlaySettings.selectedPresetId, presetId != "none" {
            VStack {
              HStack {
                Text("PREVIEW: \(getOverlayName(for: presetId))")
                  .font(.system(size: 8, weight: .bold))
                  .foregroundColor(.yellow)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .background(Color.black.opacity(0.7))
                  .cornerRadius(4)
                Spacer()
              }
              Spacer()
            }
            .padding(8)
            .allowsHitTesting(false)
          }
        }
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
    .onAppear {
      updateOverlayPreview()
    }
    .onChange(of: appState?.overlaySettings.selectedPresetId) { _ in
      updateOverlayPreview()
    }
    .onChange(of: appState?.overlaySettings.overlayTokens) { _ in
      updateOverlayPreview()
    }
    .onChange(of: appState?.overlaySettings.overlayAspect) { _ in
      updateOverlayPreview()
    }
  }
  
  // MARK: - Private Methods
  
  private func updateOverlayPreview() {
    guard let appState = appState else {
      overlayPreviewImage = nil
      return
    }
    
    guard appState.overlaySettings.selectedPresetId != "none" else {
      overlayPreviewImage = nil
      return
    }
    
    guard let tokens = appState.overlaySettings.overlayTokens else {
      overlayPreviewImage = nil
      return
    }
    
    // Use actual camera dimensions from cached settings for accurate preview
    let cameraDimensions = appState.overlaySettings.cameraDimensions
    let previewSize = cameraDimensions.width > 0 && cameraDimensions.height > 0 
      ? cameraDimensions 
      : CGSize(width: 640, height: 360) // Fallback for small cameras
    
    Task {
      await renderOverlayPreview(tokens: tokens, presetId: appState.overlaySettings.selectedPresetId, size: previewSize)
    }
  }
  
  @MainActor
  private func renderOverlayPreview(tokens: OverlayTokens, presetId: String, size: CGSize) async {
    // Get the appropriate overlay provider based on preset ID
    guard let provider = getOverlayProvider(for: presetId) else {
      overlayPreviewImage = nil
      return
    }
    
    // Render the overlay at preview resolution
    overlayPreviewImage = await SwiftUIOverlayRenderer.shared.renderCGImage(
      provider: provider,
      tokens: tokens,
      size: size,
      scale: 1.0  // Use 1.0 for performance
    )
  }
  
  private func getOverlayProvider(for presetId: String) -> (any OverlayViewProviding)? {
    // Map preset IDs to different SwiftUI providers for variety
    switch presetId {
    case "professional":
      return StandardLowerThird()
    case "personal":
      return BrandRibbon()  // Use branded style for personal
    case "company-branding":
      return BrandRibbon()  // Use branded style for company
    case "metric":
      return MetricChipBar()  // Use metrics for metric preset
    // Direct SwiftUI preset IDs
    case "swiftui.standard.lowerthird":
      return StandardLowerThird()
    case "swiftui.branded.ribbon":
      return BrandRibbon()
    case "swiftui.creative.metrics":
      return MetricChipBar()
    case "company-cropped":
      return CompanyCropped()
    case "company-cropped-v2":
      return CompanyCroppedV2()
    case "swiftui.aspectratio.test":
      return AspectRatioTest()
    case "swiftui.aspectratio.test-v2":
        return AspectRatioTestV2()
    default:
      // Fallback to StandardLowerThird for unknown presets
      return StandardLowerThird()
    }
  }
  
  private func getOverlayName(for presetId: String) -> String {
    switch presetId {
    case "professional":
      return "Standard"
    case "personal":
      return "Brand"
    case "company-branding":
      return "Brand"
    case "metric":
      return "Metrics"
    case "swiftui.standard.lowerthird":
      return "Standard"
    case "swiftui.branded.ribbon":
      return "Brand"
    case "swiftui.creative.metrics":
      return "Metrics"
    case "company-cropped":
      return "Company"
    case "company-cropped-v2":
      return "Company V2"
    default:
      return "Standard"
    }
  }
}

#if DEBUG
struct CameraPreviewCard_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      CameraPreviewCard(previewImage: nil, isActive: true, appState: nil)
      CameraPreviewCard(previewImage: nil, isActive: false, appState: nil)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }
}
#endif
