//
//  BottomBarGlass.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Glassmorphic bottom bar with modern blur effects
struct BottomBarGlass: View {
    let displayName: String
    let tagline: String?
    let accentColor: Color
    
    init(displayName: String, tagline: String? = nil, accentColor: Color = .green) {
        self.displayName = displayName
        self.tagline = tagline
        self.accentColor = accentColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
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
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .white.opacity(0.1),
                                    accentColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

#if DEBUG
#Preview {
    BottomBarGlass(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342")
    )
    .padding()
    .background(.black)
}
#endif
