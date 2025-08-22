//
//  LogoBadge.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Company/brand logo display badge
struct LogoBadge: View {
    let logoText: String?
    let accentColor: Color
    
    init(logoText: String? = nil, accentColor: Color = .green) {
        self.logoText = logoText
        self.accentColor = accentColor
    }
    
    var body: some View {
        if let logoText = logoText, !logoText.isEmpty {
            Text(logoText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        LogoBadge(
            logoText: "BONUSLY",
            accentColor: Color(hex: "#118342")
        )
        
        LogoBadge(
            logoText: "ACME CORP",
            accentColor: .blue
        )
        
        LogoBadge(
            logoText: "TECH CO",
            accentColor: .purple
        )
    }
    .padding()
    .background(.black)
}
#endif
