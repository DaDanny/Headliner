//
//  OverlayCatalog.swift
//  Headliner
//
//  Catalog of available SwiftUI overlays.
//

import SwiftUI

// MARK: - Overlay Catalog

/// Central catalog for mapping preset IDs to SwiftUI overlay views
struct OverlayCatalog {
    
    /// Build a SwiftUI view for the given overlay properties
    @ViewBuilder
    static func view(for props: OverlayProps) -> some View {
        switch props.id {
        case "lower_third":
            LowerThirdOverlay(props: props)
        case "corner_badge":
            CornerBadgeOverlay(props: props)
        default:
            // Fallback to lower third for unknown IDs
            LowerThirdOverlay(props: props)
        }
    }
    
    /// Get all available overlay presets
    static var availablePresets: [OverlayPresetDescriptor] {
        [
            OverlayPresetDescriptor(
                id: "lower_third",
                name: "Lower Third",
                description: "Classic lower third overlay with title and subtitle",
                supportsSubtitle: true,
                recommendedAspects: [.widescreen, .standard]
            ),
            OverlayPresetDescriptor(
                id: "corner_badge",
                name: "Corner Badge", 
                description: "Simple badge in the corner with your name",
                supportsSubtitle: false,
                recommendedAspects: [.widescreen, .standard, .square]
            )
        ]
    }
}

// MARK: - Preset Descriptor

/// Metadata about an overlay preset
struct OverlayPresetDescriptor: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let supportsSubtitle: Bool
    let recommendedAspects: [AspectBucket]
    
    /// Generate sample props for this preset
    func sampleProps(
        title: String = "Your Name",
        subtitle: String? = "Your Title", 
        theme: OverlayTheme = .professional,
        aspectBucket: AspectBucket = .widescreen
    ) -> OverlayProps {
        OverlayProps(
            id: id,
            name: name,
            title: title,
            subtitle: supportsSubtitle ? subtitle : nil,
            theme: theme,
            targetResolution: aspectBucket.targetResolution(),
            aspectBucket: aspectBucket
        )
    }
}

// MARK: - Additional Overlay Views

/// Simple corner badge overlay
struct CornerBadgeOverlay: View {
    let props: OverlayProps
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Spacer()
                    
                    // Corner badge
                    Text(props.title)
                        .font(.system(size: badgeFontSize(for: geometry), weight: .medium, design: .default))
                        .foregroundColor(props.theme.textColor)
                        .padding(.horizontal, props.padding)
                        .padding(.vertical, props.padding * 0.5)
                        .background(
                            RoundedRectangle(cornerRadius: props.cornerRadius)
                                .fill(props.theme.backgroundColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: props.cornerRadius)
                                        .stroke(props.theme.primaryColor.opacity(0.4), lineWidth: strokeWidth)
                                )
                        )
                        .padding(.trailing, props.padding)
                        .padding(.top, props.padding)
                }
                
                Spacer()
            }
        }
        .frame(width: props.targetResolution.width, height: props.targetResolution.height)
    }
    
    private func badgeFontSize(for geometry: GeometryProxy) -> CGFloat {
        // Smaller font for corner badge
        let baseSize: CGFloat = 24
        let scaleFactor = props.targetResolution.height / 1080
        return baseSize * scaleFactor * props.scale
    }
    
    private var strokeWidth: CGFloat {
        let baseWidth: CGFloat = 1.0
        let scaleFactor = props.targetResolution.height / 1080
        return baseWidth * scaleFactor * props.scale
    }
}