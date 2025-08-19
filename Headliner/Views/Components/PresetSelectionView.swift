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
    
    @StateObject private var manifestManager = PresetManifestManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Built-in Presets Section with Beautiful Grid
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Built-in Templates")
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                
                Text("Professional overlays designed for business and personal use")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                // Use the beautiful OverlayPresetGrid
                OverlayPresetGrid(
                    selectedPresetId: selectedPresetId,
                    onPresetSelected: { presetId in
                        selectedPresetId = presetId
                        onSelectionChanged(presetId)
                    },
                    columns: 3,
                    cardSize: CGSize(width: 140, height: 80),
                    spacing: 12,
                    showLabels: true
                )
            }
            
            // Custom Compiled Templates Section
            if manifestManager.hasCompiledPresets {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.caption)
                        Text("Custom Templates")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Developer-created overlays with modern design")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(manifestManager.getCompiledPresets()) { preset in
                            CustomTemplateCard(
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

// MARK: - Custom Template Card

struct CustomTemplateCard: View {
    let preset: PresetManifest.Preset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Template preview area
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [
                                Color.purple.opacity(0.8),
                                Color.blue.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        )
                    
                    // Template icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(height: 60)
                
                // Template name with custom badge
                HStack(spacing: 4) {
                    Text(preset.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("CUSTOM")
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
                
                // Template description
                Text(preset.description)
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
}

// MARK: - Preset Manifest Models

struct PresetManifest: Codable {
    let generatedAt: String
    let version: String
    let presets: [Preset]
    
    struct Preset: Codable, Identifiable {
        let name: String
        let id: String
        let templateFile: String
        let description: String
    }
}

// MARK: - Preset Manifest Manager

class PresetManifestManager: ObservableObject {
    static let shared = PresetManifestManager()
    
    @Published var availablePresets: [PresetManifest.Preset] = []
    @Published var hasCompiledPresets: Bool = false
    
    private init() {
        loadManifest()
    }
    
    private func loadManifest() {
        guard let url = Bundle.main.url(forResource: "PresetManifest", withExtension: "json") else {
            hasCompiledPresets = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let manifest = try JSONDecoder().decode(PresetManifest.self, from: data)
            availablePresets = manifest.presets
            hasCompiledPresets = !manifest.presets.isEmpty
        } catch {
            print("Failed to load PresetManifest.json: \(error)")
            hasCompiledPresets = false
        }
    }
    
    func getCompiledPresets() -> [PresetManifest.Preset] {
        return availablePresets
    }
}

#Preview {
    PresetSelectionView(
        selectedPresetId: .constant("professional"),
        onSelectionChanged: { _ in }
    )
    .padding()
    .background(Color.black)
}
