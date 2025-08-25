# Modern Onboarding Implementation Plan

## Overview
This document outlines the step-by-step implementation plan for replacing Headliner's existing `OnboardingView.swift` with a modern, modular onboarding experience based on the specification in `modern-onboarding.md`.

## Implementation Strategy
- **Incremental Development**: Build components in dependency order
- **Parallel Testing**: Each component gets a #Preview for immediate visual feedback  
- **Safe Migration**: Keep old OnboardingView.swift for service method reference
- **Service Reuse**: Leverage existing AppCoordinator + service architecture extensively
- **Component Reuse**: Integrate existing UI components (CameraSelector, PersonalInfoView, ModernButton)

## Key Service Integration Points
Based on analysis of `AppCoordinator.swift`, `CameraService.swift`, and existing `OnboardingView.swift`:

**✅ Ready-to-Use Services:**
- `ExtensionService` - Full install/status management with `status` and `statusMessage`
- `CameraService` - Complete camera management with `startOnboardingPreview()` and `currentPreviewFrame`
- `AppCoordinator` - Central orchestration with `installExtension()`, `selectCamera()`, `completeOnboarding()`
- Existing components: `CameraSelector`, `PersonalInfoView`, `ModernButton`

**🔄 Environment Pattern:**
- Use `@Environment(\.appCoordinator)` and `@EnvironmentObject` services
- Apply `.withAppCoordinator()` extension for automatic service injection
- Follow existing pattern: coordinator delegates, services are observed directly

## Phase 1: Foundation Components
*Dependencies: None | Duration: ~2 hours*

### 1.1 Create ModernOnboarding Directory Structure
- [x] Create `Headliner/Views/ModernOnboarding/` directory
- [x] Verify proper Swift package integration

### 1.2 OnboardingStep Enum
**File**: `ModernOnboarding/OnboardingStep.swift`
- [x] Define 5-step enum: welcome, install, personalize, preview, done
- [x] Add title, subtitle, systemImage computed properties
- [x] Implement CaseIterable, Identifiable protocols
- [x] Add #Preview for testing enum values
- [x] **Enhanced with rich content properties**
  - [x] Added `railTitle` for short step rail labels
  - [x] Added `explainerTitle` with friendly H2-style titles
  - [x] Added `explainerSubtitle` with improved copy
  - [x] Added `explainerBullets` array with 3 bullets per step
  - [x] Added `timeEstimate` property for each step
  - [x] Maintained legacy properties for compatibility

### 1.3 Core UI Building Blocks
**File**: `ModernOnboarding/MediaPane.swift`
- [x] Generic container with rounded rectangle styling
- [x] Frame constraints: minWidth: 380, minHeight: 360
- [x] Background with quaternary stroke border
- [x] Add #Preview with sample content

**File**: `ModernOnboarding/StepRail.swift`
- [x] Vertical step progress indicator (180px width)
- [x] Circle indicators with checkmarks for completed steps
- [x] Current step highlighting (bold text, primary color)
- [x] Thinmaterial background with rounded corners
- [x] Add #Preview with mock current step
- [x] Updated to use new `railTitle` property for cleaner labels

**File**: `ModernOnboarding/Components/ExplainerCard.swift` *(NEW)*
- [x] Rich left-panel component with structured content
- [x] Title + subtitle with proper typography hierarchy
- [x] Bullet points with SF Symbol icons and detail text
- [x] Time estimate pill with clock icon
- [x] Optional "Learn more" link support
- [x] 340px width for better content density
- [x] Regular material background with rounded corners

**File**: `ModernOnboarding/Models/ExplainerBullet.swift` *(NEW)*
- [x] Model for structured bullet point data
- [x] Properties: symbol, title, optional detail
- [x] Identifiable and Equatable conformance

## Phase 2: Layout Scaffold
*Dependencies: Phase 1 | Duration: ~1.5 hours*

### 2.1 OnboardingScaffold
**File**: `ModernOnboarding/OnboardingScaffold.swift`
- [x] VStack layout: Header + Body + Footer
- [x] Header: Step icon + title (22pt semibold)
- [x] Body: Generic content area (min height 420)
- [x] Footer: Back/Next buttons with keyboard shortcuts
- [x] Window sizing: 900×600 fixed
- [x] Conditional button states (disabled Back on welcome)
- [x] Primary/secondary button styling logic
- [x] Add #Preview with sample step content

### 2.2 Button State Logic
- [x] Back button: ⌘← shortcut, disabled on welcome
- [x] Next button: ⏎ for primary actions, ⌘→ for secondary
- [x] Dynamic button titles per step
- [x] Primary button styling for Preview/Done steps

## Phase 3: State Management
*Dependencies: Phase 1 | Duration: ~2 hours*

