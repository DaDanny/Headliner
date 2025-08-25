love this energy—let’s turn onboarding into a tiny, delightful product of its own. here’s a clean plan you can ship fast, plus a ready‑to‑hand to Claude to implement.

⸻

what “great onboarding” looks like for headliner

goals
	•	zero‑to‑virtual‑camera in < 2 minutes, with one obvious next action at each step
	•	friendly, modern, low‑cognitive‑load UI that matches your overlay aesthetic
	•	resilient: previews work, errors are explained inline, progress is saved

principles
	•	consistent scaffold: same header, 3‑column body, footer controls on every step
	•	animated focus: subtle slide/fade between steps; step list (“rail”) updates with progress
	•	tight copy + visuals: left = concise explainer; center = live visual (image/video/preview); right = step rail
	•	keyboard & mouse parity: ⏎ = Continue, ⌘→ = Next, ⌘← = Back, Esc = Close
	•	save state: resume where user left off using @AppStorage
	•	fail nicely: inline callouts for permissions/system extension install issues

suggested step flow (5 steps)
	1.	Welcome — what Headliner does; “Continue”
	2.	Install — system extension / virtual camera install status + “Install/Retry”
	3.	Personalize — name/title inputs and a style toggle (Rounded / Square) and camera selector
	4.	Preview — live CameraExtension preview with selected overlay; “Start Virtual Camera”
	5.	Done — confirmation + “Open Settings” and “Finish” (closes onboarding, sets flag)

You can refine copy later; we’ll wire placeholders.

⸻

architecture & layout

window
	•	keep your dedicated onboarding WindowGroup(id: "onboarding")
	•	“medium” content size (e.g., ~ 900×600) with safe minimums for smaller screens
	•	resizable off for now (cleaner visuals)

state
	•	@AppStorage("HL.onboarding.step") for current step index
	•	OnboardingStep enum as single source of truth for titles/icons
	•	ModernOnboardingViewModel holds step, install/progress flags, and calls into your existing services (reusing methods from the old OnboardingView.swift)

reusable building blocks
	•	OnboardingScaffold: header + 3‑column body + footer buttons
	•	StepRail: right‑side vertical list with current step emphasized
	•	MediaPane: center area that can render image, Lottie/GIF, or live preview
	•	StepCard: left explainer card (title + description + optional callout)
	•	PrimaryButton, SecondaryButton, TertiaryButton (or just style modifiers)
	•	InstallStatusRow: shows state machine for “Install” step (Not Installed → Installing → Installed)

animations
	•	use asymmetric transitions: .move(edge: .trailing) for forward, .move(edge: .leading) for back, with .opacity
	•	attach .animation(.spring(response: 0.35, dampingFraction: 0.9)) to currentStep
	•	animated progress tick on the rail (fill dot → checkmark)

previews
	•	every component has a #Preview with mock view models
	•	fake a “live preview” by injecting a sample image if CameraExtension not available in Preview

accessibility
	•	dynamic type friendliness (macOS sizes), VoiceOver labels on rail items
	•	clear button titles (not only icons)

⸻

implementation skeleton (SwiftUI)

this is a skeleton to compile early and iterate visually. it doesn’t bind to real services yet—Claude will wire those.

// ModernOnboarding/OnboardingStep.swift
import SwiftUI

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome, install, personalize, preview, done
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .install: return "Install"
        case .personalize: return "Personalize"
        case .preview: return "Preview"
        case .done: return "Done"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: return "A quick setup to get your virtual camera looking sharp."
        case .install: return "We’ll set up the Headliner virtual camera."
        case .personalize: return "Add your details and a style preset."
        case .preview: return "Check your look with a live preview."
        case .done: return "All set! Jump into your next call."
        }
    }

    var systemImage: String {
        switch self {
        case .welcome: return "sparkles"
        case .install: return "bolt.badge.a"
        case .personalize: return "person.crop.circle.badge.checkmark"
        case .preview: return "camera.viewfinder"
        case .done: return "checkmark.seal"
        }
    }
}

