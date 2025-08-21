import SwiftUI

struct StandardLowerThird: OverlayViewProviding {
    static let presetId = "swiftui.standard.lowerthird"
    static let defaultSize = CGSize(width: 1280, height: 720)

    func makeView(tokens: OverlayTokens) -> some View {
        ZStack {
            // DEBUG: Big obvious box in center with current timestamp
            VStack {
                Text("SWIFTUI OVERLAY ACTIVE")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                Text(Date().formatted(date: .omitted, time: .complete))
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.red, lineWidth: 3)
                    )
            )
            
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tokens.displayName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)

                        if let tagline = tokens.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }

                    Spacer(minLength: 12)

                    if let time = tokens.localTime, !time.isEmpty {
                        Text(time)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.thinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
    }
}


