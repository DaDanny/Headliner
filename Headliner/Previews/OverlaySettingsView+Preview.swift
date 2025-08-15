import SwiftUI

#if DEBUG
struct OverlaySettingsView_Previews: PreviewProvider {
  static var previews: some View {
    OverlaySettingsView(appState: AppState(
      systemExtensionManager: SystemExtensionRequestManager(logText: ""),
      propertyManager: CustomPropertyManager(),
      outputImageManager: OutputImageManager()
    ))
    .frame(width: 600, height: 700)
    .background(Color.black)
  }
}
#endif
