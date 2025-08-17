# Headliner

**Professional Virtual Camera for macOS**

Headliner is a modern virtual camera application for macOS that adds professional overlays to your video feed, seamlessly integrating with video conferencing apps like Zoom, Google Meet, Teams, and more.

## Features

✨ **Real-time Video Streaming**: Low-latency camera pipeline with real-time preview
🎥 **Full HD Quality**: Stream in 1080p @ 60 FPS to any compatible application  
🔄 **Multiple Camera Sources**: Support for built-in cameras, external webcams, and Continuity Camera
📝 **Professional Overlays**: Add customizable lower thirds, info pills, and more to your video
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

### Available Overlay Presets

- **Professional**: Lower third with name and tagline at bottom of screen
- **Personal**: Info pill with location/time/weather at top-left
- **None**: Clean video feed without overlays

### Controls

- **Start/Stop Camera**: Control the virtual camera streaming
- **Camera Selection**: Choose from available camera devices
- **Preset Selection**: Switch between overlay presets
- **Display Name**: Set your name for overlays
- **Tagline**: Add optional title or description
- **Real-time Preview**: See your camera feed with overlays before going live

## Architecture & Technical Details

For detailed information about the camera extension architecture, overlay system, and technical implementation, see:

📖 **[Camera Extension & Overlay System Documentation](docs/CAMERA_EXTENSION_AND_OVERLAYS.md)**

This comprehensive guide covers:

- System architecture and components
- How the overlay system works
- Creating and customizing overlays
- Technical implementation details
- Performance optimizations
- Troubleshooting guide

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
├── Headliner/              # Main application (SwiftUI)
│   ├── Views/              # UI components
│   ├── Managers/           # App services
│   └── AppState.swift      # State management
├── CameraExtension/        # System extension
│   ├── CameraExtensionProvider.swift
│   └── Rendering/          # Overlay renderer
├── HeadlinerShared/        # Shared code
│   ├── OverlayModels.swift
│   ├── OverlayPresets.swift
│   └── CaptureSessionManager.swift
└── docs/                   # Documentation
    └── CAMERA_EXTENSION_AND_OVERLAYS.md
```

For detailed component descriptions, see the [technical documentation](docs/CAMERA_EXTENSION_AND_OVERLAYS.md).

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **CoreMediaIO**: Camera extension APIs
- **AVFoundation**: Camera capture and video processing
- **SystemExtensions**: System extension management

## Privacy

Headliner processes all video locally on your device. No video data is transmitted to external servers. Camera access is required for the virtual camera functionality and can be revoked at any time through System Settings > Privacy & Security > Camera.

## Current Status

✅ **Working Features**:

- Virtual camera appears in all video apps
- 1080p @ 60 FPS streaming with low latency
- Camera selection with device persistence
- Professional overlay presets (Lower Third, Info Pill)
- Customizable display name and tagline
- Beautiful modern UI with animations
- Real-time preview with overlay
- Smooth transitions between presets

🚧 **Known Limitations**:

- App must be in `/Applications` folder for system extension
- Weather/location data currently uses placeholder values
- Color customization requires manual configuration

---

**Built with SwiftUI and ❤️ for macOS**
