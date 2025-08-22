//
//  SafeAreaValidation.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Validation overlay that displays safe area boundaries and compares with AspectRatioTestV2
struct SafeAreaValidation: OverlayViewProviding {
    static let presetId = "swiftui.safearea.validation"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geo in
            let settings = getOverlaySettings()
            let inputAR = settings.cameraDimensions.nonZeroAspect ?? CGSize(width: 4, height: 3)
            
            ZStack {
                // Background similar to AspectRatioTestV2
                Color.red
                
                // Show all safe area modes for comparison
                ForEach(SafeAreaMode.allCases, id: \.self) { mode in
                    SafeAreaVisualization(
                        mode: mode,
                        inputAR: inputAR,
                        containerSize: geo.size
                    )
                }
                
                // Reference AspectRatioTestV2 calculation (for comparison)
                AspectRatioTestReference(
                    inputAR: inputAR,
                    containerSize: geo.size
                )
                
                // Legend
                VStack {
                    HStack {
                        SafeAreaLegend()
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            }
        }
    }
}

/// Visualize a specific safe area mode
struct SafeAreaVisualization: View {
    let mode: SafeAreaMode
    let inputAR: CGSize
    let containerSize: CGSize
    
    var body: some View {
        let safeArea = SafeAreaCalculator.calculateSafeArea(
            mode: mode,
            inputAR: inputAR,
            outputSize: containerSize
        )
        let safeFrame = CGRect(
            x: safeArea.minX * containerSize.width,
            y: safeArea.minY * containerSize.height,
            width: safeArea.width * containerSize.width,
            height: safeArea.height * containerSize.height
        )
        
        Rectangle()
            .stroke(mode.color, lineWidth: 2)
            .frame(width: safeFrame.width, height: safeFrame.height)
            .position(x: safeFrame.midX, y: safeFrame.midY)
            .overlay(
                Text(mode.displayName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(mode.color)
                    .background(Color.black.opacity(0.7))
                    .padding(2)
                    .cornerRadius(2)
                    .position(x: safeFrame.minX + 40, y: safeFrame.minY + 12)
            )
    }
}

/// Reference implementation from AspectRatioTestV2 (for validation)
struct AspectRatioTestReference: View {
    let inputAR: CGSize
    let containerSize: CGSize
    
    // EXACT parameters from AspectRatioTestV2 - these must match perfectly!
    private let platformCropAspects: [CGSize] = [
        .init(width: 1, height: 1),   // square tiles
        .init(width: 5, height: 4),   // 5:4-ish
        .init(width: 4, height: 3),   // 4:3 tiles
        .init(width: 3, height: 2),   // 3:2 tiles
        .init(width: 16, height: 9)   // widescreen tiles
    ]
    private let titleSafeInsetPct: CGFloat = 0.04
    
    var body: some View {
        let contentSafe = fitRect(content: inputAR, into: containerSize)
        let cropRects = platformCropAspects.map { fitRectInRect(content: $0, inRect: contentSafe) }
        let platformSafe = intersectAll(cropRects)
        let paddedSafe = inset(platformSafe, pct: titleSafeInsetPct)
        
        // Show the reference yellow area from AspectRatioTestV2
        Rectangle()
            .fill(Color.yellow.opacity(0.3))
            .frame(width: paddedSafe.width, height: paddedSafe.height)
            .position(x: paddedSafe.midX, y: paddedSafe.midY)
            .overlay(
                Rectangle()
                    .stroke(Color.yellow, lineWidth: 3)
                    .frame(width: paddedSafe.width, height: paddedSafe.height)
                    .position(x: paddedSafe.midX, y: paddedSafe.midY)
            )
            .overlay(
                Text("AspectRatioTestV2 Reference")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.yellow)
                    .background(Color.black.opacity(0.7))
                    .padding(2)
                    .cornerRadius(2)
                    .position(x: paddedSafe.midX, y: paddedSafe.minY + 12)
            )
    }
    
    // Helper functions from AspectRatioTestV2
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
    
    private func fitRectInRect(content: CGSize, inRect r: CGRect) -> CGRect {
        let sx = r.width / max(content.width, 1)
        let sy = r.height / max(content.height, 1)
        let s = min(sx, sy)
        let w = content.width * s
        let h = content.height * s
        let x = r.minX + (r.width - w) * 0.5
        let y = r.minY + (r.height - h) * 0.5
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    private func intersectAll(_ rects: [CGRect]) -> CGRect {
        guard var acc = rects.first else { return .zero }
        for r in rects.dropFirst() { acc = acc.intersection(r) }
        return acc
    }
    
    private func inset(_ r: CGRect, pct: CGFloat) -> CGRect {
        let dx = r.width * pct
        let dy = r.height * pct
        return r.insetBy(dx: dx, dy: dy)
    }
}

/// Legend showing what each color represents
struct SafeAreaLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Safe Area Validation")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .background(Color.black.opacity(0.8))
                .padding(4)
                .cornerRadius(4)
            
            ForEach(SafeAreaMode.allCases, id: \.self) { mode in
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(mode.color)
                        .frame(width: 12, height: 2)
                    Text(mode.displayName)
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                }
                .background(Color.black.opacity(0.7))
                .padding(.horizontal, 4)
                .cornerRadius(2)
            }
            
            HStack(spacing: 6) {
                Rectangle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: 12, height: 8)
                Rectangle()
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: 12, height: 8)
                Text("AspectRatioTestV2 Reference")
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
            }
            .background(Color.black.opacity(0.7))
            .padding(.horizontal, 4)
            .cornerRadius(2)
        }
    }
}

/// Color extension for safe area mode visualization
extension SafeAreaMode {
    var color: Color {
        switch self {
        case .none: return .white
        case .aggressive: return .orange
        case .balanced: return .green
        case .conservative: return .blue
        case .compact: return .purple
        }
    }
}

#if DEBUG
#Preview {
    SafeAreaValidation()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
}
#endif
