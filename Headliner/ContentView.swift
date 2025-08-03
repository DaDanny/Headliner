//
//  ContentView.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI
import SystemExtensions
import OSLog
import AVFoundation
import CoreMediaIO

// MARK: - ContentView

let logger = Logger(
    subsystem: Identifiers.orgIDAndProduct.rawValue.lowercased(),
    category: "Application"
)

struct ContentView {
    // MARK: Lifecycle
    init(
        systemExtensionRequestManager: SystemExtensionRequestManager,
        propertyManager: CustomPropertyManager,
        outputImageManager: OutputImageManager
    ) {
        self.systemExtensionRequestManager = systemExtensionRequestManager
        self.propertyManager = propertyManager
        self.outputImageManager = outputImageManager
        
        // Initialize AppState as a StateObject
        self._appState = StateObject(wrappedValue: AppState(
            systemExtensionManager: systemExtensionRequestManager,
            propertyManager: propertyManager,
            outputImageManager: outputImageManager
        ))
    }

    // MARK: Internal

    @StateObject private var appState: AppState
    private let systemExtensionRequestManager: SystemExtensionRequestManager
    private let propertyManager: CustomPropertyManager
    private let outputImageManager: OutputImageManager
    
    // MARK: Private
    
    private func setupCaptureSession() {
        let captureSessionManager = CaptureSessionManager(capturingHeadliner: true)
        
        if captureSessionManager.configured == true, captureSessionManager.captureSession.isRunning == false {
            captureSessionManager.captureSession.startRunning()
            captureSessionManager.videoOutput?.setSampleBufferDelegate(
                outputImageManager,
                queue: captureSessionManager.dataOutputQueue
            )
        } else {
            logger.error("Couldn't start capture session")
        }
    }
}

// MARK: View

extension ContentView: View {
    var body: some View {
        Group {
            if appState.extensionStatus.isInstalled {
                MainAppView(
                    appState: appState,
                    outputImageManager: outputImageManager,
                    propertyManager: propertyManager
                )
            } else {
                OnboardingView(appState: appState)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.extensionStatus.isInstalled)
        .onAppear {
            setupCaptureSession()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            systemExtensionRequestManager: SystemExtensionRequestManager(logText: ""),
            propertyManager: CustomPropertyManager(),
            outputImageManager: OutputImageManager()
        )
        .frame(width: 1200, height: 800)
    }
}