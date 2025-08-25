//
//  OnboardingScaffold.swift
//  Headliner
//
//  Consistent layout scaffold for all onboarding steps
//

import SwiftUI

struct OnboardingScaffold<Content: View>: View {
    let step: OnboardingStep
    let onBack: () -> Void
    let onNext: () -> Void
    let nextTitle: String
    let isNextPrimary: Bool
    let canGoBack: Bool
    let canGoNext: Bool
    @ViewBuilder var content: () -> Content
    
    init(
        step: OnboardingStep,
        onBack: @escaping () -> Void,
        onNext: @escaping () -> Void,
        nextTitle: String = "Continue",
        isNextPrimary: Bool = false,
        canGoBack: Bool = true,
        canGoNext: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.step = step
        self.onBack = onBack
        self.onNext = onNext
        self.nextTitle = nextTitle
        self.isNextPrimary = isNextPrimary
        self.canGoBack = canGoBack && step != .welcome
        self.canGoNext = canGoNext
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Label(step.stepTitle, systemImage: step.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // Body content
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            
            // Footer
            Divider()
            
            HStack {
                Button("Back", action: onBack)
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                    .disabled(!canGoBack)
                    .opacity(canGoBack ? 1 : 0.5)
                
                Spacer()
                
                if isNextPrimary {
                    Button(nextTitle, action: onNext)
                        .keyboardShortcut(.return)
                        .buttonStyle(.borderedProminent)
                        .disabled(!canGoNext)
                } else {
                    Button(nextTitle, action: onNext)
                        .keyboardShortcut(.rightArrow, modifiers: [.command])
                        .disabled(!canGoNext)
                }
            }
            .padding(20)
        }
        .frame(width: 900, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#if DEBUG
struct OnboardingScaffold_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Welcome step (no back button)
            OnboardingScaffold(
                step: .welcome,
                onBack: {},
                onNext: {},
                nextTitle: "Get Started"
            ) {
                VStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    
                    Text("Welcome Content")
                        .font(.title)
                    
                    Text("This is the welcome step content area")
                        .foregroundStyle(.secondary)
                }
            }
            .previewDisplayName("Welcome Step")
            
            // Install step with primary button
            OnboardingScaffold(
                step: .install,
                onBack: {},
                onNext: {},
                nextTitle: "Install",
                isNextPrimary: true
            ) {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(2)
                    
                    Text("Installing...")
                        .font(.title2)
                    
                    Text("Installation in progress")
                        .foregroundStyle(.secondary)
                }
            }
            .previewDisplayName("Install Step")
            
            // Done step
            OnboardingScaffold(
                step: .done,
                onBack: {},
                onNext: {},
                nextTitle: "Finish",
                isNextPrimary: true
            ) {
                VStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                    
                    Text("All Done!")
                        .font(.title)
                    
                    Text("Setup is complete")
                        .foregroundStyle(.secondary)
                }
            }
            .previewDisplayName("Done Step")
        }
    }
}
#endif
