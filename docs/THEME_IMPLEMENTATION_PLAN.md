# Theme System Implementation Plan

## Overview

Implementation plan for a consistent, scalable theme system for Headliner overlays. This system will provide two built-in themes ("Classic Glass" and "Midnight Pro") with semantic design tokens for colors, typography, and effects.

## Goals

- ✅ **Consistency**: All overlays use the same design language
- ✅ **User Choice**: Toggle between 2 predefined themes
- ✅ **Scalability**: Easy to add more themes later
- ✅ **Performance**: No runtime overhead, compile-time safety
- ✅ **Apple Patterns**: Uses `@Environment`, `@AppStorage`, `@ObservableObject`

## Implementation Phases

### Phase 1: Foundation (1-2 hours)

#### 1.1 Create Theme System Files

**File: `Headliner/Theme/Theme.swift`**

```swift
import SwiftUI

// MARK: - Core Theme System

struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let colors: ThemeColors
    let typography: ThemeTypography
    let effects: ThemeEffects
}

struct ThemeColors: Equatable {
    // Semantic naming (not descriptive)
    let surface: Color           // glass backgrounds (pills, bars)
    let surfaceStroke: Color     // border/stroke lines
    let surfaceAccent: Color     // accent overlay tints
    let textPrimary: Color       // main text color
    let textSecondary: Color     // secondary/dimmed text
    let accent: Color            // brand/highlight color
    let shadow: Color            // drop shadows
}

struct ThemeTypography: Equatable {
    // Base sizes at 1080p for scaling
    let baseSmall: CGFloat      // 20pt - pills, tickers, small text
    let baseBody: CGFloat       // 22pt - body text, descriptions
    let baseTitle: CGFloat      // 28pt - names, titles, headers
    let baseDisplay: CGFloat    // 40pt - large display text, hero

    // Scaling function for different render sizes
    func scale(for size: CGSize, base: CGFloat = 1080) -> CGFloat {
        max(0.6, min(2.0, size.height / base))
    }

    // Semantic font getters
    func pillFont(for size: CGSize) -> Font {
        .system(size: baseSmall * scale(for: size), weight: .semibold, design: .rounded)
    }

    func bodyFont(for size: CGSize) -> Font {
        .system(size: baseBody * scale(for: size), weight: .medium)
    }

    func titleFont(for size: CGSize) -> Font {
        .system(size: baseTitle * scale(for: size), weight: .bold, design: .rounded)
    }

    func displayFont(for size: CGSize) -> Font {
        .system(size: baseDisplay * scale(for: size), weight: .bold, design: .rounded)
    }
}

struct ThemeEffects: Equatable {
    let blurRadius: CGFloat         // glass blur amount
    let shadowRadius: CGFloat       // drop shadow blur
    let cornerRadius: CGFloat       // rounded corners
    let strokeWidth: CGFloat        // border width
}
```

**File: `Headliner/Theme/BuiltInThemes.swift`**

```swift
import SwiftUI

// MARK: - Built-in Themes

extension Theme {
    static let classic = Theme(
        id: "classic",
        name: "Classic Glass",
        colors: ThemeColors(
            surface: Color.black.opacity(0.50),
            surfaceStroke: Color.white.opacity(0.18),
            surfaceAccent: Color.white.opacity(0.08),
            textPrimary: .white,
            textSecondary: .white.opacity(0.8),
            accent: Color(hex: "#FFD700"), // warm gold
            shadow: .black.opacity(0.45)
        ),
        typography: ThemeTypography(
            baseSmall: 20, baseBody: 22, baseTitle: 28, baseDisplay: 40
        ),
        effects: ThemeEffects(
            blurRadius: 12, shadowRadius: 8, cornerRadius: 18, strokeWidth: 1
        )
    )

    static let midnight = Theme(
        id: "midnight",
        name: "Midnight Pro",
        colors: ThemeColors(
            surface: Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.55),
            surfaceStroke: Color.white.opacity(0.16),
            surfaceAccent: Color(red: 0.32, green: 0.65, blue: 1.0).opacity(0.12),
            textPrimary: .white,
            textSecondary: .white.opacity(0.78),
            accent: Color(red: 0.32, green: 0.65, blue: 1.0), // cool blue
            shadow: .black.opacity(0.5)
        ),
        typography: ThemeTypography(
            baseSmall: 22, baseBody: 24, baseTitle: 30, baseDisplay: 42
        ),
        effects: ThemeEffects(
            blurRadius: 16, shadowRadius: 10, cornerRadius: 20, strokeWidth: 1.5
        )
    )
}
```

