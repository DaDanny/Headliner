//
//  BottomBarV2.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Bottom bar with profile circle and accent gradient
struct BottomBarV2: View {
    let displayName: String
    let tagline: String?
    let accentColor: Color
    
    init(displayName: String, tagline: String? = nil, accentColor: Color = .green) {
        self.displayName = displayName
        self.tagline = tagline
        self.accentColor = accentColor
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile circle with accent gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.lighten(0.2), accentColor, accentColor.darken(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
                .overlay(
                    Text(String(displayName.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)

                if let tagline = tagline, !tagline.isEmpty {
                    Text(tagline)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
#Preview {
    BottomBarV2(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342")
    )
    .padding()
    .background(.black)
}
#endif
