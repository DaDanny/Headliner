//
//  SafeAreaTest.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Simple test overlay to verify safe area calculations match AspectRatioTestV2
struct SafeAreaTest: OverlayViewProviding {
    static let presetId = "swiftui.safearea.test"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geo in
            let settings = getOverlaySettings()
            let inputAR = CGSize(width: 4, height: 3) // Same as AspectRatioTestV2
            
            ZStack {
                // Background similar to AspectRatioTestV2
                //Color.red.opacity(0.01)
                
                // Show camera content area (green)
                let contentSafe = fitRect(content: inputAR, into: geo.size)
                Rectangle()
                    .stroke(Color.green.opacity(0.82), lineWidth: 5)
                    .frame(width: contentSafe.width, height: contentSafe.height)
                    .position(x: contentSafe.midX, y: contentSafe.midY)
                
                // Show our calculated safe area (should match yellow from AspectRatioTestV2)
                let safeArea = SafeAreaCalculator.calculateSafeArea(
                    mode: .balanced,
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
                    .stroke(Color.yellow.opacity(0.45), lineWidth: 5)
                    .frame(width: safeFrame.width, height: safeFrame.height)
                    .position(x: safeFrame.midX, y: safeFrame.midY)
                    .overlay(
                        Text("SafeAreaCalculator Result (Balanced)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black)
                            .background(Color.white.opacity(0.8))
                            .padding(4)
                            .cornerRadius(4)
                            .position(x: safeFrame.midX, y: safeFrame.minY + 20)
                    )
                
                // Canvas outline
                Rectangle().stroke(Color.white.opacity(0.6), lineWidth: 1)
            }
//            .background(Color.clear)
        }
    }
    
    // Helper function from AspectRatioTestV2
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
#Preview {
    SafeAreaTest()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
}
#endif
