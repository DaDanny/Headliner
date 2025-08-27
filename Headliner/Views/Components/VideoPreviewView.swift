//
//  VideoPreviewView.swift  
//  Headliner
//
//  Direct video preview using the Headliner virtual camera device
//

import SwiftUI
import AVFoundation
import AppKit
import Combine

struct VideoPreviewView: View {
  let isActive: Bool
  
  @State private var captureSession: AVCaptureSession?
  @State private var isSetup = false
  @State private var retryTimer: Timer?
  @State private var retryCount = 0
  
  @EnvironmentObject private var extensionService: ExtensionService
  
  // Dedicated session queue to prevent main thread blocking
  private let sessionQueue = DispatchQueue(label: "com.headliner.preview.session", qos: .userInteractive)
    
  // Preview detection
  private var isInPreviewMode: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }
  var body: some View {
      ZStack {
          RoundedRectangle(cornerRadius: 20)
              .fill(.black)
          
          if isInPreviewMode {
              RoundedRectangle(cornerRadius: 8)
                  .fill(LinearGradient(
                      colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                  ))
                  .overlay(
                      VStack(spacing: 8) {
                          Image(systemName: "camera.fill")
                              .font(.system(size: 32))
                              .foregroundStyle(.white.opacity(0.8))
                          
                          Text("Mock Camera Preview")
                              .font(.callout.weight(.medium))
                              .foregroundStyle(.white.opacity(0.9))
                          
                          Text("(Xcode Preview Mode)")
                              .font(.caption)
                              .foregroundStyle(.white.opacity(0.7))
                      }
                  )
                  .background(Color.black)
          } else if isSetup, let session = captureSession {
            // Native video preview layer
            AVCaptureVideoPreviewLayerView(session: session)
              .cornerRadius(20)
          } else if isActive {
            VStack(spacing: 16) {
              ProgressView()
                .scaleEffect(1.2)
              
              Text("Starting preview...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            }
          } else {
            VStack(spacing: 16) {
              Image(systemName: "video.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white.opacity(0.6))

              Text("No Video Feed")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            }
          }
        }
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .onAppear {
          if isActive && !isInPreviewMode {
            startRetryTimer()
          }
        }
        .onChange(of: isActive) { _, newValue in
          if newValue && !isInPreviewMode {
            startRetryTimer()
          } else {
            stopVideoPreview()
            stopRetryTimer()
          }
        }
        .onChange(of: extensionService.isInstalled) { _, isInstalled in
          if isInstalled && isActive && !isSetup && !isInPreviewMode {
            // Extension just got installed, try to set up the preview
            print("📹 Extension installed, attempting to setup video preview...")
            retryCount = 0
            setupVideoPreview()
          }
        }
        .onDisappear {
          // Always stop when view disappears
          stopVideoPreview()
          stopRetryTimer()
        }
  }
  
  private func setupVideoPreview() {
    guard !isSetup else { return } // Prevent duplicate setup
    
    print("📹 Starting video preview setup (attempt #\(retryCount + 1))...")
    
    // Run all session operations on dedicated queue to prevent main thread blocking
    sessionQueue.async {
      self.setupCaptureSession()
    }
  }
  
  private func setupCaptureSession() {
    let session = AVCaptureSession()
    
    // Find the Headliner virtual camera device
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera, .deskViewCamera],
      mediaType: .video,
      position: .unspecified
    )
    
    guard let headlinerDevice = discoverySession.devices.first(where: { 
      $0.localizedName.contains("Headliner") 
    }) else {
      print("⚠️ Headliner virtual camera device not found (attempt #\(retryCount + 1))")
      
      DispatchQueue.main.async {
        self.retryCount += 1
        
        // Only retry if we haven't exceeded max retries and extension is installed
        if self.retryCount < 10 && self.extensionService.isInstalled {
          print("📹 Will retry in 2 seconds...")
        } else if !self.extensionService.isInstalled {
          print("⚠️ Extension not installed, waiting for installation...")
        }
      }
      return
    }
    
    do {
      // Configure session on background queue
      session.beginConfiguration()
      session.sessionPreset = .high
      
      // Create input from Headliner device
      let deviceInput = try AVCaptureDeviceInput(device: headlinerDevice)
      
      if session.canAddInput(deviceInput) {
        session.addInput(deviceInput)
      }
      
      session.commitConfiguration()
      
      // Start the session (this is the critical part that was blocking main thread)
      if !session.isRunning {
        session.startRunning()
      }
      
      // Update UI state on main queue
      DispatchQueue.main.async {
        self.captureSession = session
        self.isSetup = true
        
        // Stop the retry timer since we succeeded
        self.stopRetryTimer()
        
        print("✅ Video preview setup complete using Headliner device: \(headlinerDevice.localizedName)")
      }
      
    } catch {
      print("❌ Failed to setup video preview: \(error)")
      DispatchQueue.main.async {
        self.retryCount += 1
      }
    }
  }
  
  private func startRetryTimer() {
    // Stop any existing timer
    stopRetryTimer()
    
    // Only start timer if extension is installed or installing
    guard extensionService.status == .installed || extensionService.status == .installing else {
      print("📹 Extension not installed, waiting for installation before starting retry timer")
      return
    }
    
    print("📹 Starting retry timer for video preview...")
    
    // Try immediately first
    setupVideoPreview()
    
    // Then set up periodic retry
    retryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
      if !self.isSetup && self.isActive {
        self.setupVideoPreview()
      } else if self.isSetup {
        // We got the device, stop retrying
        self.stopRetryTimer()
      }
    }
  }
  
  private func stopRetryTimer() {
    retryTimer?.invalidate()
    retryTimer = nil
    retryCount = 0
  }
  
  private func stopVideoPreview() {
    guard isSetup else { return } // Only stop if actually running
    
    print("📹 Stopping video preview...")
    
    // Stop session on background queue to avoid blocking main thread
    sessionQueue.async {
      self.captureSession?.stopRunning()
      
      DispatchQueue.main.async {
        self.captureSession = nil
        self.isSetup = false
      }
    }
  }
}

// MARK: - AVCaptureVideoPreviewLayer SwiftUI Wrapper

private struct AVCaptureVideoPreviewLayerView: NSViewRepresentable {
  let session: AVCaptureSession
  
  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspect  // Changed from .resizeAspectFill to prevent cropping
    view.layer = previewLayer
    view.wantsLayer = true
    
    return view
  }
  
  func updateNSView(_ nsView: NSView, context: Context) {
    if let previewLayer = nsView.layer as? AVCaptureVideoPreviewLayer {
      previewLayer.frame = nsView.bounds
    }
  }
}

#if DEBUG
struct VideoPreviewView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      VideoPreviewView(isActive: true)
      VideoPreviewView(isActive: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .frame(height: 280)
    .frame(width: 320)
    
  }
}
#endif
