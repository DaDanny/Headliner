# Headliner Log Filtering Guide

## Quick Console.app Setup

### 1. Open Console.app
- Press `Cmd+Space`, type "Console", press Enter

### 2. Filter by Subsystem
In the search bar, use:
```
subsystem:com.dannyfrancken.headliner
```

### 3. Filter by Specific Categories
Use these filters to focus on specific areas:

#### Camera Issues
```
subsystem:com.dannyfrancken.headliner category:CaptureSession
```

#### Notification Issues
```
subsystem:com.dannyfrancken.headliner category:notifications.crossapp
```

#### Extension Issues
```
subsystem:com.dannyfrancken.headliner category:Extension
```

#### System Extension Management
```
subsystem:com.dannyfrancken.headliner category:SystemExtension
```

#### Overlay Issues
```
subsystem:com.dannyfrancken.headliner category:Overlays
```

#### Diagnostic Messages (Memory, Health, FPS)
```
subsystem:com.dannyfrancken.headliner category:Diagnostics
```

### 4. Available Log Categories
- `Application` - Main app lifecycle
- `AppState` - Application state changes
- `SystemExtension` - Extension installation/management
- `CustomProperty` - Camera extension properties
- `Extension` - Camera extension runtime
- `CaptureSession` - Camera capture and preview
- `Overlays` - Overlay rendering
- `notifications.internal` - In-app notifications only
- `notifications.crossapp` - App-to-extension notifications only
- `Analytics` - Usage tracking
- `Performance` - Performance metrics
- `Diagnostics` - System health, memory usage, frame rate monitoring

## Xcode Console Filtering

If you're running in Xcode, filter the console with:
```
📷  # Camera operations
📡  # Notifications
🔧  # System extension
🎨  # Overlays
⚡  # Performance
```

## Temporary Log Reduction

To reduce logging temporarily, you can comment out debug statements in specific files:

### Camera Service Logs
Edit `Headliner/Services/CameraService.swift` and comment out verbose debug lines.

### Notification Logs  
The notification system has focused categories - use the filters above instead of disabling.

## Common Debug Scenarios

### Camera Not Switching
```
subsystem:com.dannyfrancken.headliner category:CaptureSession OR category:Extension
```

### Extension Not Installing
```
subsystem:com.dannyfrancken.headliner category:SystemExtension
```

### Notifications Not Working
```
subsystem:com.dannyfrancken.headliner category:notifications.crossapp
```

### Preview Not Updating
```
subsystem:com.dannyfrancken.headliner category:CaptureSession
```