# SwiftUI Overlay System Documentation

## Overview

Headliner's SwiftUI overlay system provides a modern, flexible way to create professional video overlays using declarative SwiftUI code. This system replaces the legacy CoreGraphics approach with live previews, better performance, and easier development.

## Architecture

### Core Components

```
SwiftUI Overlay Pipeline:
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ SwiftUI Views   │ -> │ ImageRenderer    │ -> │ CGImage Cache   │
│ (OverlayView    │    │ (Main Thread)    │    │ (LRU + Time)    │
│  Providing)     │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        |
                                                        v
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Camera Feed     │ <- │ CoreImage        │ <- │ App Group       │
│ (Virtual Camera)│    │ Compositing      │    │ PNG Storage     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              ^                        ^
                              |                        |
                       Camera Extension         Darwin Notification
```

### Key Files

- **`SwiftUIPresetRegistry.swift`**: Central registry for all SwiftUI overlays
- **`SwiftUIOverlayRenderer.swift`**: Renders SwiftUI views to CGImage with caching
- **`OverlayRenderBroker.swift`**: Publishes rendered overlays to App Group
- **`SharedOverlayStore.swift`**: App Group storage for pre-rendered overlays
- **`OverlayViewProviding.swift`**: Protocol for SwiftUI overlay implementations

## Creating a New Overlay

### Step 1: Implement OverlayViewProviding

```swift
import SwiftUI

struct MyAwesomeOverlay: OverlayViewProviding {
    static let presetId = "swiftui.category.myawesome"
    static let defaultSize = CGSize(width: 1280, height: 720)
    
    func makeView(tokens: OverlayTokens) -> some View {
        ZStack {
            // Your overlay design here
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tokens.displayName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                        
                        if let tagline = tokens.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                    
                    // Optional: Add time, weather, etc.
                    if let time = tokens.localTime {
                        Text(time)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(20)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
    }
}
```

### Step 2: Register in SwiftUIPresetRegistry

```swift
// In SwiftUIPresetRegistry.swift, add to allPresets array:
SwiftUIPresetInfo(
    id: "swiftui.category.myawesome",
    name: "My Awesome Overlay",
    description: "A beautiful overlay with glassmorphic styling and dynamic content",
    category: .creative,  // Choose: .standard, .branded, .creative, .minimal
    provider: MyAwesomeOverlay()
)
```

### Step 3: That's It!

Your overlay will automatically:
- ✅ Appear in the preset selection UI with live preview
- ✅ Be available for real-time video rendering
- ✅ Support all dynamic tokens (name, tagline, time, weather, etc.)
- ✅ Work with the caching and App Group sync system

## Available Tokens

The `OverlayTokens` object provides dynamic content for your overlays:

```swift
struct OverlayTokens {
    let displayName: String      // User's display name
    let tagline: String?         // Optional tagline/title
    let accentColorHex: String   // Theme color (e.g., "#007AFF")
    let localTime: String?       // Current time (e.g., "2:30 PM")
    let city: String?            // User's city
    let weatherText: String?     // Weather description
    let weatherEmoji: String?    // Weather emoji (☀️, ⛅, etc.)
}
```

Usage in SwiftUI:
```swift
Text(tokens.displayName)
Text(tokens.tagline ?? "")
Color(hex: tokens.accentColorHex) ?? .blue
Text(tokens.localTime ?? "")
```

## Design Guidelines

### Performance Best Practices

1. **Keep it Simple**: Complex animations and effects can impact rendering performance
2. **Use System Fonts**: Better performance and consistency
3. **Leverage SwiftUI Materials**: `.ultraThinMaterial`, `.thinMaterial` for modern glass effects
4. **Optimize Images**: Use SF Symbols instead of custom images when possible

### Visual Guidelines

1. **Contrast**: Ensure text is readable against video backgrounds
2. **Shadows**: Use subtle shadows to improve text legibility
3. **Transparency**: Use materials and opacity for non-intrusive overlays
4. **Responsive Design**: Consider different video aspect ratios
5. **Consistent Padding**: Maintain visual consistency with other overlays

### Example Patterns

#### Glass Lower Third
```swift
VStack {
    Spacer()
    HStack {
        VStack(alignment: .leading) {
            Text(tokens.displayName)
                .font(.headline)
                .foregroundStyle(.white)
            Text(tokens.tagline ?? "")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        Spacer()
    }
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    .padding()
}
```

#### Corner Badge
```swift
VStack {
    HStack {
        Spacer()
        VStack {
            Text(tokens.displayName)
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(8)
        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
        .padding()
    }
    Spacer()
}
```

