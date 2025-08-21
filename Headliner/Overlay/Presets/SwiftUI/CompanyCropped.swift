//
//  CompanyCropped.swift
//  Headliner
//
//  Company overlay optimized for 4:3 aspect ratio presentations
//  Designed to work well in cropped video frames without responsiveness
//

import SwiftUI

/// Company overlay designed specifically for 4:3 aspect ratios and cropped presentations
/// This overlay is optimized for meeting presentations and doesn't use responsive scaling
struct CompanyCropped: OverlayViewProviding {
    
    static let presetId = "company-cropped"
    static let defaultSize = CGSize(width: 800, height: 600) // 4:3 aspect ratio
    
    func makeView(tokens: OverlayTokens) -> some View {
        GeometryReader { geometry in
            // Calculate 4:3 container size that fits within the camera resolution
            let fourThreeSize = calculateFourThreeSize(for: geometry.size)
            
            ZStack {
                // Full camera resolution background (transparent)
                Color.clear
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // 4:3 cropped container centered in the frame
                makeContent(tokens: tokens, in: fourThreeSize)
                    .frame(width: fourThreeSize.width, height: fourThreeSize.height)
                    .clipShape(Rectangle()) // Crop to 4:3
                    .background(
                        // Optional: subtle border to show 4:3 area
                        Rectangle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
    
    private func calculateFourThreeSize(for cameraSize: CGSize) -> CGSize {
        let targetAspectRatio: CGFloat = 4.0 / 3.0
        let cameraAspectRatio = cameraSize.width / cameraSize.height
        
        if cameraAspectRatio > targetAspectRatio {
            // Camera is wider than 4:3, fit by height
            let height = cameraSize.height * 0.9 // Use 90% of height for padding
            let width = height * targetAspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Camera is taller than 4:3, fit by width
            let width = cameraSize.width * 0.9 // Use 90% of width for padding
            let height = width / targetAspectRatio
            return CGSize(width: width, height: height)
        }
    }
    
    private func makeContent(tokens: OverlayTokens, in size: CGSize) -> some View {
        // Responsive scaling optimized for 4:3 presentations
        // Scale based on width, designed for 4:3 aspect ratios
        let scaleFactor = size.width / 800.0 // Base design width for 4:3
        let baseFontScale = max(scaleFactor, 0.5) // Minimum scale to ensure readability
        
        let accent = Color(hex: tokens.accentColorHex, default: .blue)
        let accentLight = accent.lighten(0.3)
        let accentDark = accent.darken(0.2)
        
        return ZStack {
            // Full demo layout showcasing ALL features
            VStack(spacing: 0) {
                upperBanner(tokens: tokens, accent: accent, accentLight: accentLight, scale: baseFontScale)
                Spacer()
                lowerInfo(tokens: tokens, accent: accent, accentDark: accentDark, scale: baseFontScale)
            }
            
            // Side panel with Bonusly logo - always show for demo
            HStack {
                VStack(alignment: .leading, spacing: 8 * baseFontScale) {
                    // Bonusly logo - always show for professional presentation
                    brandLogo(logoText: tokens.logoText ?? "BONUSLY", accent: accent, scale: baseFontScale)
                    Spacer()
                }
                .padding(.leading, 40 * baseFontScale)
                .padding(.top, 120 * baseFontScale)
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func upperBanner(tokens: OverlayTokens, accent: Color, accentLight: Color, scale: CGFloat) -> some View {
        HStack {
            Spacer()
            
            VStack(spacing: 4) {
                // Company/Brand name - Responsive
                Text(tokens.displayName)
                    .font(.system(size: 72 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 4 * scale, x: 0, y: 3 * scale)
                
                // Tagline if available - Responsive
                if let tagline = tokens.tagline, !tagline.isEmpty {
                    Text(tagline)
                        .font(.system(size: 42 * scale, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.8), radius: 3 * scale, x: 0, y: 2 * scale)
                }
            }
            .padding(.horizontal, 40 * scale)
            .padding(.vertical, 24 * scale)
            .background(
                // Gradient pill background
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accentLight.opacity(0.85), accent.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
        .padding(.top, 40 * scale)
    }
    
    @ViewBuilder
    private func lowerInfo(tokens: OverlayTokens, accent: Color, accentDark: Color, scale: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 16 * scale) {
            // Left side - Enhanced status info with ALL features
            VStack(alignment: .leading, spacing: 16 * scale) {
                HStack(spacing: 16 * scale) {
                    // Location - Only show if available
                    if let city = tokens.city, !city.isEmpty {
                        largeInfoChip(
                            icon: "location.fill",
                            text: city,
                            backgroundColor: accentDark.opacity(0.8),
                            scale: scale
                        )
                    }
                    
                    // Weather with emoji - Only show if available
                    if let weather = tokens.weatherText, !weather.isEmpty {
                        let emoji = tokens.weatherEmoji ?? "🌤️"
                        largeInfoChip(
                            icon: nil,
                            text: "\(emoji) \(weather)",
                            backgroundColor: Color.blue.opacity(0.8),
                            scale: scale
                        )
                    }
                }
                
                // Note: Removed outdated "HD Quality" indicator - this isn't 2015!
            }
            
            Spacer()
            
            // Right side - Enhanced time display
            if let time = tokens.localTime, !time.isEmpty {
                VStack(alignment: .trailing, spacing: 8 * scale) {
                    // Animated LIVE indicator
                    HStack(spacing: 8 * scale) {
                        Circle()
                            .fill(.red)
                            .frame(width: 24 * scale, height: 24 * scale)
                        Text("LIVE")
                            .font(.system(size: 36 * scale, weight: .black, design: .rounded))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 24 * scale)
                    .padding(.vertical, 12 * scale)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.95))
                    )
                    
                    Text(time)
                        .font(.system(size: 60 * scale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40 * scale)
                        .padding(.vertical, 24 * scale)
                        .background(
                            RoundedRectangle(cornerRadius: 20 * scale)
                                .fill(Color.black.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20 * scale)
                                        .stroke(accent.opacity(0.7), lineWidth: 4 * scale)
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4 * scale, x: 0, y: 2 * scale)
                }
            }
        }
        .padding(.horizontal, 40 * scale)
        .padding(.bottom, 40 * scale)
    }
    
    @ViewBuilder
    private func infoChip(icon: String?, text: String, backgroundColor: Color) -> some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private func largeInfoChip(icon: String?, text: String, backgroundColor: Color, scale: CGFloat) -> some View {
        HStack(spacing: 16 * scale) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 36 * scale, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(text)
                .font(.system(size: 36 * scale, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 30 * scale)
        .padding(.vertical, 18 * scale)
        .background(
            RoundedRectangle(cornerRadius: 20 * scale)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20 * scale)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2 * scale)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 6 * scale, x: 0, y: 3 * scale)
    }
    
    @ViewBuilder
    private func brandLogo(logoText: String, accent: Color, scale: CGFloat) -> some View {
        VStack(spacing: 8 * scale) {
            // Bonusly logo container
            RoundedRectangle(cornerRadius: 16 * scale)
                .fill(accent) // White background for logo visibility
                .frame(width: 120 * scale, height: 80 * scale)
                .overlay(
                    // Bonusly Mark logo
                    Image("Images/Bonusly-Mark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100 * scale, height: 60 * scale)
                        .clipped()
                )
            
            Text("PARTNER")
                .font(.system(size: 16 * scale, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
                .tracking(2 * scale)
        }
        .padding(16 * scale)
        .background(
            RoundedRectangle(cornerRadius: 20 * scale)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20 * scale)
                        .stroke(accent.opacity(0.6), lineWidth: 2 * scale)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 4 * scale, x: 0, y: 2 * scale)
    }
}

#if DEBUG
struct CompanyCropped_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTokens = OverlayTokens(
            displayName: "DevByDanny Studios",
            tagline: "Building the Future",
            accentColorHex: "#0066CC",
            localTime: "2:30 PM",
            logoText: "BONUSLY",
            extras: [
                "location": "San Francisco, CA",
                "weatherEmoji": "☀️",
                "weatherText": "72°F Sunny"
            ]
        )
        
        VStack(spacing: 20) {
            // 4:3 aspect ratio preview
            CompanyCropped()
                .makeView(tokens: sampleTokens)
                .frame(width: 800, height: 600) // 4:3 ratio
                .background(
                    // Simulated video background
                    LinearGradient(
                        colors: [.gray.opacity(0.3), .gray.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(8)
                .shadow(radius: 5)
            
            Text("4:3 Company Cropped Overlay")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.black.opacity(0.1))
    }
}
#endif
