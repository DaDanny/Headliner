//
//  AnalyticsManager.swift
//  Headliner
//
//  Analytics integration layer for Firebase Crashlytics, Sentry, or other providers
//

import Foundation
import SwiftUI

/// Analytics event tracking for user behavior and performance monitoring
protocol AnalyticsProvider {
  func trackEvent(_ event: AnalyticsEvent)
  func trackPerformance(_ metric: PerformanceMetric)
  func setUserId(_ id: String)
  func setUserProperty(key: String, value: String)
}

/// Main analytics manager that routes events to configured providers
@MainActor
class AnalyticsManager: ObservableObject {
  static let shared = AnalyticsManager()
  
  private var providers: [AnalyticsProvider] = []
  private let logger = HeadlinerLogger.logger(for: .analytics)
  private let deviceId: String
  
  // User properties for segmentation
  private(set) var sessionId = UUID().uuidString
  private var sessionStartTime = Date()
  
  private init() {
    // Generate or retrieve persistent device ID
    if let existingId = UserDefaults.standard.string(forKey: "HeadlinerDeviceID") {
      self.deviceId = existingId
    } else {
      self.deviceId = UUID().uuidString
      UserDefaults.standard.set(deviceId, forKey: "HeadlinerDeviceID")
    }
    
    setupProviders()
  }
  
  private func setupProviders() {
    // Add Firebase provider if available
    #if canImport(FirebaseAnalytics)
    providers.append(FirebaseAnalyticsProvider())
    #endif
    
    // Add Sentry provider if available
    #if canImport(Sentry)
    providers.append(SentryAnalyticsProvider())
    #endif
    
    // Always add debug provider in DEBUG builds
    #if DEBUG
    providers.append(DebugAnalyticsProvider())
    #endif
    
    // Set initial user properties
    providers.forEach { provider in
      provider.setUserId(deviceId)
      provider.setUserProperty(key: "app_version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
      provider.setUserProperty(key: "os_version", value: ProcessInfo.processInfo.operatingSystemVersionString)
    }
  }
  
  // MARK: - Event Tracking
  
  func track(_ event: AnalyticsEvent) {
    providers.forEach { $0.trackEvent(event) }
    logger.debug("📊 Event: \(event.name) - \(event.parameters.description)")
  }
  
  func trackPerformance(_ metric: PerformanceMetric) {
    providers.forEach { $0.trackPerformance(metric) }
    logger.debug("⏱️ Performance: \(metric.name) = \(metric.value)ms")
  }
  
  // MARK: - Convenience Methods
  
  func trackAppLaunch() {
    track(.appLaunched(sessionId: sessionId))
  }
  
  func trackExtensionStatus(_ status: String) {
    track(.extensionStatusChanged(status: status))
  }
  
  func trackCameraStart(duration: TimeInterval) {
    trackPerformance(.cameraStartTime(duration: duration))
    track(.cameraStarted)
  }
  
  func trackCameraSwitch(cameraId: String, duration: TimeInterval) {
    track(.cameraSelected(cameraId: cameraId))
    trackPerformance(.cameraSwitchTime(duration: duration))
  }
  
  func trackOverlaySelection(presetId: String) {
    track(.overlayPresetSelected(presetId: presetId))
  }
  
  func trackOverlaySettingChange(setting: String, value: Any) {
    track(.overlaySettingChanged(setting: setting, value: String(describing: value)))
  }
  
  func trackError(_ error: Error, context: String) {
    track(.errorOccurred(error: error.localizedDescription, context: context))
  }
}

// MARK: - Event Definitions

enum AnalyticsEvent {
  case appLaunched(sessionId: String)
  case extensionInstalled
  case extensionStatusChanged(status: String)
  case cameraStarted
  case cameraStopped
  case cameraSelected(cameraId: String)
  case overlayEnabled
  case overlayDisabled
  case overlayPresetSelected(presetId: String)
  case overlaySettingChanged(setting: String, value: String)
  case aspectRatioChanged(aspect: String)
  case surfaceStyleChanged(style: String)
  case locationPermissionGranted
  case locationPermissionDenied
  case personalInfoRefreshed
  case errorOccurred(error: String, context: String)
  
  var name: String {
    switch self {
    case .appLaunched: return "app_launched"
    case .extensionInstalled: return "extension_installed"
    case .extensionStatusChanged: return "extension_status_changed"
    case .cameraStarted: return "camera_started"
    case .cameraStopped: return "camera_stopped"
    case .cameraSelected: return "camera_selected"
    case .overlayEnabled: return "overlay_enabled"
    case .overlayDisabled: return "overlay_disabled"
    case .overlayPresetSelected: return "overlay_preset_selected"
    case .overlaySettingChanged: return "overlay_setting_changed"
    case .aspectRatioChanged: return "aspect_ratio_changed"
    case .surfaceStyleChanged: return "surface_style_changed"
    case .locationPermissionGranted: return "location_permission_granted"
    case .locationPermissionDenied: return "location_permission_denied"
    case .personalInfoRefreshed: return "personal_info_refreshed"
    case .errorOccurred: return "error_occurred"
    }
  }
  
