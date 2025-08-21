import SwiftUI

struct StandardLowerThird: OverlayViewProviding {
    static let presetId = "swiftui.standard.lowerthird"
    static let defaultSize = CGSize(width: 1280, height: 720)

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geometry in
            makeContent(tokens: tokens, in: geometry.size)
        }
    }
    
    private func makeContent(tokens: OverlayTokens, in size: CGSize) -> some View {
        // Calculate scale factor based on render size vs design size (720p baseline)
        let scaleFactor = min(size.width / 1280, size.height / 720)
        
        // Apply different scaling rules based on resolution
        let baseFontScale: CGFloat
        if size.width < 800 {
            // Small cameras (e.g., 640x480): scale up fonts more aggressively
            baseFontScale = max(scaleFactor * 1.5, 0.8)
        } else {
            // Normal/large cameras: standard scaling with minimum
            baseFontScale = max(scaleFactor, 0.6)
        }
        
        return ZStack {
            // DEBUG: Big obvious box in center with current timestamp
            VStack {
                Text("SWIFTUI OVERLAY ACTIVE")
                    .font(.system(size: 24 * baseFontScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                Text(Date().formatted(date: .omitted, time: .complete))
                    .font(.system(size: 18 * baseFontScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(20 * baseFontScale)
            .background(
                RoundedRectangle(cornerRadius: 12 * baseFontScale)
                    .fill(.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12 * baseFontScale)
                            .stroke(.red, lineWidth: 3 * baseFontScale)
                    )
            )
            
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tokens.displayName)
                            .font(.system(size: 28 * baseFontScale, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)

                        if let tagline = tokens.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.system(size: 17 * baseFontScale, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }

                    Spacer(minLength: 12 * baseFontScale)

                    if let time = tokens.localTime, !time.isEmpty {
                        Text(time)
                            .font(.system(size: 14 * baseFontScale, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 12 * baseFontScale).padding(.vertical, 6 * baseFontScale)
                            .background(.thinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24 * baseFontScale)
                .padding(.vertical, 14 * baseFontScale)
                .background(
                    RoundedRectangle(cornerRadius: 18 * baseFontScale)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18 * baseFontScale)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 40 * baseFontScale)
                .padding(.bottom, 32 * baseFontScale)
            }
        }
    }
}


