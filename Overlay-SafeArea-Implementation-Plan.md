# Overlay Safe Area Implementation Plan

## 🎯 Overview

This document outlines the implementation plan for adding safe area support to Headliner's SwiftUI overlay system. The safe area ensures overlays remain visible across all video conferencing platforms (Google Meet, Zoom, Teams, etc.) regardless of how they crop or display the video feed.

## 📊 Problem Statement

Different video platforms crop video feeds in various ways:

- **Google Meet**: Square tiles, 4:3 tiles, widescreen tiles
- **Zoom**: Gallery view, speaker view, various aspect ratios
- **Teams**: Similar cropping patterns to Meet/Zoom

The current overlay system positions elements without considering these platform-specific crops, potentially making overlays invisible or partially cut off.

## ✅ Proven Solution

Through testing with `AspectRatioTestV2.swift`, we've identified a **guaranteed safe zone** (the yellow area in testing) that remains visible across all tested video platform configurations. This area is calculated by:

1. Fitting camera input (4:3) into output canvas (16:9)
2. Calculating center crops for all common platform aspect ratios
3. Finding the intersection of all possible crop areas
4. Adding title-safe padding for professional appearance

## 🏗️ Implementation Architecture

### Current Pipeline (Perfect for This!)

```
Main App (SwiftUI Rendering) → SharedOverlayStore (App Group) → Camera Extension (Composite)
```

**Key Advantage**: Since SwiftUI rendering happens in the main app, we can easily add safe area calculations without touching the camera extension at all.

## 📋 Implementation Plan

### Phase 1: Core Safe Area System

#### 1.1 Enhanced SafeAreaCalculator

**File**: `HeadlinerShared/OverlayModels.swift`

```swift
enum SafeAreaMode: String, Codable, CaseIterable {
    case none = "none"              // Full frame (no safe area)
    case aggressive = "aggressive"   // Minimal safe area (more space, slight risk)
    case balanced = "balanced"       // Proven yellow zone (default)
    case conservative = "conservative" // Extra safe area (guaranteed visible)
}

struct SafeAreaCalculator {
    static func calculateSafeArea(mode: SafeAreaMode = .balanced) -> CGRect
    // Implementation uses proven logic from AspectRatioTestV2
}
```

#### 1.2 SafeAreaContainer Component

**File**: `Headliner/Overlay/Components/SafeAreaContainer.swift`

```swift
struct SafeAreaContainer<Content: View>: View {
    let mode: SafeAreaMode
    let content: Content

    // Automatically constrains child content to safe area
}
```

#### 1.3 Settings Integration

**File**: `HeadlinerShared/OverlaySettings.swift`

```swift
struct OverlaySettings: Codable {
    // ... existing properties ...
    var safeAreaMode: SafeAreaMode = .balanced
}
```

### Phase 2: Reusable Component Library

#### 2.1 Core Components

**Directory**: `Headliner/Overlay/Components/`

- `BottomBar.swift` - Professional name/tagline display
- `WeatherTicker.swift` - Location and weather information
- `TimeDisplay.swift` - Current time display
- `LogoBadge.swift` - Company/brand logo display
- `MetricChip.swift` - Key metrics or status indicators

#### 2.2 Component Design Principles

- **Consistent styling** across all components
- **Token-driven content** (user name, colors, etc.)
- **Responsive sizing** based on container
- **Composable design** for mix-and-match usage

### Phase 3: Enhanced Overlay Presets

#### 3.1 Updated SwiftUI Presets

All existing SwiftUI presets will be updated to use the component library:

```swift
struct Professional: OverlayViewProviding {
    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()

        SafeAreaContainer(mode: settings.safeAreaMode) {
            VStack {
                Spacer()
                HStack {
                    BottomBar(displayName: tokens.displayName,
                             tagline: tokens.tagline,
                             accentColor: Color(hex: tokens.accentColorHex))
                    Spacer()
                    WeatherTicker(location: tokens.city,
                                 weatherEmoji: tokens.weatherEmoji,
                                 temperature: tokens.weatherText)
                }
                .padding()
            }
        }
    }
}
```

