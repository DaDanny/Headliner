# Overlay Preset System

## Overview

The Headliner overlay preset system provides professional, customizable overlays that appear in your virtual camera feed. The system supports multiple preset templates with smooth transitions and aspect ratio support.

## Available Presets

### 1. Professional (Lower Third)

A broadcast-quality lower third overlay perfect for professional meetings and presentations.

- **Features**: Display name and optional tagline
- **Style**: Gradient bar with customizable accent color
- **Best for**: Business meetings, webinars, presentations

### 2. Personal (Location/Time/Weather)

A compact info pill showing your location, local time, and weather.

- **Features**: City, local time, weather emoji + text
- **Style**: Rounded pill in top-left corner
- **Best for**: Casual meetings, remote work, travel

### 3. None/Clean

No overlay - just your clean video feed.

- **Best for**: When you want no distractions

## Quick Start

### Enable the Preset System

The easiest way to test the preset system is using the provided script:

```bash
# Enable Professional preset
swift scripts/enable_preset_system.swift professional

# Enable Personal preset
swift scripts/enable_preset_system.swift personal

# Disable overlays (None preset)
swift scripts/enable_preset_system.swift none
```

After running the script, restart the Headliner app to see the changes.

## Architecture

### Data Models

- **OverlayPreset**: Defines the visual structure with nodes and layouts
- **OverlayTokens**: Dynamic data (name, tagline, colors, etc.)
- **OverlayNode**: Building blocks (text, rectangles, gradients)
- **NRect**: Normalized coordinates (0-1) for responsive layouts

### Rendering Pipeline

1. **OverlayRendererCI**: Core Image-based renderer
2. **Aspect Ratio Support**: 16:9 (widescreen) and 4:3 (standard)
3. **Crossfade Transitions**: Smooth 250ms transitions between aspects
4. **Performance**: Cached layouts, GPU acceleration, 720p30 target

### Components

```
HeadlinerShared/
├── OverlayModels.swift       # Core data models
├── OverlayPresets.swift      # Preset definitions
├── OverlayRenderer.swift     # Renderer protocol & helpers
└── OverlaySettings.swift     # Settings with preset support

CameraExtension/
├── OverlayRendererCI.swift   # Core Image renderer
└── CameraExtensionProvider.swift # Integration point
```

## Customization

### Modifying Tokens

The overlay system uses tokens that can be customized:

```swift
// Professional preset tokens
displayName: "Your Name"
tagline: "Your Title"
accentColorHex: "#007AFF"  // Blue

// Personal preset tokens
city: "Pittsburgh"
localTime: "4:10 PM"  // Auto-updated
weatherEmoji: "☀️"
weatherText: "Sunny"
```

### Creating New Presets

To add a new preset, edit `HeadlinerShared/OverlayPresets.swift`:

```swift
static let myCustomPreset = OverlayPreset(
    id: "custom",
    name: "My Custom Preset",
    nodes: [
        // Define your nodes here
    ],
    layout: OverlayLayout(
        widescreen: [...],  // 16:9 placements
        fourThree: [...]    // 4:3 placements
    )
)
```

## Performance

- **Target**: 720p @ 30fps on M3 MacBook
- **Caching**: Layouts cached per token configuration
- **GPU**: Core Image with hardware acceleration
- **Transitions**: Smooth crossfades without frame drops

## Testing

### In Google Meet / Zoom

1. Start Headliner and enable camera streaming
2. Open Google Meet or Zoom
3. Select "Headliner" as your camera
4. You should see your overlay on the video feed

### Switching Presets Live

While streaming, you can switch presets:

1. Run the enable script with a different preset
2. The overlay will update in real-time
3. Aspect changes trigger smooth crossfades

## Production Implementation

The overlay preset system is the only implementation in production. There is no legacy system or backwards compatibility mode - all overlays use the modern preset system with Core frameworks for optimal performance and thread safety.

## Future Enhancements

Planned improvements for future releases:

- [ ] Real weather API integration (OpenWeatherMap)
- [ ] Core Location for automatic city detection
- [ ] More preset templates (News, Gaming, Education)
- [ ] Custom image/logo support
- [ ] Animated transitions and effects
- [ ] Main app UI for preset selection

## Troubleshooting

### Overlay Not Appearing

- Ensure `isEnabled = true` in settings
- Check that a preset is selected (not "none")
- Restart the camera extension after changes

### Performance Issues

- Reduce overlay complexity
- Check CPU/GPU usage in Activity Monitor
- Ensure hardware acceleration is enabled

### Aspect Ratio Issues

- Verify aspect setting matches your camera
- Check that layouts are defined for both aspects
- Clear cache if layouts appear stretched
