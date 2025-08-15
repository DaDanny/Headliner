import SwiftUI

#if DEBUG
struct ModernButton_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 16) {
      ModernButton("Install Extension", icon: "arrow.down.circle", style: .primary) {}
      ModernButton("Start Camera", icon: "video", style: .success) {}
      ModernButton("Stop Camera", icon: "video.slash", style: .danger) {}
      ModernButton("Settings", icon: "gear", style: .secondary) {}
      ModernButton("Installing...", style: .primary, isLoading: true) {}
    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }
}
#endif
