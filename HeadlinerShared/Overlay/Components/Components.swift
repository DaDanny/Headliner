//
//  Components.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//

import CoreGraphics
import Foundation

// Components compile into (nodes appended) + placements.
protocol OverlayComponent {
    /// Appends nodes (once) and returns placements for given aspect.
    @discardableResult
    func build(nodes: inout [OverlayNode], startIndex: Int, aspect: Aspect) -> [OverlayNodePlacement]
}

// MARK: - Centering Helpers

extension NRect {
    /// Create a centered sub-frame within this rect (perfect for centering text in containers)
    func centeredSubframe(width: CGFloat, height: CGFloat) -> NRect {
        return NRect(
            x: x + (w - width) / 2,
            y: y + (h - height) / 2,
            w: width,
            h: height
        )
    }
    
    /// Create an inset frame (useful for padding)
    func inset(by padding: CGFloat) -> NRect {
        return NRect(
            x: x + padding,
            y: y + padding,
            w: w - padding * 2,
            h: h - padding * 2
        )
    }
    
    /// Split horizontally into left and right sections
    func splitHorizontal(leftPercent: CGFloat, gap: CGFloat = 0) -> (left: NRect, right: NRect) {
        let leftWidth = w * leftPercent
        let rightWidth = w - leftWidth - gap
        return (
            left: NRect(x: x, y: y, w: leftWidth, h: h),
            right: NRect(x: x + leftWidth + gap, y: y, w: rightWidth, h: h)
        )
    }
    
    /// Split vertically into top and bottom sections
    func splitVertical(topPercent: CGFloat, gap: CGFloat = 0) -> (top: NRect, bottom: NRect) {
        let topHeight = h * topPercent
        let bottomHeight = h - topHeight - gap
        return (
            top: NRect(x: x, y: y, w: w, h: topHeight),
            bottom: NRect(x: x, y: y + topHeight + gap, w: w, h: bottomHeight)
        )
    }
}

// MARK: - High-Level Prebuilt Components

/// Name card with title, subtitle, and optional logo
struct NameCard: OverlayComponent {
    var placement: Placement
    var width: CGFloat = 0.35
    var height: CGFloat = 0.2
    var backgroundColor: String = "#ffffff"
    var cornerRadius: CGFloat = 0.035
    var title: String // e.g. "{displayName}" or "Danny"
    var titleSize: CGFloat = 0.045
    var titleWeight: String = "bold"
    var titleColor: String = "#0f172a"
    var subTitle: String? // e.g. "{tagline}" or "Developer"
    var subTitleSize: CGFloat = 0.03
    var subTitleWeight: String = "medium"
    var subTitleColor: String = "#475569"
    var includeLogo: Bool = false
    var logoName: String = "Bonusly-Logo"
    var logoSize: CGFloat = 0.08
    var addAccentBar: Bool = false
    var accentColor: String = "#118342"
    
