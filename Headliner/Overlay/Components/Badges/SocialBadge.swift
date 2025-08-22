//
//  SocialBadge.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Social media handle display badge
struct SocialBadge: View {
    let platform: Platform
    let handle: String
    
    enum Platform {
        case twitter
        case instagram
        case tiktok
        case youtube
        case linkedin
        case custom(String, Color)
        
        var symbol: String {
            switch self {
            case .twitter: return "@"
            case .instagram: return "@"
            case .tiktok: return "@"
            case .youtube: return "▶"
            case .linkedin: return "in"
            case .custom(let symbol, _): return symbol
            }
        }
        
        var color: Color {
            switch self {
            case .twitter: return Color(hex: "#1DA1F2")
            case .instagram: return Color(hex: "#E4405F")
            case .tiktok: return Color(hex: "#FF0050")
            case .youtube: return Color(hex: "#FF0000")
            case .linkedin: return Color(hex: "#0077B5")
            case .custom(_, let color): return color
            }
        }
    }
    
    init(platform: Platform, handle: String) {
        self.platform = platform
        self.handle = handle
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(platform.symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(platform.color)
            
            Text(handle)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(platform.color.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        SocialBadge(platform: .twitter, handle: "dannyfrancken")
        SocialBadge(platform: .instagram, handle: "danny.codes")
        SocialBadge(platform: .youtube, handle: "DevByDanny")
        SocialBadge(platform: .linkedin, handle: "dannyfrancken")
        SocialBadge(platform: .custom("🎵", .purple), handle: "spotify/danny")
    }
    .padding()
    .background(.black)
}
#endif
