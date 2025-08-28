Camera Extension Flow
# Headliner CameraExtension - Comprehensive Mermaid Documentation

Based on your Headliner project architecture, here's the detailed visual documentation for debugging your custom CameraExtension implementation.

## 1. Class Diagram - Your Headliner CameraExtension Architecture

This diagram maps your specific implementation structure:

```mermaid
classDiagram
    %% Core Camera Extension Classes (Your Implementation)
    class CameraExtensionProvider {
        +sourceStream: ExtensionStreamSource
        +sinkStream: ExtensionStreamSource
        +isClientConnected: Bool
        +renderedOverlayImage: CGImage?
        +connectClient()
        +disconnectClient()
        +handleCustomProperty(key:value:)
        +sendFrameToSink()
    }

    class ExtensionStreamSource {
        +streamFormat: CMIOExtensionStreamFormat
        +isStreamingEnabled: Bool
        +currentPixelBuffer: CVPixelBuffer?
        +overlayCompositor: OverlayCompositor
        +generateCompositeFrame()
        +publishFrame()
    }

    class OverlayCompositor {
        +overlayRenderer: OverlayRenderer
        +sourceBuffer: CVPixelBuffer?
        +overlayImage: CGImage?
        +compositeOverlayOntoFrame()
        +scaleOverlayForBuffer()
    }

    %% Main App Components (SwiftUI)
    class AppState {
        +captureSessionManager: CaptureSessionManager
        +selectedCamera: CameraDevice?
        +selectedPreset: OverlayPreset
        +isStreamingActive: Bool
        +personalInfo: PersonalInfo
        +notifyExtension()
    }

    class MainAppView {
        +appState: AppState
        +previewRenderer: CameraPreviewCard
        +cameraSelector: LoomStyleSelector
        +overlaySelector: LoomStyleSelector
        +toggleCamera()
        +changePreset()
    }

    class MenuBarViewModel {
        +appState: AppState
        +menuContent: MenuContent
        +isPreviewPopoverShown: Bool
        +cameraDevices: [CameraDevice]
        +showPreviewPopover()
        +handleCameraSelection()
    }

    class OnboardingView {
        +currentStep: OnboardingStep
        +systemExtensionManager: SystemExtensionManager
        +progressToNextStep()
        +installExtension()
    }

    %% Shared Components (HeadlinerShared)
    class CaptureSessionManager {
        +captureSession: AVCaptureSession
        +currentDevice: AVCaptureDevice?
        +videoOutput: AVCaptureVideoDataOutput
        +previewLayer: AVCaptureVideoPreviewLayer?
        +startSession()
        +stopSession()
        +switchCamera(to:)
        +configureCameraForStreaming()
    }

    class SharedOverlayStore {
        +containerURL: URL
        +overlayImageData: Data?
        +cameraPixelBufferSize: CGSize
        +writeOverlayToAppGroup()
        +readOverlayFromAppGroup()
        +writeCameraDimensions()
    }

    class PersonalInfoModels {
        +displayName: String
        +tagline: String?
        +locationInfo: LocationInfo?
        +weatherInfo: WeatherInfo?
    }

    class OverlayModels {
        +overlayPresets: [OverlayPreset]
        +themeSystem: ThemeSystem
        +safeAreaMode: SafeAreaMode
    }

    %% SwiftUI Overlay System (Main App Only)  
    class SwiftUIPresetRegistry {
        +registeredPresets: [String: OverlayPreset]
        +getPreset(identifier:)
        +registerPreset(_:)
    }

    class SwiftUIOverlayRenderer {
        +imageRenderer: ImageRenderer
        +overlayCanvas: OverlayCanvas
        +renderOverlayToImage()
        +scaleForCameraDimensions()
    }

    class OverlayRenderBroker {
        +sharedStore: SharedOverlayStore
        +renderer: SwiftUIOverlayRenderer
        +publishRenderedOverlay()
        +handleDimensionUpdates()
    }

    class StandardLowerThird {
        +personalInfo: PersonalInfo
        +theme: Theme
        +body: some View
    }

    class BrandRibbon {
        +personalInfo: PersonalInfo  
        +theme: Theme
        +body: some View
    }

    class MetricChipBar {
        +personalInfo: PersonalInfo
        +weatherInfo: WeatherInfo?
        +theme: Theme
        +body: some View
    }

    %% UI Components
    class LoomStyleSelector {
        +options: [SelectableOption]
        +selectedValue: Binding
        +style: SelectorStyle
        +onSelectionChanged: (Any) -> Void
    }

    class MenuBarCameraSelector {
        +availableDevices: [CameraDevice]
        +selectedDevice: Binding
        +deviceStatusBadges: [DeviceStatus]
        +showDeviceDetails()
    }

    class CameraPreviewCard {
        +captureSession: AVCaptureSession
        +overlayPreview: AnyView?
        +isRenderingOverlay: Bool
        +renderLivePreview()
    }

    %% Services and Managers
    class LocationService {
        +locationManager: CLLocationManager
        +currentLocation: CLLocation?
        +cityName: String?
        +requestLocationPermission()
        +getCurrentCity()
    }

    class WeatherService {
        +weatherKit: WeatherService
        +openMeteoFallback: OpenMeteoService
        +currentWeather: WeatherInfo?
        +fetchWeatherData()
        +fallbackToOpenMeteo()
    }

    class SystemExtensionManager {
        +extensionIdentifier: String
        +activationRequest: OSSystemExtensionRequest?
        +installationState: ExtensionState
        +installExtension()
        +handleActivationResult()
    }

    %% Notification System
    class NotificationCenter {
        +internalNotifications: InternalNotificationCenter
        +crossAppNotifications: CrossAppNotificationCenter
        +sendCameraUpdate()
        +sendOverlayUpdate()
    }

    class CrossAppNotificationCenter {
        +darwinNotificationCenter: CFNotificationCenter
        +appGroupIdentifier: String
        +postOverlayUpdate()
        +observeExtensionMessages()
    }

    %% Relationships - Extension Architecture
    CameraExtensionProvider ||--o{ ExtensionStreamSource : manages
    ExtensionStreamSource ||--|| OverlayCompositor : uses
    OverlayCompositor --|> SharedOverlayStore : reads from

    %% Main App Architecture
    AppState ||--|| CaptureSessionManager : manages
    AppState ||--|| SharedOverlayStore : writes to
    AppState ||--|| PersonalInfoModels : contains
    
    MainAppView ||--|| AppState : observes
    MainAppView ||--|| LoomStyleSelector : contains
    MainAppView ||--|| CameraPreviewCard : contains
    
    MenuBarViewModel ||--|| AppState : observes
    MenuBarViewModel ||--|| MenuBarCameraSelector : manages
    
    OnboardingView ||--|| SystemExtensionManager : uses

    %% Overlay System Relationships
    SwiftUIPresetRegistry ||--o{ StandardLowerThird : contains
    SwiftUIPresetRegistry ||--o{ BrandRibbon : contains  
    SwiftUIPresetRegistry ||--o{ MetricChipBar : contains
    
    SwiftUIOverlayRenderer ||--|| SwiftUIPresetRegistry : uses
    OverlayRenderBroker ||--|| SwiftUIOverlayRenderer : manages
    OverlayRenderBroker ||--|| SharedOverlayStore : writes to

    %% Service Dependencies
    AppState ||--|| LocationService : uses
    AppState ||--|| WeatherService : uses
    AppState ||--|| NotificationCenter : uses
    
    NotificationCenter ||--|| CrossAppNotificationCenter : contains
    CrossAppNotificationCenter -.-> CameraExtensionProvider : notifies

    %% Shared Data Flow
    SharedOverlayStore -.-> ExtensionStreamSource : provides overlays
    CaptureSessionManager -.-> SharedOverlayStore : provides dimensions
```

