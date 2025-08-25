Love it—this step should feel like a mini “studio”: presets on the left, big live preview on the right. Here’s a tight plan + drop‑in SwiftUI to get you there fast.

⸻

What we’re changing (Preview step only)
	•	Remove the explainer card.
	•	Add a vertical Preset list on the left (curated list first, user can scroll to see more).
	•	Select = apply immediately to the live preview.
	•	Fix cropping by rendering the preview in an aspect‑fit container with letterboxing, not fill.

⸻

ViewModel additions (minimal)

// In ModernOnboardingViewModel
@Published var availablePresets: [OverlayPreset] = []   // load from your curated source (line 602)
@Published var selectedPresetID: String?                // bound to list selection

func selectPreset(_ preset: OverlayPreset) {
    selectedPresetID = preset.id
    // Call into overlay/renderer service to apply
    overlayService.apply(presetID: preset.id)
}

OverlayPreset can be whatever you have already; here’s a lightweight shape if you need it:

struct OverlayPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let thumbnail: NSImage?    // or image name / URL
    let aspect: CGSize?        // optional, falls back to camera aspect
}


⸻

UI: Preset rail + live preview (aspect‑fit)

1) PresetRail (left)

import SwiftUI

struct PresetRail: View {
    let presets: [OverlayPreset]
    @Binding var selectedID: String?
    var onSelect: (OverlayPreset) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Overlays")
                .font(.headline)
                .padding(.horizontal, 10)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(presets) { preset in
                        Button {
                            onSelect(preset)
                        } label: {
                            PresetRow(preset: preset, isSelected: preset.id == selectedID)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
        }
        .frame(width: 220) // feels good next to a large preview
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 1))
    }
}

private struct PresetRow: View {
    let preset: OverlayPreset
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 48, height: 32)
                if let img = preset.thumbnail {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            Text(preset.name)
                .font(.callout.weight(isSelected ? .semibold : .regular))
                .lineLimit(1)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
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

2) Aspect‑fit preview container (center)

This ensures the live preview never crops—it letterboxes to fit the available space.

