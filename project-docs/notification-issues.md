# Notification System Issues in Headliner

## Overview

The Headliner app currently has inconsistent notification patterns that are causing potential reliability issues. The main problem is the mixing of two different notification systems that serve different purposes.

## The Two Notification Systems

### 1. Darwin Notifications (CFNotificationCenter) ✅ Working Correctly

**Purpose**: Inter-process communication between the main app and camera extension

**Implementation**: 
- Defined in `HeadlinerShared/Notifications.swift`
- Uses `NotificationName` enum with proper `rawValue` strings
- Posted via `CFNotificationCenterPostNotification`
- Received via `CFNotificationCenterAddObserver` in the extension

**Usage Examples** (Working correctly):
```swift
// Sending from main app
notificationManager.postNotification(named: .setCameraDevice)

// Extension listens via Darwin notifications in CameraExtensionProvider.swift
CFNotificationCenterAddObserver(...)
```

**Files using this correctly**:
- `CameraService.swift` - ✅ Uses `notificationManager.postNotification()`
- `OverlayService.swift` - ✅ Uses `notificationManager.postNotification()`
- `SystemExtensionRequestManager.swift` - ✅ Has its own CFNotificationCenter posting
- `CameraExtensionProvider.swift` - ✅ Receives via CFNotificationCenterAddObserver

### 2. NSNotificationCenter (In-App Notifications) ⚠️ Inconsistent

**Purpose**: Communication within a single app process (main app only)

**Current Issues**:
- Mixed usage patterns
- Some classes define their own `Notification.Name` extensions
- Inconsistent with the Darwin notification system

## Specific Problems Found

### Problem 1: Non-existent `.nsNotificationName` Property

**Location**: `ExtensionService.swift:165`

```swift
// ❌ BROKEN - This property doesn't exist
NotificationCenter.default.publisher(for: NotificationName.statusChanged.nsNotificationName)
```

**Issue**: The `NotificationName` enum (designed for Darwin notifications) doesn't have an `nsNotificationName` property to bridge to NSNotificationCenter.

**Status**: Currently commented out with "TODO: Re-enable once notification system is stabilized"

### Problem 2: Inconsistent In-App Notification Patterns

**Location**: `LocationPermissionManager.swift`

```swift
// ✅ This works because it defines its own Notification.Name extension
extension Notification.Name {
    static let locationPermissionGranted = Notification.Name("LocationPermissionGranted")
}

NotificationCenter.default.post(name: .locationPermissionGranted, object: nil)
```

**Location**: `AppCoordinator.swift`

```swift
// ✅ This works with the LocationPermissionManager's extension
NotificationCenter.default.publisher(for: .locationPermissionGranted)
```

## Root Cause Analysis

The confusion stems from having two different notification paradigms:

1. **Darwin Notifications** - System-level IPC (app ↔ extension)
2. **NSNotificationCenter** - In-process communication (within app)

The `NotificationName` enum was designed for Darwin notifications but the code is trying to use it with NSNotificationCenter without a proper bridge.

## Impact Assessment

### High Impact (Currently Broken)
- ❌ Extension status change monitoring in `ExtensionService.swift` (commented out)
- ⚠️ Potential for future bugs if developers continue mixing the patterns

### Low Impact (Working but Inconsistent)
- ✅ Location permission notifications work but use a different pattern
- ✅ App activation notifications work (uses NSApplication notifications)

## Files Requiring Attention

### Broken Code
1. `ExtensionService.swift` - Lines 164-171 (commented out broken code)

### Inconsistent Patterns
1. `LocationPermissionManager.swift` - Uses separate Notification.Name extension
2. `AppCoordinator.swift` - Receives location notifications correctly
3. `LegacyAppState.swift` - Uses old observer pattern for location notifications

## Recommendations

1. **Keep Darwin notifications as-is** - They work correctly for app-extension communication
2. **Fix NSNotificationCenter usage** - Add proper bridge or use consistent patterns
3. **Standardize in-app notifications** - Either extend NotificationName or create separate system
4. **Enable commented-out code** - Fix the `.nsNotificationName` issue in ExtensionService

## Next Steps

See `notification-manager-plan.md` for detailed implementation plan and code changes.