    func build(nodes: inout [OverlayNode], startIndex: Int, aspect: Aspect) -> [OverlayNodePlacement] {
        let cardFrame = resolveFrame(placement: placement, aspect: aspect, size: .init(width: width, height: height))
        var placements: [OverlayNodePlacement] = []
        let base = startIndex
        var nodeCount = 0
        
        // Card background
        nodes.append(.rect(RectNode(colorHex: backgroundColor, cornerRadius: cornerRadius)))
        placements.append(OverlayNodePlacement(index: base + nodeCount, frame: cardFrame, zIndex: 0, opacity: 0.97))
        nodeCount += 1
        
        // Optional accent bar
        if addAccentBar {
            nodes.append(.gradient(GradientNode(startColorHex: accentColor, endColorHex: accentColor + "CC", angle: 0)))
            let accentFrame = NRect(x: cardFrame.x, y: cardFrame.y, w: cardFrame.w, h: 0.015)
            placements.append(OverlayNodePlacement(index: base + nodeCount, frame: accentFrame, zIndex: 1, opacity: 1.0))
            nodeCount += 1
        }
        
        // Calculate content area
        let contentX = cardFrame.x + LayoutDefaults.pad
        let contentY = cardFrame.y + LayoutDefaults.pad + (addAccentBar ? 0.015 : 0)
        let contentW = cardFrame.w - LayoutDefaults.pad * 2
        let contentH = cardFrame.h - LayoutDefaults.pad * 2 - (addAccentBar ? 0.015 : 0)
        
        // Layout: logo on right (if included), text on left
        let logoWidth: CGFloat = includeLogo ? logoSize : 0
        let textWidth = contentW - logoWidth - (includeLogo ? LayoutDefaults.gap : 0)
        
        // Title text
        nodes.append(.text(TextNode(text: title, fontSize: titleSize, fontWeight: titleWeight, colorHex: titleColor, alignment: "left")))
        let titleHeight = subTitle != nil ? contentH * 0.6 : contentH
        let titleFrame = NRect(x: contentX, y: contentY, w: textWidth, h: titleHeight)
        placements.append(OverlayNodePlacement(index: base + nodeCount, frame: titleFrame, zIndex: 2, opacity: 1.0))
        nodeCount += 1
        
        // Subtitle text (if provided)
        if let subTitle = subTitle {
            nodes.append(.text(TextNode(text: subTitle, fontSize: subTitleSize, fontWeight: subTitleWeight, colorHex: subTitleColor, alignment: "left")))
            let subTitleFrame = NRect(x: contentX, y: contentY + titleHeight, w: textWidth, h: contentH - titleHeight)
            placements.append(OverlayNodePlacement(index: base + nodeCount, frame: subTitleFrame, zIndex: 2, opacity: 0.95))
            nodeCount += 1
        }
        
        // Logo (if included)
        if includeLogo {
            nodes.append(.image(ImageNode(imageName: logoName, contentMode: "fit", opacity: 1.0, cornerRadius: 0.08)))
            let logoFrame = NRect(x: contentX + textWidth + LayoutDefaults.gap, y: contentY, w: logoWidth, h: contentH)
            placements.append(OverlayNodePlacement(index: base + nodeCount, frame: logoFrame, zIndex: 2, opacity: 1.0))
            nodeCount += 1
        }
        
        return placements
    }
}

/// Time chip with customizable styling
struct TimeChip: OverlayComponent {
    var placement: Placement
    var width: CGFloat = 0.20
    var backgroundColor: String = "#118342"
    var textColor: String = "#ffffff"
    var cornerRadius: CGFloat = 0.04
    var text: String = "{localTime}"
    var fontSize: CGFloat = 0.032
    var fontWeight: String = "semibold"
    
    func build(nodes: inout [OverlayNode], startIndex: Int, aspect: Aspect) -> [OverlayNodePlacement] {
        let chipHeight = LayoutDefaults.chipHeight(aspect)
        let chipFrame = resolveFrame(placement: placement, aspect: aspect, size: .init(width: width, height: chipHeight))
        
        // Background
        nodes.append(.rect(RectNode(colorHex: backgroundColor, cornerRadius: cornerRadius)))
        // Text (perfectly centered within chip - same frame as background)
        nodes.append(.text(TextNode(text: text, fontSize: fontSize, fontWeight: fontWeight, colorHex: textColor, alignment: "center")))
        
        return [
            OverlayNodePlacement(index: startIndex, frame: chipFrame, zIndex: 0, opacity: 0.92),
            OverlayNodePlacement(index: startIndex + 1, frame: chipFrame, zIndex: 1, opacity: 1.0) // Same frame = perfect centering!
        ]
    }
}

