# Camera Extension & Overlay System Documentation

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Overlay System](#overlay-system)
- [Camera Extension Implementation](#camera-extension-implementation)
- [Creating and Modifying Overlays](#creating-and-modifying-overlays)
- [Technical Details](#technical-details)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Overview

The Headliner camera extension provides a virtual camera device that appears in all macOS video conferencing applications (Zoom, Google Meet, Teams, etc.). It streams real camera feed with optional professional overlays rendered in real-time.

### Key Features

- **Real-time video streaming** at 1080p @ 60 FPS
- **SwiftUI overlays** with real-time rendering and live previews
- **App Group synchronization** for seamless overlay updates
- **Hybrid rendering** supporting both SwiftUI and CoreGraphics overlays
- **Thread-safe rendering** using Core frameworks only
- **GPU acceleration** via Metal and Core Image
- **Smart caching** with LRU and time-based expiration
- **Smooth transitions** between overlay presets and aspect ratios

## Architecture

### Component Overview

```
Headliner/
├── Main App                    # User interface & settings
│   ├── AppState.swift          # Central state management
│   ├── Overlay/                # SwiftUI overlay system
│   │   ├── SwiftUIPresetRegistry.swift   # Modern overlay registry
│   │   ├── SwiftUIOverlayRenderer.swift  # SwiftUI → CGImage renderer
│   │   ├── OverlayRenderBroker.swift     # App Group publishing
│   │   └── Presets/SwiftUI/              # SwiftUI overlay implementations
│   └── Views/Components/
│       └── SwiftUIPresetSelectionView.swift # Live preview UI
├── CameraExtension/            # System extension (separate process)
│   ├── CameraExtensionProvider.swift  # Virtual camera implementation
│   └── Rendering/
│       └── CameraOverlayRenderer.swift # Hybrid overlay renderer
└── HeadlinerShared/            # Shared between app and extension
    ├── OverlayModels.swift     # Data models for overlays
    ├── OverlayPresets.swift    # Legacy CoreGraphics presets (fallback)
    ├── OverlayRenderer.swift   # Renderer protocol
    ├── Overlay/SharedOverlayStore.swift # App Group overlay storage
    └── CaptureSessionManager.swift # Camera capture logic
```

### Inter-Process Communication

- **Darwin Notifications**: Real-time signaling between app and extension
- **UserDefaults (App Group)**: Shared settings storage
- **App Group Container**: Pre-rendered overlay image sharing via PNG files
- **No direct IPC**: Extension runs in isolated process for security

## Overlay System

### SwiftUI Overlay Pipeline (Primary)

The modern overlay system uses SwiftUI for flexible, real-time overlay rendering:

#### Architecture Flow

1. **SwiftUI Definition**: Overlays are defined as SwiftUI views implementing `OverlayViewProviding`
2. **Registration**: Presets are registered in `SwiftUIPresetRegistry` with metadata and categories
3. **Dimension Caching**: Extension caches actual pixel buffer size (1920x1080) to App Group
4. **Main App Rendering**: `SwiftUIOverlayRenderer` renders SwiftUI → `CGImage` using cached dimensions
5. **App Group Storage**: `OverlayRenderBroker` writes pixel-perfect rendered overlays to shared container
6. **Darwin Notification**: Real-time notification signals extension of overlay updates
7. **Extension Compositing**: `CameraOverlayRenderer` reads and composites pre-rendered overlays

#### Key Benefits

- **Live Previews**: Real SwiftUI rendering in preset selection UI
- **Performance**: Pre-rendered in main app, composited at ~30 FPS in extension
- **Perfect Scaling**: Automatic pixel buffer dimension sync eliminates scaling artifacts
- **Flexibility**: Full SwiftUI layout and styling capabilities
- **Caching**: 30-second LRU cache with memory management
- **Type Safety**: Protocol-based design with compile-time checking

#### Dimension Synchronization

The system automatically synchronizes camera dimensions between the extension and main app:

1. **Extension Initialization**: Camera extension caches actual pixel buffer size (1920x1080) to App Group
2. **Main App Rendering**: `OverlayRenderBroker` reads cached dimensions and renders overlays at exact pixel size
3. **Perfect Compositing**: No scaling artifacts or quality loss during final compositing
4. **Fallback Safety**: Defaults to 1920x1080 if cached dimensions unavailable

### Legacy CoreGraphics System (Fallback)

The legacy system provides fallback rendering when SwiftUI overlays aren't available:

- **Core Graphics Rendering**: Manual drawing with text, shapes, and gradients
- **Direct Extension Rendering**: Real-time rendering in camera extension
- **Backwards Compatibility**: Maintains support for existing presets

### Available Presets

#### 1. Professional (Lower Third)

A broadcast-quality lower third overlay positioned at the bottom of the video.

- **Elements**: Display name + optional tagline
- **Style**: Gradient bar with customizable accent color
- **Position**: Bottom 10-15% of frame
- **Use case**: Business meetings, webinars, presentations

#### 2. Personal (Info Pill)

A compact information pill in the top-left corner.

- **Elements**: City, local time, weather emoji + text
- **Style**: Rounded rectangle with semi-transparent background
- **Position**: Top-left corner
- **Use case**: Casual meetings, remote work

#### 3. None

No overlay - clean video feed only.

### Data Models

#### OverlayPreset

Defines the visual structure with nodes and layout:

```swift
struct OverlayPreset {
    let id: String              // Unique identifier
    let name: String            // Display name
    let nodes: [OverlayNode]    // Visual elements
    let layout: OverlayLayout   // Positioning for different aspects
}
```

#### OverlayNode

Building blocks for overlays:

- **TextNode**: Rendered text with font, color, alignment
- **RectNode**: Solid color rectangle with corner radius
- **GradientNode**: Linear gradient between two colors

#### OverlayTokens

Dynamic values that get replaced in templates:

```swift
struct OverlayTokens {
    var displayName: String     // User's name
    var tagline: String?        // Optional title/role
    var accentColorHex: String  // Hex color for theming
    var aspect: OverlayAspect   // Current aspect ratio
    // Personal preset specific:
    var city: String?
    var localTime: String?
    var weatherEmoji: String?
    var weatherText: String?
}
```

#### NRect (Normalized Rectangle)

Position and size using normalized coordinates (0.0 to 1.0):

```swift
struct NRect {
    var x: CGFloat  // 0.0 = left edge, 1.0 = right edge
    var y: CGFloat  // 0.0 = bottom edge, 1.0 = top edge
    var w: CGFloat  // Width as fraction of container
    var h: CGFloat  // Height as fraction of container
}
```

**Coordinate System**: NRect uses Core Graphics' standard bottom-left origin. This means:

- `y: 0.08` positions elements near the bottom of the screen
- `y: 0.75` positions elements near the top of the screen
- The `toCGRect()` method converts directly to screen coordinates without flipping

## Camera Extension Implementation

### CameraOverlayRenderer

The production renderer (`CameraExtension/Rendering/CameraOverlayRenderer.swift`) implements thread-safe overlay rendering using only Core frameworks.

#### Key Design Decisions

1. **No AppKit Dependencies**

   - AppKit is not thread-safe in camera extensions
   - Uses Core Text, Core Graphics, Core Image instead

2. **Metal Acceleration**

   ```swift
   if let device = MTLCreateSystemDefaultDevice() {
       ciContext = CIContext(mtlDevice: device, options: [...])
   }
   ```

3. **Smart Caching**

   - LRU cache with 6 entry capacity
   - Cache key includes all tokens that affect rendering
   - Thread-safe access via DispatchQueue

4. **Coordinate System Handling**

   - Direct mapping from normalized to screen coordinates
   - Core Text rendering handled without global context flips
   - Bottom-left origin system throughout

5. **Performance Optimizations**
   - Autoreleasepool around render method
   - Pixel snapping for crisp edges
   - GPU-accelerated crossfade transitions
   - Short-circuit for "none" preset

### Rendering Pipeline

1. **Input**: CVPixelBuffer from camera
2. **Token Resolution**: Replace `{displayName}`, `{tagline}`, etc.
3. **Layout Calculation**: Convert NRect to screen coordinates
4. **Cache Check**: Return cached overlay if unchanged
5. **Rendering**: Draw nodes to Core Graphics context
6. **Composition**: Overlay onto video frame using Core Image
7. **Output**: CIImage for display

## Creating and Modifying Overlays

### Creating a New SwiftUI Overlay (Recommended)

1. **Create your SwiftUI view implementing `OverlayViewProviding`:**

```swift
// Headliner/Overlay/Presets/SwiftUI/MyCustomOverlay.swift
import SwiftUI

struct MyCustomOverlay: OverlayViewProviding {
    static let presetId = "swiftui.custom.myoverlay"
    static let defaultSize = CGSize(width: 1280, height: 720)

    func makeView(tokens: OverlayTokens) -> some View {
        VStack {
            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    Text(tokens.displayName)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)

                    if let tagline = tokens.tagline {
                        Text(tagline)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                Spacer()
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.bottom, 32)
            .padding(.horizontal, 40)
        }
    }
}
```

2. **Register your overlay in `SwiftUIPresetRegistry.swift`:**

```swift
// Add to the allPresets array
SwiftUIPresetInfo(
    id: "swiftui.custom.myoverlay",
    name: "My Custom Overlay",
    description: "Custom lower third with glassmorphic background",
    category: .standard,  // or .branded, .creative, .minimal
    provider: MyCustomOverlay()
)
```

3. **That's it!** Your overlay will automatically appear in the UI with live preview.

### Creating a Legacy CoreGraphics Overlay (Fallback Only)

For backwards compatibility, you can still create CoreGraphics overlays in `OverlayPresets.swift` using the traditional node-based system. However, **SwiftUI overlays are strongly recommended** for new development due to their flexibility, live previews, and better maintainability.

### Modifying Existing Overlays

#### Changing Position

Edit the `NRect` values in the layout:

```swift
// Move professional overlay higher (larger y value = higher on screen)
frame: NRect(x: 0.05, y: 0.20, w: 0.9, h: 0.12)
// Note: y: 0.08 = near bottom, y: 0.75 = near top
```

#### Changing Colors

Modify the color hex values:

```swift
colorHex: "#FF0000"     // Red
colorHex: "#00FF0080"   // Semi-transparent green
colorHex: "{accentColor}" // Use dynamic token
```

#### Changing Text

Update the text content or use tokens:

```swift
text: "Static Text"
text: "{displayName} - {tagline}"
text: "🎥 {displayName}"
```

#### Font Weights

Available options: `"ultralight"`, `"thin"`, `"light"`, `"regular"`, `"medium"`, `"semibold"`, `"bold"`, `"heavy"`, `"black"`

### Token System

Tokens are replaced at render time:

- `{displayName}` - User's display name
- `{tagline}` - Optional tagline/title
- `{accentColor}` - Hex color for theming
- `{city}` - Location (personal preset)
- `{localTime}` - Current time (personal preset)
- `{weatherEmoji}` - Weather icon (personal preset)
- `{weatherText}` - Weather description (personal preset)

## Technical Details

### Thread Safety

- Camera extension can be called from multiple threads
- All cache access synchronized via DispatchQueue
- No AppKit usage in render path
- Core frameworks are thread-safe

### Performance Targets

- **< 2ms** overlay rendering at 1080p
- **95%+ cache hit rate** for static overlays
- **60 FPS** streaming without drops
- **< 100MB** memory footprint

### Color Management

- Consistent sRGB color space throughout
- Proper alpha channel handling
- Support for #RRGGBB and #RRGGBBAA formats

### Text Rendering

- System fonts via CTFontDescriptor
- Proper coordinate transform for Core Text
- Alignment support (left, center, right)
- Dynamic font sizing based on container

## Testing

### Testing Overlays

1. **In the Main App:**

   - Use the preview to see overlay rendering
   - Adjust settings and verify real-time updates

2. **In Video Apps:**

   - Start Headliner camera
   - Open Zoom/Meet/Teams
   - Select "Headliner" as camera
   - Verify overlay appears correctly

3. **Performance Testing:**
   - Monitor CPU usage in Activity Monitor
   - Check for smooth 60 FPS playback
   - Verify no memory leaks over time

### Quick Testing Commands

```bash
# Build and run
xcodebuild -scheme Headliner -configuration Debug build

# Check logs for errors
log stream --predicate 'subsystem == "com.dannyfrancken.Headliner"'

# Monitor performance
instruments -t "Time Profiler" -D trace.trace Headliner.app
```

## Troubleshooting

### Overlay Not Appearing

- Verify preset is not "none"
- Check that overlaySettings.isEnabled = true
- Restart camera extension after changes
- Check Console.app for error logs

### Text Rendering Issues

- Ensure proper coordinate transforms
- Verify font weights are valid
- Check color hex format is correct

### Performance Issues

- Reduce overlay complexity
- Check cache hit rate in logs
- Verify Metal acceleration is active
- Clear cache if layouts appear corrupted

### Coordinate Issues

- NRect uses bottom-left origin (same as Core Graphics)
- y: 0 = bottom of screen, y: 1 = top of screen
- Use `toCGRect()` for conversion to screen coordinates
- No coordinate flipping needed

### Extension Not Loading

- App must be in /Applications folder
- Check system extension approval in Settings
- Restart the app after approval
- Check for signing/entitlement issues

## Future Enhancements

Planned improvements:

- [ ] Real weather API integration
- [ ] Core Location for automatic city detection
- [ ] More preset templates (News, Gaming, Education)
- [ ] Custom image/logo support
- [ ] Animated transitions and effects
- [ ] Color picker in main app UI
- [ ] Preset import/export

## Code References

Key files to review:

- `CameraExtension/Rendering/CameraOverlayRenderer.swift` - Main renderer
- `HeadlinerShared/OverlayPresets.swift` - Preset definitions
- `HeadlinerShared/OverlayModels.swift` - Data structures
- `Headliner/AppState.swift` - Settings management
- `CameraExtension/CameraExtensionProvider.swift` - Extension integration
