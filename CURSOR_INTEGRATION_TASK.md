# HeadlinerShared Integration Task

## Context

The Headliner project has undergone a major cleanup and now has shared code extracted into `HeadlinerShared/` directory. The main app (`Headliner/`) has been updated to use these shared modules, but the `CameraExtension/` still uses the legacy `CameraExtension/Shared.swift` file. This task completes the integration.

## Current State

- ✅ `HeadlinerShared/` directory created with 4 shared modules
- ✅ Main app (`Headliner/`) updated to import from `HeadlinerShared/`
- ⏳ `CameraExtension/` still uses legacy `CameraExtension/Shared.swift`
- ⏳ Xcode project needs target configuration updates

## Goal

Complete the shared code integration so both the main app and camera extension use the same shared types from `HeadlinerShared/`.

## Files to Update

### 1. Xcode Project Configuration

In `Headliner.xcodeproj`:

- Add all files in `HeadlinerShared/` to both:
  - `Headliner` target (main app)
  - `CameraExtension` target
- Remove `CameraExtension/Shared.swift` from the `Headliner` target (keep it in `CameraExtension` for now)

### 2. Update CameraExtension Files

Update these files to import from `HeadlinerShared/` instead of using local types:

#### `CameraExtension/CameraExtensionProvider.swift`

- Add imports:
  ```swift
  import HeadlinerShared
  ```
- Replace usage of types from `Shared.swift` with imports from `HeadlinerShared`
- Update references to:
  - `Identifiers` → use `HeadlinerShared.Identifiers`
  - `NotificationName` → use `HeadlinerShared.NotificationName`
  - `NotificationManager` → use `HeadlinerShared.NotificationManager`
  - `OverlaySettings` and related types → use `HeadlinerShared.OverlaySettings`

#### `CameraExtension/main.swift`

- Add imports if needed:
  ```swift
  import HeadlinerShared
  ```
- Update any references to shared types

### 3. Verify and Clean Up

Once both targets build successfully:

- Remove duplicate type definitions from `CameraExtension/Shared.swift`
- Keep only extension-specific code in `CameraExtension/Shared.swift` (if any)
- Or delete `CameraExtension/Shared.swift` entirely if all code has been moved

## Shared Module Contents

### `HeadlinerShared/Identifiers.swift`

```swift
enum Identifiers: String {
  case appGroup = "group.378NGS49HA.com.dannyfrancken.Headliner"
  case orgIDAndProduct = "com.dannyfrancken.Headliner"
}
```

### `HeadlinerShared/Notifications.swift`

- `NotificationName` enum with Darwin notification names
- `NotificationManager` class for typed CFNotification helpers

### `HeadlinerShared/OverlaySettings.swift`

- `OverlaySettings` struct with all overlay configuration
- `OverlayPosition`, `OverlayColor` enums
- `OverlayUserDefaultsKeys` constants

### `HeadlinerShared/CaptureSessionManager.swift`

- Full `CaptureSessionManager` class for camera capture handling

## Validation Steps

1. **Build Test**: Both targets should build without errors

   ```bash
   xcodebuild -project Headliner.xcodeproj -scheme Headliner -configuration Debug build
   ```

2. **Runtime Test**: App should launch and camera extension should work normally

3. **Dead Code Check**: Run Periphery to ensure no unused code remains
   ```bash
   periphery scan --project Headliner.xcodeproj --schemes Headliner
   ```

## Expected Warnings

- You may see "Skipping duplicate build file" warnings during the transition - these will resolve once the old `Shared.swift` is properly removed from targets

## Success Criteria

- ✅ Both `Headliner` and `CameraExtension` targets build successfully
- ✅ App launches and extension works normally
- ✅ No duplicate type definitions between `HeadlinerShared/` and `CameraExtension/Shared.swift`
- ✅ Clean Periphery scan (no unused shared code)
- ✅ Single source of truth for all shared types

## Branch

Continue working on: `main-app-cleanup-aug13`

## Notes

- The main app has already been updated and is working correctly
- Focus primarily on updating the `CameraExtension/` to use `HeadlinerShared/`
- Be careful with import statements - you may need to update both files and Xcode target membership
- Test thoroughly as this affects the core camera extension functionality