## 2. Sequence Diagram - Complete Headliner Workflow

This shows your specific app flow from launch through streaming:

```mermaid
sequenceDiagram
    participant User as User
    participant MenuBar as Menu Bar App
    participant MainApp as Main SwiftUI App  
    participant Onboarding as Onboarding Flow
    participant SysExt as System Extension Manager
    participant AppState as App State
    participant CSM as CaptureSessionManager
    participant OverlayBroker as OverlayRenderBroker
    participant SwiftUIRenderer as SwiftUIOverlayRenderer
    participant SharedStore as SharedOverlayStore
    participant Extension as CameraExtensionProvider
    participant VideoApp as Video Conference App

    %% App Launch and Onboarding
    User->>MenuBar: Launch Headliner
    MenuBar->>MainApp: Check system extension status
    
    alt Extension Not Installed
        MainApp->>Onboarding: Show onboarding flow
        Onboarding->>User: Step 1: Welcome
        User->>Onboarding: Continue
        Onboarding->>User: Step 2: System Extension
        User->>Onboarding: Install Extension
        Onboarding->>SysExt: installExtension()
        SysExt->>System: OSSystemExtensionRequest
        System->>User: Admin password prompt
        User->>System: Enter password
        System->>SysExt: Extension installed
        SysExt->>Onboarding: Installation complete
        Onboarding->>User: Step 3: Camera Setup
        User->>Onboarding: Select camera & preset
        Onboarding->>User: Step 4: Personalization
        User->>Onboarding: Enter name & tagline
        Onboarding->>MainApp: Complete onboarding
    else Extension Already Installed
        MenuBar->>MainApp: Go to main interface
    end

    %% Main App Initialization
    MainApp->>AppState: Initialize app state
    AppState->>CSM: setupCaptureSession()
    CSM->>CSM: Configure AVCaptureSession
    AppState->>SharedStore: Initialize app group storage
    AppState->>OverlayBroker: Initialize overlay rendering

    %% Camera Selection and Preview
    User->>MainApp: Select camera device
    MainApp->>AppState: updateSelectedCamera()
    AppState->>CSM: switchCamera(to: selectedDevice)
    CSM->>CSM: Reconfigure capture session
    CSM->>AppState: Camera switched
    AppState->>SharedStore: writeCameraDimensions()
    
    %% Overlay Configuration
    User->>MainApp: Select overlay preset
    MainApp->>AppState: updateOverlayPreset()
    AppState->>SwiftUIRenderer: renderOverlay(preset, personalInfo)
    SwiftUIRenderer->>SwiftUIRenderer: Generate overlay image
    SwiftUIRenderer->>OverlayBroker: overlayRendered()
    OverlayBroker->>SharedStore: writeOverlayToAppGroup()
    SharedStore->>Extension: Notify overlay updated (Darwin)
    
    %% Personal Information Updates
    User->>MainApp: Update display name
    MainApp->>AppState: updatePersonalInfo()
    AppState->>SwiftUIRenderer: Re-render with new info
    SwiftUIRenderer->>OverlayBroker: overlayRendered()
    OverlayBroker->>SharedStore: writeOverlayToAppGroup()

    %% Start Virtual Camera Streaming
    User->>MainApp: Start Camera button
    MainApp->>AppState: startCameraStreaming()
    AppState->>CSM: startSession()
    CSM->>CSM: captureSession.startRunning()
    AppState->>Extension: Notify start streaming (Darwin)
    Extension->>Extension: Enable stream sources
    
    %% External App Connection
    User->>VideoApp: Select Headliner camera
    VideoApp->>Extension: connectClient()
    Extension->>Extension: isClientConnected = true
    Extension->>SharedStore: readOverlayFromAppGroup()
    Extension->>Extension: Start frame generation loop
    
    loop Frame Streaming
        Extension->>CSM: Request source frame
        CSM->>Extension: Provide CVPixelBuffer
        Extension->>Extension: compositeOverlayOntoFrame()
        Extension->>VideoApp: Send composite frame
    end

    %% Menu Bar Quick Controls
    User->>MenuBar: Open camera selector
    MenuBar->>MainApp: Update camera selection
    MainApp->>AppState: updateSelectedCamera()
    AppState->>CSM: switchCamera()
    CSM->>Extension: New camera active
    
    User->>MenuBar: Show live preview
    MenuBar->>MenuBar: Display preview popover
    MenuBar->>CSM: Get current frame
    CSM->>MenuBar: Provide preview frame

    %% Stop Streaming
    User->>VideoApp: Disconnect or close app
    VideoApp->>Extension: disconnectClient()
    Extension->>Extension: isClientConnected = false
    Extension->>Extension: Stop frame generation
    
    User->>MainApp: Stop Camera button
    MainApp->>AppState: stopCameraStreaming()
    AppState->>CSM: stopSession()
    CSM->>CSM: captureSession.stopRunning()
```