### 3.1 ModernOnboardingViewModel
**File**: `ModernOnboarding/ModernOnboardingViewModel.swift`
- [x] ObservableObject with @Published properties
- [x] @AppStorage integration for step persistence (`HL.onboarding.step`)
- [x] @AppStorage for completion flag (`HL.hasCompletedOnboarding`)
- [x] Current step management with auto-save
- [x] Navigation methods: next(), back()

### 3.2 Install State Management
- [x] Map ExtensionService.status to local InstallState enum
- [x] InstallState enum: unknown, notInstalled, installing, installed, error(String)
- [x] @Published installState property that derives from ExtensionService
- [x] Wire checkInstall() to extensionService.checkStatus()
- [x] Wire beginInstall() to appCoordinator.installExtension()

### 3.3 Personalization State
- [x] @Published displayName: String (integrate with existing overlay tokens)
- [x] @Published displayTitle: String (integrate with existing overlay tokens)  
- [x] @Published styleShape: StyleShape (rounded/square enum) - NEW feature
- [x] Wire startVirtualCamera() to cameraService.startOnboardingPreview()
- [x] Wire complete() to appCoordinator.completeOnboarding()

## Phase 4: Step-Specific Media Components
*Dependencies: Phases 1-3 | Duration: ~3 hours*

### 4.1 Welcome Step
**Component**: `WelcomeMedia`
- [x] Sparkles icon (64pt system image)
- [x] Welcome message
- [x] Simple centered layout

### 4.2 Install Step
**Component**: `InstallMedia`
- [x] Install state indicator
- [x] Action buttons based on state
- [x] Progress view for installing state
- [x] Error display with retry option
- [x] Integration with installState binding

### 4.3 Personalize Step
**Component**: `PersonalizeMedia`
- [x] Form with grouped style
- [x] Name TextField with binding (integrate with PersonalInfoView patterns)
- [x] Title TextField with binding (integrate with PersonalInfoView patterns)
- [x] Style picker (segmented: Rounded/Square) - NEW feature
- [ ] Integrate existing CameraSelector component (using Picker instead)
- [x] Proper form padding and styling matching existing PersonalInfoView

### 4.4 Preview Step
**Component**: `PreviewMedia`
- [x] Integrate `cameraService.currentPreviewFrame` for live camera display
- [x] Style-aware border rendering (rounded vs square)
- [x] Name/title overlay preview (reuse existing overlay tokens)
- [x] Handle cameraService.startOnboardingPreview() lifecycle
- [x] Fallback static preview when currentPreviewFrame is nil

### 4.5 Done Step
**Component**: `DoneMedia`
- [x] Success checkmark (56pt system image)
- [x] Completion message
- [x] Center alignment

## Phase 5: Main View Integration
*Dependencies: Phases 1-4 | Duration: ~2 hours*

### 5.1 ModernOnboardingView Assembly
**File**: `ModernOnboarding/ModernOnboardingView.swift`
- [x] StateObject ViewModel integration
- [x] OnboardingScaffold usage with proper parameters
- [x] HStack layout: Left explainer (340w) + Center media + Right rail (180w)
- [x] Step content switching logic
- [x] Transition animations configuration
- [x] Replaced simple text with ExplainerCard component
- [x] Removed stepCallout variable (functionality moved to ExplainerCard)

### 5.2 Step Explainer Cards
- [x] Left panel: title + subtitle + optional callouts
- [x] Regular material background
- [x] Rounded rectangle clipping
- [x] Error callout integration for install step
- [x] Dynamic content per step
- [x] **Enhanced ExplainerCard component with rich content**
  - [x] Created dedicated `ExplainerCard.swift` component
  - [x] Added `ExplainerBullet` model for structured bullet points
  - [x] Implemented 3 informative bullets per step with SF Symbols
  - [x] Added time estimates for each step
  - [x] Increased width from 280px to 340px for better content density
  - [x] Fixed copy issues ("Let's Get Started" apostrophe, "choose a style" vs "choose your camera")

### 5.3 Animation Implementation
- [x] Asymmetric transitions: trailing insertion, leading removal
- [x] Opacity combination with edge movements
- [x] Spring animation: response: 0.35, dampingFraction: 0.9
- [x] Animation trigger on currentStep changes

### 5.4 Step Advancement Logic
- [x] Step-specific advance() behavior
- [x] Install step: handle different install states
- [x] Preview step: start virtual camera integration
- [x] Done step: completion flow
- [x] Default: simple next() progression

## Phase 6: Service Integration
*Dependencies: Phase 5 + existing codebase analysis | Duration: ~3 hours*

### 6.1 AppCoordinator Integration
**Key Discovery**: App uses AppCoordinator pattern with environment injection
- [x] Use `@Environment(\.appCoordinator)` for service method calls
- [x] Leverage `@EnvironmentObject` services: ExtensionService, CameraService, OverlayService, LocationPermissionManager
- [x] Follow existing pattern: coordinator delegates to services, views observe services directly

