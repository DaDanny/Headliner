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

## 🎯 Key Improvements

### Expert Feedback Integration

Based on expert review, the implementation includes these critical improvements:

1. **Real Input Aspect Ratio**: Uses actual camera dimensions instead of hardcoded 4:3
2. **Right-Sized Crop Sets**: Optimized platform crop arrays per mode (balanced uses 4 crops, not 5)
3. **Future-Proof Calculator**: Parameterized output size (not hardcoded 1920×1080)
4. **Face-Avoid Bands**: Smart positioning to avoid covering faces in center of frame
5. **User-Friendly Labels**: "Tile-Safe" instead of "Balanced", "Expanded" instead of "Aggressive"
6. **Debug Overlays**: Visual validation with yellow borders in debug mode
7. **Robust Error Handling**: Graceful fallbacks for missing camera dimensions

### Technical Benefits

- **Adaptive to Camera Hardware**: Works with any camera aspect ratio (16:9, 4:3, etc.)
- **Platform Agnostic**: Calculator accepts any output resolution
- **Face-Aware Positioning**: Components can prefer top/bottom bands over center
- **Visual Debugging**: Easy validation against AspectRatioTestV2 results
- **User-Centric UI**: Layout terminology matches how users think about video calls

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

        var displayName: String {
        switch self {
        case .none: return "Full Frame"
        case .aggressive: return "Expanded"
        case .balanced: return "Tile-Safe (Recommended)"
        case .conservative: return "Ultra-Safe"
        }
    }

    var description: String {
        switch self {
        case .none: return "Use entire frame (may crop in grids)"
        case .aggressive: return "More space, works in most video apps"
        case .balanced: return "Guaranteed visible in Meet/Zoom tiles"
        case .conservative: return "Maximum compatibility, all platforms"
        }
    }
}

struct SafeAreaCalculator {
    // Platform crop aspects based on real-world testing
    private static let commonPlatformCrops: [CGSize] = [
        .init(width: 1, height: 1),   // Square tiles (most restrictive)
        .init(width: 5, height: 4),   // 5:4-ish tiles
        .init(width: 4, height: 3),   // 4:3 tiles
        .init(width: 3, height: 2),   // 3:2 tiles
        .init(width: 16, height: 9)   // Widescreen tiles
    ]

        static func calculateSafeArea(
        mode: SafeAreaMode = .balanced,
        inputAR: CGSize? = nil,
        outputSize: CGSize = CGSize(width: 1920, height: 1080)
    ) -> CGRect {
        let actualInputAR = inputAR ?? CGSize(width: 4, height: 3)

        switch mode {
        case .none:
            return CGRect(x: 0, y: 0, width: 1, height: 1)

        case .aggressive:
            return calculateWithPlatforms(
                inputAR: actualInputAR,
                platforms: [
                    .init(width: 1, height: 1),    // Square tiles
                    .init(width: 16, height: 9)    // Widescreen tiles
                ],
                titleSafeInset: 0.02,
                outputSize: outputSize
            )

        case .balanced:
            return calculateWithPlatforms(
                inputAR: actualInputAR,
                platforms: [
                    .init(width: 1, height: 1),   // Square tiles
                    .init(width: 4, height: 3),   // 4:3 tiles
                    .init(width: 3, height: 2),   // 3:2 tiles
                    .init(width: 16, height: 9)   // Widescreen tiles
                ],
                titleSafeInset: 0.04,
                outputSize: outputSize
            )

        case .conservative:
            return calculateWithPlatforms(
                inputAR: actualInputAR,
                platforms: [
                    .init(width: 1, height: 1),   // Square tiles
                    .init(width: 5, height: 4),   // 5:4 tiles
                    .init(width: 4, height: 3),   // 4:3 tiles
                    .init(width: 3, height: 2),   // 3:2 tiles
                    .init(width: 16, height: 9),  // Widescreen tiles
                    .init(width: 9, height: 16)   // Mobile portrait (rare but happens)
                ],
                titleSafeInset: 0.08,
                outputSize: outputSize
            )
        }
    }

