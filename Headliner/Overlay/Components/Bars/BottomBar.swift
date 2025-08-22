//
//  BottomBar.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Clean, professional bottom bar for displaying name and tagline
struct BottomBar: View {
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
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
#Preview {
    BottomBar(
        displayName: "Danny F",
        tagline: "High School Intern",
        accentColor: Color(hex: "#118342")
    )
    .padding()
    .background(.black)
}
#endif
