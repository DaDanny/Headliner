//
//  CardTemplates.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import Foundation
import CoreGraphics

// MARK: - Template protocol (lightweight)
protocol OverlayTemplate {
    /// Appends nodes (once) and returns placements for the current aspect.
    /// Returns: [OverlayNodePlacement] using the given starting nodeIndex.
    @discardableResult
    func build(nodes: inout [OverlayNode],
               startIndex: Int,
               aspect: OverlayAspect) -> [OverlayNodePlacement]
}

// MARK: - 1) BottomBarCard
/// A nearly full-width bottom bar with:
/// left: Name + Tagline (stacked)
/// right: Company logo
struct BottomBarCard: OverlayTemplate {
    var barColorHex: String
    var textColorHex: String = "#0f172a"
    var subTextColorHex: String = "#475569"
    var logoImageName: String // e.g. "Bonusly-Logo"

    func build(nodes: inout [OverlayNode],
               startIndex: Int,
               aspect: OverlayAspect) -> [OverlayNodePlacement] {

        let barH = (aspect == .widescreen) ? Snap.barH16x9 : Snap.barH4x3
        let bar  = AnchorPlacement(anchor: .bottomLeft,
                                   size: .init(width: 1 - Snap.margin*2, height: barH),
                                   marginX: Snap.margin, marginY: Snap.margin).resolve()

        // Nodes appended in order: [0:barBG, 1:name, 2:tagline, 3:logo]
        let base = startIndex
        nodes.append(.rect(RectNode(colorHex: "#ffffff", cornerRadius: 0.03)))
        nodes.append(.text(TextNode(text: "{displayName}", fontSize: 0.05, fontWeight: "bold", colorHex: textColorHex, alignment: "left")))
        nodes.append(.text(TextNode(text: "{tagline}", fontSize: 0.03, fontWeight: "medium", colorHex: subTextColorHex, alignment: "left")))
        nodes.append(.image(ImageNode(imageName: logoImageName, contentMode: "fit", opacity: 1.0, cornerRadius: 0.08)))

        // Internal padding
        let px = bar.x + Snap.pad
        let py = bar.y + Snap.pad
        let pw = bar.w - Snap.pad*2
        let ph = bar.h - Snap.pad*2

        // Split: left text column (70%), right logo (30%)
        let textW = pw * 0.70
        let logoW = pw - textW

        // Name/Tagline stacked in text column
        let nameH = ph * 0.55
        let tagH  = ph - nameH

        let placements: [OverlayNodePlacement] = [
            OverlayNodePlacement(index: base + 0, frame: bar, zIndex: 0, opacity: 0.97),
            OverlayNodePlacement(index: base + 1, frame: nrect(px, py, textW, nameH), zIndex: 2, opacity: 1.0),
            OverlayNodePlacement(index: base + 2, frame: nrect(px, py + nameH, textW, tagH), zIndex: 2, opacity: 0.95),
            OverlayNodePlacement(index: base + 3, frame: nrect(px + textW + Snap.gap, py, logoW - Snap.gap, ph), zIndex: 2, opacity: 1.0)
        ]
        return placements
    }
}

// MARK: - 2) TopLeftTimeChip
/// A small rounded chip showing the local time.
struct TopLeftTimeChip: OverlayTemplate {
    var bgHex: String = "#0E6D35"   // dark brand
    var fgHex: String = "#ffffff"

    func build(nodes: inout [OverlayNode],
               startIndex: Int,
               aspect: OverlayAspect) -> [OverlayNodePlacement] {
        let chip = AnchorPlacement(anchor: .topLeft,
                                   size: .init(width: 0.20, height: Snap.chipH),
                                   marginX: Snap.margin, marginY: Snap.margin).resolve()

        nodes.append(.rect(RectNode(colorHex: bgHex, cornerRadius: 0.04)))
        nodes.append(.text(TextNode(text: "{localTime}", fontSize: 0.032, fontWeight: "semibold", colorHex: fgHex, alignment: "center")))

        let base = startIndex
        return [
            OverlayNodePlacement(index: base + 0, frame: chip, zIndex: 0, opacity: 0.92),
            OverlayNodePlacement(index: base + 1, frame: nrect(chip.x + Snap.padS, chip.y + Snap.padS, chip.w - Snap.padS*2, chip.h - Snap.padS*2), zIndex: 1, opacity: 1.0)
        ]
    }
}

// MARK: - 3) TopRightCityWeather
/// Two-line block: City (line 1), Weather emoji + text (line 2).
struct TopRightCityWeather: OverlayTemplate {
    var bgHex: String = "#ffffff"
    var cityHex: String = "#0f172a"
    var weatherHex: String = "#475569"

    func build(nodes: inout [OverlayNode],
               startIndex: Int,
               aspect: OverlayAspect) -> [OverlayNodePlacement] {

        let block = AnchorPlacement(anchor: .topRight,
                                    size: .init(width: 0.30, height: 0.12),
                                    marginX: Snap.margin, marginY: Snap.margin).resolve()

        nodes.append(.rect(RectNode(colorHex: bgHex, cornerRadius: 0.03)))
        nodes.append(.text(TextNode(text: "{city}", fontSize: 0.035, fontWeight: "semibold", colorHex: cityHex, alignment: "right")))
        nodes.append(.text(TextNode(text: "{weatherEmoji} {weatherText}", fontSize: 0.03, fontWeight: "medium", colorHex: weatherHex, alignment: "right")))

        let base = startIndex
        let inner = nrect(block.x + Snap.pad, block.y + Snap.pad, block.w - Snap.pad*2, block.h - Snap.pad*2)
        let cityH: CGFloat = inner.h * 0.55

        return [
            OverlayNodePlacement(index: base + 0, frame: block, zIndex: 0, opacity: 0.97),
            OverlayNodePlacement(index: base + 1, frame: nrect(inner.x, inner.y, inner.w, cityH), zIndex: 1, opacity: 1.0),
            OverlayNodePlacement(index: base + 2, frame: nrect(inner.x, inner.y + cityH, inner.w, inner.h - cityH), zIndex: 1, opacity: 0.95)
        ]
    }
}