/// Location card showing city and weather
struct LocationCard: OverlayComponent {
    var placement: Placement
    var width: CGFloat = 0.30
    var height: CGFloat = 0.12
    var backgroundColor: String = "#ffffff"
    var cornerRadius: CGFloat = 0.035
    var cityText: String = "{city}"
    var citySize: CGFloat = 0.035
    var cityWeight: String = "semibold"
    var cityColor: String = "#0f172a"
    var weatherText: String = "{weatherEmoji} {weatherText}"
    var weatherSize: CGFloat = 0.03
    var weatherWeight: String = "medium"
    var weatherColor: String = "#475569"
    var textAlignment: String = "right"
    
    func build(nodes: inout [OverlayNode], startIndex: Int, aspect: Aspect) -> [OverlayNodePlacement] {
        let cardFrame = resolveFrame(placement: placement, aspect: aspect, size: .init(width: width, height: height))
        
        // Card background
        nodes.append(.rect(RectNode(colorHex: backgroundColor, cornerRadius: cornerRadius)))
        
        // Use better centering helpers
        let textArea = cardFrame.inset(by: LayoutDefaults.pad)
        let (cityArea, weatherArea) = textArea.splitVertical(topPercent: 0.55)
        
        // City text (top half)
        nodes.append(.text(TextNode(text: cityText, fontSize: citySize, fontWeight: cityWeight, colorHex: cityColor, alignment: textAlignment)))
        
        // Weather text (bottom half)
        nodes.append(.text(TextNode(text: weatherText, fontSize: weatherSize, fontWeight: weatherWeight, colorHex: weatherColor, alignment: textAlignment)))
        
        return [
            OverlayNodePlacement(index: startIndex, frame: cardFrame, zIndex: 0, opacity: 0.97),
            OverlayNodePlacement(index: startIndex + 1, frame: cityArea, zIndex: 1, opacity: 1.0),
            OverlayNodePlacement(index: startIndex + 2, frame: weatherArea, zIndex: 1, opacity: 0.95)
        ]
    }
}

/// Full-width bottom bar with automatic content layout
struct BottomBar: OverlayComponent {
    var backgroundColor: String = "#ffffff"
    var cornerRadius: CGFloat = 0.03
    var title: String = "{displayName}"
    var titleSize: CGFloat = 0.05
    var titleWeight: String = "bold"
    var titleColor: String = "#0f172a"
    var subtitle: String? = "{tagline}"
    var subtitleSize: CGFloat = 0.03
    var subtitleWeight: String = "medium"
    var subtitleColor: String = "#475569"
    var includeLogo: Bool = false
    var logoName: String = "Bonusly-Logo"
    var logoWidth: CGFloat = 0.25
    var addBrandStrip: Bool = false
    var brandStripColor: String = "#118342"
    
