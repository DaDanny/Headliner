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
    .onChange(of: appState?.overlaySettings.safeAreaMode) { _ in
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
    
    // Get current safe area mode from appState
    let safeAreaMode = appState?.overlaySettings.safeAreaMode ?? .balanced
    let renderTokens = RenderTokens(safeAreaMode: safeAreaMode)
    
    // Get PersonalInfo for previews (optional, could be nil)
    let personalInfo = getCurrentPersonalInfo()
    
    // Render the overlay at preview resolution
    overlayPreviewImage = await SwiftUIOverlayRenderer.shared.renderCGImage(
      provider: provider,
      tokens: tokens,
      size: size,
      scale: 1.0,  // Use 1.0 for performance
      renderTokens: renderTokens,
      personalInfo: personalInfo
    )
  }
  
  /// Get current PersonalInfo from App Group storage (same as AppState)
  private func getCurrentPersonalInfo() -> PersonalInfo? {
    guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let data = userDefaults.data(forKey: "overlay.personalInfo.v1"),
          let info = try? JSONDecoder().decode(PersonalInfo.self, from: data) else {
      return nil
    }
    return info
  }

  private func getOverlayProvider(for presetId: String) -> (any OverlayViewProviding)? {
    // Use SwiftUI registry as the single source of truth
    if let preset = SwiftUIPresetRegistry.preset(withId: presetId) {
      return preset.provider
    }
    
    // Legacy mapping for old preset IDs (gradually migrate these to use new IDs)
    let legacyMappings: [String: String] = [
      "professional": "swiftui.professional",
      "personal": "swiftui.branded.ribbon", 
      "company-branding": "swiftui.branded.ribbon",
      "metric": "swiftui.creative.metrics"
    ]
    
    if let newId = legacyMappings[presetId] {
      return SwiftUIPresetRegistry.preset(withId: newId)?.provider
    }
    
    // Fallback to first available preset from registry
    return SwiftUIPresetRegistry.allPresets.first?.provider
  }
  
  private func getOverlayName(for presetId: String) -> String {
    // Use SwiftUI registry as the single source of truth
    if let preset = SwiftUIPresetRegistry.preset(withId: presetId) {
      return preset.name
    }
    
    // Legacy mapping for old preset IDs
    let legacyMappings: [String: String] = [
      "professional": "swiftui.professional",
      "personal": "swiftui.branded.ribbon",
      "company-branding": "swiftui.branded.ribbon", 
      "metric": "swiftui.creative.metrics"
    ]
    
    if let newId = legacyMappings[presetId],
       let preset = SwiftUIPresetRegistry.preset(withId: newId) {
      return preset.name
    }
    
    // Fallback
    return "Unknown"
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