// ModernOnboarding/ModernOnboardingViewModel.swift
import SwiftUI
import Combine

final class ModernOnboardingViewModel: ObservableObject {
    @AppStorage("HL.onboarding.step") private var savedStepIndex: Int = 0
    @AppStorage("HL.hasCompletedOnboarding",
                store: UserDefaults(suiteName: Identifiers.appGroup))
    private var hasCompletedOnboarding: Bool = false

    @Published var currentStep: OnboardingStep = .welcome {
        didSet { savedStepIndex = currentStep.rawValue }
    }

    // Install state
    enum InstallState { case unknown, notInstalled, installing, installed, error(String) }
    @Published var installState: InstallState = .unknown

    // Personalization
    @Published var displayName: String = ""
    @Published var displayTitle: String = ""
    @Published var styleShape: StyleShape = .rounded
    enum StyleShape: String, CaseIterable { case rounded, square }

    init() {
        if let step = OnboardingStep(rawValue: savedStepIndex) { currentStep = step }
    }

    func next() {
        guard let idx = OnboardingStep.allCases.firstIndex(of: currentStep),
              idx + 1 < OnboardingStep.allCases.count else { return }
        currentStep = OnboardingStep.allCases[idx + 1]
    }

    func back() {
        guard let idx = OnboardingStep.allCases.firstIndex(of: currentStep),
              idx - 1 >= 0 else { return }
        currentStep = OnboardingStep.allCases[idx - 1]
    }

    func complete() {
        hasCompletedOnboarding = true
        // optionally post a notification to switch app activation policy, etc.
    }

    // MARK: Service hooks (to wire with legacy methods)
    func checkInstall() { /* TODO: query extension status; update installState */ }
    func beginInstall() { /* TODO: launch installer flow; update installState */ }
    func startVirtualCamera() { /* TODO: call into service */ }
}

// ModernOnboarding/OnboardingScaffold.swift
import SwiftUI

struct OnboardingScaffold<Content: View>: View {
    let step: OnboardingStep
    let onBack: () -> Void
    let onNext: () -> Void
    let nextTitle: String
    let isNextPrimary: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Label(step.title, systemImage: step.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Body
            content()
                .padding(20)
                .frame(minHeight: 420)

            // Footer
            Divider()
            HStack {
                Button("Back", action: onBack)
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                    .disabled(step == .welcome)

                Spacer()

                if isNextPrimary {
                    Button(nextTitle, action: onNext)
                        .keyboardShortcut(.return)
                        .buttonStyle(.borderedProminent)
                } else {
                    Button(nextTitle, action: onNext)
                        .keyboardShortcut(.rightArrow, modifiers: [.command])
                }
            }
            .padding(16)
        }
        .frame(width: 900, height: 600) // “medium”
    }
}

// ModernOnboarding/StepRail.swift
import SwiftUI

struct StepRail: View {
    let steps: [OnboardingStep]
    let current: OnboardingStep

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(steps) { step in
                HStack(spacing: 10) {
                    ZStack {
                        Circle().strokeBorder(.quaternary, lineWidth: 1)
                            .frame(width: 18, height: 18)
                        if step.rawValue < current.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
                    Text(step.title)
                        .font(.system(size: 13, weight: step == current ? .semibold : .regular))
                        .foregroundStyle(step == current ? .primary : .secondary)
                }
                .contentTransition(.numericText())
            }
            Spacer()
        }
        .padding(16)
        .frame(width: 180)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// ModernOnboarding/MediaPane.swift
import SwiftUI

struct MediaPane<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.quaternary))
            content()
        }
        .frame(minWidth: 380, minHeight: 360)
    }
}

// ModernOnboarding/ModernOnboardingView.swift
import SwiftUI

struct ModernOnboardingView: View {
    @StateObject private var model = ModernOnboardingViewModel()

