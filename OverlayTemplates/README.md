# Overlay Templates System

This directory contains the developer-focused overlay template system for Headliner. This system allows you and your designer to create and preview overlay templates directly in Xcode without needing to build and run the full app.

## 🎯 Goals

- **Live Xcode Previews**: Design overlays with real-time SwiftUI previews
- **Video Frame Bounds**: See exactly where elements will appear on camera feeds
- **Aspect Ratio Support**: Preview templates in both 16:9 and 4:3 aspect ratios
- **Build-time Compilation**: Templates compile into the final app format automatically

## 📁 Current Structure

```
OverlayTemplates/
├── BaseOverlayTemplate.swift    # Base classes and video frame helpers
├── ProfessionalTemplate.swift   # Professional overlay template
├── PersonalTemplate.swift       # Personal/weather overlay template
└── README.md                    # This file
```

## 🚀 Current Status

✅ **COMPLETED:**

- Base overlay template system with video frame bounds
- Professional and Personal template examples
- Video frame bounds helper for Xcode previews
- Clean build system (no more complex overlay files)
- Working fallback overlays in the app

🔄 **IN PROGRESS:**

- Template compilation system (build script created, needs integration)

⏳ **NEXT STEPS:**

- Integrate templates into the main app build process
- Enable dynamic template discovery and selection
- Add more template examples

## 🎨 How to Use Templates

### 1. Preview in Xcode

Open any template file (e.g., `ProfessionalTemplate.swift`) and use the SwiftUI preview to see how it looks with different aspect ratios and video frame bounds.

### 2. Design New Templates

Create a new file in the `OverlayTemplates/` directory:

- Inherit from `OverlayTemplate` protocol
- Implement required methods: `templateId`, `displayName`, `description`, `previewView`, `compile`
- Use `VideoFrameBounds` helper to show proper video frame positioning

### 3. Test Video Frame Bounds

The `VideoFrameBounds` helper shows:

- **16:9 Widescreen**: Standard modern video format
- **4:3 Standard**: Traditional video format with safety margins
- **Safe zones**: Areas guaranteed to be visible on all devices

## 🔧 Template Compilation

Currently, templates are designed for visual preview in Xcode. The build-time compilation system is being developed to automatically convert these SwiftUI templates into the `OverlayPreset` format used by the camera extension.

## 📱 Current Working Overlays

The app currently uses these built-in overlays:

- **Professional**: Lower third with gradient background and name/tagline
- **Personal**: Weather-integrated pill with location, time, and weather info

## 🚧 Development Notes

- Templates are currently separate from the main app build
- The goal is to integrate them so they automatically compile into usable overlays
- Video frame bounds system ensures templates work correctly in both aspect ratios
- All templates use the existing `OverlayPreset` data structure for compatibility

## 🔮 Future Enhancements

- **Template Marketplace**: Share and download community templates
- **Live Preview**: Real-time preview with actual camera feed
- **Template Categories**: Business, Gaming, Education, etc.
- **Custom Assets**: Support for custom fonts, images, and animations
