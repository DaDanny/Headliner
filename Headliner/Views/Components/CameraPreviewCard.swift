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
  let overlayService: OverlayService?  // Optional for overlay preview
  
  @State private var overlayPreviewImage: CGImage?
  @State private var renderTask: Task<Void, Never>?  // Track rendering task

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .fill(.black)
        .frame(height: 300)

      if let previewImage {
        ZStack {
          // Base camera preview - optimized rendering
          Image(previewImage, scale: 1.0, label: Text("Camera Preview"))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 300)
            .clipped()
            .cornerRadius(20)
            .id(previewImage)  // Force refresh when image changes
          
          // Overlay preview (if available)
          if let overlayImage = overlayPreviewImage {
            Image(overlayImage, scale: 1.0, label: Text("Overlay Preview"))
              .resizable()
              .aspectRatio(contentMode: .fit)  // Use .fit to maintain overlay proportions
              .frame(height: 300)
              .clipped()
              .cornerRadius(20)
              .allowsHitTesting(false)  // Don't interfere with camera preview interactions
              .id(overlayImage)  // Force refresh when overlay changes
          } 
          
          // DEBUG: Visual indicator when overlay should be active
          if let presetId = overlayService?.settings.selectedPresetId, presetId != "none" {
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
    .onChange(of: overlayService?.settings.selectedPresetId) { _ in
      updateOverlayPreview()
    }
    .onChange(of: overlayService?.settings.overlayTokens) { _ in
      updateOverlayPreview()
    }
    .onChange(of: overlayService?.settings.overlayAspect) { _ in
      updateOverlayPreview()
    }
    .onChange(of: overlayService?.settings.safeAreaMode) { _ in
      updateOverlayPreview()
    }
    .onChange(of: overlayService?.settings.selectedSurfaceStyle) { _ in
      updateOverlayPreview()
    }
    .onDisappear {
      // Cancel any pending render task when view disappears
      renderTask?.cancel()
    }
  }
  
  // MARK: - Private Methods
  
  private func updateOverlayPreview() {
    // Cancel any existing rendering task
    renderTask?.cancel()
    
    guard let overlayService = overlayService else {
      overlayPreviewImage = nil
      return
    }
    
    guard overlayService.settings.selectedPresetId != "none" else {
      overlayPreviewImage = nil
      return
    }
    
    guard let tokens = overlayService.settings.overlayTokens else {
      overlayPreviewImage = nil
      return
    }
    
    // Use actual camera dimensions from cached settings for accurate preview
    let cameraDimensions = overlayService.settings.cameraDimensions
    let previewSize = cameraDimensions.width > 0 && cameraDimensions.height > 0 
      ? cameraDimensions 
      : CGSize(width: 640, height: 360) // Fallback for small cameras
    
    // Create new rendering task
    renderTask = Task {
      await renderOverlayPreview(tokens: tokens, presetId: overlayService.settings.selectedPresetId, size: previewSize)
    }
  }
  
  @MainActor
  private func renderOverlayPreview(tokens: OverlayTokens, presetId: String, size: CGSize) async {
    // Get the appropriate overlay provider based on preset ID
    guard let provider = getOverlayProvider(for: presetId) else {
      overlayPreviewImage = nil
      return
    }
    
    // Get current safe area mode and surface style from overlayService
    let safeAreaMode = overlayService?.settings.safeAreaMode ?? .balanced
    let surfaceStyle = overlayService?.settings.selectedSurfaceStyle ?? "rounded"
    let renderTokens = RenderTokens(safeAreaMode: safeAreaMode, surfaceStyle: surfaceStyle)
    
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
  
  /// Get current PersonalInfo from App Group storage
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
    
    // Legacy mapping for old preset IDs (migrated to remaining valid presets)
    let legacyMappings: [String: String] = [
      "professional": "swiftui.modern.personal", // Use ModernPersonal as fallback
      "personal": "swiftui.modern.personal", 
      "company-branding": "swiftui.modern.personal",
      "metric": "swiftui.modern.personal" // Use ModernPersonal as fallback
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
      "professional": "swiftui.modern.personal",
      "personal": "swiftui.modern.personal",
      "company-branding": "swiftui.modern.personal", 
      "metric": "swiftui.modern.personal"
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
      CameraPreviewCard(previewImage: nil, isActive: true, overlayService: nil)
      CameraPreviewCard(previewImage: nil, isActive: false, overlayService: nil)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }
}
#endif
