# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Headliner is a professional virtual camera application for macOS that provides real-time video effects and seamless integration with video conferencing apps. The project consists of two main components:

### Container App (`Headliner/`)
- SwiftUI-based main application that users interact with
- Manages system extension installation, camera selection, and video effects
- Located at `/Applications/Headliner.app` for proper system extension installation
- Main entry point: `HeadlinerApp.swift`, root view: `MainAppView.swift`
- State management: `AppState.swift` coordinates UI, extension, and camera management

### System Extension (`CameraExtension/`)
- CoreMediaIO Camera Extension that creates the virtual camera device
- Processes video frames with real-time effects using vImage framework
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
- **Darwin Notifications**: App-to-extension communication for starting/stopping camera, effect changes
- **UserDefaults (App Group)**: Shared settings storage using suite `378NGS49HA.com.dannyfrancken.Headliner`
- **Custom CMIO Properties**: Extension property management via `CustomPropertyManager`

### Video Processing Pipeline
- Container app captures preview using `CaptureSessionManager` 
- Extension processes frames with vImage framework for effects
- Supports multiple effects: New Wave, Berlin, Old Film, Sunset, Bad Energy, Beyond The Beyond, Drama
- 1280x720 HD output at 60fps to virtual camera device

### Key Managers
- `AppState`: Main state coordination and camera management
- `SystemExtensionRequestManager`: Handles system extension installation/uninstallation
- `CustomPropertyManager`: Manages CMIO device properties and extension detection
- `OutputImageManager`: Handles video frame processing for preview

### SwiftUI View Structure
- `MainAppView`: Root application view with onboarding/main UI switching
- `OnboardingView`: System extension installation flow
- `Components/`: Reusable UI components (CameraSelector, StatusCard, etc.)
- `OverlaySettings`: User name overlay configuration

## Development Guidelines

### Restrictions
- **Never modify**: Xcode project files, entitlements, Info.plist files, or system extension implementation
- Files excluded via `.cursorignore`: `*.xcodeproj`, `*.entitlements`, `Info.plist`, `*.plist`
- System extension must remain in `/Applications/` for proper installation

### Camera Integration
- Uses AVFoundation for camera device discovery and capture
- Filters out "Headliner" virtual camera from available devices
- Supports built-in cameras, external webcams, iPhone Continuity Camera, Desk View Camera
- Camera selection persisted in UserDefaults and shared with extension

### Effects System
- Reference images stored in `CameraExtension/` (1.jpg through 7.jpg)
- Histogram specification and color grading applied via vImage
- Effect changes communicated via Darwin notifications

### Testing
- Unit tests: `HeadlinerTests.xctest`
- UI tests: `HeadlinerUITests.xctest`
- Test apps can be built but main focus should be on `Headliner` target

## App Group Configuration

The app uses App Group `378NGS49HA.com.dannyfrancken.Headliner` for container-extension communication. Settings shared include:
- Selected camera device ID
- Overlay settings (username, enabled state)
- Effect preferences

## Troubleshooting Notes

- Extension installation requires app to be in `/Applications/`
- Camera permissions required for both preview and virtual camera functionality
- System extension approval required in System Preferences > Privacy & Security
- Darwin notification system used for real-time communication between app and extension