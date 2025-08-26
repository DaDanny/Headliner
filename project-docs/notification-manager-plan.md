# Notification Manager Migration Plan - Clean Architecture (Focused)

## Overview

This document provides a step-by-step plan to fix the notification system inconsistencies in Headliner by creating **two dedicated classes** with clear separation of concerns and focused safety improvements.

## Strategy: Two-Class Architecture

**Problem**: Mixed notification paradigms causing confusion and bugs

**Solution**: Create dedicated classes for each notification domain:
1. `InternalNotifications` - NSNotificationCenter for in-app communication
2. `CrossAppExtensionNotifications` - Darwin notifications for app-extension IPC

**Key Safety Improvements**:
- Token-based observer removal (prevents memory leaks)
- Versioned notification names (future-proofing)  
- Main thread assertions (catches threading bugs)
- Filterable logging per domain (debugging focus)

## Architecture Design

### InternalNotifications Class
- **Purpose**: In-app communication within main app process
- **Technology**: NSNotificationCenter.default
- **Use Cases**: UI state changes, permission updates, app lifecycle events
- **Scope**: Main app only

### CrossAppExtensionNotifications Class  
- **Purpose**: Inter-process communication between app and extension
- **Technology**: CFNotificationCenter Darwin notifications
- **Use Cases**: Camera controls, overlay updates, device switching
- **Scope**: App ↔ Extension

## Implementation Plan

### Phase 1: Create InternalNotifications Class (Low Risk)

#### Step 1.1: Create Internal Notification Types

**New File**: `Headliner/Services/InternalNotifications.swift`

```swift
import Foundation
import Combine

// MARK: - Internal Notification Names

enum InternalNotificationName: String, CaseIterable {
  case extensionStatusChanged
  case locationPermissionGranted
  case appStateChanged
  // Add other in-app notifications as needed
  
  var rawValue: String {
    switch self {
    case .extensionStatusChanged:
      return "\(Identifiers.notificationPrefix).internal.extensionStatusChanged.v1"
    case .locationPermissionGranted:
      return "\(Identifiers.notificationPrefix).internal.locationPermissionGranted.v1"
    case .appStateChanged:
      return "\(Identifiers.notificationPrefix).internal.appStateChanged.v1"
    }
  }
  
  var notificationName: NSNotification.Name {
    NSNotification.Name(self.rawValue)
  }
  
  // Required for CaseIterable when we override rawValue
  static var allCases: [InternalNotificationName] {
    [.extensionStatusChanged, .locationPermissionGranted, .appStateChanged]
  }
  
  // Support for initialization from string
  init?(rawValue: String) {
    for notification in InternalNotificationName.allCases {
      if notification.rawValue == rawValue {
        self = notification
        return
      }
    }
    return nil
  }
}

// MARK: - Internal Notifications Manager

final class InternalNotifications {
  
  private init() {} // Prevent instantiation
  
  // Focused logging for internal notifications only
  private static let logger = HeadlinerLogger.logger(for: .internalNotifications)
  
  // MARK: - Posting
  
  static func post(_ name: InternalNotificationName, userInfo: [AnyHashable: Any]? = nil) {
    precondition(Thread.isMainThread, "Internal notifications should be posted on main thread")
    
    logger.debug("📱 Internal notification: \(name.rawValue)")
    NotificationCenter.default.post(
      name: name.notificationName,
      object: nil,
      userInfo: userInfo
    )
  }
  
  // MARK: - Observing (Token-Based - Safer)
  
  @discardableResult
  static func addObserver(
    for name: InternalNotificationName,
    using block: @escaping (Notification) -> Void
  ) -> NSObjectProtocol {
    logger.debug("🔔 Adding observer for: \(name.rawValue)")
    return NotificationCenter.default.addObserver(
      forName: name.notificationName,
      object: nil,
      queue: .main,
      using: block
    )
  }
  
  static func removeObserver(_ token: NSObjectProtocol) {
    NotificationCenter.default.removeObserver(token)
  }
  
  // MARK: - Observing (Combine)
  
  static func publisher(for name: InternalNotificationName) -> NotificationCenter.Publisher {
    NotificationCenter.default.publisher(for: name.notificationName)
  }
}
```

#### Step 1.2: Create CrossAppExtensionNotifications Class

**New File**: `HeadlinerShared/CrossAppExtensionNotifications.swift`