        private static func calculateWithPlatforms(
        inputAR: CGSize,
        platforms: [CGSize],
        titleSafeInset: CGFloat,
        outputSize: CGSize
    ) -> CGRect {

        // Step 1: Fit camera input into output canvas
        let contentSafe = fitRect(content: inputAR, into: outputSize)

        // Step 2: Calculate center crops for each platform
        let cropRects = platforms.map { fitRectInRect(content: $0, inRect: contentSafe) }

        // Step 3: Find intersection = always visible area
        let platformSafe = intersectAll(cropRects)

        // Step 4: Add title-safe padding
        let paddedSafe = inset(platformSafe, pct: titleSafeInset)

        // Step 5: Convert to normalized coordinates (0-1)
        return CGRect(
            x: paddedSafe.minX / outputSize.width,
            y: paddedSafe.minY / outputSize.height,
            width: paddedSafe.width / outputSize.width,
            height: paddedSafe.height / outputSize.height
        )
    }

    // MARK: - Helper Functions (copied from AspectRatioTestV2)

    private static func fitRect(content: CGSize, into container: CGSize) -> CGRect {
        let sx = container.width / max(content.width, 1)
        let sy = container.height / max(content.height, 1)
        let s = min(sx, sy)
        let w = content.width * s
        let h = content.height * s
        let x = (container.width - w) * 0.5
        let y = (container.height - h) * 0.5
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private static func fitRectInRect(content: CGSize, inRect r: CGRect) -> CGRect {
        let sx = r.width / max(content.width, 1)
        let sy = r.height / max(content.height, 1)
        let s = min(sx, sy)
        let w = content.width * s
        let h = content.height * s
        let x = r.minX + (r.width - w) * 0.5
        let y = r.minY + (r.height - h) * 0.5
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private static func intersectAll(_ rects: [CGRect]) -> CGRect {
        guard var acc = rects.first else { return .zero }
        for r in rects.dropFirst() { acc = acc.intersection(r) }
        return acc
    }

    private static func inset(_ r: CGRect, pct: CGFloat) -> CGRect {
        let dx = r.width * pct
        let dy = r.height * pct
        return r.insetBy(dx: dx, dy: dy)
    }
}

// MARK: - Face-Avoid Bands

/// Safe bands that avoid the center where faces typically appear
struct SafeBands {
    let top: CGRect
    let bottom: CGRect
    let left: CGRect
    let right: CGRect
    let center: CGRect // Avoid this area for overlays
}

extension SafeAreaCalculator {
    /// Create safe bands within a safe area that avoid covering faces
    static func makeBands(
        in safeArea: CGRect,
        centerHeightPct: CGFloat = 0.40,
        sideWidthPct: CGFloat = 0.22
    ) -> SafeBands {
        let ch = safeArea.height * max(0, min(1, centerHeightPct))
        let sw = safeArea.width * max(0, min(1, sideWidthPct))

        let center = CGRect(
            x: safeArea.minX,
            y: safeArea.midY - ch/2,
            width: safeArea.width,
            height: ch
        )

        let top = CGRect(
            x: safeArea.minX,
            y: safeArea.minY,
            width: safeArea.width,
            height: center.minY - safeArea.minY
        )

        let bottom = CGRect(
            x: safeArea.minX,
            y: center.maxY,
            width: safeArea.width,
            height: safeArea.maxY - center.maxY
        )

        let left = CGRect(
            x: safeArea.minX,
            y: safeArea.minY,
            width: sw,
            height: safeArea.height
        )

        let right = CGRect(
            x: safeArea.maxX - sw,
            y: safeArea.minY,
            width: sw,
            height: safeArea.height
        )

        return SafeBands(top: top, bottom: bottom, left: left, right: right, center: center)
    }
}
```

#### 1.2 SafeAreaContainer Component

**File**: `Headliner/Overlay/Components/SafeAreaContainer.swift`

```swift
struct SafeAreaContainer<Content: View>: View {
    let mode: SafeAreaMode
    let content: Content

    init(mode: SafeAreaMode = .balanced, @ViewBuilder content: () -> Content) {
        self.mode = mode
        self.content = content()
    }

        var body: some View {
        GeometryReader { geo in
            let settings = getOverlaySettings()
            let inputAR = settings.cameraDimensions.nonZeroAspect
            let safeArea = SafeAreaCalculator.calculateSafeArea(
                mode: mode,
                inputAR: inputAR,
                outputSize: geo.size
            )
            let safeFrame = CGRect(
                x: safeArea.minX * geo.size.width,
                y: safeArea.minY * geo.size.height,
                width: safeArea.width * geo.size.width,
                height: safeArea.height * geo.size.height
            )

            content
                .frame(width: safeFrame.width, height: safeFrame.height)
                .position(x: safeFrame.midX, y: safeFrame.midY)
                .clipped()
            #if DEBUG
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.yellow.opacity(0.6), lineWidth: 1)
                )
            #endif
        }
    }
}

