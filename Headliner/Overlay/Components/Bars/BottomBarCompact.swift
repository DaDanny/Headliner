//
//  BottomBarCompact.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Minimal, compact bottom bar for subtle overlays
struct BottomBarCompact: View {
    let displayName: String
    let tagline: String?
    let accentColor: Color
    
    @Environment(\.theme) private var theme

    init(displayName: String, tagline: String? = nil, accentColor: Color = .green) {
        self.displayName = displayName
        self.tagline = tagline
        self.accentColor = accentColor
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Accent line indicator
            Rectangle()
                .fill(accentColor)
                .frame(width: 3, height: 24)
                .cornerRadius(1.5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                if let tagline = tagline, !tagline.isEmpty {
                    Text(tagline)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
#Preview {
    BottomBarCompact(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342")
    )
    .padding()
    .background(.black)
    .environment(\.theme, .classic)
}
#endif