```swift
import Foundation
import OSLog

// MARK: - Cross-App Extension Notification Names

enum CrossAppNotificationName: String, CaseIterable {
  case startStream
  case stopStream
  case setCameraDevice
  case updateOverlaySettings
  case overlayUpdated
  // Phase 2: Enhanced bidirectional notifications
  case requestStart
  case requestStop
  case requestSwitchDevice
  case statusChanged
  
  var rawValue: String {
    switch self {
    case .startStream:
      return "\(Identifiers.notificationPrefix).startStream.v1"
    case .stopStream:
      return "\(Identifiers.notificationPrefix).stopStream.v1"
    case .setCameraDevice:
      return "\(Identifiers.notificationPrefix).setCameraDevice.v1"
    case .updateOverlaySettings:
      return "\(Identifiers.notificationPrefix).updateOverlaySettings.v1"
    case .overlayUpdated:
      return "\(Identifiers.notificationPrefix).overlayUpdated.v1"
    // Phase 2: Enhanced bidirectional notifications
    case .requestStart:
      return "\(Identifiers.notificationPrefix).request.start.v1"
    case .requestStop:
      return "\(Identifiers.notificationPrefix).request.stop.v1"
    case .requestSwitchDevice:
      return "\(Identifiers.notificationPrefix).request.switchDevice.v1"
    case .statusChanged:
      return "\(Identifiers.notificationPrefix).status.changed.v1"
    }
  }
  
  // Required for CaseIterable when we override rawValue
  static var allCases: [CrossAppNotificationName] {
    [.startStream, .stopStream, .setCameraDevice, .updateOverlaySettings, .overlayUpdated,
     .requestStart, .requestStop, .requestSwitchDevice, .statusChanged]
  }
  
  // Support for initialization from string (used in CameraExtension)
  init?(rawValue: String) {
    for notification in CrossAppNotificationName.allCases {
      if notification.rawValue == rawValue {
        self = notification
        return
      }
    }
    return nil
  }
}

// MARK: - Cross-App Extension Notifications Manager

final class CrossAppExtensionNotifications {
  
  private init() {} // Prevent instantiation
  
  // Focused logging for cross-app notifications only
  private static let logger = HeadlinerLogger.logger(for: .crossAppNotifications)
  
  // MARK: - Posting (From Main App)
  
  static func post(_ name: CrossAppNotificationName) {
    logger.debug("🌉 Cross-app notification: \(name.rawValue)")
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(name.rawValue as NSString),
      nil,
      nil,
      true
    )
  }
  
  static func post(_ name: CrossAppNotificationName, overlaySettings: OverlaySettings) {
    logger.debug("🌉 Cross-app notification with overlay settings: \(name.rawValue)")
    
    // Save settings to shared app group defaults
    if let sharedDefaults = UserDefaults(suiteName: Identifiers.appGroup),
       let encoded = try? JSONEncoder().encode(overlaySettings) {
      sharedDefaults.set(encoded, forKey: OverlayUserDefaultsKeys.overlaySettings)
      sharedDefaults.synchronize()
    }
    
    // Post the notification
    post(name)
  }
  
  // MARK: - Listening (From Extension)
  
  static func addObserver(
    observer: UnsafeRawPointer,
    callback: @escaping CFNotificationCallback,
    name: CrossAppNotificationName
  ) {
    logger.debug("🔔 Adding Darwin observer for: \(name.rawValue)")
    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      observer,
      callback,
      name.rawValue as CFString,
      nil,
      .deliverImmediately
    )
  }
  
  static func removeAllObservers(observer: UnsafeRawPointer) {
    CFNotificationCenterRemoveEveryObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      observer
    )
  }
}
```

### Phase 2: Migration Strategy (Medium Risk)

#### Step 2.1: Migrate Current Darwin Notification Usage

**Current Files to Update:**

1. **CameraService.swift** - Replace `notificationManager.postNotification()` calls
2. **OverlayService.swift** - Replace `notificationManager.postNotification()` calls  
3. **SystemExtensionRequestManager.swift** - Replace direct CFNotification calls
4. **CameraExtensionProvider.swift** - Update notification listening

**Example Migration - CameraService.swift:**

```swift
// OLD:
notificationManager.postNotification(named: .startStream)

// NEW: 
CrossAppExtensionNotifications.post(.startStream)
```

#### Step 2.2: Migrate Current NSNotificationCenter Usage

**Files to Update:**

1. **ExtensionService.swift** - Fix broken status change listening
2. **LocationPermissionManager.swift** - Migrate to InternalNotifications
3. **AppCoordinator.swift** - Update to use InternalNotifications
4. **LegacyAppState.swift** - Update observer pattern

**Example Migration - ExtensionService.swift:**

```swift
// OLD (broken):
/*
NotificationCenter.default.publisher(for: NotificationName.statusChanged.nsNotificationName)
*/

// NEW (token-based observer):
extensionStatusToken = InternalNotifications.addObserver(for: .extensionStatusChanged) { [weak self] _ in
  self?.handleExtensionStatusChange()
}

// Or Combine (automatically handles main thread):
InternalNotifications.publisher(for: .extensionStatusChanged)
  .receive(on: DispatchQueue.main)
  .sink { [weak self] _ in
    self?.handleExtensionStatusChange()
  }
  .store(in: &cancellables)
```

