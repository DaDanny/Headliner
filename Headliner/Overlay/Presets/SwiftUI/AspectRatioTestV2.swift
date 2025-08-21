//
//  AspectRatioTestV2.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

struct AspectRatioTestV2: OverlayViewProviding {
    static let presetId = "swiftui.aspectratio.test-v2"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    // Tweak these:
    private let assumeInputAR = CGSize(width: 4, height: 3) // or (16,9) if your camera is 16:9
    private let platformCropAspects: [CGSize] = [ // centered crops Meet/Zoom might use
        .init(width: 1, height: 1),   // square tiles
        .init(width: 5, height: 4),   // 5:4-ish
        .init(width: 4, height: 3),   // 4:3 tiles
        .init(width: 3, height: 2),   // 3:2 tiles
        .init(width: 16, height: 9)   // widescreen tiles
    ]
    private let titleSafeInsetPct: CGFloat = 0.04 // extra padding inside the final safe box

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geo in
            let canvas = geo.size                                // 16:9 output
            let contentSafe = fitRect(content: assumeInputAR, into: canvas) // where camera image actually is

            // For each platform aspect, center-fit a crop INSIDE the visible content
            let cropRects = platformCropAspects.map { fitRectInRect(content: $0, inRect: contentSafe) }

            // Intersection of all crops = always-visible center region
            let platformSafe = intersectAll(cropRects)

            // Optional “title-safe” inset (to avoid hugging edges)
            let paddedSafe = inset(platformSafe, pct: titleSafeInsetPct)

            ZStack {
                // Full canvas (what you emit)
                Color.red

                // Your camera content-safe area (e.g., 4:3 inside 16:9)
                Rectangle()
                    .fill(Color.green.opacity(0.82))
                    .frame(width: contentSafe.width, height: contentSafe.height)
                    .position(x: contentSafe.midX, y: contentSafe.midY)

                // Draw crop outlines for each platform aspect
                ForEach(Array(cropRects.enumerated()), id: \.offset) { _, r in
                    Rectangle()
                        .strokeBorder(.white.opacity(0.35), lineWidth: 2)
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                }

                // Final “always visible on Meet/Zoom tiles” region
                Rectangle()
                    .fill(Color.yellow.opacity(0.45))
                    .frame(width: paddedSafe.width, height: paddedSafe.height)
                    .position(x: paddedSafe.midX, y: paddedSafe.midY)

                // Canvas outline
                Rectangle().stroke(Color.white.opacity(0.6), lineWidth: 1)
            }
            .background(Color.black)
        }
    }
}

// MARK: - Geometry helpers

/// Aspect-fit `content` into `container` size.
private func fitRect(content: CGSize, into container: CGSize) -> CGRect {
    let sx = container.width / max(content.width, 1)
    let sy = container.height / max(content.height, 1)
    let s  = min(sx, sy)
    let w = content.width  * s
    let h = content.height * s
    let x = (container.width  - w) * 0.5
    let y = (container.height - h) * 0.5
    return CGRect(x: x, y: y, width: w, height: h)
}

/// Aspect-fit `content` into a *rect*, returned in the parent’s coordinate space.
private func fitRectInRect(content: CGSize, inRect r: CGRect) -> CGRect {
    let sx = r.width  / max(content.width, 1)
    let sy = r.height / max(content.height, 1)
    let s  = min(sx, sy)
    let w = content.width  * s
    let h = content.height * s
    let x = r.minX + (r.width  - w) * 0.5
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
