//
//  ProfessionalTemplate.swift
//  OverlayTemplates
//
//  Professional overlay template with gradient background and modern typography.
//  Perfect for business meetings, presentations, and professional content.
//

import Foundation
import SwiftUI

/// Professional overlay with gradient background and clean typography
struct ProfessionalTemplate: OverlayTemplate {
    
    // MARK: - Template Info
    
    static let templateId = "professional-custom"
    static let displayName = "Professional Custom"
    static let description = "Modern gradient background with clean typography, perfect for business meetings"
    
    // MARK: - SwiftUI Preview
    
    static var previewView: AnyView {
        AnyView(ProfessionalTemplatePreview())
    }
    
    // MARK: - Template Compilation
    
    static func compile() -> OverlayPreset {
        return OverlayPreset(
            id: templateId,
            name: displayName,
            nodes: [
                // Background gradient
                BaseOverlayTemplate.gradientBackground(
                    startColor: BaseOverlayTemplate.Gradients.oceanBlue.start,
                    endColor: BaseOverlayTemplate.Gradients.oceanBlue.end,
                    angle: 135
                ),
                
                // Accent bar at bottom
                BaseOverlayTemplate.solidRect(
                    color: BaseOverlayTemplate.Colors.white,
                    cornerRadius: 0.02
                ),
                
                // Main name text
                BaseOverlayTemplate.displayNameText(
                    color: BaseOverlayTemplate.Colors.white,
                    weight: "bold",
                    alignment: "left"
                ),
                
                // Tagline text
                BaseOverlayTemplate.taglineText(
                    color: "#e2e8f0",
                    weight: "medium",
                    alignment: "left"
                ),
                
                // Decorative accent circle
                BaseOverlayTemplate.decorativeCircle(
                    color: BaseOverlayTemplate.Colors.orange
                )
            ],
            layout: OverlayLayout(
                widescreen: [
                    // Background gradient (full screen)
                    BaseOverlayTemplate.fullScreenBackground(nodeIndex: 0),
                    
                    // Accent bar at bottom
                    BaseOverlayTemplate.bottomAccentBar(nodeIndex: 1),
                    
                    // Main name text
                    BaseOverlayTemplate.lowerLeftText(
                        nodeIndex: 2,
                        x: 0.08, y: 0.15, width: 0.6, height: 0.12
                    ),
                    
                    // Tagline text
                    BaseOverlayTemplate.lowerLeftText(
                        nodeIndex: 3,
                        x: 0.08, y: 0.28, width: 0.6, height: 0.08
                    ),
                    
                    // Decorative accent circle
                    BaseOverlayTemplate.upperRightDecoration(nodeIndex: 4)
                ],
                fourThree: [
                    // Background gradient (full screen)
                    BaseOverlayTemplate.fullScreenBackground(nodeIndex: 0),
                    
                    // Accent bar at bottom
                    BaseOverlayTemplate.bottomAccentBar(nodeIndex: 1),
                    
                    // Main name text
                    BaseOverlayTemplate.lowerLeftText(
                        nodeIndex: 2,
                        x: 0.08, y: 0.15, width: 0.6, height: 0.12
                    ),
                    
                    // Tagline text
                    BaseOverlayTemplate.lowerLeftText(
                        nodeIndex: 3,
                        x: 0.08, y: 0.28, width: 0.6, height: 0.08
                    ),
                    
                    // Decorative accent circle
                    BaseOverlayTemplate.upperRightDecoration(nodeIndex: 4)
                ]
            )
        )
    }
}

// MARK: - SwiftUI Preview

/// SwiftUI preview for the Professional template
struct ProfessionalTemplatePreview: View {
    
    @State private var displayName = "Sarah Chen"
    @State private var tagline = "Senior Product Designer"
    @State private var selectedAspectRatio: CGFloat = 16.0/9.0
    @State private var showGrid = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Professional Template")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Modern gradient background with clean typography")
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
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.blue,
                        Color.purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    // Overlay content
                    ZStack {
                        // Accent bar at bottom
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.white.opacity(0.9))
                                .frame(height: 8)
                                .padding(.bottom, 20)
                        }
                        
                        // Text content positioned in lower left
                        VStack {
                            Spacer()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(displayName)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(tagline)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // Decorative circle in upper right area
                                VStack {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 60, height: 60)
                                        .opacity(0.8)
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 60)
                        }
                    }
                )
            }
            .frame(maxWidth: 1200, maxHeight: 800)
            
            // Controls
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.headline)
                    TextField("Enter name", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tagline")
                        .font(.headline)
                    TextField("Enter tagline", text: $tagline)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle("Professional Template")
    }
}

// MARK: - SwiftUI Preview Provider

#if DEBUG
struct ProfessionalTemplate_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfessionalTemplatePreview()
        }
    }
}
#endif
