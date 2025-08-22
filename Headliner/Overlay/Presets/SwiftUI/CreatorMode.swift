//
//  CreatorMode.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Creator mode preset with social badges and live metrics
struct CreatorMode: OverlayViewProviding {
    static let presetId = "swiftui.creator.mode"
    static let defaultSize = CGSize(width: 1920, height: 1080)

    func makeView(tokens: OverlayTokens) -> some View {
        let settings = getOverlaySettings()
        let accentColor = TokenHelpers.accentColor(from: tokens)
        let socialHandles = TokenHelpers.extractSocialHandles(from: tokens)
        
        SafeAreaContainer(mode: settings.safeAreaMode) {
            VStack {
                // Top area for live status and metrics
                HStack {
                    StatusBadge(status: .live)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        MetricTicker(label: "Viewers", value: "1.2K", accentColor: accentColor)
                        MetricTicker(label: "Followers", value: "42.5K", accentColor: accentColor)
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom area for identity and social
                HStack {
                    BottomBarV2(
                        displayName: tokens.displayName,
                        tagline: tokens.tagline,
                        accentColor: accentColor
                    )
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        // Social media handles
                        HStack(spacing: 6) {
                            if let twitterHandle = socialHandles["twitter"] {
                                SocialBadge(platform: .twitter, handle: twitterHandle)
                            }
                            if let instagramHandle = socialHandles["instagram"] {
                                SocialBadge(platform: .instagram, handle: instagramHandle)
                            }
                            if let youtubeHandle = socialHandles["youtube"] {
                                SocialBadge(platform: .youtube, handle: youtubeHandle)
                            }
                        }
                        
                        if let time = tokens.localTime {
                            TimeTicker(time: time)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#if DEBUG
#Preview {
    var previewTokens = OverlayTokens.previewDanny
    previewTokens.extras = [
        "twitter": "dannyfrancken",
        "instagram": "danny.codes",
        "youtube": "DevByDanny"
    ]
    
    return CreatorMode()
        .makeView(tokens: previewTokens)
        .frame(width: 1920, height: 1080)
        .background(.black)
}
#endif
