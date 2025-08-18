# Personal Info Subsystem

The Personal Info subsystem provides realtime location and weather updates for the Headliner overlay system.

## Features

- **Location Services**: Fetches user's city and local time using CoreLocation
- **Weather Updates**: Current weather conditions with emoji and text description
- **Dual Weather Providers**: 
  - Primary: WeatherKit (requires Apple Developer signing)
  - Fallback: Open-Meteo API (works without special capabilities)
- **App Group Persistence**: Data stored as JSON in shared UserDefaults for extension access
- **Automatic Updates**: Refreshes every 15 minutes with manual refresh option

## Architecture

### Core Components

1. **PersonalInfoModels.swift** - Data structures and protocols
2. **LocationService.swift** - CoreLocation wrapper with async/await
3. **WeatherProviderWeatherKit.swift** - WeatherKit integration
4. **WeatherProviderOpenMeteo.swift** - Open-Meteo fallback API
5. **PersonalInfoLive.swift** - Service composer with automatic fallback
6. **PersonalInfoPump.swift** - Timer-based updates and persistence
7. **PersonalInfoSettingsVM.swift** - UI view model
8. **SettingsView.swift** - User interface controls

### Data Flow

```
LocationService + WeatherProvider → PersonalInfoLive → PersonalInfoPump → App Group JSON
                                                                           ↓
                                                              CameraExtension reads for overlays
```

## Setup Requirements

### Manual Xcode Configuration

Since Info.plist files are excluded from code modifications, perform these steps manually:

1. **Add WeatherKit Capability**:
   - Select Headliner target → Signing & Capabilities → + Capability → WeatherKit

2. **Add Location Usage Description**:
   - Target → Info tab → Add key: `NSLocationWhenInUseUsageDescription`
   - Value: `"Used to show your city and local time in the overlay."`

### Environment Variables

- `WEATHERKIT_DISABLED=1` - Forces Open-Meteo fallback for development

## App Group Storage

Personal info is stored in the app group UserDefaults with key:
- `overlay.personalInfo.v1` - JSON-encoded PersonalInfo struct

## Usage

The system starts automatically when the app launches. Users can:
- Toggle location services in Settings
- Manually refresh weather data
- View automatic updates every 15 minutes

## Error Handling

- **Location Denied**: Returns partial info (time + default weather)
- **Network Issues**: Continues with last known data
- **WeatherKit Unavailable**: Automatically falls back to Open-Meteo
- All errors are logged to console for debugging

## Development

### Testing Manual Fallback

```bash
# Force Open-Meteo fallback
export WEATHERKIT_DISABLED=1
```

### Verification

1. Check App Group UserDefaults for `overlay.personalInfo.v1` key
2. Verify JSON structure matches PersonalInfo model
3. Test with location services enabled/disabled
4. Verify automatic 15-minute updates