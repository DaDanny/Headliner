//
//  StatusNote.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

/// Small status note component for helpful text and warnings
struct StatusNote: View {
    let text: String
    let style: Style
    
    enum Style {
        case info
        case warning
        case success
        
        var icon: String {
            switch self {
            case .info:
                return "info.circle"
            case .warning:
                return "exclamationmark.triangle"
            case .success:
                return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .info:
                return .secondary
            case .warning:
                return .orange
            case .success:
                return .green
            }
        }
    }
    
    init(_ text: String, style: Style = .info) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: style.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(style.color)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(style.color)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(style.color.opacity(0.1))
        )
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StatusNote("This may momentarily reload audio/video services.", style: .info)
        
        StatusNote("Camera access denied. Enable in System Settings.", style: .warning)
        
        StatusNote("Look for 'Headliner' in your video app's camera selection menu.", style: .success)
    }
    .frame(width: 500, height: 200)
    .background(Color(NSColor.windowBackgroundColor))
}