## 3. Component Data Flow - Your Headliner Architecture

This diagram shows how data flows through your specific implementation:

```mermaid
flowchart TD
    %% User Input Layer
    subgraph "User Interface Layer"
        UI1[Menu Bar Interface]
        UI2[Main SwiftUI App]
        UI3[Onboarding Flow]
        UI4[Live Preview Card]
    end

    %% App State Management
    subgraph "State Management"
        AS[AppState ObservableObject]
        MVM[MenuBarViewModel]
        PI[PersonalInfo Store]
        NC[NotificationCenter]
    end

    %% Camera and Media Layer
    subgraph "Camera Management"  
        CSM[CaptureSessionManager]
        AVS[AVCaptureSession]
        AVD[AVCaptureDevice]
        AVO[AVCaptureVideoDataOutput]
    end

    %% Overlay Rendering System
    subgraph "SwiftUI Overlay System"
        SPR[SwiftUIPresetRegistry]
        SOR[SwiftUIOverlayRenderer]
        ORB[OverlayRenderBroker]
        OC[OverlayCanvas]
        
        subgraph "Overlay Presets"
            SLT[StandardLowerThird]
            BR[BrandRibbon] 
            MCB[MetricChipBar]
        end
    end

    %% Shared Data Layer
    subgraph "App Group Storage"
        SOS[SharedOverlayStore]
        AGC[App Group Container]
        DN[Darwin Notifications]
    end

    %% Extension Layer
    subgraph "Camera Extension"
        CEP[CameraExtensionProvider]
        ESS[ExtensionStreamSource]
        OComp[OverlayCompositor]
    end

    %% External Services
    subgraph "External Services"
        LS[LocationService]
        WS[WeatherService] 
        WK[WeatherKit]
        OM[OpenMeteo Fallback]
    end

    %% System Integration
    subgraph "System Layer"
        SE[System Extension Manager]
        VCA[Video Conference Apps]
        CM[CoreMediaIO]
    end

    %% User Interaction Flow
    UI1 -->|Select Camera| AS
    UI1 -->|Show Preview| UI4
    UI2 -->|Configure Settings| AS
    UI3 -->|Install Extension| SE
    UI4 -->|Display Feed| CSM

    %% State Management Flow
    AS -->|Manage Session| CSM
    AS -->|Store Personal Info| PI  
    AS -->|Trigger Notifications| NC
    MVM -->|Observe State| AS

    %% Camera Flow
    CSM -->|Configure| AVS
    AVS -->|Use Device| AVD
    AVS -->|Capture Output| AVO
    AVO -->|Pixel Buffers| SOS

    %% Overlay Rendering Flow
    AS -->|Request Render| ORB
    ORB -->|Use Renderer| SOR
    SOR -->|Get Presets| SPR
    SPR -->|Contains| SLT
    SPR -->|Contains| BR
    SPR -->|Contains| MCB
    SOR -->|Render to Canvas| OC
    OC -->|Generate CGImage| ORB
    ORB -->|Store Result| SOS

    %% Personal Info Integration
    PI -->|Name & Tagline| SLT
    PI -->|Weather Data| MCB
    AS -->|Location Request| LS
    LS -->|Weather Request| WS
    WS -->|Primary| WK
    WS -->|Fallback| OM
    WS -->|Weather Data| PI

    %% App Group Communication
    SOS -->|Write Overlay| AGC
    SOS -->|Write Dimensions| AGC
    SOS -->|Send Notification| DN
    DN -->|Notify Extension| CEP

    %% Extension Processing
    CEP -->|Read Overlay| AGC
    CEP -->|Manage Streams| ESS
    ESS -->|Composite| OComp
    OComp -->|Read Overlay Data| AGC
    OComp -->|Process Frame| CEP

    %% System Integration
    SE -->|Install| CM
    CEP -->|Register with| CM
    CM -->|Available to| VCA
    VCA -->|Select Camera| CEP
    VCA -->|Receive Frames| ESS

    %% Notification Flow
    NC -->|Internal Updates| AS
    NC -->|Cross-App Updates| DN
    DN -.->|Real-time Updates| CEP

    %% Data Persistence
    AS -.->|Auto-save Settings| AGC
    PI -.->|Cache Weather| AGC

    %% Styling
    classDef uiLayer fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef stateLayer fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef cameraLayer fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef overlayLayer fill:#fff8e1,stroke:#f57f17,stroke-width:2px
    classDef sharedLayer fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef extensionLayer fill:#f1f8e9,stroke:#689f38,stroke-width:2px
    classDef serviceLayer fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef systemLayer fill:#efebe9,stroke:#5d4037,stroke-width:2px

    class UI1,UI2,UI3,UI4 uiLayer
    class AS,MVM,PI,NC stateLayer
    class CSM,AVS,AVD,AVO cameraLayer
    class SPR,SOR,ORB,OC,SLT,BR,MCB overlayLayer
    class SOS,AGC,DN sharedLayer
    class CEP,ESS,OComp extensionLayer
    class LS,WS,WK,OM serviceLayer
    class SE,VCA,CM systemLayer
```

