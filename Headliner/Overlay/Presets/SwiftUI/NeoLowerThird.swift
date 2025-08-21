//
//  CutCorners.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

/// A modern, high-contrast lower-third with cut corners and an angled accent.
/// No animations; GPU-friendly gradients and vector shapes only.
struct NeoLowerThird: OverlayViewProviding {
    static let presetId = "swiftui.neo.lowerthird"
    static let defaultSize = CGSize(width: 1280, height: 720)

    // MARK: - Tunables
    private let designBase = CGSize(width: 1280, height: 720)
    private let accentHex = "#118342" // fallback if tokens don’t provide a brand color

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geo in
            makeContent(tokens: tokens, in: geo.size)
        }
    }

    // MARK: - View
    private func makeContent(tokens: OverlayTokens, in size: CGSize) -> some View {
        let scale = min(size.width / designBase.width, size.height / designBase.height)

        // “Readable even when tiny” font scale rules
        let fontScale: CGFloat = {
            if size.width < 800 { return max(scale * 1.5, 0.8) }
            return max(scale, 0.6)
        }()

        // Accent color: use tokens.accentColorHex with fallback to accentHex default
        let accent = Color(hex: tokens.accentColorHex, default: Color(hex: accentHex, default: .green))
        let accentHi = accent.lighten(0.22)
        let accentLo = accent.darken(0.26)

        return ZStack {
            debugOverlay(fontScale: fontScale, scale: scale)
            lowerThirdOverlay(tokens: tokens, accent: accent, accentHi: accentHi, accentLo: accentLo, fontScale: fontScale, scale: scale)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func debugOverlay(fontScale: CGFloat, scale: CGFloat) -> some View {
        // DEBUG plate (center) – easy to comment out
        VStack(spacing: 8 * fontScale) {
            Text("SWIFTUI OVERLAY ACTIVE")
                .font(.system(size: 24 * fontScale, weight: .bold, design: .rounded))
                .foregroundStyle(.red)
            Text(Date().formatted(date: .omitted, time: .complete))
                .font(.system(size: 18 * fontScale, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.95))
        }
        .padding(18 * fontScale)
        .background(
            CutCornerShape(corner: 12 * fontScale)
                .fill(Color.black.opacity(0.78))
                .overlay(CutCornerShape(corner: 12 * fontScale)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1 * scale))
        )
    }
    
    @ViewBuilder
    private func lowerThirdOverlay(tokens: OverlayTokens, accent: Color, accentHi: Color, accentLo: Color, fontScale: CGFloat, scale: CGFloat) -> some View {
        VStack {
            Spacer(minLength: 0)
            
            ZStack(alignment: .bottomLeading) {
                angledBand(accent: accent, accentHi: accentHi, accentLo: accentLo, fontScale: fontScale)
                infoPlate(fontScale: fontScale, scale: scale)
                overlayContent(tokens: tokens, accentHi: accentHi, fontScale: fontScale, scale: scale)
            }
            .padding(.horizontal, 40 * fontScale)
            .padding(.bottom, 32 * fontScale)
        }
    }
    
    @ViewBuilder
    private func angledBand(accent: Color, accentHi: Color, accentLo: Color, fontScale: CGFloat) -> some View {
        AngledBand(angle: .degrees(-12))
            .fill(
                LinearGradient(
                    colors: [accentHi, accent, accentLo],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .opacity(0.95)
            .frame(height: 60 * fontScale)
            .offset(y: 26 * fontScale)
    }
    
    @ViewBuilder
    private func infoPlate(fontScale: CGFloat, scale: CGFloat) -> some View {
        let shape = CutCornerShape(corner: 18 * fontScale)
        
        shape
            .fill(Color.black.opacity(0.70))
            .overlay(plateInnerBorder(shape: shape, scale: scale))
            .overlay(plateTopEdge(fontScale: fontScale, scale: scale))
    }
    
    @ViewBuilder
    private func plateInnerBorder(shape: CutCornerShape, scale: CGFloat) -> some View {
        shape
            .stroke(Color.white.opacity(0.18), lineWidth: 1 * scale)
    }
    
    @ViewBuilder
    private func plateTopEdge(fontScale: CGFloat, scale: CGFloat) -> some View {
        CutCornerEdgeStroke(corner: 18 * fontScale, edges: [.top])
            .stroke(Color.white.opacity(0.10), lineWidth: 1 * scale)
    }
    
    @ViewBuilder
    private func overlayContent(tokens: OverlayTokens, accentHi: Color, fontScale: CGFloat, scale: CGFloat) -> some View {
        HStack(spacing: 16 * fontScale) {
            LBracket(width: 14 * fontScale, length: 36 * fontScale, thickness: 3 * scale)
                .foregroundStyle(accentHi)
            
            VStack(alignment: .leading, spacing: 4 * fontScale) {
                Text(tokens.displayName)
                    .font(.system(size: 28 * fontScale, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 1)
                
                if let tagline = tokens.tagline, !tagline.isEmpty {
                    Text(tagline)
                        .font(.system(size: 16.5 * fontScale, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            
            Spacer(minLength: 12 * fontScale)
            
            if let time = tokens.localTime, !time.isEmpty {
                timeTag(time: time, fontScale: fontScale, scale: scale)
            }
        }
        .padding(.horizontal, 22 * fontScale)
        .padding(.vertical, 14 * fontScale)
    }
    
    @ViewBuilder
    private func timeTag(time: String, fontScale: CGFloat, scale: CGFloat) -> some View {
        SlantedTag(slant: 10 * fontScale)
            .fill(Color.white.opacity(0.10))
            .overlay(SlantedTag(slant: 10 * fontScale)
                .stroke(Color.white.opacity(0.22), lineWidth: 1 * scale))
            .overlay(
                Text(time)
                    .font(.system(size: 14 * fontScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12 * fontScale)
                    .padding(.vertical, 6 * fontScale)
                    .fixedSize()
            )
            .accessibilityLabel("Local time \(time)")
    }
}

// MARK: - Custom Shapes

/// Rectangle with chamfered/cut corners (no rounded corners).
struct CutCornerShape: Shape {
    var corner: CGFloat = 16
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = min(corner, min(r.width, r.height) * 0.25)
        p.move(to: CGPoint(x: r.minX + c, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - c, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + c))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - c))
        p.addLine(to: CGPoint(x: r.maxX - c, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + c, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - c))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + c))
        p.closeSubpath()
        return p
    }
}

/// Hairline stroke along selected edges of a CutCornerShape.
struct CutCornerEdgeStroke: Shape {
    enum Edge { case top, bottom, leading, trailing }
    var corner: CGFloat = 16
    var edges: Set<Edge> = [.top]

    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = min(corner, min(r.width, r.height) * 0.25)

        if edges.contains(.top) {
            p.move(to: CGPoint(x: r.minX + c, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - c, y: r.minY))
        }
        if edges.contains(.bottom) {
            p.move(to: CGPoint(x: r.minX + c, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX - c, y: r.maxY))
        }
        if edges.contains(.leading) {
            p.move(to: CGPoint(x: r.minX, y: r.minY + c))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY - c))
        }
        if edges.contains(.trailing) {
            p.move(to: CGPoint(x: r.maxX, y: r.minY + c))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - c))
        }
        return p
    }
}

