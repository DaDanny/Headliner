//
//  SwiftUIOverlayRenderer.swift
//  HeadlinerShared
//
//  Created by AI Assistant on 8/2/25.
//  
//  Proof-of-concept: Render SwiftUI views to images for overlay system
//

import SwiftUI
import CoreImage
import CoreGraphics

@available(iOS 16.0, macOS 13.0, *)
class SwiftUIOverlayRenderer {
    
    // Simple cache for rendered images
    private var imageCache: [String: CGImage] = [:]
    
    /// Render a SwiftUI overlay to a CGImage
    func renderOverlay(tokens: OverlayTokens, size: CGSize, presetId: String = "") async -> CIImage? {
        let cacheKey = "\(tokens.displayName)_\(tokens.tagline ?? "")_\(tokens.accentColorHex)_\(presetId)_\(size.width)x\(size.height)"
        
        // Check cache first
        if let cached = imageCache[cacheKey] {
            return CIImage(cgImage: cached)
        }
        
        // Render on main actor to handle SwiftUI properly
        let cgImage = await MainActor.run {
            // Create SwiftUI view
            let overlayView = createOverlayView(tokens: tokens, presetId: presetId)
            
            // Render to image
            let renderer = ImageRenderer(content: overlayView)
            renderer.proposedSize = ProposedViewSize(size)
            renderer.scale = 2.0 // Retina quality
            
            return renderer.cgImage
        }
        
        guard let cgImage = cgImage else {
            print("Failed to render SwiftUI view to image")
            return nil
        }
        
        // Cache the result
        imageCache[cacheKey] = cgImage
        
        return CIImage(cgImage: cgImage)
    }
    
    /// Create a SwiftUI overlay view (this is where the magic happens!)
    private func createOverlayView(tokens: OverlayTokens, presetId: String = "") -> some View {
        // Check if this is the flashy demo
        let isFlashyDemo = presetId == "swiftui-demo-2"
        
        if isFlashyDemo {
            return AnyView(createFlashyOverlay(tokens: tokens))
        } else {
            return AnyView(createStandardOverlay(tokens: tokens))
        }
    }
    
    /// Standard SwiftUI overlay (original design)
    private func createStandardOverlay(tokens: OverlayTokens) -> some View {
        ZStack {
            // Transparent background
            Color.clear
            
            VStack {
                Spacer()
                
                // Bottom card with name and tagline
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tokens.displayName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if let tagline = tokens.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Simple logo placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("LOGO")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            
            // Top-right time chip (if we have time data)
            VStack {
                HStack {
                    Spacer()
                    
                    if let localTime = tokens.localTime, !localTime.isEmpty {
                        Text(localTime)
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.8), in: Capsule())
                    }
                }
                .padding(.top, 40)
                .padding(.trailing, 40)
                
                Spacer()
            }
        }
    }
    
    /// Flashy SwiftUI overlay with Bonusly branding (static design)
    private func createFlashyOverlay(tokens: OverlayTokens) -> some View {
        ZStack {
            // Transparent background
            Color.clear
            
            // Top-left Bonusly logo
            VStack {
                HStack {
                    HStack(spacing: 8) {
                        // Compact Bonusly logo
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 35, height: 35)
                            .overlay(
                                Text("B")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            )
                        
                        Text("BONUSLY")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.leading, 30)
                
                Spacer()
            }
            
            // Top-right time chip
            VStack {
                HStack {
                    Spacer()
                    
                    if let localTime = tokens.localTime, !localTime.isEmpty {
                        Text(localTime)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
                .padding(.top, 20)
                .padding(.trailing, 30)
                
                Spacer()
            }
            
            // Bottom name card
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tokens.displayName)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                        
                        if let tagline = tokens.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                    }
                    
                    Spacer()
                    
                    // Compact celebration element
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow, .orange],
                                center: .center,
                                startRadius: 5,
                                endRadius: 25
                            )
                        )
                        .frame(width: 45, height: 45)
                        .overlay(
                            Text("🎉")
                                .font(.system(size: 20))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
    
    /// Clear the image cache
    func clearCache() {
        imageCache.removeAll()
    }
}