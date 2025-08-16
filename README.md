# Headliner

**Professional Virtual Camera for macOS**

Headliner is a modern virtual camera application for macOS that provides a clean video pipeline with overlay capabilities, seamlessly integrating with video conferencing apps like Zoom, Google Meet, Teams, and more.

## Features

✨ **Real-time Video Streaming**: Low-latency camera pipeline with real-time preview
🎥 **Full HD Quality**: Stream in 1080p @ 60 FPS to any compatible application  
🔄 **Multiple Camera Sources**: Support for built-in cameras, external webcams, Continuity Camera, and DeskView cameras
⚡ **Professional Overlays**: Add customizable name and version overlays to your video feed
🎨 **Modern UI**: Beautiful SwiftUI interface with animated backgrounds and glassmorphic design
🛠 **Easy Setup**: Guided onboarding with automatic system extension installation

## System Requirements

- macOS 13.0 or later
- Camera permissions
- Administrator access (for system extension installation)

## Installation

1. **Download** the latest release from the releases page
2. **Move** the Headliner app to your `/Applications` folder
3. **Launch** Headliner and follow the onboarding process
4. **Install** the system extension when prompted
5. **Grant** camera permissions when requested

> **Important**: The app must be located in `/Applications` for the system extension to install properly.

## Usage

### First Time Setup

1. Launch Headliner
2. Click "Install System Extension" on the welcome screen
3. Follow the system prompts to approve the extension
4. Select your preferred camera source
5. Start the virtual camera

### Using Headliner in Video Apps

1. Open your video conferencing app (Zoom, Meet, Teams, etc.)
2. Go to video/camera settings
3. Select "Headliner" as your camera source
4. You should now see your Headliner camera feed (with overlays if enabled)

### Controls

- **Start/Stop Camera**: Control the virtual camera streaming
- **Camera Selection**: Choose from available camera devices (built-in, external, Continuity)
- **Overlay Settings**: Configure your display name, position, colors, and visibility
- **Real-time Preview**: See your camera feed with overlays before going live

## Architecture

Headliner consists of two main components:

### Container App (`Headliner/`)

The main user interface built with SwiftUI that provides:

- Modern, professional user interface
- Camera device selection and management
- Overlay configuration
- System extension management
- Real-time preview of video feed

### System Extension (`CameraExtension/`)

A CoreMediaIO Camera Extension that:

- Creates a virtual camera device visible to other applications
- Manages video pipeline and streaming of the camera feed
- Reads overlay settings via shared app group and Darwin notifications
- Handles communication with the container app

## Technical Details

### Inter-Process Communication

- **Darwin Notifications**: Real-time communication between app and extension
- **UserDefaults (App Group)**: Shared settings storage for camera selection and overlay configuration
- **Shared Code**: Common functionality in `HeadlinerShared/` used by both targets

### Video Pipeline

- **Capture**: `CaptureSessionManager` handles camera device selection and capture session
- **Streaming**: CoreMediaIO extension provides virtual camera visible to other apps
- **Overlays**: Real-time overlay rendering with customizable text, position, and styling

## Troubleshooting

### Extension Not Installing

- Ensure the app is in `/Applications`
- Check System Preferences > Privacy & Security for pending approvals
- Restart the app and try again

### Camera Not Appearing in Other Apps

- Restart the video conferencing app
- Check that Headliner camera is started in the app
- Verify camera permissions are granted

### Video Quality Issues

- Check your source camera quality
- Ensure adequate lighting
- Try different camera sources
- Restart both apps if issues persist

## Development

### Building from Source

```bash
# Open in Xcode
open Headliner.xcodeproj

# Build and run (⌘R)
# Note: Configure signing with your Apple Developer account
# The app must run from /Applications for the system extension to work
```

### Project Structure

```
Headliner/
├── Headliner/              # Main application
│   ├── Views/              # SwiftUI views
│   │   ├── Components/     # Reusable UI components
│   │   ├── MainAppView.swift
│   │   └── OnboardingView.swift
│   ├── Managers/           # App-specific managers
│   ├── AppState.swift      # Main app state management
│   ├── ContentView.swift   # Root view controller
│   └── HeadlinerApp.swift  # App entry point
├── CameraExtension/        # System extension
│   ├── CameraExtensionProvider.swift  # Virtual camera implementation
│   └── main.swift          # Extension entry point
├── HeadlinerShared/        # Shared code between app and extension
│   ├── CaptureSessionManager.swift    # Camera capture logic
│   ├── Identifiers.swift   # Bundle and app group identifiers
│   ├── Logger.swift        # Centralized logging configuration
│   ├── Notifications.swift # Darwin notification system
│   └── OverlaySettings.swift          # Overlay configuration models
└── Assets/                 # App icons and resources
```

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **CoreMediaIO**: Camera extension APIs
- **AVFoundation**: Camera capture and video processing
- **SystemExtensions**: System extension management

## Privacy

Headliner processes all video locally on your device. No video data is transmitted to external servers. Camera access is required for the virtual camera functionality and can be revoked at any time through System Settings > Privacy & Security > Camera.

## Current Status (MVP)

✅ **Working Features**:

- Virtual camera appears in all video apps
- 1080p @ 60 FPS streaming with low latency
- Camera selection with persistence
- Name and version overlays with customizable positioning
- Beautiful modern UI with animations

🚧 **Known Limitations**:

- App must be in `/Applications` folder for system extension
- Camera changes require restarting the capture session
- Initial camera permission request requires app restart

---

**Built with SwiftUI and ❤️ for macOS**
