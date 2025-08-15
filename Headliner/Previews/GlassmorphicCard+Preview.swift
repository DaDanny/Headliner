import SwiftUI

#if DEBUG
struct GlassmorphicCard_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      AnimatedBackground()

      VStack(spacing: 20) {
        GlassmorphicCard {
          VStack(spacing: 16) {
            Text("Glassmorphic Card")
              .font(.headline)

            Text("This card has a beautiful glassmorphic effect with blur and transparency.")
              .font(.body)
              .multilineTextAlignment(.center)
          }
          .padding(24)
        }

        PulsingButton(
          title: "Start Camera",
          icon: "video",
          color: .green,
          isActive: true
        ) {}

        PulsingButton(
          title: "Install Extension",
          icon: "arrow.down.circle",
          color: .blue,
          isActive: false
        ) {}
      }
      .frame(width: 300)
    }
    .frame(width: 600, height: 400)
  }
}
#endif