// Helper function to read overlay settings from UserDefaults
func getOverlaySettings() -> OverlaySettings {
    guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
          let data = userDefaults.data(forKey: OverlayUserDefaultsKeys.overlaySettings),
          let settings = try? JSONDecoder().decode(OverlaySettings.self, from: data) else {
        return OverlaySettings() // Return default settings
    }
    return settings
}

// Helper extension to safely convert camera dimensions to aspect ratio
extension CGSize {
    var nonZeroAspect: CGSize? {
        guard width > 0 && height > 0 else { return nil }
        return self
    }
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

**Directory Structure**: `Headliner/Overlay/Components/`

```
Headliner/Overlay/Components/
├── Bars/
│   ├── BottomBar.swift           // Original clean design
│   ├── BottomBarV2.swift         // With profile circle
│   ├── BottomBarCompact.swift    // Minimal version
│   └── BottomBarGlass.swift      // Glassmorphic effect
├── Tickers/
│   ├── WeatherTicker.swift       // Location and weather information
│   ├── TimeTicker.swift          // Current time display
│   └── MetricTicker.swift        // Live metrics (followers, views, etc.)
├── Badges/
│   ├── LogoBadge.swift           // Company/brand logo display
│   ├── StatusBadge.swift         // Live/recording status indicators
│   └── SocialBadge.swift         // Social media handles
└── Utils/
    ├── SafeAreaContainer.swift   // Safe area constraint container
    └── TokenHelpers.swift        // Token processing utilities
```

**Core Component Examples**:

- **Bottom Bars**: Professional name/tagline display with various styling options
- **Tickers**: Weather, time, and metric information displays
- **Badges**: Logo, status, and social media elements
- **Utilities**: Safe area management and token processing

#### 2.2 Component Design Principles

- **Consistent styling** across all components
- **Token-driven content** (user name, colors, etc.)
- **Responsive sizing** based on container
- **Composable design** for mix-and-match usage

#### 2.3 Rapid Component Development Workflow

**Creating Component Variations**:

```swift
// Example: Bottom bar iterations
BottomBar          // Original clean design
BottomBarV2        // With profile circle + accent gradient
BottomBarCompact   // Minimal version for subtle overlays
BottomBarGlass     // Glassmorphic effect for modern look
BottomBarNeon      // Cyberpunk/gaming style
```

**Mix & Match in Presets**:

```swift
Professional      = BottomBar + WeatherTicker
ModernProfessional = BottomBarV2 + WeatherTicker
Minimal           = BottomBarCompact only
Corporate         = BottomBarGlass + LogoBadge + MetricTicker
Gaming            = BottomBarNeon + MetricTicker + StatusBadge
Creator           = BottomBarV2 + SocialBadge + MetricTicker
```

**Development Speed Comparison**:

- **Traditional Approach**: ~2.5 hours per overlay (positioning, rendering, testing)
- **Component Approach**: ~40 minutes per overlay (15min component + 25min preset)
- **Component Reuse**: ~5 minutes per additional preset using existing components

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

**Core Presets** (using component combinations):

- **Professional** - `BottomBar` + `WeatherTicker`
- **Modern Professional** - `BottomBarV2` + `WeatherTicker` + `TimeTicker`
- **Minimal** - `BottomBarCompact` only
- **Corporate** - `BottomBarGlass` + `LogoBadge` + `MetricTicker`
- **Personal** - `BottomBar` + `WeatherTicker` + `TimeTicker`
- **Creator Mode** - `BottomBarV2` + `SocialBadge` + `MetricTicker` + `StatusBadge`
- **Gaming** - `BottomBarNeon` + `MetricTicker` + `StatusBadge`

**Layout Variations** (same components, different positioning):

- **Bottom Focus** - All components in bottom safe area
- **Distributed** - Components spread across top and bottom
- **Corner Layout** - Components in safe area corners
- **Center Stage** - Minimal components, maximum content focus

### Phase 4: User Interface Updates

#### 4.1 Safe Area Settings UI

Add to overlay settings panel:

```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Layout")
        .font(.headline)

    Picker("Layout Mode", selection: $safeAreaMode) {
        ForEach(SafeAreaMode.allCases, id: \.self) { mode in
            Text(mode.displayName).tag(mode)
        }
    }
    .pickerStyle(SegmentedPickerStyle())

    Text(safeAreaMode.description)
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)
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

### Critical Validation Steps

1. **Validate Against AspectRatioTestV2 Results**

   - Compare SafeAreaCalculator output with proven yellow zone from testing
   - Ensure balanced mode matches the intersection area that remained visible across all screenshots
   - Verify calculations produce same results as manual testing

2. **Cross-Platform Testing**

   - **Google Meet**: Gallery view, focus view, different participant counts
   - **Zoom**: Gallery view, speaker view, breakout rooms
   - **Teams**: Gallery view, together mode, spotlight
   - **Other platforms**: Slack, Discord, WebEx for additional validation

3. **Safe Area Mode Verification**

   - **None**: Overlays use full 1920x1080 canvas
   - **Aggressive**: Larger usable area than balanced, still protects against common crops
   - **Balanced**: Matches AspectRatioTestV2 yellow zone exactly
   - **Conservative**: Smaller area than balanced, maximum compatibility

4. **Component Integration Testing**

   - Test all component combinations in different safe area modes
   - Verify components scale properly within safe areas
   - Ensure consistent spacing and alignment

5. **Performance Validation**
   - 60fps rendering maintained with SafeAreaContainer
   - No lag when switching between safe area modes
   - SwiftUI rendering pipeline efficiency preserved

### Reference Implementation Validation

**Key Validation Point**: The `balanced` mode should produce a safe area that exactly matches the yellow zone from your AspectRatioTestV2 testing. If overlays positioned within this calculated safe area are not visible in your original Google Meet screenshots, the implementation needs adjustment.

**Test Command**: Create a validation overlay that draws the calculated safe area boundaries and compare visually with AspectRatioTestV2 results.

## 📝 Success Criteria

### Functional Requirements

- [ ] All overlays remain visible in Google Meet gallery view
- [ ] All overlays remain visible in Zoom gallery view
- [ ] All overlays remain visible in Teams gallery view
- [ ] Users can toggle between safe area modes
- [ ] Component library enables easy preset creation
- [ ] Legacy Core Graphics system removed
- [ ] Performance remains smooth (60fps)

### Implementation Validation Checklist

#### SafeAreaCalculator

- [ ] Balanced mode uses optimized platform crops: `[(1,1), (4,3), (3,2), (16,9)]` (4 crops, not 5)
- [ ] Input aspect ratio reads from camera dimensions with 4:3 fallback
- [ ] Title-safe insets: None=0%, Aggressive=2%, Balanced=4%, Conservative=8%
- [ ] Output size parameterized (not hardcoded 1920×1080)
- [ ] Face-avoid bands implemented with 40% center height, 22% side width
- [ ] Helper functions copied exactly from AspectRatioTestV2

#### SafeAreaContainer

- [ ] Accepts SafeAreaMode parameter
- [ ] Uses GeometryReader for responsive sizing
- [ ] Reads camera dimensions from settings
- [ ] Calculates safe frame from normalized coordinates
- [ ] Centers content within safe area using `.position()`
- [ ] Includes `.clipped()` to prevent content overflow
- [ ] Debug overlay with yellow border in DEBUG builds

#### Settings Integration

- [ ] SafeAreaMode added to OverlaySettings with `.balanced` default
- [ ] Settings read from App Group UserDefaults
- [ ] Settings UI includes mode picker with descriptions
- [ ] Mode changes immediately affect overlay rendering

#### Component System

- [ ] Organized directory structure (Bars/, Tickers/, Badges/, Utils/)
- [ ] All components accept consistent token parameters
- [ ] Components work within any safe area mode
- [ ] Easy component swapping in presets (BottomBar → BottomBarV2)

### Critical Validation

**🎯 The balanced mode safe area must exactly match the yellow zone from AspectRatioTestV2 testing. If not, the calculation logic needs debugging.**

---

This comprehensive implementation plan ensures Headliner overlays work reliably across all major video conferencing platforms while maintaining the flexibility and performance of the existing SwiftUI rendering system. The detailed code examples and validation steps provide everything needed for accurate implementation.
