@available(*, deprecated, message: "Legacy CoreGraphics overlay path. Prefer SwiftUI overlays.")
// swiftlint:disable file_length
//
//  Placement.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import CoreGraphics

enum Aspect { case widescreen16x9, fourThree }

enum Placement {
    case topLeft, topRight, topCenter
    case bottomLeft, bottomRight, bottom
    case center
}

struct LayoutDefaults {
    // global snaps
    static let margin: CGFloat = 0.05
    static let pad:    CGFloat = 0.03
    static let gap:    CGFloat = 0.015

    // component sizing that differs by aspect
    static func barHeight(_ a: Aspect) -> CGFloat { a == .widescreen16x9 ? 0.12 : 0.14 }
    static func chipHeight(_ a: Aspect) -> CGFloat { 0.08 }
}

@inline(__always) func nrect(_ x: CGFloat,_ y: CGFloat,_ w: CGFloat,_ h: CGFloat) -> NRect {
    NRect(x: x, y: y, w: w, h: h)
}

func resolveFrame(
    placement: Placement,
    aspect: Aspect,
    size: CGSize,                 // normalized w,h (use <= 1.0)
    marginX: CGFloat = LayoutDefaults.margin,
    marginY: CGFloat = LayoutDefaults.margin,
    dx: CGFloat = 0, dy: CGFloat = 0
) -> NRect {
    let (w,h) = (size.width, size.height)
    switch placement {
    case .topLeft:
        return nrect(marginX + dx, 1 - marginY - h + dy, w, h)  // Flipped Y
    case .topRight:
        return nrect(1 - marginX - w + dx, 1 - marginY - h + dy, w, h)  // Flipped Y
    case .topCenter:
        return nrect(0.5 - w/2 + dx, 1 - marginY - h + dy, w, h)  // Flipped Y
    case .bottomLeft:
        return nrect(marginX + dx, marginY + dy, w, h)  // Flipped Y
    case .bottomRight:
        return nrect(1 - marginX - w + dx, marginY + dy, w, h)  // Flipped Y
    case .bottom:
        return nrect(0.5 - w/2 + dx, marginY + dy, w, h)  // Flipped Y
    case .center:
        return nrect(0.5 - w/2 + dx, 0.5 - h/2 + dy, w, h)  // Center stays the same
    }
}