## 4. State Diagram - Your Headliner App States

This shows the specific states your Headliner app can be in:

```mermaid
stateDiagram-v2
    [*] --> LaunchCheck : App Launch

    state LaunchCheck {
        [*] --> CheckingExtension : Check System Extension
        CheckingExtension --> ExtensionInstalled : Extension Found
        CheckingExtension --> ExtensionMissing : No Extension
        
        ExtensionInstalled --> MainApp : Go to Main Interface
        ExtensionMissing --> OnboardingRequired : Start Onboarding
    }

    LaunchCheck --> Onboarding : Extension Missing
    LaunchCheck --> MainInterface : Extension Installed

    state Onboarding {
        [*] --> Welcome : Step 1
        Welcome --> SystemExtensionStep : Step 2
        SystemExtensionStep --> InstallingExtension : User Confirms
        InstallingExtension --> AdminAuth : Request Admin Access
        AdminAuth --> ExtensionInstalling : Password Entered
        ExtensionInstalling --> CameraSetup : Installation Success
        ExtensionInstalling --> InstallationError : Installation Failed
        InstallationError --> SystemExtensionStep : Retry
        CameraSetup --> Personalization : Step 3 Complete
        Personalization --> OnboardingComplete : Step 4 Complete
    }

    Onboarding --> MainInterface : Complete

    state MainInterface {
        [*] --> CameraStopped : Initial State
        
        state CameraStopped {
            [*] --> SelectingCamera : Choose Camera Device
            [*] --> ConfiguringOverlay : Choose Overlay Preset
            [*] --> UpdatingPersonalInfo : Edit Name/Tagline
            
            SelectingCamera --> CameraSelected : Device Chosen
            ConfiguringOverlay --> OverlayConfigured : Preset Selected
            UpdatingPersonalInfo --> PersonalInfoUpdated : Auto-saved
        }
        
        CameraStopped --> CameraStarting : Start Camera Button

        state CameraStarting {
            [*] --> InitializingSession : Setup AVCaptureSession
            InitializingSession --> RenderingOverlay : Session Ready
            RenderingOverlay --> PublishingToAppGroup : Overlay Rendered
            PublishingToAppGroup --> CameraReady : Data Published
            InitializingSession --> StartupError : Session Failed
            RenderingOverlay --> RenderError : Overlay Failed
            StartupError --> CameraStopped : Handle Error
            RenderError --> CameraStopped : Handle Error
        }
        
        CameraStarting --> CameraActive : Success
        CameraStarting --> CameraStopped : Error

        state CameraActive {
            [*] --> StreamingReady : Extension Available
            StreamingReady --> ClientConnected : External App Connects
            ClientConnected --> ActiveStreaming : Frames Flowing
            
            ActiveStreaming --> OverlayUpdating : Change Preset
            ActiveStreaming --> CameraSwitching : Change Device
            ActiveStreaming --> PersonalInfoUpdating : Edit Info
            
            OverlayUpdating --> ActiveStreaming : Overlay Updated
            CameraSwitching --> ActiveStreaming : Camera Switched
            PersonalInfoUpdating --> ActiveStreaming : Info Updated
            
            ClientConnected --> StreamingReady : Client Disconnects
            StreamingReady --> CameraActive : Wait for Client
        }
        
        CameraActive --> CameraStopped : Stop Camera Button
        CameraActive --> SystemInterrupted : System Issues
    }

    state MenuBarStates {
        MenuBarIdle --> CameraSelection : Open Camera Selector
        MenuBarIdle --> PreviewShowing : Show Live Preview
        MenuBarIdle --> OverlayNavigation : Navigate to Overlays
        
        CameraSelection --> MenuBarIdle : Selection Made
        PreviewShowing --> MenuBarIdle : Preview Closed
        OverlayNavigation --> MainInterface : Open Main App
    }

    state SystemInterrupted {
        [*] --> ExtensionError : Extension Crashed  
        [*] --> CameraInUse : Device Busy
        [*] --> MemoryPressure : System Overloaded
        [*] --> PermissionRevoked : User Revoked Access
        
        ExtensionError --> MainInterface : Restart Extension
        CameraInUse --> MainInterface : Device Available
        MemoryPressure --> MainInterface : Resources Available  
        PermissionRevoked --> PermissionRequest : Re-request Access
        
        PermissionRequest --> MainInterface : Permission Granted
        PermissionRequest --> [*] : Permission Denied
    }

    state ErrorStates {
        [*] --> OnboardingError : Onboarding Failed
        [*] --> CameraError : Camera Issues
        [*] --> OverlayError : Overlay Rendering Failed
        [*] --> ExtensionError : System Extension Issues
        [*] --> NetworkError : Weather/Location Failed
        
        OnboardingError --> Onboarding : Retry Onboarding
        CameraError --> MainInterface : Reset Camera
        OverlayError --> MainInterface : Reset Overlays
        ExtensionError --> LaunchCheck : Restart App
        NetworkError --> MainInterface : Use Cached Data
    }

    MainInterface --> [*] : Quit App
    SystemInterrupted --> [*] : Force Quit
    ErrorStates --> [*] : Unrecoverable Error

    %% Extension States (runs separately)
    state ExtensionLifecycle {
        ExtensionIdle --> ExtensionActivated : System Activation
        ExtensionActivated --> WaitingForClient : Ready for Connections
        WaitingForClient --> ClientConnected : Video App Connects
        ClientConnected --> StreamingFrames : Active Frame Generation
        StreamingFrames --> ClientConnected : Client Disconnects
        ClientConnected --> ExtensionActivated : All Clients Disconnect
        ExtensionActivated --> ExtensionIdle : System Deactivation
    }
```

