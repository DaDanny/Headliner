//
//  MetricTicker.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Live metrics display (followers, views, etc.)
struct MetricTicker: View {
    let label: String
    let value: String
    let accentColor: Color
    
    init(label: String, value: String, accentColor: Color = .green) {
        self.label = label
        self.value = value
        self.accentColor = accentColor
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Live indicator dot
            Circle()
                .fill(accentColor)
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        MetricTicker(
            label: "Viewers",
            value: "1.2K",
            accentColor: .red
        )
        
        MetricTicker(
            label: "Followers",
            value: "42.5K",
            accentColor: Color(hex: "#118342")
        )
        
        MetricTicker(
            label: "Live",
            value: "ON AIR",
            accentColor: .orange
        )
    }
    .padding()
    .background(.black)
}
#endif