  var parameters: [String: Any] {
    switch self {
    case .appLaunched(let sessionId):
      return ["session_id": sessionId, "timestamp": Date().timeIntervalSince1970]
    case .extensionStatusChanged(let status):
      return ["status": status]
    case .cameraSelected(let cameraId):
      return ["camera_id": cameraId]
    case .overlayPresetSelected(let presetId):
      return ["preset_id": presetId]
    case .overlaySettingChanged(let setting, let value):
      return ["setting": setting, "value": value]
    case .aspectRatioChanged(let aspect):
      return ["aspect": aspect]
    case .surfaceStyleChanged(let style):
      return ["style": style]
    case .errorOccurred(let error, let context):
      return ["error": error, "context": context]
    default:
      return [:]
    }
  }
}

// MARK: - Performance Metrics

enum PerformanceMetric {
  case appLaunchTime(duration: TimeInterval)
  case cameraStartTime(duration: TimeInterval)
  case cameraSwitchTime(duration: TimeInterval)
  case extensionPollCount(count: Int)
  case overlayRenderTime(duration: TimeInterval)
  case settingsSaveTime(duration: TimeInterval)
  
  var name: String {
    switch self {
    case .appLaunchTime: return "app_launch_time"
    case .cameraStartTime: return "camera_start_time"
    case .cameraSwitchTime: return "camera_switch_time"
    case .extensionPollCount: return "extension_poll_count"
    case .overlayRenderTime: return "overlay_render_time"
    case .settingsSaveTime: return "settings_save_time"
    }
  }
  
  var value: Double {
    switch self {
    case .appLaunchTime(let duration),
         .cameraStartTime(let duration),
         .cameraSwitchTime(let duration),
         .overlayRenderTime(let duration),
         .settingsSaveTime(let duration):
      return duration * 1000 // Convert to milliseconds
    case .extensionPollCount(let count):
      return Double(count)
    }
  }
}

// MARK: - Debug Provider

#if DEBUG
class DebugAnalyticsProvider: AnalyticsProvider {
  func trackEvent(_ event: AnalyticsEvent) {
    print("🔵 [Analytics] Event: \(event.name) | Params: \(event.parameters)")
  }
  
  func trackPerformance(_ metric: PerformanceMetric) {
    print("🟡 [Analytics] Performance: \(metric.name) = \(String(format: "%.2f", metric.value))ms")
  }
  
  func setUserId(_ id: String) {
    print("🟢 [Analytics] User ID: \(id)")
  }
  
  func setUserProperty(key: String, value: String) {
    print("🟣 [Analytics] Property: \(key) = \(value)")
  }
}
#endif

// MARK: - Firebase Provider Stub
// Uncomment and implement when Firebase is added to the project

/*
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
import FirebaseCrashlytics

class FirebaseAnalyticsProvider: AnalyticsProvider {
  func trackEvent(_ event: AnalyticsEvent) {
    Analytics.logEvent(event.name, parameters: event.parameters)
  }
  
  func trackPerformance(_ metric: PerformanceMetric) {
    // Log to Crashlytics custom keys for performance monitoring
    Crashlytics.crashlytics().setCustomValue(metric.value, forKey: metric.name)
    
    // Also log as event for Analytics
    Analytics.logEvent("performance_metric", parameters: [
      "metric_name": metric.name,
      "value": metric.value
    ])
  }
  
  func setUserId(_ id: String) {
    Analytics.setUserID(id)
    Crashlytics.crashlytics().setUserID(id)
  }
  
  func setUserProperty(key: String, value: String) {
    Analytics.setUserProperty(value, forName: key)
    Crashlytics.crashlytics().setCustomValue(value, forKey: key)
  }
}
#endif
*/

// MARK: - Sentry Provider Stub
// Uncomment and implement when Sentry is added to the project

/*
#if canImport(Sentry)
import Sentry

class SentryAnalyticsProvider: AnalyticsProvider {
  func trackEvent(_ event: AnalyticsEvent) {
    SentrySDK.capture(message: event.name) { scope in
      scope.setContext(value: event.parameters, key: "event_data")
    }
  }
  
  func trackPerformance(_ metric: PerformanceMetric) {
    // Create a transaction for performance monitoring
    let transaction = SentrySDK.startTransaction(name: metric.name, operation: "measure")
    transaction.setMeasurement(name: metric.name, value: NSNumber(value: metric.value), unit: MeasurementUnit(unit: "millisecond"))
    transaction.finish()
  }
  
  func setUserId(_ id: String) {
    SentrySDK.configureScope { scope in
      scope.setUser(Sentry.User(userId: id))
    }
  }
  
  func setUserProperty(key: String, value: String) {
    SentrySDK.configureScope { scope in
      scope.setTag(value: value, key: key)
    }
  }
}
#endif
*/