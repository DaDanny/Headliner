# Live Preview Step Implementation Plan

## Problem Analysis

After analyzing the codebase, I've identified several critical issues preventing the live preview from working properly:

### **Core Issues:**

1. **Settings Not Applied During Onboarding**: The ModernOnboardingViewModel stores personalization data (`displayName`, `displayTitle`, `selectedCameraID`, `styleShape`) but **only saves to AppGroup UserDefaults and updates overlay tokens on completion** (line 111-129 in ModernOnboardingViewModel.swift). This means during onboarding, the services don't receive updated settings.

2. **Camera Selection Not Persisted**: Camera selection is handled via binding in PersonalizeMedia, but the selected camera is only passed to `cameraService.selectCamera()` in `startVirtualCamera()` method (line 144-146) which isn't called until the preview step advance action.

3. **Overlay Service Not Updated**: The overlay service isn't receiving real-time updates of the user's name, title, or style during onboarding - only after completion.

4. **Live Preview Missing Overlay Integration**: The current PreviewMedia component only shows a basic overlay preview using local data, not the actual overlay service rendering.

## Solution Strategy

### **Phase 1: Fix Settings Persistence (Critical)**

1. **Real-time Settings Updates**: Modify ModernOnboardingViewModel to immediately update services when settings change, not just on completion.

2. **Camera Selection Persistence**: Ensure camera selection is applied immediately in the personalize step.

3. **Overlay Token Updates**: Update overlay service with real-time name/title changes during onboarding.

### **Phase 2: Live Preview Step Redesign**

1. **Remove Explainer Card**: Replace left panel with PresetRail component.
2. **Add Preset Selection**: Integrate with existing `SwiftUIPresetInfo` from overlay service.
3. **Aspect-Fit Preview**: Replace cropped preview with letterboxed container.
4. **Real-time Overlay Rendering**: Connect to actual overlay service instead of mock overlay.

---

## Implementation Plan

### **Step 1: Fix ViewModel Settings Persistence**

**File**: `Headliner/Views/ModernOnboarding/ModernOnboardingViewModel.swift`

**Changes Needed**:

```swift
// Add real-time overlay token updates
private func updateOverlayTokens() {
    let tokens = OverlayTokens(
        displayName: displayName.isEmpty ? "Your Name" : displayName,
        tagline: displayTitle.isEmpty ? "Your Title" : displayTitle
    )
    overlayService?.updateTokens(tokens)
}

// Add real-time camera selection
private func updateCameraSelection() {
    if !selectedCameraID.isEmpty,
       let camera = cameraService?.availableCameras.first(where: { $0.id == selectedCameraID }) {
        Task { @MainActor in
            await cameraService?.selectCamera(camera)
        }
    }
}

// Add property observers to existing properties
@Published var displayName: String = "" {
    didSet {
        updateOverlayTokens()
        savePersonalizationData() // Save immediately, not just on completion
    }
}

@Published var displayTitle: String = "" {
    didSet {
        updateOverlayTokens()
        savePersonalizationData()
    }
}

@Published var selectedCameraID: String = "" {
    didSet {
        updateCameraSelection()
    }
}

// New method for immediate persistence
private func savePersonalizationData() {
    guard let appGroupDefaults = UserDefaults(suiteName: Identifiers.appGroup) else { return }
    appGroupDefaults.set(displayName, forKey: "HL.displayName")
    appGroupDefaults.set(displayTitle, forKey: "HL.tagline")
    appGroupDefaults.synchronize()
}
```

### **Step 2: Add Preset Support to ViewModel**

**Add to ModernOnboardingViewModel**:

```swift
// MARK: - Preview Step Support

@Published var availablePresets: [SwiftUIPresetInfo] = []
@Published var selectedPresetID: String? {
    didSet {
        if let presetID = selectedPresetID {
            overlayService?.selectPreset(presetID)
        }
    }
}

// Load curated presets (same as OnboardingView.swift:602)
private func loadAvailablePresets() {
    guard let overlayService = overlayService else { return }
    
    let curatedIds = [
        "swiftui.identity.strip",
        "swiftui.modern.personal", 
        "swiftui.clean",
        "swiftui.status.bar",
        "swiftui.info.corner"
    ]
    
    availablePresets = overlayService.availablePresets.filter { 
        curatedIds.contains($0.id) 
    }
    
    // Set initial selection to first preset
    if selectedPresetID == nil, let firstPreset = availablePresets.first {
        selectedPresetID = firstPreset.id
    }
}

func selectPreset(_ preset: SwiftUIPresetInfo) {
    selectedPresetID = preset.id
}
```