### 6.2 Install Services Integration
**Existing Methods Found:**
- [x] Wire `checkInstall()` to `extensionService.checkStatus()` 
- [x] Connect `beginInstall()` to `extensionService.install()` via `appCoordinator.installExtension()`
- [x] Monitor `extensionService.status` (unknown/notInstalled/installing/installed)
- [x] Handle `extensionService.statusMessage` for user feedback
- [x] Use existing InstallState mapping from current OnboardingView

### 6.3 Camera Services Integration
**Existing Methods Found:**
- [x] Wire camera preview to `cameraService.startOnboardingPreview()` and `stopOnboardingPreview()`
- [ ] Use existing CameraSelector component in personalize step (using Picker instead)
- [x] Integrate `cameraService.currentPreviewFrame` for live preview display
- [x] Handle `cameraService.hasCameraPermission` and `requestPermission()` flow
- [x] Use `appCoordinator.selectCamera()` for camera selection

### 6.4 Settings Persistence & Completion
**Existing Patterns Found:**
- [x] Use AppGroup UserDefaults: `UserDefaults(suiteName: Identifiers.appGroup)`
- [x] Persist step progress with `@AppStorage("HL.onboarding.step")`
- [x] Set completion flag: `@AppStorage("HL.hasCompletedOnboarding")`
- [x] Wire `startVirtualCamera()` to `cameraService.startOnboardingPreview()` 
- [x] Call `appCoordinator.completeOnboarding()` on finish

## Phase 7: App Integration & Testing
*Dependencies: Phase 6 | Duration: ~2 hours*

### 7.1 App-Level Integration
- [ ] Update WindowGroup for onboarding window
- [ ] Verify proper window sizing and behavior
- [ ] Test onboarding trigger conditions
- [ ] Ensure proper cleanup on completion

### 7.2 Preview Development
- [ ] Add comprehensive #Preview to all components
- [ ] Mock ViewModel data for preview environments
- [ ] Test component isolation and reusability
- [ ] Verify visual consistency across components

### 7.3 Accessibility Implementation
- [ ] Add VoiceOver labels to step rail items
- [ ] Ensure button titles are descriptive
- [ ] Test keyboard navigation flow
- [ ] Verify dynamic type support

### 7.4 Testing & Validation
- [ ] Test step transitions in both directions
- [ ] Verify keyboard shortcuts functionality
- [ ] Test error states and recovery flows
- [ ] Validate persistence across app restarts
- [ ] Test onboarding completion flow

## Phase 8: Reuse Existing Components
*Dependencies: Phase 4 | Duration: ~1 hour*

### 8.1 Component Integration
**Components Available for Reuse:**
- [ ] `CameraSelector` - Use directly in PersonalizeMedia step
- [ ] `PersonalInfoView` - Integrate patterns for name/title inputs
- [ ] `LocationInfoView` - Consider for personalization step if needed
- [ ] `ModernButton` - Already used throughout existing onboarding
- [ ] Existing overlay token system for preview step

### 8.2 Environment Setup
- [ ] Ensure ModernOnboardingView uses `.withAppCoordinator()` extension
- [ ] Verify all `@EnvironmentObject` services are available
- [ ] Test environment injection in all sub-components

## Phase 9: Migration & Cleanup
*Dependencies: Phase 8 | Duration: ~1 hour*

### 9.1 Migration Testing
- [ ] Verify new onboarding matches old functionality
- [ ] Test all service integrations work correctly
- [ ] Ensure no regressions in extension installation
- [ ] Validate camera setup and preview flows

### 9.2 Code Cleanup
- [ ] Remove old OnboardingView.swift usage from app
- [ ] Keep file for reference but remove from build target
- [ ] Update any direct references to use ModernOnboardingView
- [ ] Clean up unused imports and dependencies

## Success Criteria
- [ ] App builds without old OnboardingView in use
- [ ] All 5 steps navigate smoothly with animations
- [ ] Step progress persists via @AppStorage
- [ ] Install flow works end-to-end
- [ ] Camera preview integrates properly
- [ ] Personalization saves to shared preferences
- [ ] Keyboard shortcuts all functional
- [ ] All components have working #Previews
- [ ] VoiceOver accessibility working
- [ ] No functionality regressions

## Timeline Estimate
**Total Duration**: ~17 hours across 9 phases
- **Foundation & Layout** (Phases 1-2): ~3.5 hours
- **State & Components** (Phases 3-4): ~5 hours  
- **Integration & Services** (Phases 5-6): ~5 hours
- **Testing & Reuse** (Phases 7-8): ~2.5 hours
- **Migration** (Phase 9): ~1 hour

## Risk Mitigation
- **Service Integration Complexity**: Keep detailed notes on existing service patterns
- **Animation Performance**: Test on older hardware if available
- **Camera Preview Integration**: Plan fallback for development/preview environments
- **State Management**: Thoroughly test persistence edge cases