    var body: some View {
        OnboardingScaffold(
            step: model.currentStep,
            onBack: { model.back() },
            onNext: { advance() },
            nextTitle: nextTitle,
            isNextPrimary: isNextPrimary
        ) {
            HStack(spacing: 16) {
                // Left: explainer
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.currentStep.title)
                        .font(.title2.bold())
                    Text(model.currentStep.subtitle)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    // Optional callouts per step
                    stepCallout
                }
                .frame(maxWidth: 280)
                .padding(16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Center: media
                MediaPane {
                    stepMedia
                        .transition(stepTransition)
                }

                // Right: rail
                StepRail(steps: OnboardingStep.allCases, current: model.currentStep)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: model.currentStep)
        }
        .onAppear { if model.currentStep == .install { model.checkInstall() } }
    }

    // MARK: Derived UI

    private var nextTitle: String {
        switch model.currentStep {
        case .welcome: return "Continue"
        case .install: return installNextTitle
        case .personalize: return "Continue"
        case .preview: return "Start Virtual Camera"
        case .done: return "Finish"
        }
    }

    private var isNextPrimary: Bool {
        switch model.currentStep {
        case .preview, .done: return true
        default: return false
        }
    }

    private var installNextTitle: String {
        switch model.installState {
        case .installed: return "Continue"
        case .installing: return "Installing…"
        case .error: return "Retry Install"
        default: return "Install"
        }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity))
    }

    @ViewBuilder private var stepMedia: some View {
        switch model.currentStep {
        case .welcome:
            WelcomeMedia()
        case .install:
            InstallMedia(state: model.installState,
                         onInstall: model.beginInstall)
        case .personalize:
            PersonalizeMedia(displayName: $model.displayName,
                             displayTitle: $model.displayTitle,
                             style: $model.styleShape)
        case .preview:
            PreviewMedia(name: model.displayName,
                         title: model.displayTitle,
                         style: model.styleShape)
        case .done:
            DoneMedia()
        }
    }

    @ViewBuilder private var stepCallout: some View {
        if case .error(let message) = model.installState {
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }

    private func advance() {
        switch model.currentStep {
        case .install:
            switch model.installState {
            case .installed: model.next()
            case .installing: break
            default: model.beginInstall()
            }
        case .preview:
            model.startVirtualCamera()
            model.next()
        case .done:
            model.complete()
        default:
            model.next()
        }
    }
}

// MARK: - Step-specific media stubs

private struct WelcomeMedia: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
            Text("Let’s set you up in a minute.")
                .font(.headline)
        }
    }
}

private struct InstallMedia: View {
    let state: ModernOnboardingViewModel.InstallState
    let onInstall: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Label("Virtual Camera", systemImage: "bolt.badge.a")
                .font(.headline)
            switch state {
            case .installed:
                Label("Installed", systemImage: "checkmark.seal")
            case .installing:
                ProgressView("Installing…")
            case .error(let msg):
                VStack(spacing: 8) {
                    Text(msg).foregroundStyle(.orange)
                    Button("Retry Install", action: onInstall)
                }
            default:
                Button("Install", action: onInstall)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct PersonalizeMedia: View {
    @Binding var displayName: String
    @Binding var displayTitle: String
    @Binding var style: ModernOnboardingViewModel.StyleShape
    var body: some View {
        Form {
            TextField("Your name", text: $displayName)
            TextField("Your title", text: $displayTitle)
            Picker("Style", selection: $style) {
                Text("Rounded").tag(ModernOnboardingViewModel.StyleShape.rounded)
                Text("Square").tag(ModernOnboardingViewModel.StyleShape.square)
            }
            .pickerStyle(.segmented)
        }
        // Camera Selector Component
        .formStyle(.grouped)
        .padding()
    }
}

private struct PreviewMedia: View {
    let name: String
    let title: String
    let style: ModernOnboardingViewModel.StyleShape
    var body: some View {
        // Placeholder: swap with live CameraExtension preview
        VStack {
            Text("Live Preview")
            RoundedRectangle(cornerRadius: style == .rounded ? 16 : 2)
                .strokeBorder(style == .rounded ? .blue : .green, lineWidth: 2)
                .overlay(
                    VStack {
                        Text(name.isEmpty ? "Your Name" : name).font(.title3.bold())
                        Text(title.isEmpty ? "Your Title" : title).foregroundStyle(.secondary)
                    }
                )
                .padding()
        }
    }
}

private struct DoneMedia: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 56))
            Text("You’re ready to go!").font(.headline)
        }
    }
}

