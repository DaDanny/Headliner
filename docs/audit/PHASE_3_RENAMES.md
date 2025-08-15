# Phase 3 — Naming & Module Consolidation

Goal: eliminate legacy naming and consolidate shared types to a single place consumable by both the main app and the extension.

Planned consolidation (create `HeadlinerShared/` as a local group or Swift package later):

- From `CameraExtension/Shared.swift` move the following into `HeadlinerShared/`:
  - `Identifiers` (app group/org identifiers)
  - `NotificationName` (Darwin notifs)
  - `NotificationManager` (typed CFNotification helpers)
  - `OverlaySettings`, `OverlayPosition`, `OverlayColor`, `OverlayUserDefaultsKeys`
  - `CaptureSessionManager` (consider splitting interface for app vs extension if needed)

Refactors:
- Replace ad-hoc string literals for user defaults keys and notification names with shared constants.
- Keep one authoritative `OverlaySettings` model; remove duplicates.

Steps:
1. Create `HeadlinerShared/` module (local group for now).
2. Extract the types listed above into dedicated files.
3. Update imports in `Headliner/` and `CameraExtension/` to reference `HeadlinerShared`.
4. Build & run app and extension; fix any import cycles.

Acceptance:
- One source of truth for overlay settings and notification names.
- No compile-time references from the main app to `CameraExtension/Shared.swift`.

