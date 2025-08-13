import SwiftUI

#if DEBUG
struct AnimatedBackground_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      AnimatedBackground()
      FloatingParticles()
    }
    .frame(width: 800, height: 600)
  }
}
#endif
