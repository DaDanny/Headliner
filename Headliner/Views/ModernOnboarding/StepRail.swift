//
//  StepRail.swift
//  Headliner
//
//  Vertical step progress indicator for onboarding
//

import SwiftUI

struct StepRail: View {
    let steps: [OnboardingStep]
    let current: OnboardingStep
    var showsProgressCaption: Bool = true
    var onSelect: ((OnboardingStep) -> Void)? = nil  // pass to allow jumping, or nil to disable

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            if showsProgressCaption, let idx = steps.firstIndex(of: current) {
                Text("Step \(idx + 1) of \(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 2)
                    .transition(.opacity)
            }

            ForEach(steps) { step in
                StepRailRowTextOnly(
                    title: step.railTitle,
                    isCurrent: step == current,
                    isCompleted: step.rawValue < current.rawValue
                )
                .contentShape(Rectangle()) // full-row hit area
                .onTapGesture {
                    onSelect?(step)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: 130)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeInOut(duration: 0.18), value: current)
    }
}

private struct StepRailRowTextOnly: View {
    let title: String
    let isCurrent: Bool
    let isCompleted: Bool
    @State private var isHovering = false

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        // Apple-y: weight + opacity + subtle capsule for current
        Text(title)
            .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
            .foregroundStyle(
                isCurrent ? .primary : (isCompleted ? .secondary : .tertiary)
            )
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(isHovering ? 0.05 : 0))
            )
            .onHover { hovering in isHovering = hovering }
            .animation(.easeInOut(duration: 0.15), value: isHovering)
    }

    @ViewBuilder
    private var background: some View {
        if isCurrent {
            // a gentle tint fill + hairline stroke feels native
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.tint.opacity(scheme == .dark ? 0.14 : 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.tint.opacity(0.55), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        } else {
            Color.clear
        }
    }
}

#if DEBUG
struct StepRail_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 32) {
               ForEach([OnboardingStep.welcome, .install, .personalize, .preview, .done], id: \.self) { currentStep in
                   VStack(alignment: .leading, spacing: 8) {
                       Text("Current: \(currentStep.stepTitle)")
                           .font(.caption)
                           .foregroundStyle(.secondary)

                       StepRail(
                           steps: OnboardingStep.allCases,
                           current: currentStep,
                           showsProgressCaption: true,
                           onSelect: { _ in } // or nil to disable selection
                       )
                       .frame(height: 300)
                   }
               }
           }
           .padding(24)
           .background(Color(nsColor: .windowBackgroundColor))
    }
}
#endif