**File: `Headliner/Theme/ThemeManager.swift`**

```swift
import SwiftUI

// MARK: - Environment Integration

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = .classic
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    @AppStorage("selectedThemeID") private var storedThemeID = Theme.classic.id
    @Published var current: Theme = .classic

    let availableThemes: [Theme] = [.classic, .midnight]

    init() {
        selectTheme(id: storedThemeID)
    }

    func selectTheme(id: String) {
        current = availableThemes.first { $0.id == id } ?? .classic
        storedThemeID = current.id
    }
}
```

#### 1.2 Integrate with AppState

**Update `AppState.swift`:**

```swift
// Add to AppState class
@Published var themeManager = ThemeManager()
```

**Update `HeadlinerApp.swift`:**

```swift
@main
struct HeadlinerApp: App {
  var body: some Scene {
    WindowGroup {
      let mgr = SystemExtensionRequestManager(logText: "")
      ContentView(
        systemExtensionRequestManager: mgr,
        propertyManager: CustomPropertyManager(),
        outputImageManager: OutputImageManager()
      )
      .frame(minWidth: 1280, maxWidth: 1360, minHeight: 900, maxHeight: 940)
    }
  }
}
```

**Update `ContentView.swift`:**

```swift
extension ContentView: View {
  var body: some View {
    Group {
      if appState.extensionStatus.isInstalled {
        MainAppView(
          appState: appState,
          outputImageManager: outputImageManager,
          propertyManager: propertyManager
        )
      } else {
        OnboardingView(appState: appState)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: appState.extensionStatus.isInstalled)
    .environmentObject(appState.themeManager)
    .environment(\.theme, appState.themeManager.current)
  }
}
```

### Phase 2: Component Examples (2-3 hours)

#### 2.1 Update SimpleWeatherTicker

**Note**: Don't worry about updating existing components or overlays to use the new theme system. Only update the SimpleWeatherTicker and ModernPersonal to use it. I will handle implementing it in other places and use that as a guide.

**File: `Headliner/Overlay/Components/Tickers/SimpleWeatherTicker.swift`**

```swift
import SwiftUI

/// Weather information display with location and temperature
struct SimpleWeatherTicker: View {
    let weatherEmoji: String?
    let temperature: String?

    @Environment(\.theme) private var theme

    init(weatherEmoji: String? = nil, temperature: String? = nil) {
        self.weatherEmoji = weatherEmoji
        self.temperature = temperature
    }

    var body: some View {
        GeometryReader { geometry in
            if hasContent {
                let scale = theme.typography.scale(for: geometry.size)

                HStack(spacing: 8 * scale) {
                    if let emoji = weatherEmoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 28 * scale))
                    }

                    if let temperature = temperature, !temperature.isEmpty {
                        Text(temperature)
                            .font(theme.typography.pillFont(for: geometry.size))
                            .foregroundStyle(theme.colors.textPrimary)
                    }
                }
                .padding(.horizontal, 12 * scale)
                .padding(.vertical, 8 * scale)
                .background(
                    Capsule()
                        .fill(theme.colors.surface)
                        .overlay(
                            Capsule().stroke(theme.colors.surfaceStroke,
                                           lineWidth: theme.effects.strokeWidth * scale)
                        )
                        .shadow(color: theme.colors.shadow,
                               radius: theme.effects.shadowRadius * scale,
                               x: 0, y: 2 * scale)
                )
            }
        }
    }

    private var hasContent: Bool {
        (weatherEmoji?.isEmpty == false) ||
        (temperature?.isEmpty == false)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        SimpleWeatherTicker(
            weatherEmoji: "☀️",
            temperature: "72°F"
        )

        SimpleWeatherTicker(
            temperature: "68°F"
        )

        SimpleWeatherTicker(
            weatherEmoji: "🌧️",
            temperature: "65°F"
        )
    }
    .padding()
    .background(.black)
    .environment(\.theme, .classic)
}
#endif
```

#### 2.2 Update ModernPersonal Preset

