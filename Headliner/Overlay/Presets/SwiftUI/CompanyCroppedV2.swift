import SwiftUI

struct CompanyCroppedV2: OverlayViewProviding {
    static let presetId = "company-cropped-v2"
    static let defaultSize = CGSize(width: 800, height: 600) // 4:3

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geo in
            let outer = geo.size
            let crop = calculateFourThreeSize(for: outer)

            ZStack {
                Color.clear.frame(width: outer.width, height: outer.height)

                ContentGrid(
                    tokens: tokens,
                    size: crop
                )
                .frame(width: crop.width, height: crop.height)
                .clipped()
                .overlay(Rectangle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }

    private func calculateFourThreeSize(for cameraSize: CGSize) -> CGSize {
        let ar: CGFloat = 4/3
        let camAR = cameraSize.width / cameraSize.height
        let pad: CGFloat = 0.90

        if camAR > ar {
            let h = cameraSize.height * pad
            return .init(width: h * ar, height: h)
        } else {
            let w = cameraSize.width * pad
            return .init(width: w, height: w / ar)
        }
    }
}

private struct ContentGrid: View {
    let tokens: OverlayTokens
    let size: CGSize

    var body: some View {
        let scale = max(size.width / 800.0, 0.5)
        let inset = 24.0 * scale
        let railWidth = 140.0 * scale
        let headerMaxWidth = size.width - (railWidth + inset * 2)

        let nameFont = clamp(28 * scale, 18, 40)
        let tagFont  = clamp(16 * scale, 12, 26)
        let timeFont = clamp(22 * scale, 14, 32)
        let chipFont = clamp(14 * scale, 12, 22)

        let accent = Color(hex: tokens.accentColorHex, default: Color(red: 0.07, green: 0.51, blue: 0.26))

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                BrandRail(tokens: tokens, accent: accent, scale: scale, inset: inset, width: railWidth)
                HeaderBlock(tokens: tokens, inset: inset, headerMaxWidth: headerMaxWidth, nameFont: nameFont, tagFont: tagFont, scale: scale)
            }
            LowerBar(tokens: tokens, inset: inset, chipFont: chipFont, timeFont: timeFont, accent: accent)
        }
        .frame(width: size.width, height: size.height)
        .compositingGroup()
    }
}

private struct BrandRail: View {
    let tokens: OverlayTokens
    let accent: Color
    let scale: CGFloat
    let inset: CGFloat
    let width: CGFloat

    var body: some View {
        let accentLo = accent.opacity(0.85)
        return VStack(spacing: 12 * scale) {
            LogoBox(tokens: tokens, fill: accentLo, scale: scale)
                .frame(height: 96 * scale)
            Spacer(minLength: 0)
        }
        .padding(inset)
        .frame(width: width)
        .background(Color.black.opacity(0.55))
    }
}

private struct LogoBox: View {
    let tokens: OverlayTokens
    let fill: Color
    let scale: CGFloat

    var body: some View {
        Rectangle()
            .fill(fill)
            .overlay(logoOverlay)
            .clipShape(Rectangle())
    }

    @ViewBuilder
    private var logoOverlay: some View {
        Image("Images/Bonusly-Mark.png").resizable().scaledToFit().padding(12 * scale)
    }
}

private struct HeaderBlock: View {
    let tokens: OverlayTokens
    let inset: CGFloat
    let headerMaxWidth: CGFloat
    let nameFont: CGFloat
    let tagFont: CGFloat
    let scale: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6 * scale) {
                    Text(tokens.displayName)
                        .font(.system(size: nameFont, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: headerMaxWidth, alignment: .leading)

                    if let tagline = tokens.tagline, !tagline.isEmpty {
                        Text(tagline)
                            .font(.system(size: tagFont, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: headerMaxWidth, alignment: .leading)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, inset)
            .padding(.top, inset)
            .padding(.bottom, inset * 0.75)

            Spacer(minLength: 0)
        }
    }
}

private struct LowerBar: View {
    let tokens: OverlayTokens
    let inset: CGFloat
    let chipFont: CGFloat
    let timeFont: CGFloat
    let accent: Color

    var body: some View {
        HStack(spacing: inset * 0.75) {
            HStack(spacing: inset * 0.5) {
                if let city = tokens.city, !city.isEmpty {
                    Chip(text: city, icon: "mappin.and.ellipse", font: chipFont, bg: accent.opacity(0.85))
                }
                if let weather = tokens.weatherText, !weather.isEmpty {
                    Chip(text: "\(tokens.weatherEmoji ?? "🌤️") \(weather)", icon: nil, font: chipFont, bg: Color.blue.opacity(0.80))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let time = tokens.localTime, !time.isEmpty {
                TimeTag(time: time, font: timeFont)
            }
        }
        .padding(.horizontal, inset)
        .padding(.vertical, inset * 0.75)
        .background(
            Rectangle()
                .fill(.black.opacity(0.55))
                .overlay(Rectangle().stroke(.white.opacity(0.10), lineWidth: 1))
        )
    }
}

private struct Chip: View {
    let text: String
    let icon: String?
    let font: CGFloat
    let bg: Color

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: font, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(text)
                .font(.system(size: font, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Rectangle().fill(bg))
    }
}

private struct TimeTag: View {
    let time: String
    let font: CGFloat

    var body: some View {
        Text(time)
            .font(.system(size: font, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .overlay(Rectangle().stroke(Color.white.opacity(0.22), lineWidth: 1))
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

// MARK: - Utilities

private func clamp(_ value: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat {
    max(minV, min(value, maxV))
}

private extension Color {
    init(hex: String?, default fallback: Color) {
        guard let hex, !hex.isEmpty else { self = fallback; return }
        let s = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var n: UInt64 = 0
        Scanner(string: s).scanHexInt64(&n)
        guard s.count == 6 else { self = fallback; return }
        let r = Double((n & 0xFF0000) >> 16) / 255.0
        let g = Double((n & 0x00FF00) >> 8) / 255.0
        let b = Double(n & 0x0000FF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
