//
//  PersonalTemplate.swift
//  OverlayTemplates
//
//  Personal overlay template with weather integration and modern card design.
//  Perfect for casual streams, personal content, and location-based overlays.
//

import Foundation
import SwiftUI

/// Personal overlay with weather integration and card design
struct PersonalTemplate: OverlayTemplate {
    
    // MARK: - Template Info
    
    static let templateId = "personal-custom"
    static let displayName = "Personal Custom"
    static let description = "Weather-integrated card design perfect for casual streams and personal content"
    
    // MARK: - SwiftUI Preview
    
    static var previewView: AnyView {
        AnyView(PersonalTemplatePreview())
    }
    
    // MARK: - Template Compilation
    
    static func compile() -> OverlayPreset {
        return OverlayPreset(
            id: templateId,
            name: displayName,
            nodes: [
                // Background card with subtle shadow effect
                BaseOverlayTemplate.solidRect(
                    color: BaseOverlayTemplate.Colors.white,
                    cornerRadius: 0.03
                ),
                
                // Accent gradient bar
                BaseOverlayTemplate.gradientBackground(
                    startColor: BaseOverlayTemplate.Gradients.purpleToBlue.start,
                    endColor: BaseOverlayTemplate.Gradients.purpleToBlue.end,
                    angle: 90
                ),
                
                // Weather emoji
                .text(TextNode(
                    text: "{weatherEmoji}",
                    fontWeight: "regular",
                    colorHex: "#1f2937",
                    alignment: "center"
                )),
                
                // City name
                .text(TextNode(
                    text: "{city}",
                    fontWeight: "medium",
                    colorHex: "#6b7280",
                    alignment: "center"
                )),
                
                // Local time
                .text(TextNode(
                    text: "{localTime}",
                    fontWeight: "regular",
                    colorHex: "#9ca3af",
                    alignment: "center"
                )),
                
                // Weather description
                .text(TextNode(
                    text: "{weatherText}",
                    fontWeight: "medium",
                    colorHex: "#6b7280",
                    alignment: "center"
                )),
                
                // Decorative dots
                BaseOverlayTemplate.solidRect(
                    color: "#e5e7eb",
                    cornerRadius: 0.5
                ),
                
                BaseOverlayTemplate.solidRect(
                    color: "#e5e7eb",
                    cornerRadius: 0.5
                ),
                
                BaseOverlayTemplate.solidRect(
                    color: "#e5e7eb",
                    cornerRadius: 0.5
                )
            ],
            layout: OverlayLayout(
                widescreen: [
                    // Background card - small and at bottom left (matching working coordinates)
                    OverlayNodePlacement(
                        index: 0,
                        frame: NRect(x: 0.02, y: 0.75, w: 0.18, h: 0.12),
                        zIndex: 0,
                        opacity: 0.95
                    ),
                    
                    // Accent gradient bar at top of card
                    OverlayNodePlacement(
                        index: 1,
                        frame: NRect(x: 0.02, y: 0.75, w: 0.18, h: 0.01),
                        zIndex: 1,
                        opacity: 1.0
                    ),
                    
                    // Weather emoji (smaller)
                    OverlayNodePlacement(
                        index: 2,
                        frame: NRect(x: 0.08, y: 0.78, w: 0.06, h: 0.05),
                        zIndex: 2,
                        opacity: 1.0
                    ),
                    
                    // City name
                    OverlayNodePlacement(
                        index: 3,
                        frame: NRect(x: 0.03, y: 0.815, w: 0.16, h: 0.03),
                        zIndex: 2,
                        opacity: 1.0
                    ),
                    
                    // Local time
                    OverlayNodePlacement(
                        index: 4,
                        frame: NRect(x: 0.03, y: 0.785, w: 0.16, h: 0.03),
                        zIndex: 2,
                        opacity: 0.8
                    ),
                    
                    // Weather description
                    OverlayNodePlacement(
                        index: 5,
                        frame: NRect(x: 0.03, y: 0.755, w: 0.16, h: 0.03),
                        zIndex: 2,
                        opacity: 0.9
                    ),
                    
                    // Decorative dots (left)
                    OverlayNodePlacement(
                        index: 6,
                        frame: NRect(x: 0.03, y: 0.73, w: 0.01, h: 0.01),
                        zIndex: 1,
                        opacity: 0.6
                    ),
                    
                    // Decorative dots (center)
                    OverlayNodePlacement(
                        index: 7,
                        frame: NRect(x: 0.10, y: 0.73, w: 0.01, h: 0.01),
                        zIndex: 1,
                        opacity: 0.6
                    ),
                    
                    // Decorative dots (right)
                    OverlayNodePlacement(
                        index: 8,
                        frame: NRect(x: 0.17, y: 0.73, w: 0.01, h: 0.01),
                        zIndex: 1,
                        opacity: 0.6
                    )
                ],
                fourThree: [
                    // Background card - small and at bottom left (matching working coordinates)
                    OverlayNodePlacement(
                        index: 0,
                        frame: NRect(x: 0.02, y: 0.72, w: 0.22, h: 0.14),
                        zIndex: 0,
                        opacity: 0.95
                    ),
                    
                    // Accent gradient bar at top of card
                    OverlayNodePlacement(
                        index: 1,
                        frame: NRect(x: 0.02, y: 0.72, w: 0.22, h: 0.01),
                        zIndex: 1,
                        opacity: 1.0
                    ),
                    
                    // Weather emoji (smaller)
                    OverlayNodePlacement(
                        index: 2,
                        frame: NRect(x: 0.08, y: 0.75, w: 0.08, h: 0.06),
                        zIndex: 2,
                        opacity: 1.0
                    ),
                    
                    // City name
                    OverlayNodePlacement(
                        index: 3,
                        frame: NRect(x: 0.03, y: 0.795, w: 0.20, h: 0.035),
                        zIndex: 2,
                        opacity: 1.0
                    ),
                    
                    // Local time
                    OverlayNodePlacement(
                        index: 4,
                        frame: NRect(x: 0.03, y: 0.760, w: 0.20, h: 0.035),
                        zIndex: 2,
                        opacity: 0.8
                    ),
                    
                    // Weather description
                    OverlayNodePlacement(
                        index: 5,
                        frame: NRect(x: 0.03, y: 0.725, w: 0.20, h: 0.035),
                        zIndex: 2,
                        opacity: 0.9
                    ),
                    
                    // Decorative dots (left)
                    OverlayNodePlacement(
                        index: 6,
                        frame: NRect(x: 0.03, y: 0.70, w: 0.01, h: 0.01),
                        zIndex: 1,
                        opacity: 0.6
                    ),
                    
                    // Decorative dots (center)
                    OverlayNodePlacement(
                        index: 7,
                        frame: NRect(x: 0.12, y: 0.70, w: 0.01, h: 0.01),
                        zIndex: 1,
                        opacity: 0.6
                    ),
                    
                    // Decorative dots (right)
                    OverlayNodePlacement(
                        index: 8,
                        frame: NRect(x: 0.21, y: 0.70, w: 0.01, h: 0.01),
                        zIndex: 1,
                        opacity: 0.6
                    )
                ]
            )
        )
    }
}

