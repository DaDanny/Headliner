# Branch Status: app-live-preview-fix

**Date**: Sunday, August 17, 2025 - 10:39 PM EDT
**Status**: IN PROGRESS - Paused for MVP prioritization

## Overview

This branch implements a live in-app preview feature that displays real-time video from the camera extension within the main Headliner app. The feature is **fully implemented and functional** but has **performance issues** affecting camera startup time in video conferencing apps (~0.5 second lag when starting camera).

## What Was Accomplished

### ✅ Fully Implemented Components

1. **XPC Service Architecture**

   - `CameraExtension/FrameSharingService.swift` - NSXPC service for frame sharing
   - `HeadlinerShared/FrameSharingProtocol.swift` - Protocol definition
   - `HeadlinerShared/FrameParcel.swift` - NSSecureCoding frame transport
   - Zero-copy IOSurface sharing via mach ports

2. **Client Implementation**

   - `Headliner/Preview/FrameClient.swift` - XPC client with reconnection logic
   - Darwin notification observers for frame events
   - Fallback polling mechanism at 15Hz

3. **UI Components**

   - `Headliner/Views/Components/LivePreviewLayer.swift` - AVSampleBufferDisplayLayer wrapper
   - Hardware-accelerated video rendering
   - Format change detection and handling

4. **Entitlements Configuration**

   - Mach service exceptions properly configured
   - Both targets have correct entitlements

5. **Integration Points**
   - Modified `CameraExtensionProvider.swift` to cache frames
   - Added `frameAvailable` and `streamStopped` notifications
   - Updated `CameraPreviewCard.swift` to conditionally show live preview

## Current Issues

### 🔧 Performance Impact

- **Problem**: Introducing ~0.5s lag when starting camera in Google Meet/Zoom
- **Cause**: XPC service initialization and frame caching overhead
- **Impact**: Degrades user experience during critical moment (joining meetings)

### 🔧 Timing Issue (Resolved but with trade-offs)

- **Original Problem**: XPC connection attempted before service was ready
- **Fix Applied**: Delayed connection + only show when camera is running
- **Trade-off**: The delay fix contributes to the performance issue

## Debug Work Completed

### Added Comprehensive Logging

- 🔵 XPC service start/stop logging
- 🟢 Connection request logging
- 🟡 Frame caching events
- File-based logging to app group container for debugging

### Debug Tools Created (Now Deleted)

- `check_xpc_logs.sh` - Script to check XPC logs
- `test_xpc.sh` - Script to test XPC connection
- `DEBUG_XPC_CONNECTION.md` - Debug plan documentation
- `DEBUG_XPC_FIX.md` - Documentation of the timing fix

## Files Modified/Added

### New Files (Feature Implementation)

```
CameraExtension/FrameSharingService.swift
Headliner/Preview/FrameClient.swift
Headliner/Views/Components/LivePreviewLayer.swift
HeadlinerShared/FrameParcel.swift
HeadlinerShared/FrameSharingProtocol.swift
```

### Modified Files

```
CameraExtension/CameraExtensionProvider.swift - Added frame caching
Headliner/Views/MainAppView.swift - Added LivePreviewLayer condition
Headliner/Views/Components/CameraPreviewCard.swift - Added live preview support
HeadlinerShared/Notifications.swift - Added new notifications
*.entitlements - Added mach service exceptions
```

### Documentation

```
docs/APP_PREVIEW.md - Complete technical documentation
docs/APP_PREVIEW_REVIEW.md - Code review and findings
docs/LIVE_PREVIEW_STATUS.md - Current status and performance issues
```

## How to Continue Development

### Current State:

The feature is **currently enabled** with all components active. The 0.5s delay in `FrameClient.swift` helps with connection timing but contributes to the performance issue.

### To Test:

1. Build and run the app
2. Start the camera
3. Live preview should appear (with the noted performance lag)

### To Temporarily Disable (for testing without lag):

In `Headliner/Views/MainAppView.swift` line 29:

```swift
// Change from:
isExtensionRunning: appState.cameraStatus.isRunning
// To:
isExtensionRunning: false
```

### Potential Solutions to Explore

1. **Lazy Initialization**

   - Only start XPC service when user explicitly requests preview
   - Add a "Show Preview" button rather than automatic

2. **Optimized Frame Path**

   - Cache frames only when preview is visible
   - Skip frames (e.g., only cache every 3rd frame)
   - Use lower resolution for preview

3. **Different IPC Mechanism**

   - Investigate if shared memory via App Groups could work
   - Consider if Darwin notifications + shared container is sufficient

4. **Async Architecture**
   - Move frame caching completely off the main render pipeline
   - Use background queue for all XPC operations

## Lessons Learned

### What Worked Well

- Zero-copy IOSurface transport is efficient
- NSXPC with mach ports works correctly when timing is right
- Debug logging to files was essential for troubleshooting

### What Didn't Work

- Starting XPC service adds noticeable startup lag
- Timing between extension start and client connection is tricky
- Feature adds complexity without clear user value

## Recommendation

**For MVP**: Keep this feature disabled. The virtual camera works perfectly without it, and users can see their preview in the meeting app.

**For Future**: Only revisit if users specifically request in-app preview. Consider making it an optional feature that users can enable if they accept the performance trade-off.

## Branch Status

This branch is **IN PROGRESS** with the feature working but not ready for MVP due to performance issues. The branch represents significant learning about:

- XPC communication between extension and app
- Zero-copy frame sharing on macOS
- Performance trade-offs in real-time video systems

**Decision**: Pause this feature as-is with code working but performance issues unresolved. Focus on higher-value MVP features and return to this later if needed.

## Time Invested

Approximately 4-5 hours on implementation and debugging. While the feature didn't ship, the learning about system architecture and performance constraints was valuable.

---

_Branch preserved for potential future iteration when performance can be properly addressed._
