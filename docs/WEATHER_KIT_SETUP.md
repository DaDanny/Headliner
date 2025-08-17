# WeatherKit and Location Services Setup

## Manual Xcode Configuration Required

Since this project excludes Info.plist modifications via .cursorignore, the following steps must be performed manually in Xcode:

### 1. Add WeatherKit Capability
1. Open `Headliner.xcodeproj` in Xcode
2. Select the **Headliner** target (main app target)
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** 
5. Add **WeatherKit** capability

### 2. Add Location Services Usage Description
1. In the same **Headliner** target settings
2. Go to **Info** tab
3. Add the following key-value pair:
   - **Key**: `NSLocationWhenInUseUsageDescription`  
   - **Type**: String
   - **Value**: `"Used to show your city and local time in the overlay."`

### 3. Verify App Group
Ensure the **App Groups** capability is present with identifier:
```
group.378NGS49HA.com.dannyfrancken.Headliner
```

## Development Notes
- WeatherKit requires a valid Apple Developer Team for signing
- If WeatherKit is unavailable (no dev team/capability), the app automatically falls back to Open-Meteo API
- Location permission is requested at runtime when personal info is first fetched
- All personal info is persisted in the App Group for extension access