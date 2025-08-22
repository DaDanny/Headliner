//
//  StatusBadge.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Live/recording status indicator badge
struct StatusBadge: View {
    let status: Status
    
    enum Status {
        case live
        case recording
        case offline
        case custom(String, Color)
        
        var text: String {
            switch self {
            case .live: return "LIVE"
            case .recording: return "REC"
            case .offline: return "OFFLINE"
            case .custom(let text, _): return text
            }
        }
        
        var color: Color {
            switch self {
            case .live: return .red
            case .recording: return .orange
            case .offline: return .gray
            case .custom(_, let color): return color
            }
        }
    }
    
    init(status: Status = .live) {
        self.status = status
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Pulsing indicator dot
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: status.color)
            
            Text(status.text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.black.opacity(0.8))
                .overlay(
                    Capsule()
                        .stroke(status.color.opacity(0.6), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        StatusBadge(status: .live)
        StatusBadge(status: .recording)
        StatusBadge(status: .offline)
        StatusBadge(status: .custom("ON AIR", .purple))
    }
    .padding()
    .background(.black)
}
#endif