    func build(nodes: inout [OverlayNode], startIndex: Int, aspect: Aspect) -> [OverlayNodePlacement] {
        let barHeight = LayoutDefaults.barHeight(aspect)
        let barFrame = resolveFrame(placement: .bottom, aspect: aspect, size: .init(width: 0.9, height: barHeight))
        var placements: [OverlayNodePlacement] = []
        let base = startIndex
        var nodeCount = 0
        
        // Bar background
        nodes.append(.rect(RectNode(colorHex: backgroundColor, cornerRadius: cornerRadius)))
        placements.append(OverlayNodePlacement(index: base + nodeCount, frame: barFrame, zIndex: 0, opacity: 0.97))
        nodeCount += 1
        
        // Use the new centering helpers for better layout
        let contentArea = barFrame.inset(by: LayoutDefaults.pad)
        
        // Split content area between text and logo
        let (textArea, logoArea) = includeLogo ? 
            contentArea.splitHorizontal(leftPercent: 0.7, gap: LayoutDefaults.gap) :
            (contentArea, NRect(x: 0, y: 0, w: 0, h: 0))
        
        // Title text
        nodes.append(.text(TextNode(text: title, fontSize: titleSize, fontWeight: titleWeight, colorHex: titleColor, alignment: "left")))
        let titleHeight = subtitle != nil ? contentArea.h * 0.6 : contentArea.h
        let titleFrame = NRect(x: textArea.x, y: textArea.y, w: textArea.w, h: titleHeight)
        placements.append(OverlayNodePlacement(index: base + nodeCount, frame: titleFrame, zIndex: 2, opacity: 1.0))
        nodeCount += 1
        
        // Subtitle (if provided)
        if let subtitle = subtitle {
            nodes.append(.text(TextNode(text: subtitle, fontSize: subtitleSize, fontWeight: subtitleWeight, colorHex: subtitleColor, alignment: "left")))
            let subtitleFrame = NRect(x: textArea.x, y: textArea.y + titleHeight, w: textArea.w, h: textArea.h - titleHeight)
            placements.append(OverlayNodePlacement(index: base + nodeCount, frame: subtitleFrame, zIndex: 2, opacity: 0.95))
            nodeCount += 1
        }
        
        // Logo (if included) - perfectly centered in logo area
        if includeLogo {
            nodes.append(.image(ImageNode(imageName: logoName, contentMode: "fit", opacity: 1.0, cornerRadius: 0.08)))
            placements.append(OverlayNodePlacement(index: base + nodeCount, frame: logoArea, zIndex: 2, opacity: 1.0))
            nodeCount += 1
        }
        
        // Brand strip (if enabled)
        if addBrandStrip {
            nodes.append(.gradient(GradientNode(startColorHex: brandStripColor, endColorHex: brandStripColor + "CC", angle: 0)))
            let stripFrame = NRect(x: barFrame.x, y: barFrame.y + barFrame.h - 0.01, w: barFrame.w, h: 0.01)
            placements.append(OverlayNodePlacement(index: base + nodeCount, frame: stripFrame, zIndex: 3, opacity: 1.0))
            nodeCount += 1
        }
        
        return placements
    }
}

// MARK: - Card (rect bg with optional accent bar)
struct Card: OverlayComponent {
    var placement: Placement
    var size: CGSize
    var cornerRadius: CGFloat = 0.035
    var bgHex: String = "#ffffff"
    var addAccentBar: Bool = false
    var accentStart: String = "#118342"
    var accentEnd: String = "#0E6D35"
    var accentHeight: CGFloat = 0.018

    func build(nodes: inout [OverlayNode], startIndex: Int, aspect: Aspect) -> [OverlayNodePlacement] {
        let frame = resolveFrame(placement: placement, aspect: aspect, size: size)
        let base = startIndex
        nodes.append(.rect(RectNode(colorHex: bgHex, cornerRadius: cornerRadius)))
        var placements = [OverlayNodePlacement(index: base, frame: frame, zIndex: 0, opacity: 0.97)]
        if addAccentBar {
            nodes.append(.gradient(GradientNode(startColorHex: accentStart, endColorHex: accentEnd, angle: 0)))
            let bar = nrect(frame.x, frame.y + frame.h - accentHeight, frame.w, accentHeight)
            placements.append(OverlayNodePlacement(index: base + 1, frame: bar, zIndex: 1, opacity: 1))
        }
        return placements
    }
}

// MARK: - FullWidthBar (bottom bar container)
struct FullWidthBar: OverlayComponent {
    var placement: Placement = .bottom
    var heightFn: (Aspect) -> CGFloat = LayoutDefaults.barHeight

    // Returns bar rect; children should be placed relative to it.
    @discardableResult
    func build(nodes: inout [OverlayNode], startIndex: Int, aspect: Aspect) -> [OverlayNodePlacement] {
        let h = heightFn(aspect)
        let w = 1 - LayoutDefaults.margin*2
        let barRect = resolveFrame(placement: placement, aspect: aspect, size: .init(width: w, height: h))
        nodes.append(.rect(RectNode(colorHex: "#ffffff", cornerRadius: 0.03)))
        return [OverlayNodePlacement(index: startIndex, frame: barRect, zIndex: 0, opacity: 0.97)]
    }
}