## 5. Debugging Focus Areas

Based on your implementation, here are the key debugging areas with their relationships:

```mermaid
mindmap
  root((Headliner Debug Areas))
    System Extension
      Installation Issues
        Code Signing Problems
        Admin Permissions
        App Location Requirements
      Runtime Issues
        Extension Crashes
        Memory Leaks
        Frame Generation Errors
    Camera Pipeline
      AVCaptureSession Issues
        Device Selection Problems
        Session Configuration Errors
        Thread Safety Issues
      Frame Processing
        Buffer Management
        Performance Bottlenecks
        Color Space Issues
    Overlay System
      SwiftUI Rendering
        ImageRenderer Performance
        View Update Cycles
        Memory Usage
      App Group Communication
        File Write Permissions
        Data Synchronization
        Darwin Notifications
    Inter-Process Communication
      Main App ↔ Extension
        Notification Delivery
        Shared Storage Access
        Timing Issues
      Menu Bar ↔ Main App
        State Synchronization
        UI Updates
        Quick Control Actions
    External App Integration
      Video Conference Apps
        Camera Selection Issues
        Format Compatibility
        Frame Rate Problems
      System Integration
        CoreMediaIO Registration
        Virtual Camera Visibility
        Stream Format Negotiation
```

## Key Implementation Notes for Debugging

### Critical Debug Points:
1. **System Extension Installation**: Check logs with `subsystem:com.dannyfrancken.headliner category:Extension`
2. **Frame Generation**: Monitor `category:CaptureSession` for pipeline issues
3. **App Group Communication**: Watch `category:notifications.crossapp` for IPC problems
4. **Overlay Rendering**: Track SwiftUI rendering performance and memory usage
5. **External App Integration**: Test with multiple video apps for compatibility

### Common Issues to Watch:
- **Threading**: Ensure AVCaptureSession operations stay on the session queue
- **Memory Management**: Watch for retain cycles in the extension
- **File Permissions**: Verify App Group container access rights
- **Timing**: Handle async operations between app and extension properly
- **Error Recovery**: Implement robust error handling for system interruptions
