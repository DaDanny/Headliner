//
//  PresetRail.swift
//  Headliner
//
//  Vertical preset selector for modern onboarding preview step
//

import SwiftUI

struct PresetRail: View {
    let presets: [SwiftUIPresetInfo]
    @Binding var selectedID: String?
    var onSelect: (SwiftUIPresetInfo) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 16)
                
                Text("Overlays")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(presets, id: \.id) { preset in
                        Button {
                            onSelect(preset)
                        } label: {
                            PresetRow(
                                preset: preset,
                                isSelected: preset.id == selectedID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
        .frame(width: 220)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
}

private struct PresetRow: View {
    let preset: SwiftUIPresetInfo
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail with category icon
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.callout.weight(isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                Text(preset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#if DEBUG
struct PresetRail_Previews: PreviewProvider {
    static var previews: some View {
        PresetRail(
            presets: [
                SwiftUIPresetInfo(
                    id: "test1",
                    name: "Professional",
                    description: "Clean identity strip",
                    category: .standard,
                    provider: Clean()
                ),
                SwiftUIPresetInfo(
                    id: "test2",
                    name: "Modern Personal",
                    description: "Personal with modern look",
                    category: .standard,
                    provider: Clean()
                )
            ],
            selectedID: .constant("test1"),
            onSelect: { _ in }
        )
        .padding()
        .frame(width: 300, height: 400)
    }
}
#endif