#### Full Width Banner
```swift
VStack {
    HStack {
        Text(tokens.displayName)
            .font(.headline)
            .foregroundStyle(.white)
        Spacer()
        Text(tokens.localTime ?? "")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
    }
    .padding()
    .background(.black.opacity(0.6))
    Spacer()
}
```

## Categories

Organize your overlays by category for better UX:

- **`.standard`**: Professional lower thirds and standard layouts
- **`.branded`**: Company branding with logos and brand colors  
- **`.creative`**: Artistic designs with animations and unique layouts
- **`.minimal`**: Clean, subtle designs with minimal visual impact

## Testing and Debugging

### Live Previews

SwiftUI overlays automatically get live previews in the preset selection UI. Test your designs by:

1. Building the app
2. Opening overlay settings
3. Viewing your overlay in the preset grid with live preview

### Xcode Previews

Add SwiftUI previews to your overlay files for faster iteration:

```swift
#Preview {
    let tokens = OverlayTokens(
        displayName: "John Doe",
        tagline: "Senior Developer",
        accentColorHex: "#007AFF"
    )
    
    MyAwesomeOverlay()
        .makeView(tokens: tokens)
        .frame(width: 400, height: 300)
        .background(.black)
}
```

### Debugging

Use the HeadlinerLogger for debugging:

```swift
private let logger = HeadlinerLogger.logger(for: .overlays)

func makeView(tokens: OverlayTokens) -> some View {
    logger.debug("Rendering overlay with tokens: \(tokens.displayName)")
    
    return VStack {
        // Your view
    }
}
```

## Migration from CoreGraphics

If you're migrating from the old CoreGraphics system:

### Before (CoreGraphics)
```swift
.text(TextNode(
    text: "{displayName}",
    fontSize: 0.05,
    fontWeight: "bold", 
    colorHex: "#FFFFFF",
    alignment: "left"
))
```

### After (SwiftUI)
```swift
Text(tokens.displayName)
    .font(.system(size: 32, weight: .bold))  // 0.05 * 720 ≈ 36pt
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity, alignment: .leading)
```

### Migration Checklist

- [ ] Convert text nodes to SwiftUI Text views
- [ ] Convert rect nodes to SwiftUI shapes/backgrounds
- [ ] Replace positioning (NRect) with SwiftUI layout (VStack, HStack, etc.)
- [ ] Update colors from hex strings to SwiftUI Color
- [ ] Replace manual token interpolation with direct token usage
- [ ] Test with live previews

## Advanced Features

### Custom Animations

```swift
@State private var isVisible = false

var body: some View {
    VStack {
        // Your content
    }
    .opacity(isVisible ? 1 : 0.8)
    .scaleEffect(isVisible ? 1 : 0.95)
    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isVisible)
    .onAppear {
        isVisible = true
    }
}
```

### Conditional Content

```swift
func makeView(tokens: OverlayTokens) -> some View {
    VStack {
        Text(tokens.displayName)
        
        // Only show tagline if it exists
        if let tagline = tokens.tagline, !tagline.isEmpty {
            Text(tagline)
        }
        
        // Show weather if available
        if let weather = tokens.weatherEmoji {
            HStack {
                Text(weather)
                Text(tokens.weatherText ?? "")
            }
        }
    }
}
```

### Dynamic Styling

```swift
func makeView(tokens: OverlayTokens) -> some View {
    let accentColor = Color(hex: tokens.accentColorHex) ?? .blue
    
    return VStack {
        Text(tokens.displayName)
            .foregroundStyle(.white)
        
        Rectangle()
            .fill(accentColor)
            .frame(height: 4)
    }
}
```

## Troubleshooting

### Common Issues

1. **Overlay not appearing**: Check that it's registered in `SwiftUIPresetRegistry`
2. **Preview not updating**: Clean build folder and rebuild
3. **Performance issues**: Simplify animations and avoid heavy computations in `makeView`
4. **Layout issues**: Test with different screen sizes and aspect ratios

### Debug Logging

Enable overlay system debug logging:
```swift
let logger = HeadlinerLogger.logger(for: .overlays)
logger.debug("My debug message")
```

### Cache Issues

If overlays seem stale, the cache might need clearing:
- Cache expires automatically after 30 seconds
- Different tokens create different cache keys
- Restart the app to clear all caches

---

## Examples Repository

Check out the existing SwiftUI overlays for inspiration:
- `StandardLowerThird.swift` - Professional lower third
- `BrandRibbon.swift` - Company branding overlay
- `MetricChipBar.swift` - Dynamic metrics display

Happy overlay building! 🎨
