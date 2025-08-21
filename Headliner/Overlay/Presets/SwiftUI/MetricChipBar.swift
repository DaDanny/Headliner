import SwiftUI

struct MetricChipBar: OverlayViewProviding {
    static let presetId = "swiftui.metric.chips"
    static let defaultSize = CGSize(width: 1280, height: 720)

    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geometry in
            makeContent(tokens: tokens, in: geometry.size)
        }
    }
    
    private func makeContent(tokens: OverlayTokens, in size: CGSize) -> some View {
        let chips = [
            tokens.extras?["location"],
            tokens.localTime
        ].compactMap { $0 }.filter { !$0.isEmpty }
        
        // Calculate scale factor for responsive design
        let scaleFactor = min(size.width / 1280, size.height / 720)
        let baseFontScale: CGFloat
        if size.width < 800 {
            baseFontScale = max(scaleFactor * 1.5, 0.8)
        } else {
            baseFontScale = max(scaleFactor, 0.6)
        }

        return ZStack {
            VStack(spacing: 10 * baseFontScale) {
                HStack {
                    Text(tokens.displayName)
                        .font(.system(size: 30 * baseFontScale, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 20 * baseFontScale)
                HStack(spacing: 10 * baseFontScale) {
                    ForEach(chips, id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 14 * baseFontScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12 * baseFontScale).padding(.vertical, 6 * baseFontScale)
                            .background(.black.opacity(0.75), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20 * baseFontScale)
                Spacer()
            }
            .padding(.top, 24 * baseFontScale)
        }
    }
}


