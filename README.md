# Headliner

**Professional Virtual Camera for macOS**

Headliner is a modern virtual camera application for macOS that adds professional overlays to your video feed, seamlessly integrating with video conferencing apps like Zoom, Google Meet, Teams, and more.

## Features

✨ **Real-time Video Streaming**: Low-latency camera pipeline with real-time preview
🎥 **Full HD Quality**: Stream in 1080p @ 60 FPS to any compatible application  
🔄 **Multiple Camera Sources**: Support for built-in cameras, external webcams, and Continuity Camera
📝 **SwiftUI Overlays**: Modern, real-time SwiftUI overlays with theme system and live rendering
🎨 **Theme System**: Choose between Classic Glass and Midnight Pro themes with consistent styling
🛠 **Guided Onboarding**: Step-by-step setup process with automatic system extension installation
📍 **Location & Weather**: Real-time city and weather data in overlays (optional)
⚡ **Auto-save Settings**: Modern UX with automatic preference persistence
🔧 **Safe Area Support**: Intelligent overlay positioning for different video platforms
📱 **Menu Bar Interface**: Elegant menu bar app with Loom-style selectors and popover preview

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

- **Modern Personal**: Modern overlay with weather ticker and bottom bar
- **Safe Area Testing**: Validation tools for overlay positioning
- **Aspect Ratio Testing**: Tools for testing different video formats
- **Theme Support**: Choose between Classic Glass and Midnight Pro themes

### Menu Bar Interface

**Quick Access from Menu Bar:**
- **Camera Selector**: Elegant dropdown with device type indicators and status badges
- **Overlay Selector**: Navigate to overlay settings with visual feedback
- **Live Preview**: Popover preview showing camera feed with active overlays
- **Status Indicators**: Real-time camera and overlay status at a glance

**Main App Controls:**
- **Start/Stop Camera**: Control the virtual camera streaming
- **Camera Selection**: Choose from available camera devices with native dropdown UI
- **Preset Selection**: Switch between overlay presets with visual preview cards
- **Theme Selection**: Choose between Classic Glass and Midnight Pro themes
- **Display Name**: Set your name for overlays (auto-saves as you type)
- **Tagline**: Add optional title or description (auto-saves as you type)
- **Real-time Preview**: See your camera feed with overlays before going live
- **Location Services**: Optional city and weather data in overlays
- **Safe Area Mode**: Choose overlay positioning strategy for different platforms

## Architecture & Technical Details

For detailed information about the camera extension architecture, overlay system, and technical implementation, see:

📖 **[Camera Extension & Overlay System Documentation](docs/CAMERA_EXTENSION_AND_OVERLAYS.md)**

📖 **[SwiftUI Overlay System Documentation](docs/SWIFTUI_OVERLAY_SYSTEM.md)**

📖 **[Theme System Implementation Plan](docs/THEME_IMPLEMENTATION_PLAN.md)**

These comprehensive guides cover:

- System architecture and components
- How the overlay system works
- Creating and customizing overlays with themes
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
│   │   │   ├── LoomStyleSelector.swift   # Beautiful pill-style selector component
│   │   │   ├── MenuBarCameraSelector.swift # Menu bar camera dropdown
│   │   │   └── CameraPreviewCard.swift   # Live preview with overlay rendering
│   │   ├── OnboardingView.swift  # Guided setup flow
│   │   ├── MainAppView.swift     # Main application interface
│   │   ├── MenuContent.swift     # Menu bar interface content
│   │   └── SettingsView.swift    # App configuration
│   ├── Managers/           # App services
│   ├── Services/           # Location, weather, and personal info services
│   ├── ViewModels/         # View-specific state management
│   │   └── MenuBarViewModel.swift # Menu bar state management
│   └── AppState.swift      # Central state management
├── CameraExtension/        # System extension
│   ├── CameraExtensionProvider.swift
│   └── Rendering/          # Overlay renderer
├── HeadlinerShared/        # Shared code between app and extension
│   ├── OverlayModels.swift
│   ├── OverlayPresets.swift      # Legacy CoreGraphics presets (fallback)
│   ├── Overlay/
│   │   └── SharedOverlayStore.swift  # App Group overlay storage
│   ├── CaptureSessionManager.swift
│   └── PersonalInfoModels.swift
├── Headliner/Overlay/      # SwiftUI overlay system (main app only)
│   ├── SwiftUIPresetRegistry.swift   # Modern overlay preset registry
│   ├── SwiftUIOverlayRenderer.swift  # SwiftUI → CGImage renderer
│   ├── OverlayRenderBroker.swift     # App Group publishing
│   ├── SwiftUI/            # SwiftUI overlay framework
│   │   ├── OverlayViewProviding.swift # Protocol for overlay views
│   │   ├── OverlayCanvas.swift        # SwiftUI render container
│   │   └── OverlayPreviewUtils.swift  # Development utilities
│   └── Presets/SwiftUI/    # SwiftUI overlay implementations
│       ├── StandardLowerThird.swift
│       ├── BrandRibbon.swift
│       └── MetricChipBar.swift
└── docs/                   # Documentation
    ├── CAMERA_EXTENSION_AND_OVERLAYS.md
    └── PERSONAL_INFO_SUBSYSTEM.md
```

For detailed component descriptions, see the [technical documentation](docs/CAMERA_EXTENSION_AND_OVERLAYS.md).

### Key Technologies

- **SwiftUI**: Modern declarative UI framework with real-time overlay rendering via `ImageRenderer`
- **App Groups**: Inter-process communication for sharing rendered overlays and camera dimensions
- **Darwin Notifications**: Lightweight IPC for real-time overlay updates
- **CoreImage**: GPU-accelerated image processing and compositing pipeline
- **Dimension Synchronization**: Automatic caching of actual camera pixel buffer size (1920x1080) for perfect overlay scaling
- **CoreMediaIO**: Camera extension APIs for virtual camera integration
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

## Menu Bar App

Headliner includes a streamlined menu bar interface for quick camera control:

- **Beautiful Design**: Loom-inspired pill-style selectors with glassmorphic backgrounds
- **Smart Chevrons**: Down arrows for dropdowns, right arrows for navigation
- **Live Preview**: Popover showing real-time camera feed with overlays
- **Status Awareness**: Visual indicators showing camera and overlay status
- **Quick Access**: Control camera and overlays without opening the main app

The menu bar app provides instant access to your most-used controls while keeping the interface clean and unobtrusive.

---

**Built with SwiftUI and ❤️ for macOS**
