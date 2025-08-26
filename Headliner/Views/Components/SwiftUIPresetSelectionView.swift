//
//  SwiftUIPresetSelectionView.swift
//  Headliner
//
//  Clean preset selection view using the new SwiftUI registry system
//

import SwiftUI

struct SwiftUIPresetSelectionView: View {
    @Binding var selectedPresetId: String
    let onSelectionChanged: (String) -> Void
    
    // Sample tokens for previews
    private let previewTokens = OverlayTokens(
        displayName: "Danny Francken",
        tagline: "Senior Developer",
        accentColorHex: "#007AFF"
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // SwiftUI Presets by Category
            ForEach(SwiftUIPresetCategory.allCases, id: \.self) { category in
                let presetsInCategory = SwiftUIPresetRegistry.presets(in: category)
                
                if !presetsInCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        // Category Header
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .font(.caption)
                            Text(category.rawValue)
                                .font(.headline)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        
                        Text(categoryDescription(for: category))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Preset Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(presetsInCategory, id: \.id) { preset in
                                SwiftUIPresetCardNew(
                                    preset: preset,
                                    isSelected: selectedPresetId == preset.id,
                                    previewTokens: previewTokens
                                ) {
                                    selectedPresetId = preset.id
                                    onSelectionChanged(preset.id)
                                }
                            }
                        }
                    }
                }
            }
            
            // That's it! Only SwiftUI presets now. 🎉
        }
    }
    
    private func categoryDescription(for category: SwiftUIPresetCategory) -> String {
        switch category {
        case .standard:
            return "Professional lower thirds and standard overlay layouts"
        case .branded:
            return "Company branding with logos and accent elements"
        case .creative:
            return "Dynamic displays with animations and unique layouts"
        case .debug:
            return "Debug overlays for testing and development"
        case .minimal:
            return "Clean, minimal designs with subtle styling"
        }
    }
}

// MARK: - SwiftUI Preset Card with Live Preview

struct SwiftUIPresetCardNew: View {
    let preset: SwiftUIPresetInfo
    let isSelected: Bool
    let previewTokens: OverlayTokens
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Live Preview
                SwiftUIPresetPreview(
                    preset: preset,
                    tokens: previewTokens,
                    size: CGSize(width: 120, height: 80)
                )
                .scaleEffect(0.7) // Scale down for card view
                .frame(height: 60)
                .clipped()
                
                // Preset Info
                VStack(spacing: 4) {
                    Text(preset.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(preset.description)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(preset.category.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? preset.category.color : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Legacy preset card removed - SwiftUI-only system now! 🚀

// MARK: - Preview

#Preview {
    SwiftUIPresetSelectionView(
        selectedPresetId: .constant("swiftui.standard.lowerthird"),
        onSelectionChanged: { _ in }
    )
    .padding()
    .background(Color.black)
    .frame(width: 400, height: 600)
}
