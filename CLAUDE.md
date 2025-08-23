# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Headliner is a professional virtual camera application for macOS that provides a clean, low-latency video pipeline with configurable overlays and seamless integration with video conferencing apps. The project consists of two main components:

### Container App (`Headliner/`)
- SwiftUI-based main application that users interact with
- Manages system extension installation, camera selection, and overlay configuration
- Located at `/Applications/Headliner.app` for proper system extension installation
- Main entry point: `HeadlinerApp.swift`, root view: `MainAppView.swift`
- State management: `AppState.swift` coordinates UI, extension, and camera management

### System Extension (`CameraExtension/`)
- CoreMediaIO Camera Extension that creates the virtual camera device
- Streams frames and applies overlay settings read from the shared app group
- Communicates with container app via Darwin notifications and UserDefaults
- **CRITICAL: Do not modify system extension files, entitlements, or Info.plist files**

## Build Commands

This is an Xcode project. Common development commands:

- **Build**: `xcodebuild -project Headliner.xcodeproj -scheme Headliner build`
- **Run Tests**: `xcodebuild -project Headliner.xcodeproj -scheme Headliner test`
- **Clean**: `xcodebuild -project Headliner.xcodeproj -scheme Headliner clean`
- **Archive for Release**: `xcodebuild -project Headliner.xcodeproj -scheme Headliner archive`

The build scheme includes a post-action that copies the built app to `/Applications/` for proper system extension functionality.

## Architecture Details

### Communication Between Components
- **Darwin Notifications**: App-to-extension communication for starting/stopping camera, overlay updates
- **UserDefaults (App Group)**: Shared settings storage using suite `378NGS49HA.com.dannyfrancken.Headliner`
- **Custom CMIO Properties**: Extension property management via `CustomPropertyManager`

### Video Pipeline & Overlays
- Container app captures preview using `CaptureSessionManager` (shared in `HeadlinerShared/`)
- Extension streams to the virtual camera and reads overlay settings from the app group
- Target output: 1280x720 to virtual camera device

### Key Managers
- `AppState`: Main state coordination and camera management
- `SystemExtensionRequestManager`: Handles system extension install/uninstall and Darwin posts
- `CustomPropertyManager`: CMIO/AVFoundation detection for extension presence and devices
- `OutputImageManager`: AVCaptureVideoDataOutput delegate for preview frames
- `PersonalInfoPump`: Manages location and weather data updates with automatic refresh
- `LocationPermissionManager`: Handles location services permission and status tracking
- `Logging`: Centralized `logger` (OSLog) in `Headliner/Managers/Logging.swift`

### SwiftUI View Structure
- `ContentView`: Switches between onboarding and main app based on extension status
- `MainAppView`: Main app layout
- `OnboardingView`: System extension installation flow
- `SettingsView`: General app settings including overlay configuration
- `Components/`: Reusable UI components (CameraSelector, StatusCard, PersonalInfoView, etc.)
- `Services/`: Location, weather, and personal info services
- `ViewModels/`: View-specific state management
- `Previews/`: DEBUG-only SwiftUI previews, excluded from Periphery/SwiftLint

## Development Guidelines

### Restrictions
- **Never modify**: Xcode project files, entitlements, Info.plist files, or system extension implementation
- Files excluded via `.cursorignore`: `*.xcodeproj`, `*.entitlements`, `Info.plist`, `*.plist`
- System extension must remain in `/Applications/` for proper installation
- **Avoid git commands**: Do not use git commands for commits, branches, or other version control operations

### Camera Integration
- Uses AVFoundation for camera device discovery and capture
- Filters out "Headliner" virtual camera from available devices
- Supports built-in cameras, external webcams, iPhone Continuity Camera, Desk View Camera
- Camera selection persisted in UserDefaults and shared with extension

### Overlays System
- Overlay settings (`OverlaySettings`) and models (`OverlayModels`, `OverlayPresets`) live in `HeadlinerShared/`
- Modern token-based preset system with `OverlayTokens` for dynamic data replacement
- Settings are encoded to the app group by the container app and loaded by the extension on update
- Supports preset switching, aspect ratio adaptation (16:9, 4:3), and dynamic personal info integration

### Testing
- Unit tests: `HeadlinerTests.xctest`
- UI tests: `HeadlinerUITests.xctest`
- Test apps can be built but main focus should be on `Headliner` target

## App Group Configuration

The app uses App Group `378NGS49HA.com.dannyfrancken.Headliner` for container-extension communication. Settings shared include:
- Selected camera device ID
- Overlay settings (isEnabled, userName, position, colors)
- Personal info data (location, weather, time) for dynamic overlays
- Extension readiness status via `ExtensionProviderReady` flag

## Troubleshooting Notes

- Extension installation requires app to be in `/Applications/`
- Camera permissions required for both preview and virtual camera functionality
- System extension approval required in System Preferences > Privacy & Security
- Darwin notification system used for real-time communication between app and extension

## Developer Utilities

- Format: `swiftformat Headliner`
- Lint: `swiftlint lint --quiet`
- Dead code: `periphery scan --project Headliner.xcodeproj --schemes Headliner`