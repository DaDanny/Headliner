//
//  LegacyAppStateBridge.swift
//  Headliner
//
//  DEPRECATED: Temporary bridge to use new service architecture with old API
//  This allows gradual migration from AppState to services
//  TODO: Delete this file after Big Bang Migration is complete
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import CoreLocation

/// DEPRECATED: Bridge that maintains old AppState API while using new services internally
@available(*, deprecated, message: "Use AppCoordinator + Services instead")
@MainActor
final class LegacyAppStateBridge: ObservableObject {
  // Keep using old AppState for now
  private let legacyAppState: AppState
  
  // Forward all the old API
  var extensionStatus: ExtensionStatus { legacyAppState.extensionStatus }
  var cameraStatus: CameraStatus { legacyAppState.cameraStatus }
  var availableCameras: [CameraDevice] { legacyAppState.availableCameras }
  var selectedCameraID: String { legacyAppState.selectedCameraID }
  var statusMessage: String { legacyAppState.statusMessage }
  var overlaySettings: OverlaySettings { legacyAppState.overlaySettings }
  var themeManager: ThemeManager { legacyAppState.themeManager }
  let locationPermissionManager: LocationPermissionManager
  
  @Published var isShowingSettings = false
  @Published var isShowingOverlaySettings = false
  
  init() {
    // For now, just use the old AppState
    self.legacyAppState = AppState(
      systemExtensionManager: SystemExtensionRequestManager(logText: ""),
      propertyManager: CustomPropertyManager(),
      outputImageManager: OutputImageManager()
    )
    self.locationPermissionManager = legacyAppState.locationPermissionManager
  }
  
  // Forward all methods
  func initializeApp() { legacyAppState.initializeForUse() }
  func startCamera() { legacyAppState.startCamera() }
  func stopCamera() { legacyAppState.stopCamera() }
  func selectCamera(_ camera: CameraDevice) { legacyAppState.selectCamera(camera) }
  func installExtension() { legacyAppState.installExtension() }
  func refreshCameras() { legacyAppState.refreshCameras() }
  func updateOverlaySettings(_ settings: OverlaySettings) { legacyAppState.updateOverlaySettings(settings) }
  func selectPreset(_ presetId: String) { legacyAppState.selectPreset(presetId) }
  func requestLocationPermission() { legacyAppState.requestLocationPermission() }
  
  var isCameraRunning: Bool { legacyAppState.cameraStatus.isRunning }
  var hasCameraPermission: Bool { legacyAppState.hasCameraPermission }
  var needsPermissions: Bool { legacyAppState.needsPermissions }
}