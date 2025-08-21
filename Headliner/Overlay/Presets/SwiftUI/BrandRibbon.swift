import SwiftUI

struct BrandRibbon: OverlayViewProviding {
    static let presetId = "swiftui.brand.ribbon"
    static let defaultSize = CGSize(width: 1280, height: 720)

    func makeView(tokens: OverlayTokens) -> some View {
        let accent = Color(hex: tokens.accentColorHex) ?? Color.blue

        return ZStack {
            // top-left brand chip
            VStack {
                HStack {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [accent, accent.opacity(0.6)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text("B").font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            )
                        Text(tokens.logoText ?? "BONUSLY")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.65))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.28), lineWidth: 1))
                    )
                    Spacer()
                }
                .padding(.top, 20).padding(.leading, 28)
                Spacer()
            }

            // bottom ribbon lower third
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tokens.displayName)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                        if let tagline = tokens.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                    }
                    Spacer()
                    if let time = tokens.localTime, !time.isEmpty {
                        Text(time)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)))
                    }
                }
                .padding(.horizontal, 22).padding(.vertical, 14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.78))
                        RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.35), lineWidth: 1)
                        // Thin accent ribbon
                        RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.7), lineWidth: 3).opacity(0.35)
                    }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 28)
            }
        }
    }
}




