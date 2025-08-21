//
//  AspectRatioTest.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

struct AspectRatioTest: OverlayViewProviding {
    static let presetId = "swiftui.aspectratio.test"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geo in
            let canvas = geo.size
            let safe4x3 = fitRect(content: CGSize(width: 4, height: 3), into: canvas)
            let squareCrop = fitRectInRect(content: CGSize(width: 1, height: 1), inRect: safe4x3)

            ZStack {
                // Full canvas: RED (represents your output buffer)
                Color.red

                // 4:3 safe area: GREEN (what a 4:3 input would occupy if aspect-fitted)
                Rectangle()
                    .fill(Color.green.opacity(0.82))
                    .frame(width: safe4x3.width, height: safe4x3.height)
                    .position(x: safe4x3.midX, y: safe4x3.midY)
                
                // Square crop outline (what Meet/Zoom might show)
                Rectangle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: squareCrop.width, height: squareCrop.height)
                    .position(x: squareCrop.midX, y: squareCrop.midY)


                // Thin outlines so edges are unmistakable
                Rectangle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)

                Rectangle()
                    .path(in: safe4x3)
                    .strokedPath(.init(lineWidth: 2))
                    .fill(Color.black.opacity(0.7))

                // Optional: corner ticks for the 4:3 box (helps spot 1–2 px drift)
                CornerTicks(rect: safe4x3, tick: 18, thickness: 3)
                    .stroke(.white.opacity(0.9), lineWidth: 3)
                    .blendMode(.plusLighter)
            }
        }
        .background(Color.black)
    }
}

// MARK: - Helpers

/// Aspect-fit `content` into `container`, returning the fitted rect in the container's coordinate space.
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

// Fits an aspect-rect into a *rect*, returned in the parent’s coordinate space.
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

/// Simple corner ticks around a rect.
private struct CornerTicks: Shape {
    let rect: CGRect
    let tick: CGFloat
    let thickness: CGFloat

    func path(in _: CGRect) -> Path {
        var p = Path()
        let r = rect

        // TL
        p.addRect(CGRect(x: r.minX, y: r.minY, width: tick, height: thickness))
        p.addRect(CGRect(x: r.minX, y: r.minY, width: thickness, height: tick))
        // TR
        p.addRect(CGRect(x: r.maxX - tick, y: r.minY, width: tick, height: thickness))
        p.addRect(CGRect(x: r.maxX - thickness, y: r.minY, width: thickness, height: tick))
        // BL
        p.addRect(CGRect(x: r.minX, y: r.maxY - thickness, width: tick, height: thickness))
        p.addRect(CGRect(x: r.minX, y: r.maxY - tick, width: thickness, height: tick))
        // BR
        p.addRect(CGRect(x: r.maxX - tick, y: r.maxY - thickness, width: tick, height: thickness))
        p.addRect(CGRect(x: r.maxX - thickness, y: r.maxY - tick, width: thickness, height: tick))

        return p
    }
}
