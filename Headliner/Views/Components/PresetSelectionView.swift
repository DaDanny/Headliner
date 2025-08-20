//
//  PresetSelectionView.swift
//  Headliner
//
//  View for selecting overlay presets from both compiled templates and built-in presets
//

import SwiftUI

struct PresetSelectionView: View {
    @Binding var selectedPresetId: String
    let onSelectionChanged: (String) -> Void
    
    // Load all available presets dynamically
    private var allPresets: [OverlayPreset] {
        return OverlayPresets.allPresets
    }
    
    // Group presets by category
    private var modernPresets: [OverlayPreset] {
        return allPresets.filter { 
            ["modern-card", "glass-pill", "minimal-clean", "vibrant-creative"].contains($0.id) 
        }
    }
    
    private var classicPresets: [OverlayPreset] {
        return allPresets.filter { 
            ["professional", "personal", "professional-custom", "personal-custom"].contains($0.id) 
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Modern Presets Section
            if !modernPresets.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.caption)
                        Text("Modern Designs")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Beautiful, modern overlay designs perfect for any use case")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(modernPresets, id: \.id) { preset in
                            ModernPresetCard(
                                preset: preset,
                                isSelected: selectedPresetId == preset.id
                            ) {
                                selectedPresetId = preset.id
                                onSelectionChanged(preset.id)
                            }
                        }
                    }
                }
            }
            
            // Classic Presets Section
            if !classicPresets.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Classic Templates")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Traditional overlay styles for business and personal use")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(classicPresets, id: \.id) { preset in
                            ClassicPresetCard(
                                preset: preset,
                                isSelected: selectedPresetId == preset.id
                            ) {
                                selectedPresetId = preset.id
                                onSelectionChanged(preset.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Modern Preset Card

struct ModernPresetCard: View {
    let preset: OverlayPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Preview area with style-specific design
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(presetGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        )
                    
                    // Style-specific icon
                    Image(systemName: presetIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(height: 60)
                
                // Preset name with modern badge
                HStack(spacing: 4) {
                    Text(preset.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                
                // Preset description
                Text(presetDescription)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.white.opacity(0.8) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var presetGradient: LinearGradient {
        switch preset.id {
        case "modern-card":
            return LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "glass-pill":
            return LinearGradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "minimal-clean":
            return LinearGradient(colors: [Color.gray.opacity(0.6), Color.black.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "vibrant-creative":
            return LinearGradient(colors: [Color.red.opacity(0.7), Color.teal.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var presetIcon: String {
        switch preset.id {
        case "modern-card": return "rectangle.fill"
        case "glass-pill": return "capsule.fill"
        case "minimal-clean": return "minus"
        case "vibrant-creative": return "paintbrush.fill"
        default: return "sparkles"
        }
    }
    
    private var presetDescription: String {
        switch preset.id {
        case "modern-card": return "Clean white card with accent bar"
        case "glass-pill": return "Glassmorphic pill design"
        case "minimal-clean": return "Ultra-minimal name display"
        case "vibrant-creative": return "Bold gradients & decorations"
        default: return "Custom overlay design"
        }
    }
}

// MARK: - Classic Preset Card

struct ClassicPresetCard: View {
    let preset: OverlayPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Preview area
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [
                                Color.orange.opacity(0.7),
                                Color.yellow.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        )
                    
                    // Classic icon
                    Image(systemName: classicIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(height: 60)
                
                // Preset name
                Text(preset.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Preset description
                Text(classicDescription)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.white.opacity(0.8) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var classicIcon: String {
        switch preset.id {
        case "professional", "professional-custom": return "briefcase.fill"
        case "personal", "personal-custom": return "person.fill"
        default: return "star.fill"
        }
    }
    
    private var classicDescription: String {
        switch preset.id {
        case "professional": return "Business lower-third style"
        case "personal": return "Weather & location info"
        case "professional-custom": return "Custom professional design"
        case "personal-custom": return "Custom personal design"
        default: return "Classic overlay style"
        }
    }
}

// MARK: - Preview

#Preview {
    PresetSelectionView(
        selectedPresetId: .constant("professional"),
        onSelectionChanged: { _ in }
    )
    .padding()
    .background(Color.black)
}
