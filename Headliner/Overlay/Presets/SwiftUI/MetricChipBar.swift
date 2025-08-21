import SwiftUI

struct MetricChipBar: OverlayViewProviding {
    static let presetId = "swiftui.metric.chips"
    static let defaultSize = CGSize(width: 1280, height: 720)

    func makeView(tokens: OverlayTokens) -> some View {
        let chips = [
            tokens.extras?["location"],
            tokens.localTime
        ].compactMap { $0 }.filter { !$0.isEmpty }

        return ZStack {
            VStack(spacing: 10) {
                HStack {
                    Text(tokens.displayName)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                HStack(spacing: 10) {
                    ForEach(chips, id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.black.opacity(0.75), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                Spacer()
            }
            .padding(.top, 24)
        }
    }
}


