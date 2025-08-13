# Headliner — Phase 0 Report (Main App Only)

## File Inventory (Headliner/)
- App entry: `HeadlinerApp.swift` → creates `SystemExtensionRequestManager` and injects into `ContentView`
- Root view: `ContentView.swift` → owns `@StateObject AppState`; routes to `MainAppView` vs `OnboardingView`
- State: `AppState.swift` (@MainActor ObservableObject)
- Managers:
  - `Managers/SystemExtensionRequestManager.swift` — OS SystemExtension activation and status
  - `Managers/CustomPropertyManager.swift` — device discovery for virtual camera presence
  - `Managers/OutputImageManager.swift` — AVCaptureVideoDataOutput delegate → `CGImage` for preview
- Views:
  - `Views/MainAppView.swift` — primary UI, status cards, camera selector, overlay sheet
  - `Views/OnboardingView.swift` — onboarding and install flow
  - Components: `AnimatedBackground`, `CameraPreviewCard`, `CameraSelector`, `GlassmorphicCard`, `ModernButton`, `OverlaySettingsView`, `StatusCard`

## Feature/Dependency Map
- AppState composes: `SystemExtensionRequestManager`, `CustomPropertyManager`, `OutputImageManager`
- Preview capture: `CaptureSessionManager` (defined in `CameraExtension/Shared.swift`) used by main app for local preview. Delegates frames to `OutputImageManager`.
- Notifications/IPC: `NotificationManager` and `NotificationName` live in `CameraExtension/Shared.swift`. Main app posts via those types.
- Overlay settings: `OverlaySettings` model and related enums live in `CameraExtension/Shared.swift`. AppState loads/saves via `UserDefaults(suiteName: Identifiers.appGroup)`.

## Legacy/Duplicates/Hotspots
- Shared types live in `CameraExtension/Shared.swift` but are used heavily by the main app:
  - `CaptureSessionManager`, `OverlaySettings`, `OverlayPosition`, `OverlayColor`, `NotificationName`, `NotificationManager`, `Identifiers`, `OverlayUserDefaultsKeys`.
  - Recommendation (Phase 3): extract a `HeadlinerShared/` module or local group, referenced by both app and extension.
- Copy in UI still references “effects” (purely copy, no code paths). Suggest text cleanup.
- No references to `SceneIt` or `Ritually` in main app code.

## Suspected Dead/Thin Areas
- `CustomPropertyManager.refreshExtensionStatus()` is currently a no-op; `deviceObjectID` accessor triggers discovery each call. Keep or consolidate into `AppState` in later phases.
- `AppState.waitForExtensionDeviceAppear()` polling duplicates some readiness checks. Accept for now; consider centralizing in an IPC service later (Phase 4/5).

## Notification Usage
- Posts Darwin notifications via `NotificationManager` (extension-side class) and `SystemExtensionRequestManager.postNotification(named:)` convenience.
- Observing: `NSWorkspace.shared.notificationCenter.addObserver` used for `NSApplication.didBecomeActiveNotification` only; no custom observers in the app.

## Exit Criteria Status
- Baseline map created. Duplicated shared types identified for extraction in Phase 3.

