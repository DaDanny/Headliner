import SwiftUI

#if DEBUG
struct StatusCard_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 16) {
      StatusCard(
        title: "Extension Status",
        status: "Installed",
        icon: "checkmark.circle.fill",
        color: .green
      )

      StatusCard(
        title: "Camera Status",
        status: "Running",
        icon: "video.circle.fill",
        color: .blue
      )

      StatusCard(
        title: "Extension Status",
        status: "Not Installed",
        icon: "exclamationmark.circle.fill",
        color: .orange
      )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }
}
#endif