// MARK: - SwiftUI Preview

/// SwiftUI preview for the Personal template
struct PersonalTemplatePreview: View {
    
    @State private var city = "San Francisco"
    @State private var localTime = "2:30 PM"
    @State private var weatherEmoji = "☀️"
    @State private var weatherText = "72°F Sunny"
    @State private var selectedAspectRatio: CGFloat = 16.0/9.0
    @State private var showGrid = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Personal Template")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Weather-integrated card design for personal content")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Aspect ratio controls
            HStack {
                Text("Aspect Ratio:")
                    .font(.headline)
                
                Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                    Text("16:9 (Widescreen)").tag(16.0/9.0)
                    Text("4:3 (Standard)").tag(4.0/3.0)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Toggle("Show Grid", isOn: $showGrid)
            }
            .padding(.horizontal)
            
            // Preview with video frame bounds
            TemplatePreviewContainer(aspectRatio: selectedAspectRatio, showGrid: showGrid) {
                ZStack {
                    // Background card - now small and at bottom left
                    VStack {
                        Spacer()
                        
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.95))
                                .frame(width: 280, height: 120)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            Spacer()
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.leading, 40)
                    
                    // Accent gradient bar at top of card
                    VStack {
                        Spacer()
                        
                        HStack {
                            LinearGradient(
                                colors: [
                                    Color.blue,
                                    Color.purple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 280, height: 8)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            
                            Spacer()
                        }
                        .padding(.bottom, 152)
                        .padding(.leading, 40)
                    }
                    
                    // Content - positioned within the small card
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 8) {
                                // Weather emoji
                                Text(weatherEmoji)
                                    .font(.system(size: 32))
                                
                                // City and info
                                VStack(spacing: 4) {
                                    Text(city)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text(localTime)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                        .opacity(0.8)
                                    
                                    Text(weatherText)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .opacity(0.9)
                                }
                            }
                            .frame(width: 280, height: 120)
                            .padding(.bottom, 40)
                            .padding(.trailing, 40)
                        }
                    }
                    
                    // Decorative dots - positioned above the small card
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 20) {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 6, height: 6)
                                    .opacity(0.6)
                                
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 6, height: 6)
                                    .opacity(0.6)
                                
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 6, height: 6)
                                    .opacity(0.6)
                            }
                        }
                        .padding(.bottom, 170)
                        .padding(.trailing, 40)
                    }
                }
            }
            .frame(maxWidth: 1200, maxHeight: 800)
            
            // Controls
            VStack(spacing: 12) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("City")
                            .font(.headline)
                        TextField("Enter city", text: $city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Local Time")
                            .font(.headline)
                        TextField("Enter time", text: $localTime)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weather Emoji")
                            .font(.headline)
                        TextField("Weather emoji", text: $weatherEmoji)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weather Text")
                            .font(.headline)
                        TextField("Weather description", text: $weatherText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle("Personal Template")
    }
}



// MARK: - SwiftUI Preview Provider

#if DEBUG
struct PersonalTemplate_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PersonalTemplatePreview()
        }
    }
}
#endif
