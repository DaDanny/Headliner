//
//  OnboardingStep.swift
//  Headliner
//
//  Modern onboarding step definition with rich content for explainer cards
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case install
    case personalize
    case preview
    case done
    
    var id: Int { rawValue }
    
    // Short label for the step rail (one word, Apple-y)
    var railTitle: String {
        switch self {
        case .welcome: return "Welcome"
        case .install: return "Install"
        case .personalize: return "Personalize"
        case .preview: return "Preview"
        case .done: return "Done"
        }
    }
    
    // Left-panel friendly title (H2 style)
    var explainerTitle: String {
        switch self {
        case .welcome: return "Let's Get Started"
        case .install: return "Enable Virtual Camera"
        case .personalize: return "Make It Yours"
        case .preview: return "See It Live"
        case .done: return "You're All Set"
        }
    }
    
    // Left-panel subtitle (one sentence, secondary)
    var explainerSubtitle: String {
        switch self {
        case .welcome: return "A quick setup to get your virtual camera looking sharp."
        case .install: return "We'll set up the Headliner camera extension."
        case .personalize: return "Add your name and title, then choose a style."
        case .preview: return "Check how everything looks before you join a call."
        case .done: return "Headliner is ready to shine in your next meeting."
        }
    }
    
    // Bullets for the left-panel checklist
    var explainerBullets: [ExplainerBullet] {
        switch self {
        case .welcome:
            return [
                .init(symbol: "sparkles", title: "Whats Headliner", detail: "Clean overlays that look great in Meet and Zoom."),
                .init(symbol: "hand.tap", title: "Simple steps", detail: "Install, personalize, preview — then you're ready."),
                .init(symbol: "lock.shield", title: "Private by design", detail: "Runs locally; you control what's shown.")
            ]
        case .install:
            return [
                .init(symbol: "bolt.badge.a", title: "System extension", detail: "macOS may prompt for approval."),
                .init(symbol: "checkmark.seal", title: "One-time setup", detail: "You won't need to do this again."),
                .init(symbol: "questionmark.circle", title: "Stuck?", detail: "We'll show clear instructions if approval fails.")
            ]
        case .personalize:
            return [
                .init(symbol: "textformat", title: "Display name", detail: "Shown in your overlay."),
                .init(symbol: "camera.fill", title: "Select camera", detail: "Choose your input camera for the live preview."),
                .init(symbol: "rectangle.roundedtop", title: "Style", detail: "Rounded or Square to match your vibe.")
            ]
        case .preview:
            return [
                .init(symbol: "camera.viewfinder", title: "Live preview", detail: "What others will see in Meet/Zoom."),
                .init(symbol: "slider.horizontal.3", title: "Adjust quickly", detail: "Tweak name, title, or style on the fly."),
                .init(symbol: "key", title: "Privacy", detail: "Turn overlays off anytime from the menu bar.")
            ]
        case .done:
            return [
                .init(symbol: "sparkles", title: "Pick 'Headliner Camera'", detail: "Select it in Meet or Zoom."),
                .init(symbol: "menubar.rectangle", title: "Menu bar control", detail: "Start/stop, overlay picker, settings."),
                .init(symbol: "text.bubble", title: "Try a demo call", detail: "Use Photo Booth or FaceTime to test it.")
            ]
        }
    }
    
    // Time estimate for the step
    var timeEstimate: String {
        switch self {
        case .welcome: return "~1 min"
        case .install: return "~30 sec"
        case .personalize: return "~20 sec"
        case .preview: return "~10 sec"
        case .done: return "Done ✨"
        }
    }
    
    // SF Symbol used in the header area
    var systemImage: String {
        switch self {
        case .welcome: return "sparkles"
        case .install: return "bolt.badge.a"
        case .personalize: return "person.crop.circle.badge.checkmark"
        case .preview: return "camera.viewfinder"
        case .done: return "checkmark.seal"
        }
    }
    
    // Legacy properties for compatibility
    var title: String { explainerTitle }
    var subtitle: String { explainerSubtitle }
    var stepTitle: String { railTitle }
}

#if DEBUG
struct OnboardingStep_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach(OnboardingStep.allCases) { step in
                HStack(spacing: 12) {
                    Image(systemName: step.systemImage)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.headline)
                        Text(step.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
        }
        .padding()
        .frame(width: 500)
    }
}
#endif
