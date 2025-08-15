import SwiftUI

#if DEBUG
struct CameraPreviewCard_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      CameraPreviewCard(previewImage: nil, isActive: true)
      CameraPreviewCard(previewImage: nil, isActive: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }
}
#endif
