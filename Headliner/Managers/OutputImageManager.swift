//
//  OutputImageManager.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI
import AVFoundation
import CoreImage
import OSLog

class OutputImageManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    @Published var videoExtensionStreamOutputImage: CGImage?
    let noVideoImage: CGImage = NSImage(
        systemSymbolName: "video.slash",
        accessibilityDescription: "Image to indicate no video feed available"
    )!.cgImage(forProposedRect: nil, context: nil, hints: nil)! // OK to fail if this isn't available.

    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        autoreleasepool {
            guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                logger.debug("Couldn't get image buffer, returning.")
                return
            }

            guard let ioSurface = CVPixelBufferGetIOSurface(cvImageBuffer) else {
                logger.debug("Pixel buffer had no IOSurface") // The camera uses IOSurface so we want image to break if there is none.
                return
            }

            let ciImage = CIImage(ioSurface: ioSurface.takeUnretainedValue())
                .oriented(.upMirrored) // Cameras show the user a mirrored image, the other end of the conversation an unmirrored image.

            let context = CIContext(options: nil)

            guard let cgImage = context
                .createCGImage(ciImage, from: ciImage.extent) else { 
                logger.debug("Failed to create CGImage from CIImage")
                return 
            }

            //logger.debug("Successfully captured frame - \(cgImage.width)x\(cgImage.height)")

            DispatchQueue.main.async {
                self.videoExtensionStreamOutputImage = cgImage
                //logger.debug("Updated videoExtensionStreamOutputImage on main thread")
            }
        }
    }
}