#Preview("ModernOnboardingView") {
    ModernOnboardingView()
}


⸻

how this slots into your app today
	•	keep your old OnboardingView.swift around for service references only (calls for install, permission checks, starting virtual camera).
	•	wire those into ModernOnboardingViewModel’s checkInstall(), beginInstall(), and startVirtualCamera().
	•	after you confirm parity, delete the old view.

⸻

✅ deliverable for Claude (copy/paste)

# Headliner — Modern Onboarding Implementation Spec

## Objective
Replace `OnboardingView.swift` with a new, modular `ModernOnboardingView` that uses a consistent scaffold, animated step transitions, and reusable components. Preserve the old view temporarily for reference to its service calls; do not modify those services.

## Files to Create
- `ModernOnboarding/OnboardingStep.swift` — enum with titles, subtitles, icons.
- `ModernOnboarding/ModernOnboardingViewModel.swift` — state, AppStorage, service stubs.
- `ModernOnboarding/OnboardingScaffold.swift` — header/body/footer layout wrapper.
- `ModernOnboarding/StepRail.swift` — right-side vertical progress list.
- `ModernOnboarding/MediaPane.swift` — shared visual container.
- `ModernOnboarding/ModernOnboardingView.swift` — step composition & transitions.

## Layout
- Window size ~ **900×600**, fixed for MVP.
- Scaffold: `VStack` (Header) + main content + footer.
- Main content: `HStack` with **Left Explainer Card (280w)**, **Center Media Pane**, **Right Step Rail (180w)**.
- Footer: `Back` (⌘←), `Continue/Next` (⏎, ⌘→). Primary style on Preview/Finish.

## Steps
1. `welcome` — explainer; continue.
2. `install` — shows install state; actions:
   - `checkInstall()` on appear.
   - `beginInstall()` on button; show `installing` → `installed` or `error(msg)`.
3. `personalize` — name, title, style (Rounded/Square) and camera selector.
4. `preview` — live camera preview (use existing CameraExtension preview view if available; else placeholder). Action: `startVirtualCamera()`.
5. `done` — confirmation; `complete()` sets `HL.hasCompletedOnboarding = true`.

## Animations
- Use `.transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))`
- `.animation(.spring(response: 0.35, dampingFraction: 0.9), value: model.currentStep)`

## Reuse & Previews
- All components must include `#Preview` using mock VM data.
- Keep service calls abstracted in the ViewModel so the UI compiles independently.

## Accessibility
- Provide VoiceOver labels for rail items and install status.
- Ensure buttons have descriptive titles.

## Wiring to Legacy Services
Implement these in the ViewModel by calling the existing service methods from the old onboarding:
- `checkInstall()` → read extension status → map to `.installed/.notInstalled`
- `beginInstall()` → start install → update to `.installing` → then `.installed` or `.error(msg)`
- `startVirtualCamera()` → kick off camera pipeline for preview step
- `complete()` → set `HL.hasCompletedOnboarding = true` and close onboarding window

## Acceptance Criteria
- App builds without the old `OnboardingView` (though file remains present).
- Progress is persisted via `@AppStorage("HL.onboarding.step")`.
- Step transitions animate smoothly in both directions.
- The rail updates with bold current step and checks for completed ones.
- Preview step displays either a live camera preview (if available) or a placeholder.
- Keyboard shortcuts work (⏎, ⌘→, ⌘←).
- All files have `#Preview` and compile in Xcode previews.

## Nice-to-Have (if time)
- Inline callout component for errors (warning icon + text).
- “Skip” button on Welcome that jumps to Install.


⸻

if you want, I can also drop in a tiny “LiveCameraPreviewView” shim that swaps between a sample static frame in Previews and your real CameraExtension view at runtime.