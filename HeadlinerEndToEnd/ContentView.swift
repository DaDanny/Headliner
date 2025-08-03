//
//  ContentView.swift
//  HeadlinerEndToEnd
//
//  Created by Danny Francken on 8/2/25.
//

import CoreMediaIO
import SwiftUI

// MARK: - ContentView

struct ContentView {
    @ObservedObject var endToEndStreamProvider: EndToEndStreamProvider
}

extension ContentView: View {
    var body: some View {
        VStack {
            Image(
                self.endToEndStreamProvider
                    .videoExtensionStreamOutputImage ?? self.endToEndStreamProvider
                    .noVideoImage,
                scale: 1.0,
                label: Text("Video Feed")
            )
        }
    }
}

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(endToEndStreamProvider: EndToEndStreamProvider())
    }
}

// MARK: - EndToEndStreamProvider

class EndToEndStreamProvider: NSObject, ObservableObject,
    CameraExtensionDeviceSourceDelegate {
    // MARK: Lifecycle

    override init() {
        providerSource = CameraExtensionProviderSource(clientQueue: nil)
        super.init()
        providerSource
            .deviceSource = CameraExtensionDeviceSource(localizedName: "Headliner")
        providerSource.deviceSource.cameraExtensionDeviceSourceDelegate = self
        providerSource.deviceSource.startStreaming()
    }

    // MARK: Internal

    @Published var videoExtensionStreamOutputImage: CGImage?
    let noVideoImage : CGImage = NSImage(
        systemSymbolName: "video.slash",
        accessibilityDescription: "Image to indicate no video feed available"
    )!.cgImage(forProposedRect: nil, context: nil, hints: nil)! // OK to fail if this isn't available.
    
    let providerSource: CameraExtensionProviderSource

    func bufferReceived(_ buffer: CMSampleBuffer) {
        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            print("Couldn't get image buffer, returning.")
            return
        }

        guard let ioSurface = CVPixelBufferGetIOSurface(cvImageBuffer) else {
            print("Pixel buffer had no IOSurface") // The camera uses IOSurface so we want image to break if there is none.
            return
        }

        let ciImage = CIImage(ioSurface: ioSurface.takeUnretainedValue())
            .oriented(.upMirrored)

        let context = CIContext(options: nil)

        guard let cgImage = context
            .createCGImage(ciImage, from: ciImage.extent) else { return }

        DispatchQueue.main.async {
            self.videoExtensionStreamOutputImage = cgImage
        }
    }
}
