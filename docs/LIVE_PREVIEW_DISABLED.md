# Live Preview Feature - IN PROGRESS

## Current Status

The live in-app preview feature is **fully implemented and working** but has performance issues:

1. **Performance Impact**: The XPC connection and frame sharing introduced noticeable lag when starting the camera in Google Meet/Zoom
2. **User Experience**: A fast, responsive virtual camera is more important than an in-app preview
3. **Redundant Feature**: Users can already see their video in the meeting app's preview

## Current State

The feature is **fully implemented** but disabled. The code remains in place and can be re-enabled if needed.

### What's Disabled:

- ✅ XPC service initialization in camera extension (commented out)
- ✅ Frame caching and notifications (commented out)
- ✅ LivePreviewLayer UI component (condition set to false)
- ✅ All performance overhead eliminated

### What Still Works:

- ✅ Virtual camera in Google Meet/Zoom
- ✅ Static preview image
- ✅ All overlay features
- ✅ Camera controls

## How to Re-Enable (If Needed)

If you want to experiment with live preview in the future:

### 1. Re-enable XPC Service

In `CameraExtension/CameraExtensionProvider.swift` line ~117:

```swift
// Uncomment these lines:
frameSharingService = FrameSharingService()
extensionLogger.debug("✅ Initialized frame sharing service for live preview")
```

### 2. Re-enable Frame Caching

In `CameraExtension/CameraExtensionProvider.swift` line ~382:

```swift
// Uncomment these lines:
frameSharingService?.cacheFrame(pixelBuffer: pixelBuffer, pts: timingInfo.presentationTimeStamp)
NotificationManager.postNotification(named: .frameAvailable)
```

Also uncomment the `clearCache()` calls at lines ~205 and ~274.

### 3. Re-enable UI

In `Headliner/Views/MainAppView.swift` line 29:

```swift
// Change from:
isExtensionRunning: false  // Live preview disabled for performance

// To:
isExtensionRunning: appState.cameraStatus.isRunning
```

## Performance Considerations

If you re-enable this feature, consider:

1. **Lazy Loading**: Only initialize XPC when user explicitly requests preview
2. **Lower Frame Rate**: Sample every Nth frame instead of all frames
3. **Resolution Reduction**: Send lower resolution frames for preview
4. **Async Processing**: Move frame caching off the main render path
5. **User Toggle**: Let users opt-in to preview if they want it

## The Right Decision

Disabling this feature was the **right product decision**:

- Users care more about performance than preview
- The virtual camera (core feature) works perfectly
- Preview is nice-to-have, not essential
- Performance issues would drive users away

Remember: **Ship fast, iterate later!** 🚀