// MARK: - Chip (rounded pill with single text)
struct Chip: OverlayComponent {
    var placement: Placement
    var width: CGFloat = 0.22
    var heightFn: (Aspect) -> CGFloat = LayoutDefaults.chipHeight
    var bgHex: String = "#118342"
    var fgHex: String = "#ffffff"
    var text: String    // supports tokens like {localTime}
    var fontSize: CGFloat = 0.032
    var fontWeight: String = "semibold"

    func build(nodes: inout [OverlayNode], startIndex: Int, aspect: Aspect) -> [OverlayNodePlacement] {
        let size = CGSize(width: width, height: heightFn(aspect))
        let frame = resolveFrame(placement: placement, aspect: aspect, size: size)
        let inner = nrect(frame.x + LayoutDefaults.pad, frame.y + LayoutDefaults.pad, frame.w - LayoutDefaults.pad*2, frame.h - LayoutDefaults.pad*2)
        nodes.append(.rect(RectNode(colorHex: bgHex, cornerRadius: 0.04)))
        nodes.append(.text(TextNode(text: text, fontSize: fontSize, fontWeight: fontWeight, colorHex: fgHex, alignment: "center")))
        return [
            OverlayNodePlacement(index: startIndex + 0, frame: frame, zIndex: 0, opacity: 0.92),
            OverlayNodePlacement(index: startIndex + 1, frame: inner, zIndex: 1, opacity: 1.0)
        ]
    }
}

// MARK: - ImageBox (for logos)
struct ImageBox: OverlayComponent {
    var containerRect: (NRect) -> NRect   // place relative to a parent
    var imageName: String
    var cornerRadius: CGFloat = 0.08

    func build(nodes: inout [OverlayNode], startIndex: Int, aspect: Aspect) -> [OverlayNodePlacement] {
        // caller passes concrete rect via containerRect
        fatalError("Use ImageBox inside a composite builder where parent rect is known.")
    }
}

// MARK: - TextBlock (for name/tagline inside a parent)
struct TextBlock {
    var nameText: String      // {displayName}
    var nameSize: CGFloat = 0.05
    var nameWeight: String = "bold"
    var nameColor: String = "#0f172a"
    var taglineText: String   // {tagline}
    var taglineSize: CGFloat = 0.03
    var taglineWeight: String = "medium"
    var taglineColor: String = "#475569"

    func append(nodes: inout [OverlayNode], startIndex: Int, in rect: NRect) -> [OverlayNodePlacement] {
        let nameH = rect.h * 0.55
        let nameRect = nrect(rect.x, rect.y, rect.w, nameH)
        let tagRect  = nrect(rect.x, rect.y + nameH, rect.w, rect.h - nameH)
        nodes.append(.text(TextNode(text: nameText, fontSize: nameSize, fontWeight: nameWeight, colorHex: nameColor, alignment: "left")))
        nodes.append(.text(TextNode(text: taglineText, fontSize: taglineSize, fontWeight: taglineWeight, colorHex: taglineColor, alignment: "left")))
        return [
            OverlayNodePlacement(index: startIndex + 0, frame: nameRect, zIndex: 2, opacity: 1.0),
            OverlayNodePlacement(index: startIndex + 1, frame: tagRect,  zIndex: 2, opacity: 0.95)
        ]
    }
}

// MARK: - BarContent helper
struct BarContent {
    /// Splits a bar into left text column (pct) and right logo.
    static func split(bar: NRect, leftPct: CGFloat = 0.70) -> (textRect: NRect, logoRect: NRect) {
        let px = bar.x + LayoutDefaults.pad
        let py = bar.y + LayoutDefaults.pad
        let pw = bar.w - LayoutDefaults.pad*2
        let ph = bar.h - LayoutDefaults.pad*2
        let textW = pw * leftPct
        let logoW = pw - textW - LayoutDefaults.gap
        let textRect = nrect(px, py, textW, ph)
        let logoRect = nrect(px + textW + LayoutDefaults.gap, py, logoW, ph)
        return (textRect, logoRect)
    }
}
