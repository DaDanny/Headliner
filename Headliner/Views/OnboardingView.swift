//
//  OnboardingView.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 24) {
                // App Icon/Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "video.circle.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.white)
                }
                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 8)
                
                VStack(spacing: 12) {
                    Text("Welcome to Headliner")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Professional virtual camera for macOS")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(appVersionText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 48)
            
            // Features Section
            VStack(spacing: 24) {
                FeatureRow(
                    icon: "text.badge.star",
                    title: "Configurable Overlays",
                    description: "Add your display name and version badge to the video feed."
                )

                FeatureRow(
                    icon: "video.and.waveform",
                    title: "High-Quality Streaming",
                    description: "Stream in HD quality to any app that supports video cameras."
                )

                FeatureRow(
                    icon: "gear.badge.checkmark",
                    title: "Easy Setup",
                    description: "Simple one-click installation of the system extension."
                )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
            
            Spacer()
            
            // Installation Section
            VStack(spacing: 20) {
                if appState.extensionStatus == .installing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                        
                        Text("Installing System Extension...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                } else {
                    VStack(spacing: 16) {
                        Text("To get started, we need to install a system extension")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        PulsingButton(
                            title: "Install System Extension",
                            icon: "arrow.down.circle",
                            color: .blue,
                            isActive: appState.extensionStatus == .installing
                        ) {
                            appState.installExtension()
                        }
                    }
                }
                
                // Status message
                if !appState.statusMessage.isEmpty {
                    Text(appState.statusMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                AnimatedBackground()
                    .opacity(0.1)
                FloatingParticles()
                    .opacity(0.3)
            }
        )
    }

    private var appVersionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "v\(shortVersion) (\(buildNumber))"
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(
            appState: AppState(
                systemExtensionManager: SystemExtensionRequestManager(logText: ""),
                propertyManager: CustomPropertyManager(),
                outputImageManager: OutputImageManager()
            )
        )
        .frame(width: 800, height: 600)
    }
}