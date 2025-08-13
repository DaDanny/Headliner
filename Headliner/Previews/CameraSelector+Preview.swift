import SwiftUI

#if DEBUG
struct CameraSelector_Previews: PreviewProvider {
  static var previews: some View {
    CameraSelector(
      appState: AppState(
        systemExtensionManager: SystemExtensionRequestManager(logText: ""),
        propertyManager: CustomPropertyManager(),
        outputImageManager: OutputImageManager()
      )
    )
    .padding()
    .frame(width: 400)
    .background(Color.gray.opacity(0.1))
  }
}
#endif
