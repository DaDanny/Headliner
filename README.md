# Headliner

**Professional Virtual Camera for macOS**

Headliner is a modern virtual camera application for macOS that adds professional overlays to your video feed, seamlessly integrating with video conferencing apps like Zoom, Google Meet, Teams, and more.

## Features

✨ **Real-time Video Streaming**: Low-latency camera pipeline with real-time preview
🎥 **Full HD Quality**: Stream in 1080p @ 60 FPS to any compatible application  
🔄 **Multiple Camera Sources**: Support for built-in cameras, external webcams, and Continuity Camera
📝 **Professional Overlays**: Add customizable lower thirds, info pills, and more to your video
🎨 **Modern UI**: Beautiful SwiftUI interface with animated backgrounds and glassmorphic design
🛠 **Guided Onboarding**: Step-by-step setup process with automatic system extension installation
📍 **Location & Weather**: Real-time city and weather data in overlays (optional)
⚡ **Auto-save Settings**: Modern UX with automatic preference persistence

## System Requirements

- macOS 13.0 or later
- Camera permissions
- Administrator access (for system extension installation)
- Location permissions (optional, for weather/location overlays)

## Installation

1. **Download** the latest release from the releases page
2. **Move** the Headliner app to your `/Applications` folder
3. **Launch** Headliner and follow the guided onboarding process
4. **Install** the system extension when prompted
5. **Grant** camera permissions when requested

> **Important**: The app must be located in `/Applications` for the system extension to install properly.

## Usage

### First Time Setup

Headliner features a streamlined 4-step onboarding process:

1. **Welcome** - Overview and expectations (takes ~2 minutes)
2. **System Extension** - Automatic installation with clear explanations
3. **Camera Setup** - Device selection and overlay preset choice
4. **Personalization** - Display name, tagline, and optional location services

The onboarding only appears when the system extension isn't installed. Once installed, you'll go straight to the main app on subsequent launches.

### Using Headliner in Video Apps

1. Open your video conferencing app (Zoom, Meet, Teams, etc.)
2. Go to video/camera settings
3. Select "Headliner" as your camera source
4. You should now see your Headliner camera feed (with overlays if enabled)

### Available Overlay Presets

- **Professional**: Lower third with name and tagline at bottom of screen
- **Personal**: Info pill with location/time/weather at top-left
- **Clean**: No overlays - just your camera feed
- **Creative**: Coming soon - advanced overlay options

### Controls

- **Start/Stop Camera**: Control the virtual camera streaming
- **Camera Selection**: Choose from available camera devices with native dropdown UI
- **Preset Selection**: Switch between overlay presets with visual preview cards
- **Display Name**: Set your name for overlays (auto-saves as you type)
- **Tagline**: Add optional title or description (auto-saves as you type)
- **Real-time Preview**: See your camera feed with overlays before going live
- **Location Services**: Optional city and weather data in overlays

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

📖 **[Personal Info Subsystem Documentation](docs/PERSONAL_INFO_SUBSYSTEM.md)**

Details about the location and weather features:

- Location services integration
- Weather data providers (WeatherKit & Open-Meteo)
- Automatic refresh system
- App Group persistence for extension access

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

### Onboarding Issues

- If onboarding appears repeatedly, check that the system extension is properly installed
- Try restarting the app after extension installation
- Check System Preferences > Privacy & Security for any pending approvals

## Development

### Building from Source

```bash
# Open in Xcode
open Headliner.xcodeproj

# Build and run (⌘R)
# Note: Configure signing with your Apple Developer account
# The app must run from /Applications for the system extension to work
# SwiftUI previews are included in each View file for development
```

### Project Structure

```
Headliner/
├── Headliner/              # Main application (SwiftUI)
│   ├── Views/              # UI components and their previews
│   │   ├── Components/     # Reusable UI components
│   │   ├── OnboardingView.swift  # Guided setup flow
│   │   ├── MainAppView.swift     # Main application interface
│   │   └── SettingsView.swift    # App configuration
│   ├── Managers/           # App services
│   ├── Services/           # Location, weather, and personal info services
│   ├── ViewModels/         # View-specific state management
│   └── AppState.swift      # Central state management
├── CameraExtension/        # System extension
│   ├── CameraExtensionProvider.swift
│   └── Rendering/          # Overlay renderer
├── HeadlinerShared/        # Shared code between app and extension
│   ├── OverlayModels.swift
│   ├── OverlayPresets.swift
│   ├── CaptureSessionManager.swift
│   └── PersonalInfoModels.swift
└── docs/                   # Documentation
    ├── CAMERA_EXTENSION_AND_OVERLAYS.md
    └── PERSONAL_INFO_SUBSYSTEM.md
```

For detailed component descriptions, see the [technical documentation](docs/CAMERA_EXTENSION_AND_OVERLAYS.md).

### Key Technologies

- **SwiftUI**: Modern declarative UI framework with comprehensive previews
- **CoreMediaIO**: Camera extension APIs
- **AVFoundation**: Camera capture and video processing
- **SystemExtensions**: System extension management
- **CoreLocation**: Location services for weather overlays
- **WeatherKit**: Apple's weather service with Open-Meteo fallback

## Privacy

Headliner processes all video locally on your device. No video data is transmitted to external servers.

**Required Permissions:**

- **Camera**: Required for virtual camera functionality
- **Location** (optional): Used for displaying city and local time in overlays

Weather data is fetched from either Apple's WeatherKit service or the open-source Open-Meteo API. All permissions can be revoked at any time through System Settings > Privacy & Security.

## Current Status

✅ **Working Features**:

- Virtual camera appears in all video apps
- 1080p @ 60 FPS streaming with low latency
- Camera selection with device persistence and native UI
- Professional overlay presets with visual preview cards
- Customizable display name and tagline with auto-save
- Beautiful modern UI with animations and glassmorphic design
- Real-time preview with overlay rendering
- Smooth transitions between presets
- Real location and weather data with automatic updates
- Dual weather providers (WeatherKit + Open-Meteo fallback)
- **NEW**: Streamlined 4-step onboarding flow
- **NEW**: Auto-save settings for seamless UX
- **NEW**: Comprehensive location services component
- **NEW**: Visual overlay preset selection

🚧 **Known Limitations**:

- App must be in `/Applications` folder for system extension
- Color customization requires manual configuration
- Creative overlay preset coming in future updates

---

**Built with SwiftUI and ❤️ for macOS**
