# Headliner

**Professional Virtual Camera for macOS**

Headliner is a modern virtual camera application for macOS that provides professional-grade video effects and seamless integration with video conferencing apps like Zoom, Google Meet, Teams, and more.

## Features

✨ **Real-time Video Effects**: Apply professional video filters and effects to your camera feed
🎥 **HD Quality Streaming**: Stream in high-definition quality to any compatible application  
🔄 **Multiple Camera Sources**: Support for built-in cameras, external webcams, and iPhone Continuity Camera
⚡ **Low Latency**: Optimized for real-time performance with minimal delay
🎨 **Multiple Moods**: Choose from various artistic effects including New Wave, Berlin, Old Film, Sunset, and more
🛠 **Easy Setup**: Simple one-click installation with guided onboarding

## System Requirements

- macOS 13.0 or later
- Camera permissions
- Administrator access (for system extension installation)

## Installation

1. **Download** the latest release from the releases page
2. **Move** the Headliner app to your `/Applications` folder
3. **Launch** Headliner and follow the onboarding process
4. **Install** the system extension when prompted
5. **Grant** camera permissions when requested

> **Important**: The app must be located in `/Applications` for the system extension to install properly.

## Usage

### First Time Setup

1. Launch Headliner
2. Click "Install System Extension" on the welcome screen
3. Follow the system prompts to approve the extension
4. Select your preferred camera source
5. Start the virtual camera

### Using Headliner in Video Apps

1. Open your video conferencing app (Zoom, Meet, Teams, etc.)
2. Go to video/camera settings
3. Select "Headliner" as your camera source
4. You should now see your video feed with the selected effects

### Applying Effects

1. In the Headliner app, click the "Effects" button
2. Choose from available video effects:
   - **Bypass**: No effects (default)
   - **New Wave**: Retro-style color grading
   - **Berlin**: Cool, urban aesthetic
   - **Old Film**: Vintage film look
   - **Sunset**: Warm, golden tones
   - **Bad Energy**: High contrast, dramatic
   - **Beyond The Beyond**: Surreal effects
   - **Drama**: Cinematic enhancement

### Camera Controls

- **Start Camera**: Begin streaming your video feed
- **Stop Camera**: Stop the virtual camera
- **Camera Source**: Select from available camera devices
- **Effects Panel**: Choose and apply video effects

## Architecture

Headliner consists of two main components:

### Container App (`Headliner/`)
The main user interface built with SwiftUI that provides:
- Modern, professional user interface
- Camera device selection and management
- Effect selection and control
- System extension management
- Real-time preview of video feed

### System Extension (`CameraExtension/`)
A CoreMediaIO Camera Extension that:
- Creates a virtual camera device visible to other applications
- Processes video frames with real-time effects using vImage
- Manages video pipeline and streaming
- Handles communication with the container app

## Technical Details

### Video Processing
- Uses Apple's vImage framework for high-performance image processing
- Real-time histogram specification for color grading effects
- Temporal blur and noise generation for cinematic effects
- 1280x720 HD output resolution at 24fps

### Communication
- Darwin notifications for app-extension communication
- UserDefaults sharing for persistent settings
- Custom CMIO properties for effect control

### Effects Engine
The effects system uses sophisticated image processing techniques:
- **Histogram Specification**: Matches video feed to reference image histograms
- **Temporal Blur**: Adds subtle motion blur for film-like quality
- **Procedural Noise**: Generates film grain and texture
- **Color Grading**: Professional color correction and styling

## Troubleshooting

### Extension Not Installing
- Ensure the app is in `/Applications`
- Check System Preferences > Privacy & Security for pending approvals
- Restart the app and try again

### Camera Not Appearing in Other Apps
- Restart the video conferencing app
- Check that Headliner camera is started in the app
- Verify camera permissions are granted

### Video Quality Issues
- Check your source camera quality
- Ensure adequate lighting
- Try different camera sources
- Restart both apps if issues persist

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/your-username/headliner.git
cd headliner

# Open in Xcode
open Headliner.xcodeproj

# Build and run
# Make sure to configure signing and provisioning profiles
```

### Project Structure

```
Headliner/
├── Headliner/              # Container app
│   ├── Views/              # SwiftUI views and components
│   ├── AppState.swift      # Main app state management
│   ├── ContentView.swift   # Root view controller
│   └── HeadlinerApp.swift  # App entry point
├── CameraExtension/        # System extension
│   ├── CameraExtensionProvider.swift  # Main extension logic
│   ├── Shared.swift        # Shared types and utilities
│   └── Effects/            # Video effects implementation
└── Assets/                 # App icons and resources
```

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **CoreMediaIO**: Camera extension APIs
- **vImage**: High-performance image processing
- **AVFoundation**: Camera capture and video processing
- **SystemExtensions**: System extension management

## Privacy

Headliner processes video locally on your device. No video data is transmitted to external servers. Camera access is only used for the virtual camera functionality and can be revoked at any time through System Preferences.

## License

[Add your license information here]

## Support

If you encounter issues or have questions:
1. Check the troubleshooting section above
2. Review existing GitHub issues
3. Create a new issue with detailed information about your problem

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

---

**Made with ❤️ for the macOS community**