### **Step 3: Create Preview Step Components**

**New File**: `Headliner/Views/ModernOnboarding/Components/PresetRail.swift`

```swift
import SwiftUI

struct PresetRail: View {
    let presets: [SwiftUIPresetInfo]
    @Binding var selectedID: String?
    var onSelect: (SwiftUIPresetInfo) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 16)
                
                Text("Overlays")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(presets, id: \.id) { preset in
                        Button {
                            onSelect(preset)
                        } label: {
                            PresetRow(
                                preset: preset, 
                                isSelected: preset.id == selectedID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
        }
        .frame(width: 220)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

private struct PresetRow: View {
    let preset: SwiftUIPresetInfo
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail placeholder (can be enhanced later)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 48, height: 32)
                .overlay(
                    Image(systemName: preset.category.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.callout.weight(isSelected ? .semibold : .regular))
                    .lineLimit(1)
                
                Text(preset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? .tint.opacity(0.12) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? .tint.opacity(0.55) : .clear, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
```

### **Step 4: Create LivePreviewPane Component**

**New File**: `Headliner/Views/ModernOnboarding/Components/LivePreviewPane.swift`

```swift
import SwiftUI

struct LivePreviewPane<Content: View>: View {
    let title: String
    let targetAspect: CGFloat?
    @ViewBuilder var content: () -> Content
    
    init(
        title: String, 
        targetAspect: CGFloat? = 16.0/9.0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.targetAspect = targetAspect
        self.content = content
    }
    
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            
            GeometryReader { geo in
                ZStack {
                    // Background
                    Rectangle()
                        .fill(Color.secondary.opacity(0.08))
                    
                    // Aspect-fit content
                    AspectFitBox(
                        containerSize: geo.size,
                        aspect: targetAspect
                    ) {
                        content()
                    }
                }
                .clipShape(shape)
                .overlay(
                    shape.stroke(.quaternary, lineWidth: 1)
                )
            }
            .frame(minHeight: 360)
            
            Text("This is how you'll appear in video calls")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AspectFitBox<C: View>: View {
    let containerSize: CGSize
    let aspect: CGFloat?
    @ViewBuilder var content: () -> C
    
    var body: some View {
        let targetAspect = aspect ?? (16.0/9.0)
        let containerAspect = containerSize.width / max(containerSize.height, 1)
        
        let fittedSize: CGSize = {
            if containerAspect > targetAspect {
                // Container wider than content → limit by height
                let height = containerSize.height
                let width = height * targetAspect
                return CGSize(width: width, height: height)
            } else {
                // Container taller than content → limit by width
                let width = containerSize.width
                let height = width / targetAspect
                return CGSize(width: width, height: height)
            }
        }()
        
        content()
            .frame(width: fittedSize.width, height: fittedSize.height)
            .clipped()
            .animation(.easeInOut(duration: 0.2), value: fittedSize)
    }
}
```

### **Step 5: Update PreviewMedia Component**

**File**: `Headliner/Views/ModernOnboarding/StepMediaComponents.swift`

**Replace PreviewMedia with**:

```swift
// MARK: - Preview Media

struct PreviewMedia: View {
    let name: String
    let title: String 
    let style: ModernOnboardingViewModel.StyleShape
    let availablePresets: [SwiftUIPresetInfo]
    @Binding var selectedPresetID: String?
    let onPresetSelect: (SwiftUIPresetInfo) -> Void
    
    @EnvironmentObject private var cameraService: CameraService
    @EnvironmentObject private var overlayService: OverlayService
    @State private var hasStartedPreview = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Preset Rail
            PresetRail(
                presets: availablePresets,
                selectedID: $selectedPresetID,
                onSelect: onPresetSelect
            )
            
            // Center: Live Preview with Overlay
            LivePreviewPane(
                title: "Live Preview",
                targetAspect: 16.0/9.0
            ) {
                ZStack {
                    if let frame = cameraService.currentPreviewFrame {
                        Image(frame, scale: 1.0, label: Text("Camera preview"))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if hasStartedPreview {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Starting camera preview...")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            
                            Text("Camera preview will appear here")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Real overlay rendering
                    if let frame = cameraService.currentPreviewFrame,
                       let selectedPresetID = selectedPresetID,
                       let preset = availablePresets.first(where: { $0.id == selectedPresetID }) {
                        
                        // This renders the actual overlay from the service
                        OverlayRenderView(
                            preset: preset,
                            tokens: OverlayTokens(
                                displayName: name.isEmpty ? "Your Name" : name,
                                tagline: title.isEmpty ? "Your Title" : title
                            )
                        )
                        .allowsHitTesting(false)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            Task {
                hasStartedPreview = true
                await cameraService.startOnboardingPreview()
            }
        }
        .onDisappear {
            cameraService.stopOnboardingPreview()
        }
    }
}
```

