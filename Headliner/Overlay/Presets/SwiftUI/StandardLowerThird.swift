import SwiftUI

struct StandardLowerThird: OverlayViewProviding {
    static let presetId = "swiftui.standard.lowerthird"
    static let defaultSize = CGSize(width: 1280, height: 720)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            VStack {
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
                
                Spacer()
                
                HStack {
                    BottomBar(
                        displayName: tokens.displayName,
                        tagline: tokens.tagline,
                        accentColor: accentColor
                    )
                    
                    Spacer()
                    
                    if let time = tokens.localTime {
                        TimeTicker(time: time)
                    }
                }
                .padding()
            }
        }
    }
}