struct LivePreviewPane<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    var targetAspect: CGFloat? = nil // width / height; if nil, uses content’s own sizing

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        VStack(spacing: 8) {
            Text(title).font(.headline)
            GeometryReader { geo in
                ZStack {
                    // Backdrop
                    Rectangle()
                        .fill(Color.secondary.opacity(0.08))

                    // Letterboxed content
                    AspectFitBox(containerSize: geo.size, aspect: targetAspect) {
                        content()
                    }
                }
                .clipShape(shape)
                .overlay(shape.stroke(.quaternary, lineWidth: 1))
            }
            .frame(minHeight: 360)
            Text("This is how you'll appear in video calls")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// Helper: sizes child to fit inside container preserving aspect (letterbox)
private struct AspectFitBox<C: View>: View {
    let containerSize: CGSize
    let aspect: CGFloat? // width / height
    @ViewBuilder var content: () -> C

    var body: some View {
        let a = aspect ?? (16.0/9.0)
        let w = containerSize.width
        let h = containerSize.height
        let containerAspect = w / max(h, 1)

        let fittedSize: CGSize = {
            if containerAspect > a {
                // container wider than content → limit by height
                let height = h
                let width  = height * a
                return CGSize(width: width, height: height)
            } else {
                // container taller than content → limit by width
                let width = w
                let height = width / a
                return CGSize(width: width, height: height)
            }
        }()

        return AnyView(
            content()
                .frame(width: fittedSize.width, height: fittedSize.height)
                .clipped()
                .animation(.easeInOut(duration: 0.2), value: fittedSize)
        )
    }
}

In your actual preview view, pass the camera stream + overlay view as content(). If you know the camera aspect (e.g., 16:9, 4:3), pass it via targetAspect: so the letterboxing is exact.

⸻

Wiring it into the Preview step

Replace the .preview layout for this step only:

// Inside ModernOnboardingView, for .preview case
HStack(spacing: 16) {
    // LEFT: presets
    PresetRail(
        presets: viewModel.availablePresets,
        selectedID: $viewModel.selectedPresetID,
        onSelect: { preset in viewModel.selectPreset(preset) }
    )

    // CENTER: live preview (aspect‑fit, not cropped)
    LivePreviewPane(title: "Live Preview", targetAspect: 16.0/9.0) {
        // Your live camera + overlay view here:
        HeadlinerLivePreviewView(                       // whatever you already have
            selectedPresetID: viewModel.selectedPresetID,
            name: viewModel.displayName,
            title: viewModel.displayTitle,
            style: viewModel.styleShape
        )
        .id(viewModel.selectedPresetID) // ensures a smooth swap when changing presets
    }

    // RIGHT: step rail (unchanged)
    StepRail(steps: OnboardingStep.allCases, current: viewModel.currentStep, showsProgressCaption: true)
}
.transition(stepTransition)

Note on applying presets
When selectPreset(_:) is called:
	•	Update selectedPresetID
	•	Notify your overlay renderer (e.g., through overlayService.apply(presetID:))
Consider debouncing (100–150 ms) if thumbnails are wildly clicked.

⸻

Claude todo (copy/paste to your repo)
	•	Replace Preview step layout: add PresetRail on the left, remove ExplainerCard.
	•	Bind PresetRail to viewModel.availablePresets and viewModel.selectedPresetID.
	•	On selection, call viewModel.selectPreset(_:) which applies the preset to the overlay renderer.
	•	Swap center preview container to LivePreviewPane with AspectFitBox so the feed is letterboxed, not cropped.
	•	Keep the StepRail on the right.
	•	Load curated presets from the existing source (see Headliner/Views/OnboardingView.swift around line 602) and merge with any user‑available presets if needed.

⸻

If you want, I can also add a tiny “Show more” at the bottom of the preset rail that toggles from your curated set to the full set, plus a hover scrub (arrow keys up/down to change selection).

onboarding_preview_step:
  objective: >
    Redesign the Preview step to remove the explainer card and instead show a
    vertical list of curated overlay presets alongside a live preview. The user
    should be able to select a preset and see it applied immediately in the
    live preview. The preview container should letterbox content (aspect-fit)
    instead of cropping.

  changes:
    - remove: ExplainerCard from the Preview step layout
    - add: PresetRail (left panel)
      details:
        - vertical list of available overlay presets
        - initial list is curated (from existing preset logic in OnboardingView.swift:602)
        - user can scroll if there are more
        - each row shows:
            - thumbnail preview (48x32, rounded corners)
            - preset name
            - checkmark if selected
        - clicking a preset updates `selectedPresetID` and applies overlay
    - modify: Live Preview container (center panel)
      details:
        - wrap in `LivePreviewPane` with rounded rectangle
        - use `AspectFitBox` helper so video is scaled with letterboxing (not cropped)
        - pass `targetAspect: 16:9` or detect from camera
        - content: live camera feed + selected overlay
        - update live preview immediately when `selectedPresetID` changes
    - keep: StepRail on the right (unchanged)

  viewmodel_updates:
    - add: availablePresets: [OverlayPreset]
      source: curated preset list (line 602 of OnboardingView.swift)
    - add: selectedPresetID: String?
    - add: selectPreset(_:)
      details:
        - sets `selectedPresetID`
        - calls overlayService.apply(presetID:)
        - consider debounce if selection is rapid

  acceptance_criteria:
    - user sees curated preset list on left
    - clicking a preset updates overlay instantly
    - live preview is correctly letterboxed, never cropped
    - step rail remains visible on the right
    - curated presets load from existing preset source
    - design feels like a "mini studio": presets on left, preview on right

  nice_to_have:
    - "Show more" button at bottom of preset list to expand beyond curated set
    - keyboard navigation: arrow keys up/down to change preset selection