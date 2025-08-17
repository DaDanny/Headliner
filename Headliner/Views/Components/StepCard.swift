//
//  StepCard.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

/// Main content card for onboarding steps with actions and progress
struct StepCard: View {
    let title: String
    let body: String?
    let bullets: [String]?
    let primaryTitle: String
    let primaryAction: () -> Void
    let secondaryTitle: String?
    let secondaryAction: (() -> Void)?
    let progressIndex: Int
    let isLoading: Bool
    let isInteractive: Bool
    
    init(
        title: String,
        body: String? = nil,
        bullets: [String]? = nil,
        primaryTitle: String,
        primaryAction: @escaping () -> Void,
        secondaryTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        progressIndex: Int,
        isLoading: Bool = false,
        isInteractive: Bool = true
    ) {
        self.title = title
        self.body = body
        self.bullets = bullets
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
        self.progressIndex = progressIndex
        self.isLoading = isLoading
        self.isInteractive = isInteractive
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            if progressIndex > 0 {
                HStack {
                    Spacer()
                    Text("Step \(progressIndex) of \(OnboardingPhase.totalSteps)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)
            }
            
            VStack(spacing: 24) {
                // Content
                VStack(spacing: 16) {
                    // Body text
                    if let body = body {
                        Text(body)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Bullet points
                    if let bullets = bullets {
                        VStack(spacing: 12) {
                            ForEach(bullets, id: \.self) { bullet in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 6, height: 6)
                                        .alignmentGuide(.firstTextBaseline) { d in d[.top] + 8 }
                                    
                                    Text(bullet)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                
                // Loading indicator
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                        
                        if !primaryTitle.isEmpty {
                            Text(primaryTitle)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 16)
                }
                
                // Action buttons
                if isInteractive && !isLoading {
                    VStack(spacing: 12) {
                        // Primary action
                        if !primaryTitle.isEmpty {
                            Button(action: primaryAction) {
                                HStack {
                                    Text(primaryTitle)
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Secondary action
                        if let secondaryTitle = secondaryTitle,
                           let secondaryAction = secondaryAction {
                            Button(action: secondaryAction) {
                                Text(secondaryTitle)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .underline()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StepCard(
            title: "Install Headliner Camera",
            bullets: [
                "Lets apps like Zoom/Meet use Headliner's video",
                "You'll approve it in System Settings",
                "One-time setup for all your video calls"
            ],
            primaryTitle: "Install & Enable",
            primaryAction: {},
            secondaryTitle: "Open System Settings",
            secondaryAction: {},
            progressIndex: 1
        )
        
        StepCard(
            title: "Starting Camera",
            primaryTitle: "Starting camera...",
            primaryAction: {},
            progressIndex: 2,
            isLoading: true,
            isInteractive: false
        )
    }
    .frame(width: 500, height: 600)
    .background(Color(NSColor.windowBackgroundColor))
}