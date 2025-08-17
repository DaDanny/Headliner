# Onboarding Flow Implementation

This document describes the comprehensive onboarding system implemented for Headliner, which addresses all requirements from [GitHub Issue #11](https://github.com/DaDanny/Headliner/issues/11).

## Overview

The new onboarding system provides a guided, two-step setup process that helps users:
1. Install and approve the camera system extension 
2. Start the camera and optionally personalize overlays

## Architecture

### State Machine (`OnboardingPhase`)

The onboarding flow is managed by a deterministic state machine with these phases:

- **`preflight`** - App launched, onboarding not started
- **`needsExtensionInstall`** - Extension not present or approved
- **`awaitingApproval`** - User clicked install; waiting for OS approval
- **`readyToStart`** - Extension installed & detected, ready to start camera
- **`startingCamera`** - Camera is spinning up
- **`running`** - Preview live, camera running  
- **`personalizeOptional`** - After running; optional personalization step
- **`completed`** - Onboarding flow completed successfully
- **`error(String)`** - Recoverable error with specific message and recovery actions

### Permission Management (`PermissionStatus`)

Camera permissions are tracked separately:
- **`unknown`** - Permission status not yet determined
- **`authorized`** - User has granted camera access
- **`denied`** - User has denied camera access  
- **`restricted`** - Camera access restricted by system policy

### Components

The onboarding UI is built from reusable components:

- **`StepHeader`** - Header with icon, title, and subtitle for each step
- **`StepCard`** - Main content card with actions and progress indication
- **`StatusNote`** - Small helper text with info/warning/success styling

## Implementation Details

### AppState Integration

The `AppState` class was enhanced with:

- `@Published var onboardingPhase: OnboardingPhase = .preflight`
- `@Published var cameraPermission: PermissionStatus = .unknown`
- `func beginOnboarding()` - Initialize onboarding flow
- `func recomputeOnboardingPhase()` - Update phase based on current states
- `func requestCameraPermissionIfNeeded(completion:)` - Handle camera permissions
- `func completeOnboarding()` - Mark onboarding as finished

All existing methods that change extension or camera status call `recomputeOnboardingPhase()` to ensure consistent state transitions.

### Persistence

- **Onboarding completion**: Tracked via `UserDefaults.standard.bool(forKey: "OnboardingCompleted")`
- **Camera selection**: Persisted in app group UserDefaults for extension access
- **Overlay settings**: Existing persistence in app group UserDefaults maintained

### Error Handling & Recovery

Each error state provides specific recovery actions:

- **Camera access denied**: "Open Privacy Settings" → Direct link to Privacy & Security settings
- **Extension timeout**: Clear instructions to check System Settings → Login Items & Extensions
- **General errors**: "Try Again" restarts the onboarding flow

### Phase-Specific Behavior

#### Installation Phase (Steps 1)
- **UI**: Bullet points explaining what the extension does
- **Primary Action**: "Install & Enable" → Calls `appState.installExtension()`
- **Secondary Action**: "Open System Settings" → Direct link to extensions panel
- **Note**: "This may momentarily reload audio/video services."

#### Approval Phase
- **UI**: Loading indicator with clear instructions
- **Primary Action**: "Recheck" → Calls `appState.refreshCameras()`
- **Timeout Handling**: Specific error message after 60 seconds with recovery instructions

#### Ready to Start (Step 2) 
- **UI**: Camera source selection if multiple cameras available
- **Primary Action**: "Start Camera" → Calls `appState.startCamera()`
- **Permission Check**: Automatic camera permission request with error handling

#### Running Phase
- **UI**: Live camera preview showing exactly what others will see
- **Primary Action**: "Personalize Overlay" → Opens overlay settings sheet
- **Secondary Action**: "Finish" → Completes onboarding without personalization
- **Note**: "Look for 'Headliner' in your video app's camera selection menu."

#### Personalization Phase (Optional Step 3)
- **UI**: Full overlay settings sheet with presets, customization options
- **Integration**: Reuses existing `OverlaySettingsView` updated to use `@EnvironmentObject`
- **Completion**: "Finish" button completes onboarding flow

## User Experience Features

### Visual Design
- **Minimalist approach**: Removed decorative animated backgrounds
- **Focus on clarity**: Clean cards with subtle shadows on neutral background
- **Progress indication**: "Step X of Y" shown in each card corner
- **Consistent styling**: Blue accent color, rounded corners, clear typography

### Accessibility
- **Clear CTAs**: Single primary action per step, never ambiguous
- **Descriptive text**: Each phase has specific title, subtitle, and body content
- **Error feedback**: Specific error messages with actionable recovery steps
- **Loading states**: Clear progress indicators during system operations

### System Integration
- **Deep links**: Direct links to relevant System Settings panels
- **Permission handling**: Graceful camera permission requests and error recovery
- **Extension detection**: Robust polling with timeout handling for OS approval delays
- **App lifecycle**: Proper handling of app backgrounding during approval process

## Technical Implementation

### File Structure
```
Headliner/
├── App/Models/
│   ├── OnboardingPhase.swift          # State machine definition
│   └── PermissionStatus.swift         # Camera permission states
├── Views/
│   ├── OnboardingView.swift           # Main onboarding flow
│   └── Components/
│       ├── StepHeader.swift           # Phase header component
│       ├── StepCard.swift             # Main content card component  
│       ├── StatusNote.swift           # Helper text component
│       └── OverlaySettingsView.swift  # Updated personalization UI
├── AppState.swift                     # Enhanced with onboarding logic
└── ContentView.swift                  # Updated navigation logic
```

### State Transitions

The state machine ensures deterministic transitions:

```swift
// Simplified transition logic
switch (extensionStatus, cameraStatus, cameraPermission) {
case (.unknown/.notInstalled, _, _):           → .needsExtensionInstall
case (.installing, _, _):                      → .awaitingApproval  
case (.installed, .stopped, .authorized):     → .readyToStart
case (.installed, .starting, _):              → .startingCamera
case (.installed, .running, _):               → .running
case (_, _, .denied/.restricted):             → .error(message)
case (.error(let e), _, _):                   → .error(e)
}
```

### Integration Points

- **System Extensions**: Uses existing `SystemExtensionRequestManager`
- **Camera Management**: Integrates with `CaptureSessionManager` for preview
- **Settings**: Reuses `OverlaySettingsView` for personalization
- **Notifications**: Uses Darwin notifications for app-extension communication

## Fulfillment of Requirements

This implementation addresses all requirements from [GitHub Issue #11](https://github.com/DaDanny/Headliner/issues/11):

### ✅ Onboarding Steps
1. **Welcome screen with extension status** - Implemented via phase-specific UI
2. **Camera permissions request** - Integrated permission handling with recovery
3. **Camera device selection with live preview** - Shows camera selector and preview
4. **Overlay preset selection** - Optional personalization step
5. **Success screen with app selection instructions** - Clear completion with usage instructions

### ✅ Acceptance Criteria  
- **Check and request camera permissions** - `PermissionStatus` + `requestCameraPermissionIfNeeded()`
- **Detect extension installation status** - Robust polling with `SystemExtensionRequestManager`
- **Live preview during camera selection** - `CameraPreviewCard` integration
- **Clear instructions for Zoom/Meet setup** - Status notes with usage guidance
- **Skip onboarding if already configured** - UserDefaults persistence + smart detection

### ✅ Technical Notes
- **AVCaptureDevice.authorizationStatus checks** - Wrapped in `PermissionStatus` enum
- **OSSystemExtensionRequest status monitoring** - Enhanced polling with timeout handling
- **UserDefaults for onboarding completion flag** - `"OnboardingCompleted"` key

## Testing & QA

The implementation handles these edge cases:

- **Cold boot with extension not installed** → Flows through install, approval, recheck, ready
- **User cancels installer** → Returns gracefully to `.needsExtensionInstall`
- **Timeout waiting for approval** → Surfaces `.error` with recovery links  
- **Camera permission denied** → Clear error + direct link to privacy settings
- **Device list changes during selection** → Dynamic camera list updates
- **Fast path (already installed)** → Skips directly to `.readyToStart`
- **App backgrounded during approval** → Resumes polling when returning to foreground

## Future Enhancements

Potential improvements for future iterations:

1. **Analytics Integration**: Track onboarding funnel metrics
2. **A/B Testing**: Test different copy and flow variations  
3. **Guided Tours**: Optional tips overlay for first-time main app usage
4. **Troubleshooting**: Built-in diagnostics for common setup issues
5. **Accessibility**: VoiceOver support and keyboard navigation
6. **Localization**: Multi-language support for international users

---

*This onboarding system provides a solid foundation for user acquisition and reduces support burden by guiding users through the setup process with clear, actionable steps.*