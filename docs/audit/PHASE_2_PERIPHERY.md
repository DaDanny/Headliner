# Phase 2 — Periphery Scan Results

Ran: `periphery scan --project Headliner.xcodeproj --schemes Headliner`

Actions applied (Main App only):
- Removed PreviewProviders from: `ContentView`, `MainAppView`, `AnimatedBackground`, `CameraPreviewCard`, `CameraSelector`, `StatusCard`, `ModernButton`, `OverlaySettingsView`, `GlassmorphicCard`.
- `ContentView`: removed unused stored property `systemExtensionRequestManager`.
- `OutputImageManager`: removed unused `noVideoImage`.
- `SystemExtensionRequestManager`: mark `postNotification(named:)` and `uninstall()` with `@discardableResult` to silence unused result.
- `AppState.UserDefaultsKeys`: removed unused `hasCompletedOnboarding`.

Remaining (not edited in main app):
- Items in `CameraExtension/*` (ignored per scope): `kWhiteStripeHeight`, `selectedCameraDevice`, several `Shared.swift` helpers (`MoodName`, `PropertyName`, `OverlayColor.displayName`, `OverlayUserDefaultsKeys.userName`, `String.convertedToCMIOObjectPropertySelectorName`).

Next steps:
- Extract shared types to `HeadlinerShared/` and prune unused after consolidation (Phase 3).

