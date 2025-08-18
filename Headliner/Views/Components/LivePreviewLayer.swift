//
//  LivePreviewLayer.swift
//  Headliner
//
//  Live video preview using AVSampleBufferDisplayLayer
//

import SwiftUI
import AppKit
import AVFoundation
import CoreMedia
import CoreVideo
import OSLog

/// SwiftUI view that displays live video frames from the camera extension
struct LivePreviewLayer: NSViewRepresentable {
    @StateObject private var frameClient = FrameClient()
    @Binding var isActive: Bool
    
    func makeNSView(context: Context) -> LivePreviewView {
        let view = LivePreviewView()
        
        // Set up frame callback
        frameClient.onFrameReceived = { pixelBuffer, pts in
            view.displayFrame(pixelBuffer: pixelBuffer, pts: pts)
        }
        
        frameClient.onStreamStopped = {
            view.clearDisplay()
        }
        
        return view
    }
    
    func updateNSView(_ nsView: LivePreviewView, context: Context) {
        // Update preview state based on isActive binding
        if isActive {
            nsView.showPlaceholder(text: frameClient.isConnected ? "Starting preview..." : "Connecting...")
        } else {
            nsView.clearDisplay()
        }
    }
}

/// NSView that hosts the AVSampleBufferDisplayLayer
class LivePreviewView: NSView {
    
    // MARK: - Properties
    
    private let logger = HeadlinerLogger.logger(for: .application)
    private var displayLayer: AVSampleBufferDisplayLayer?
    private var placeholderTextField: NSTextField?
    
    /// Cached format description for current video format
    private var currentFormatDescription: CMFormatDescription?
    private var lastWidth: Int32 = 0
    private var lastHeight: Int32 = 0
    private var lastPixelFormat: OSType = 0
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupDisplayLayer()
        setupPlaceholder()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDisplayLayer()
        setupPlaceholder()
    }
    
    // MARK: - Setup
    
    private func setupDisplayLayer() {
        // Ensure we have a backing layer
        self.wantsLayer = true
        
        // Create AVSampleBufferDisplayLayer
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspectFill
        layer.backgroundColor = NSColor.black.cgColor
        
        // Set layer properties for better performance
        layer.isOpaque = true
        layer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        // Add to view's layer
        self.layer?.addSublayer(layer)
        displayLayer = layer
        
        logger.debug("Created AVSampleBufferDisplayLayer")
    }
    
    private func setupPlaceholder() {
        // Create placeholder text field
        let textField = NSTextField(labelWithString: "Waiting for video...")
        textField.textColor = .white
        textField.alignment = .center
        textField.font = .systemFont(ofSize: 18, weight: .medium)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(textField)
        
        // Center the text field
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        placeholderTextField = textField
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        
        // Update display layer frame
        displayLayer?.frame = bounds
    }
    
    // MARK: - Display Methods
    
    /// Display a video frame
    func displayFrame(pixelBuffer: CVPixelBuffer, pts: CMTime) {
        // Hide placeholder when we get first frame
        DispatchQueue.main.async { [weak self] in
            self?.placeholderTextField?.isHidden = true
        }
        
        // Check if format changed
        let width = Int32(CVPixelBufferGetWidth(pixelBuffer))
        let height = Int32(CVPixelBufferGetHeight(pixelBuffer))
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        let formatChanged = width != lastWidth || height != lastHeight || pixelFormat != lastPixelFormat
        
        if formatChanged {
            logger.debug("Format changed: \(width)x\(height) format: \(pixelFormat)")
            
            // Create new format description
            var formatDescription: CMFormatDescription?
            let result = CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &formatDescription
            )
            
            if result == noErr, let format = formatDescription {
                currentFormatDescription = format
                lastWidth = width
                lastHeight = height
                lastPixelFormat = pixelFormat
                
                // Flush display layer on format change (must be on main thread)
                DispatchQueue.main.async { [weak self] in
                    self?.displayLayer?.flush()
                    self?.logger.debug("Flushed display layer for format change")
                }
            } else {
                logger.error("Failed to create format description: \(result)")
                return
            }
        }
        
        guard let formatDescription = currentFormatDescription else {
            logger.error("No format description available")
            return
        }
        
        // Create timing info
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime.invalid,
            presentationTimeStamp: pts,
            decodeTimeStamp: CMTime.invalid
        )
        
        // Create sample buffer
        var sampleBuffer: CMSampleBuffer?
        let result = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        if result == noErr, let buffer = sampleBuffer {
            // Enqueue sample buffer to display layer
            displayLayer?.enqueue(buffer)
            
            // Request flush if needed (helps with low latency)
            if displayLayer?.status == .failed {
                logger.error("Display layer in failed state, attempting recovery")
                displayLayer?.flush()
            }
        } else {
            logger.error("Failed to create sample buffer: \(result)")
        }
    }
    
    /// Clear the display
    func clearDisplay() {
        DispatchQueue.main.async { [weak self] in
            self?.displayLayer?.flushAndRemoveImage()
            self?.placeholderTextField?.isHidden = false
            self?.placeholderTextField?.stringValue = "Camera stopped"
        }
        
        // Reset format
        currentFormatDescription = nil
        lastWidth = 0
        lastHeight = 0
        lastPixelFormat = 0
        
        logger.debug("Cleared display")
    }
    
    /// Show placeholder with custom text
    func showPlaceholder(text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.placeholderTextField?.stringValue = text
            self?.placeholderTextField?.isHidden = false
        }
    }
}

// MARK: - Preview Provider

struct LivePreviewLayer_Previews: PreviewProvider {
    static var previews: some View {
        LivePreviewLayer(isActive: .constant(true))
            .frame(height: 300)
            .background(Color.black)
            .cornerRadius(20)
    }
}