/// A lean “L” bracket used as a left accent.
struct LBracket: Shape {
    var width: CGFloat
    var length: CGFloat
    var thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let x = rect.minX
        let y = rect.midY - length / 2
        // Vertical
        p.addRect(CGRect(x: x, y: y, width: thickness, height: length))
        // Horizontal
        p.addRect(CGRect(x: x, y: y + length - thickness, width: width, height: thickness))
        return p
    }
}

/// A slanted-ended tag (no rounded ends).
struct SlantedTag: Shape {
    var slant: CGFloat = 10
    func path(in r: CGRect) -> Path {
        var p = Path()
        let s = min(slant, r.height * 0.9)

        p.move(to: CGPoint(x: r.minX + s, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - s, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A wide, angled band used behind the plate.
struct AngledBand: Shape {
    var angle: Angle = .degrees(-10)
    func path(in r: CGRect) -> Path {
        var p = Path()
        // Build a band that spans width with a fixed thickness and rotate via transform
        let h = r.height
        let bandH = max(40, h * 0.08)
        let y = h - bandH
        p.addRect(CGRect(x: 0, y: y, width: r.width, height: bandH))
        // Apply rotation around bottom-left
        let transform = CGAffineTransform(translationX: 0, y: 0)
            .rotated(by: CGFloat(angle.radians))
            .translatedBy(x: 0, y: 0)
        return p.applying(transform)
    }
}

// MARK: - Note: Color helpers (lighten, darken, mix) are now in shared Extensions/Color+Hex.swift
