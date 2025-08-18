//
//  LowerThirdOverlay.swift
//  Headliner
//
//  SwiftUI view for lower third overlay rendering.
//

import SwiftUI

struct LowerThirdOverlay: View {
    let props: OverlayProps
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                // Lower third container
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // Main title
                        if !props.title.isEmpty {
                            Text(props.title)
                                .font(.system(size: titleFontSize(for: geometry), weight: .semibold, design: .default))
                                .foregroundColor(props.theme.textColor)
                                .lineLimit(1)
                        }
                        
                        // Subtitle
                        if let subtitle = props.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: subtitleFontSize(for: geometry), weight: .medium, design: .default))
                                .foregroundColor(props.theme.textColor.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Optional accent element
                    Circle()
                        .fill(props.theme.primaryColor)
                        .frame(width: accentSize(for: geometry), height: accentSize(for: geometry))
                        .opacity(props.theme == .minimal ? 0 : 1)
                }
                .padding(.horizontal, props.padding)
                .padding(.vertical, props.padding * 0.75)
                .background(
                    RoundedRectangle(cornerRadius: props.cornerRadius)
                        .fill(props.theme.backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: props.cornerRadius)
                                .stroke(props.theme.primaryColor.opacity(0.3), lineWidth: strokeWidth)
                        )
                )
                .padding(.horizontal, props.padding)
                .padding(.bottom, props.padding * 1.5)
            }
        }
        .frame(width: props.targetResolution.width, height: props.targetResolution.height)
    }
    
    // MARK: - Dynamic Sizing
    
    private func titleFontSize(for geometry: GeometryProxy) -> CGFloat {
        // Scale font size based on target resolution height
        // Base size is 36pt for 1080p
        let baseSize: CGFloat = 36
        let scaleFactor = props.targetResolution.height / 1080
        return baseSize * scaleFactor * props.scale
    }
    
    private func subtitleFontSize(for geometry: GeometryProxy) -> CGFloat {
        // Subtitle is 75% of title size
        titleFontSize(for: geometry) * 0.75
    }
    
    private func accentSize(for geometry: GeometryProxy) -> CGFloat {
        // Scale accent element based on font size
        titleFontSize(for: geometry) * 0.6
    }
    
    private var strokeWidth: CGFloat {
        let baseWidth: CGFloat = 1.5
        let scaleFactor = props.targetResolution.height / 1080
        return baseWidth * scaleFactor * props.scale
    }
}

// MARK: - Preview

struct LowerThirdOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Professional theme
            LowerThirdOverlay(props: OverlayProps(
                id: "lower_third_professional",
                name: "Lower Third Professional",
                title: "Danny Francken",
                subtitle: "Senior Software Engineer",
                theme: .professional,
                targetResolution: CGSize(width: 1920, height: 1080)
            ))
            .previewDisplayName("Professional")
            
            // Creative theme
            LowerThirdOverlay(props: OverlayProps(
                id: "lower_third_creative",
                name: "Lower Third Creative", 
                title: "Creative Director",
                subtitle: "Making pixels dance",
                theme: .creative,
                targetResolution: CGSize(width: 1920, height: 1080)
            ))
            .previewDisplayName("Creative")
            
            // Minimal theme
            LowerThirdOverlay(props: OverlayProps(
                id: "lower_third_minimal",
                name: "Lower Third Minimal",
                title: "John Smith",
                subtitle: "Product Designer",
                theme: .minimal,
                targetResolution: CGSize(width: 1920, height: 1080)
            ))
            .previewDisplayName("Minimal")
            
            // Bold theme
            LowerThirdOverlay(props: OverlayProps(
                id: "lower_third_bold",
                name: "Lower Third Bold",
                title: "Sarah Wilson",
                subtitle: "CEO & Founder",
                theme: .bold,
                targetResolution: CGSize(width: 1920, height: 1080)
            ))
            .previewDisplayName("Bold")
        }
        .frame(width: 960, height: 540) // Half-size preview
        .background(Color.gray.opacity(0.3)) // Simulate video background
    }
}