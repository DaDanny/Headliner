import SwiftUI

struct BrandRibbon: OverlayViewProviding {
    static let presetId = "swiftui.brand.ribbon"
    static let defaultSize = CGSize(width: 1280, height: 720)

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geometry in
            makeContent(tokens: tokens, in: geometry.size)
        }
    }
    
    private func makeContent(tokens: OverlayTokens, in size: CGSize) -> some View {
        let accent = Color(hex: tokens.accentColorHex, default: .blue)
        
        // Calculate scale factor for responsive design
        let scaleFactor = min(size.width / 1280, size.height / 720)
        let baseFontScale: CGFloat
        if size.width < 800 {
            baseFontScale = max(scaleFactor * 1.5, 0.8)
        } else {
            baseFontScale = max(scaleFactor, 0.6)
        }

        return ZStack {
            // top-left brand chip
            VStack {
                HStack {
                    HStack(spacing: 8 * baseFontScale) {
                        RoundedRectangle(cornerRadius: 8 * baseFontScale)
                            .fill(LinearGradient(colors: [accent, accent.opacity(0.6)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36 * baseFontScale, height: 36 * baseFontScale)
                            .overlay(
                                Text("B").font(.system(size: 18 * baseFontScale, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            )
                        Text(tokens.logoText ?? "BONUSLY")
                            .font(.system(size: 16 * baseFontScale, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12 * baseFontScale).padding(.vertical, 8 * baseFontScale)
                    .background(
                        RoundedRectangle(cornerRadius: 20 * baseFontScale)
                            .fill(Color.black.opacity(0.65))
                            .overlay(RoundedRectangle(cornerRadius: 20 * baseFontScale).stroke(.white.opacity(0.28), lineWidth: 1))
                    )
                    Spacer()
                }
                .padding(.top, 20 * baseFontScale).padding(.leading, 28 * baseFontScale)
                Spacer()
            }

            // bottom ribbon lower third
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 4 * baseFontScale) {
                        Text(tokens.displayName)
                            .font(.system(size: 26 * baseFontScale, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                        if let tagline = tokens.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.system(size: 15 * baseFontScale, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                    }
                    Spacer()
                    if let time = tokens.localTime, !time.isEmpty {
                        Text(time)
                            .font(.system(size: 14 * baseFontScale, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 12 * baseFontScale).padding(.vertical, 6 * baseFontScale)
                            .background(Capsule().fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)))
                    }
                }
                .padding(.horizontal, 22 * baseFontScale).padding(.vertical, 14 * baseFontScale)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16 * baseFontScale).fill(Color.black.opacity(0.78))
                        RoundedRectangle(cornerRadius: 16 * baseFontScale).stroke(.white.opacity(0.35), lineWidth: 1)
                        // Thin accent ribbon
                        RoundedRectangle(cornerRadius: 16 * baseFontScale).stroke(accent.opacity(0.7), lineWidth: 3 * baseFontScale).opacity(0.35)
                    }
                )
                .padding(.horizontal, 32 * baseFontScale)
                .padding(.bottom, 28 * baseFontScale)
            }
        }
    }
}




