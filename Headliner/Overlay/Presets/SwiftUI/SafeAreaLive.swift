//
//  SafeAreaLive.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Live safe area testing overlay - perfect for real meeting testing
/// Combines the clean aesthetic of SafeAreaTest with live camera dimensions and selected safe area mode
struct SafeAreaLive: OverlayViewProviding {
    static let presetId = "swiftui.safearea.live"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geo in
            let settings = getOverlaySettings()
            let inputAR = settings.cameraDimensions.nonZeroAspect ?? CGSize(width: 16, height: 9) // Default to 16:9 if no camera
            let selectedMode = settings.safeAreaMode
            
            ZStack {
                // Clean black background like SafeAreaTest
                Color.clear // Transparent for meeting testing
                
                // Show camera content area (green outline)
                let contentSafe = fitRect(content: inputAR, into: geo.size)
                Rectangle()
                    .stroke(Color.green.opacity(0.82), lineWidth: 5)
                    .frame(width: contentSafe.width, height: contentSafe.height)
                    .position(x: contentSafe.midX, y: contentSafe.midY)
                
                // Show selected safe area (yellow outline) 
                let safeArea = SafeAreaCalculator.calculateSafeArea(
                    mode: selectedMode,
                    inputAR: inputAR,
                    outputSize: geo.size
                )
                let safeFrame = CGRect(
                    x: safeArea.minX * geo.size.width,
                    y: safeArea.minY * geo.size.height,
                    width: safeArea.width * geo.size.width,
                    height: safeArea.height * geo.size.height
                )
                
                Rectangle()
                    .stroke(Color.yellow.opacity(0.82), lineWidth: 5)
                    .frame(width: safeFrame.width, height: safeFrame.height)
                    .position(x: safeFrame.midX, y: safeFrame.midY)
                
                // Info label (top-left, minimal)
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Live Safe Area: \(selectedMode.displayName)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Camera: \(Int(inputAR.width)):\(Int(inputAR.height))")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(12)
                
                // Canvas outline (subtle)
                Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 1)
            }
        }
    }
    
    // Helper function (same as SafeAreaTest)
    private func fitRect(content: CGSize, into container: CGSize) -> CGRect {
        let sx = container.width / max(content.width, 1)
        let sy = container.height / max(content.height, 1)
        let s = min(sx, sy)
        let w = content.width * s
        let h = content.height * s
        let x = (container.width - w) * 0.5
        let y = (container.height - h) * 0.5
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

#if DEBUG
#Preview("Full Frame (None)") {
    SafeAreaLivePreview(mode: .none)
}

#Preview("Tile-Safe (Balanced)") {
    SafeAreaLivePreview(mode: .balanced)
}

#Preview("Ultra-Safe (Aggressive)") {
    SafeAreaLivePreview(mode: .aggressive)
}

#Preview("Conservative") {
    SafeAreaLivePreview(mode: .conservative)
}

#Preview("🎯 Compact (New!)") {
    SafeAreaLivePreview(mode: .compact)
}

// Helper view for previews that overrides the safe area mode
private struct SafeAreaLivePreview: View {
    let mode: SafeAreaMode
    
    var body: some View {
        GeometryReader { geo in
            let inputAR = CGSize(width: 16, height: 9) // Preview with 16:9 for consistency
            
            ZStack {
                Color.clear
                
                // Show camera content area (green outline)
                let contentSafe = fitRect(content: inputAR, into: geo.size)
                Rectangle()
                    .stroke(Color.green.opacity(0.82), lineWidth: 5)
                    .frame(width: contentSafe.width, height: contentSafe.height)
                    .position(x: contentSafe.midX, y: contentSafe.midY)
                
                // Show selected safe area (yellow outline) 
                let safeArea = SafeAreaCalculator.calculateSafeArea(
                    mode: mode,
                    inputAR: inputAR,
                    outputSize: geo.size
                )
                let safeFrame = CGRect(
                    x: safeArea.minX * geo.size.width,
                    y: safeArea.minY * geo.size.height,
                    width: safeArea.width * geo.size.width,
                    height: safeArea.height * geo.size.height
                )
                
                Rectangle()
                    .stroke(Color.yellow.opacity(0.82), lineWidth: 5)
                    .frame(width: safeFrame.width, height: safeFrame.height)
                    .position(x: safeFrame.midX, y: safeFrame.midY)
                
                // Info label (top-left, minimal)
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Preview: \(mode.displayName)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Camera: 16:9 (Preview)")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(12)
                
                // Canvas outline (subtle)
                Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 1)
            }
        }
        .frame(width: 1920, height: 1080)
        .background(.black)
    }
    
    // Helper function (same as main view)
    private func fitRect(content: CGSize, into container: CGSize) -> CGRect {
        let sx = container.width / max(content.width, 1)
        let sy = container.height / max(content.height, 1)
        let s = min(sx, sy)
        let w = content.width * s
        let h = content.height * s
        let x = (container.width - w) * 0.5
        let y = (container.height - h) * 0.5
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

#Preview {
    SafeAreaLive()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
}
#endif