**File: `Headliner/Overlay/Presets/SwiftUI/ModernPersonal.swift`**

```swift
import SwiftUI

/// Modern Personal Preset with all the bells and whistles
struct ModernPersonal: OverlayViewProviding {
    static let presetId = "swiftui.modern.personal"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)

        SafeAreaContainer(mode: settings.safeAreaMode) {
            ZStack(alignment: .top) {
                // Theme-aware debug border (only visible in debug themes)
                ThemeAwareDebugBorder()

                VStack {
                    HStack {
                        SimpleWeatherTicker(
                            weatherEmoji: tokens.weatherEmoji,
                            temperature: tokens.weatherText
                        )
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                    Spacer()

                    BottomBarV2(
                        displayName: tokens.displayName,
                        tagline: tokens.tagline,
                        accentColor: accentColor
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// Helper for theme-aware debug visualization
private struct ThemeAwareDebugBorder: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Rectangle()
            .stroke(theme.colors.accent.opacity(0.3), lineWidth: 2)
            .fill(Color.clear)
    }
}

#if DEBUG
#Preview("Classic Theme") {
    ModernPersonal()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .classic)
}

#Preview("Midnight Theme") {
    ModernPersonal()
        .makeView(tokens: OverlayTokens.previewDanny)
        .frame(width: 1920, height: 1080)
        .background(.black)
        .environment(\.theme, .midnight)
}
#endif
```

### Phase 3: Settings Integration (1 hour)

#### 3.1 Add Theme Picker

**Create: `Headliner/Views/Components/ThemePickerView.swift`**

```swift
import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Choose the visual style for your overlays")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Theme", selection: Binding(
                get: { themeManager.current.id },
                set: { themeManager.selectTheme(id: $0) }
            )) {
                ForEach(themeManager.availableThemes) { theme in
                    Text(theme.name).tag(theme.id)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
#Preview {
    ThemePickerView()
        .environmentObject(ThemeManager())
        .padding()
}
#endif
```

#### 3.2 Integrate Theme Picker in Settings

**Update `SettingsView.swift`** (add to existing settings):

```swift
// Add this section to your existing SettingsView
Section {
    ThemePickerView()
} header: {
    Text("Theme")
}
```

## File Structure

After implementation, the structure will be:

```
Headliner/
├── Theme/
│   ├── Theme.swift              // Core theme structures
│   ├── BuiltInThemes.swift      // Classic & Midnight themes
│   └── ThemeManager.swift       // State management + Environment
├── Views/
│   └── Components/
│       └── ThemePickerView.swift   // Settings UI
├── Overlay/
│   ├── Components/
│   │   └── Tickers/
│   │       └── SimpleWeatherTicker.swift  // ✅ Updated with theme
│   └── Presets/
│       └── SwiftUI/
│           └── ModernPersonal.swift       // ✅ Updated with theme
```

## Testing Strategy

1. **Theme Switching**: Verify both themes work in Settings
2. **Persistence**: Restart app, ensure selected theme persists
3. **Previews**: Confirm SwiftUI previews work with both themes
4. **Scaling**: Test different render sizes (720p, 1080p, 4K)
5. **Components**: Verify SimpleWeatherTicker renders correctly in both themes

## Benefits

✅ **Immediate Consistency**: Components using theme look unified  
✅ **User Choice**: Simple theme toggle in settings  
✅ **Developer Experience**: Clear examples for future components  
✅ **Performance**: No runtime overhead, compile-time safety  
✅ **Scalable**: Easy to add branded themes later (Bonusly, etc.)  
✅ **Apple Standards**: Follows SwiftUI environment patterns

## Migration Notes

- **Don't worry about updating existing components or overlays to use the new theme system**
- **Only update the SimpleWeatherTicker and ModernPersonal to use it**
- **I will handle implementing it in other places and use that as a guide**
- Use the updated `SimpleWeatherTicker` as the template for other components
- Theme scaling works automatically across all render sizes
- All themes maintain accessibility and readability standards

## Future Expansion

Once this foundation is solid, consider:

- **Brand Themes**: Add company-specific color schemes
- **Spacing Tokens**: Standardize padding, margins, gaps
- **Animation Themes**: Consistent motion design
- **Export/Import**: JSON theme sharing for teams

