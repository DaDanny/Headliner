//
//  StepHeader.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

/// Header component for onboarding steps with icon, title, and subtitle
struct StepHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.white)
            }
            .shadow(color: .blue.opacity(0.2), radius: 12, x: 0, y: 4)
            
            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 24)
    }
}

// MARK: - Preview

#Preview {
    StepHeader(
        icon: "arrow.down.circle",
        title: "Install Headliner Camera",
        subtitle: "One-time setup so Meet/Zoom can see your video."
    )
    .frame(width: 400, height: 300)
    .background(Color(NSColor.windowBackgroundColor))
}