# Floating Overlay Controller - Implementation Guide

## Overview

This document outlines how to implement a floating window for quick overlay preset switching, building on the existing preset management infrastructure.

## Architecture

The preset management system has been designed with reusability in mind. All core functionality is available through AppState methods that can be called from any view.

## Reusable Methods in AppState

The following methods are available for any view (including a future floating window):

```swift
// Switch to a different preset
appState.selectPreset("professional")  // or "personal", "none"

// Update overlay tokens (customization)
let tokens = OverlayTokens(
    displayName: "John Doe",
    tagline: "Senior Developer",
    accentColorHex: "#007AFF",
    aspect: .widescreen
)
appState.updateOverlayTokens(tokens)

// Switch aspect ratio
appState.selectAspectRatio(.widescreen)  // or .fourThree

// Get current state
let currentPreset = appState.currentPresetId
let currentAspect = appState.currentAspectRatio
```

## Implementing the Floating Window

### Step 1: Create FloatingOverlayController View

```swift
import SwiftUI

struct FloatingOverlayController: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            // Preset Quick Switcher
            HStack {
                PresetQuickButton(icon: "person.text.rectangle",
                                 presetId: "professional",
                                 appState: appState)
                PresetQuickButton(icon: "location.circle",
                                 presetId: "personal",
                                 appState: appState)
                PresetQuickButton(icon: "video",
                                 presetId: "none",
                                 appState: appState)
            }

            // Aspect Ratio Toggle
            HStack {
                AspectButton(aspect: .widescreen, appState: appState)
                AspectButton(aspect: .fourThree, appState: appState)
            }
        }
        .padding(12)
        .background(VisualEffectBlur())
        .cornerRadius(12)
    }
}
```

### Step 2: Create NSWindow for Floating Panel

```swift
class FloatingPanelWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure window properties
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Set up content view
        let hostingView = NSHostingView(
            rootView: FloatingOverlayController(appState: appState)
        )
        contentView = hostingView
    }
}
```

### Step 3: Window Management in AppState

Add these properties and methods to AppState:

```swift
// Add to AppState
private var floatingWindow: FloatingPanelWindow?

func showFloatingController() {
    if floatingWindow == nil {
        floatingWindow = FloatingPanelWindow()
    }
    floatingWindow?.makeKeyAndOrderFront(nil)
}

func hideFloatingController() {
    floatingWindow?.close()
    floatingWindow = nil
}

func toggleFloatingController() {
    if floatingWindow?.isVisible == true {
        hideFloatingController()
    } else {
        showFloatingController()
    }
}
```

## Quick Implementation Components

### PresetQuickButton

```swift
struct PresetQuickButton: View {
    let icon: String
    let presetId: String
    @ObservedObject var appState: AppState

    var body: some View {
        Button(action: {
            appState.selectPreset(presetId)
        }) {
            Image(systemName: icon)
                .foregroundColor(
                    appState.currentPresetId == presetId
                        ? .accentColor
                        : .secondary
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(presetName)
    }

    var presetName: String {
        switch presetId {
        case "professional": return "Professional"
        case "personal": return "Personal"
        case "none": return "None"
        default: return presetId
        }
    }
}
```

### AspectButton

```swift
struct AspectButton: View {
    let aspect: OverlayAspect
    @ObservedObject var appState: AppState

    var body: some View {
        Button(action: {
            appState.selectAspectRatio(aspect)
        }) {
            Text(aspect == .widescreen ? "16:9" : "4:3")
                .font(.caption)
                .foregroundColor(
                    appState.currentAspectRatio == aspect
                        ? .accentColor
                        : .secondary
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(aspect.displayName)
    }
}
```

## Keyboard Shortcuts

Consider adding global keyboard shortcuts for quick switching:

```swift
// In AppDelegate or main app
.keyboardShortcut("1", modifiers: [.command, .shift]) // Professional
.keyboardShortcut("2", modifiers: [.command, .shift]) // Personal
.keyboardShortcut("3", modifiers: [.command, .shift]) // None
.keyboardShortcut("a", modifiers: [.command, .shift]) // Toggle aspect
```

## Menu Bar Integration

Alternatively, consider a menu bar item for quick access:

```swift
// Create NSStatusItem
let statusItem = NSStatusBar.system.statusItem(
    withLength: NSStatusItem.variableLength
)
statusItem.button?.image = NSImage(systemSymbolName: "video.badge.ellipsis")

// Add menu with preset options
let menu = NSMenu()
menu.addItem(withTitle: "Professional",
             action: #selector(selectProfessional),
             keyEquivalent: "1")
// ... add other presets
statusItem.menu = menu
```

## Benefits of This Architecture

1. **Reusability**: All preset management logic is in AppState
2. **Consistency**: Same methods work from any view
3. **Real-time Updates**: Changes immediately reflect in video stream
4. **No Duplication**: Settings view and floating window use same code
5. **Easy Testing**: Can test preset switching from any interface

## Testing

To test the floating window integration:

1. Call `appState.selectPreset()` from the floating window
2. Verify the overlay updates in the camera feed
3. Check that both OverlaySettingsView and floating window stay in sync
4. Test aspect ratio switching with smooth transitions

## Future Enhancements

- Drag to reposition floating window
- Opacity slider for window transparency
- Quick color picker for accent color
- Preset favorites/recent presets
- Thumbnail preview of current overlay