#### 3.2 New Preset Variations

- **Professional** - Full bottom bar with weather
- **Minimal** - Name only
- **Corporate** - Logo + name + metrics
- **Creator** - Name + social handles + subscriber count

### Phase 4: User Interface Updates

#### 4.1 Safe Area Settings UI

Add to overlay settings panel:

```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Safe Area")
        .font(.headline)

    Picker("Safe Area Mode", selection: $safeAreaMode) {
        ForEach(SafeAreaMode.allCases, id: \.self) { mode in
            Text(mode.displayName).tag(mode)
        }
    }
    .pickerStyle(SegmentedPickerStyle())

    Text(safeAreaMode.description)
        .font(.caption)
        .foregroundColor(.secondary)
}
```

#### 4.2 Preview Integration

Update camera preview to show safe area boundaries when configuring overlays.

### Phase 5: Legacy System Removal

#### 5.1 Remove Core Graphics System

- Remove `OverlayPresets.swift` (old Core Graphics presets)
- Remove Core Graphics rendering path from `HybridOverlayRenderer`
- Update camera extension to only use SwiftUI pre-rendered overlays
- Simplify settings to only support SwiftUI presets

#### 5.2 Clean Up

- Remove unused overlay positioning enums
- Remove legacy overlay settings
- Update documentation

## 🎯 Safe Area Modes Explained

### None (Full Frame)

- **Use Case**: Maximum screen real estate
- **Risk**: High - overlays may be cropped on some platforms
- **Safe Area**: Entire 1920x1080 canvas

### Aggressive

- **Use Case**: Power users who want more space
- **Risk**: Medium - protects against most common crops
- **Safe Area**: Protects against square (1:1) and widescreen (16:9) crops only
- **Padding**: 2% title-safe

### Balanced (Default)

- **Use Case**: Recommended for most users
- **Risk**: Low - proven through testing
- **Safe Area**: Intersection of all common platform crops (the yellow zone)
- **Padding**: 4% title-safe

### Conservative

- **Use Case**: Mission-critical scenarios, maximum compatibility
- **Risk**: Minimal - guaranteed visible on all platforms
- **Safe Area**: Extra protection against extreme crops
- **Padding**: 8% title-safe

## 📈 Benefits

### For Users

- **Guaranteed visibility** across all video platforms
- **Flexible options** from conservative to aggressive
- **Professional appearance** with consistent spacing
- **Mix-and-match components** for customization

### For Development

- **No camera extension changes** required
- **Leverages existing SwiftUI pipeline** perfectly
- **Component reuse** reduces development time
- **Easy testing** with visual safe area overlay

### For MVP

- **Removes complexity** of legacy Core Graphics system
- **Focuses on SwiftUI-only** approach
- **Proven safe area calculation** from real-world testing
- **Simple settings** (just one safe area mode picker)

## 🚀 Implementation Order

1. **SafeAreaCalculator & SafeAreaContainer** - Core safe area system
2. **OverlaySettings update** - Add safe area mode setting
3. **Component library** - Build reusable components
4. **Update existing presets** - Use components + safe area
5. **Settings UI** - Add safe area mode picker
6. **Legacy removal** - Remove Core Graphics system
7. **Testing & polish** - Verify across all platforms

## 🧪 Testing Strategy

1. **Use AspectRatioTestV2** to validate safe area calculations
2. **Test across video platforms** (Meet, Zoom, Teams)
3. **Verify all safe area modes** work as expected
4. **Test component combinations** in different presets
5. **Performance testing** with SwiftUI rendering pipeline

## 📝 Success Criteria

- [ ] All overlays remain visible in Google Meet gallery view
- [ ] All overlays remain visible in Zoom gallery view
- [ ] All overlays remain visible in Teams gallery view
- [ ] Users can toggle between safe area modes
- [ ] Component library enables easy preset creation
- [ ] Legacy Core Graphics system removed
- [ ] Performance remains smooth (60fps)

---

This implementation plan ensures Headliner overlays work reliably across all major video conferencing platforms while maintaining the flexibility and performance of the existing SwiftUI rendering system.