### **Step 6: Update ModernOnboardingView Layout**

**File**: `Headliner/Views/ModernOnboarding/ModernOnboardingView.swift`

**Update the .preview case in stepMedia**:

```swift
case .preview:
    PreviewMedia(
        name: viewModel.displayName,
        title: viewModel.displayTitle,
        style: viewModel.styleShape,
        availablePresets: viewModel.availablePresets,
        selectedPresetID: $viewModel.selectedPresetID,
        onPresetSelect: { preset in
            viewModel.selectPreset(preset)
        }
    )
```

**Update layout for preview step**:

```swift
// In body, replace the HStack for preview step only
if viewModel.currentStep == .preview {
    // Preview step uses full width without explainer card
    MediaPane {
        stepMedia
            .transition(stepTransition)
    }
    .frame(maxWidth: .infinity)
    .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(.quaternary, lineWidth: 1)
    )
} else {
    // All other steps use explainer + media + rail layout
    HStack(alignment: .top, spacing: 20) {
        // ... existing ExplainerCard + MediaPane + StepRail
    }
}
```

### **Step 7: Create OverlayRenderView Helper**

**New File**: `Headliner/Views/ModernOnboarding/Components/OverlayRenderView.swift`

```swift
import SwiftUI

struct OverlayRenderView: View {
    let preset: SwiftUIPresetInfo
    let tokens: OverlayTokens
    
    var body: some View {
        // This should use the actual overlay rendering system
        // For now, create a simplified version that matches the preset
        preset.provider.makeView(tokens: tokens)
            .allowsHitTesting(false)
    }
}
```

### **Step 8: Update ViewModel Configuration**

**In ModernOnboardingViewModel.configure() method, add**:

```swift
func configure(
    appCoordinator: AppCoordinator,
    extensionService: ExtensionService,
    cameraService: CameraService,
    overlayService: OverlayService
) {
    self.appCoordinator = appCoordinator
    self.extensionService = extensionService
    self.cameraService = cameraService
    self.overlayService = overlayService
    
    setupBindings()
    loadAvailablePresets() // Add this line
    
    // Apply initial settings immediately
    updateOverlayTokens()
    updateCameraSelection()
}
```

---

## Testing Checklist

### **Phase 1 Testing (Settings Persistence)**
- [ ] Enter name in Personalize step → verify overlay service receives update
- [ ] Enter title in Personalize step → verify overlay service receives update  
- [ ] Select camera in Personalize step → verify camera service switches immediately
- [ ] Check AppGroup UserDefaults are updated in real-time

### **Phase 2 Testing (Live Preview)**
- [ ] Preview step shows preset rail on left with curated presets
- [ ] Clicking preset updates overlay immediately in live preview
- [ ] Live preview shows actual camera feed (not black/blank)
- [ ] Preview is aspect-fit with letterboxing (not cropped)
- [ ] Real overlays render with user's name/title from previous step
- [ ] StepRail still visible and functional

### **Integration Testing**
- [ ] Complete onboarding → verify main app has correct camera/overlay settings
- [ ] Settings persist across app restarts
- [ ] No regressions in other onboarding steps

---

## Success Criteria

1. **Real-time Settings**: User changes in Personalize step immediately reflected in services
2. **Working Live Preview**: Preview step shows actual camera feed with real overlay rendering
3. **Preset Selection**: User can select different overlays and see them applied instantly
4. **Proper Aspect Ratio**: Camera feed is letterboxed, never cropped
5. **Seamless Integration**: Completed onboarding settings match main app state

---

## Implementation Priority

1. **Critical (Fix broken preview)**: Phase 1 - Settings Persistence
2. **High (UI improvement)**: Phase 2.1-2.4 - Layout changes
3. **Medium (Polish)**: Phase 2.5-2.7 - Real overlay rendering
4. **Nice-to-have**: Keyboard navigation, "Show more" presets

This plan addresses both the core technical issues (settings not persisting during onboarding) and the UI/UX improvements (preset rail + aspect-fit preview) specified in the live-preview-step.md requirements.