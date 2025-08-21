@available(*, deprecated, message: "Legacy CoreGraphics overlay path. Prefer SwiftUI overlays.")
// swiftlint:disable file_length
//
//  Snap.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import CoreGraphics

// Snap palette: keep coordinates consistent across presets.
enum Snap {
    static let marginS: CGFloat = 0.03
    static let margin:  CGFloat = 0.05
    static let padS:   CGFloat = 0.02
    static let pad:    CGFloat = 0.03
    static let gapS:   CGFloat = 0.01
    static let gap:    CGFloat = 0.015

    // Common sizes
    static let barH16x9: CGFloat = 0.12   // bottom bar height
    static let barH4x3:  CGFloat = 0.14
    static let chipH:    CGFloat = 0.08
}



enum Anchor { case topLeft, topRight, bottomLeft, bottomRight, center }

struct AnchorPlacement {
    var anchor: Anchor
    var size: CGSize
    var marginX: CGFloat = Snap.margin
    var marginY: CGFloat = Snap.margin
    var dx: CGFloat = 0
    var dy: CGFloat = 0

    func resolve() -> NRect {
        let (w,h) = (size.width, size.height)
        switch anchor {
        case .topLeft:
            return nrect(marginX + dx, marginY + dy, w, h)
        case .topRight:
            return nrect(1 - marginX - w + dx, marginY + dy, w, h)
        case .bottomLeft:
            return nrect(marginX + dx, 1 - marginY - h + dy, w, h)
        case .bottomRight:
            return nrect(1 - marginX - w + dx, 1 - marginY - h + dy, w, h)
        case .center:
            return nrect(0.5 - w/2 + dx, 0.5 - h/2 + dy, w, h)
        }
    }
}
