import SwiftUI

#if DEBUG
struct MainAppView_Previews: PreviewProvider {
  static var previews: some View {
    MainAppView(
      appState: AppState(
        systemExtensionManager: SystemExtensionRequestManager(logText: ""),
        propertyManager: CustomPropertyManager(),
        outputImageManager: OutputImageManager()
      ),
      outputImageManager: OutputImageManager(),
      propertyManager: CustomPropertyManager()
    )
    .frame(width: 1200, height: 800)
  }
}
#endif