**Example Migration - LocationPermissionManager.swift:**

```swift
// OLD:
extension Notification.Name {
    static let locationPermissionGranted = Notification.Name("LocationPermissionGranted")
}
NotificationCenter.default.post(name: .locationPermissionGranted, object: nil)

// NEW:
InternalNotifications.post(.locationPermissionGranted)
```

### Phase 3: Clean Up Old System (Low Risk)

#### Step 3.1: Deprecate Old NotificationManager

**File**: `HeadlinerShared/Notifications.swift`

Mark the old system as deprecated:

```swift
// MARK: - DEPRECATED - Use InternalNotifications or CrossAppExtensionNotifications

@available(*, deprecated, message: "Use InternalNotifications or CrossAppExtensionNotifications instead")
final class NotificationManager {
  // ... existing code
}

@available(*, deprecated, message: "Use CrossAppNotificationName instead")
enum NotificationName: String, CaseIterable {
  // ... existing code
}
```

#### Step 3.2: Remove Deprecated Code (Future Phase)

After successful migration and testing, the old classes can be completely removed.

## Logger Category Setup (For Filterable Logging)

**Add to your existing logger categories**:

```swift
// In HeadlinerShared/Logger.swift or wherever you define categories
enum LoggerCategory: String {
  // ... existing categories
  case internalNotifications = "notifications.internal"
  case crossAppNotifications = "notifications.crossapp"
}
```

**Usage for filtered logging**:
```bash
# Debug only internal notifications
log show --predicate 'category == "notifications.internal"' --style compact --last 1h

# Debug only cross-app notifications  
log show --predicate 'category == "notifications.crossapp"' --style compact --last 1h

# Debug all notifications
log show --predicate 'category BEGINSWITH "notifications."' --style compact --last 1h
```

## Code Changes Summary

### Phase 1: Create New Classes + Logger Categories (Must Do)

1. **Update**: `HeadlinerShared/Logger.swift` - Add notification logger categories
2. **Create**: `Headliner/Services/InternalNotifications.swift`
3. **Create**: `HeadlinerShared/CrossAppExtensionNotifications.swift`

### Phase 2: Update Call Sites (Must Do)

4. **Update**: `CameraService.swift` - Use `CrossAppExtensionNotifications`
5. **Update**: `OverlayService.swift` - Use `CrossAppExtensionNotifications`
6. **Update**: `ExtensionService.swift` - Use `InternalNotifications`
7. **Update**: `LocationPermissionManager.swift` - Use `InternalNotifications`
8. **Update**: `AppCoordinator.swift` - Use `InternalNotifications`
9. **Update**: `CameraExtensionProvider.swift` - Use `CrossAppExtensionNotifications`

### Phase 3: Cleanup (Nice to Have)

10. **Mark deprecated**: Old NotificationManager and NotificationName enum
11. **Remove deprecated**: After migration is complete and tested

## Migration Benefits

### ✅ Clear Separation of Concerns
- No confusion about which system to use when
- Type-safe APIs for each notification domain
- Consistent patterns throughout codebase

### ✅ Better Developer Experience
- IntelliSense shows only relevant notifications for each context
- Compiler catches misuse of notification systems
- Self-documenting code with clear class names

### ✅ Easier Testing
- Mock InternalNotifications for unit tests
- Test app-extension communication separately
- Clear boundaries for integration testing

### ✅ Maintainability
- Easy to add new notifications to appropriate enum
- Centralized logging and debugging
- Single source of truth for each notification type

## Testing Plan

### Phase 1: Create Classes
1. Create both new classes
2. Build project - should compile without errors
3. No functional changes yet

### Phase 2: Migrate Usage  
1. Update one file at a time
2. Test each migration individually
3. Ensure old functionality still works

### Phase 3: Integration Testing
1. Test all camera controls (start/stop/device switching)
2. Test all in-app notifications (location, status changes)
3. Test app-extension communication end-to-end

## Risk Assessment

### Low Risk Changes
- ✅ Creating new classes (purely additive)
- ✅ Migrating call sites (one-to-one replacement)

### Medium Risk Areas
- ⚠️ Extension notification listening (CFNotification callback changes)
- ⚠️ Combining observer lifecycle management

### Risk Mitigation
- Migrate one file at a time
- Keep old system working until migration complete
- Thorough testing at each step

## Success Metrics

1. ✅ No more mixed notification patterns in codebase
2. ✅ ExtensionService status monitoring works correctly
3. ✅ All camera controls continue working
4. ✅ All in-app notifications continue working
5. ✅ Code is more maintainable and clear to new developers

## Future Benefits

1. **Type Safety**: Easy to add typed userInfo payloads
2. **Performance**: Optimized for each use case
3. **Debugging**: Centralized logging and monitoring
4. **Documentation**: Self-documenting notification domains