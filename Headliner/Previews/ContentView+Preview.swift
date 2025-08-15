import SwiftUI

#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    let mgr = SystemExtensionRequestManager(logText: "")
    ContentView(
      systemExtensionRequestManager: mgr,
      propertyManager: CustomPropertyManager(),
      outputImageManager: OutputImageManager()
    )
    .frame(width: 1200, height: 800)
  }
}
#endif
