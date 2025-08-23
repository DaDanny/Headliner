//
//  OverlaySettingsMenu.swift
//  Headliner
//
//  Created by Danny Francken on 8/22/25.
//

import SwiftUI

struct PillSegmented<T: Hashable>: View {
    let items: [T]
    let label: (T) -> (title: String, systemImage: String?)
    @Binding var selection: T
    var height: CGFloat = 34
    var cornerRadius: CGFloat = 8

    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                let isSelected = item == selection
                Button {
                    selection = item
                } label: {
                    HStack(spacing: 6) {
                        if let sf = label(item).systemImage {
                            Image(systemName: sf).font(.system(size: 12, weight: .medium))
                        }
                        Text(label(item).title)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: cornerRadius - 2)
                                .fill(Color.accentColor)
                                .matchedGeometryEffect(id: "pill", in: ns)
                        }
                    }
                )
                .foregroundStyle(isSelected ? .white : .primary)
            }
        }
        .frame(height: height)
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.primary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct OverlaySettingsMenu: View {
    @ObservedObject var viewModel: MenuBarViewModel
    let onBack: () -> Void
    
    @State private var overlayStyle: OverlayStyle = .rounded
    @State private var hoveredOverlayID: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with back button - compact like Settings
            headerSection
            
            Divider()
                .padding(.horizontal, 12)
            
            // Style toggle section
            styleToggleSection
                .padding(.top, 8)
            
            Divider()
                .padding(.horizontal, 12)
            
            // Overlay list with section headers
            overlayListSection
        }
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        ZStack {
                // Centered title
                Text("Choose Overlay")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                // Leading back button
                HStack {
                    Button(action: onBack) {
                        Label("Back", systemImage: "chevron.left")
                            .labelStyle(.titleAndIcon)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.link)
                    .controlSize(.small)     // tighter macOS chrome
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 48)
    }
    
    // MARK: - Style Toggle Section
    
    private var styleToggleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
                Text("Style")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                PillSegmented(
                    items: OverlayStyle.allCases,
                    label: { style in (style.rawValue, style.icon) },
                    selection: $overlayStyle,
                    height: 32,                 // make it taller here (e.g., 36–40)
                    cornerRadius: 9
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
    }
    
    
    // MARK: - Overlay List Section
    
    private var overlayListSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(SwiftUIPresetCategory.allCases, id: \.self) { category in
                    let categoryOverlays = overlaysForCategory(category)
                    
                    if !categoryOverlays.isEmpty {
                        // Section header
                        OverlaySectionHeader(category: category, count: categoryOverlays.count)
                            .padding(.top, category == SwiftUIPresetCategory.allCases.first ? 4 : 12)
                            .padding(.bottom, 6)
                        
                        // Section overlays
                        ForEach(categoryOverlays, id: \.id) { overlay in
                            OverlayListRow(
                                overlay: overlay,
                                isSelected: overlay.id == viewModel.selectedOverlayID,
                                isHovered: hoveredOverlayID == overlay.id,
                                style: overlayStyle
                            ) {
                                viewModel.selectOverlay(overlay.id)
                                onBack()
                            }
                            .onHover { isHovering in
                                hoveredOverlayID = isHovering ? overlay.id : nil
                            }
                            .padding(.bottom, 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(maxHeight: 350)
    }
    
    // MARK: - Helper Properties
    
    private func overlaysForCategory(_ category: SwiftUIPresetCategory) -> [SwiftUIPresetInfo] {
        viewModel.overlays.filter { $0.category == category }
    }
}

// MARK: - Supporting Types

enum OverlayStyle: String, CaseIterable {
    case rounded = "Rounded"
    case square = "Square"
    
    var icon: String {
        switch self {
        case .rounded: return "rectangle.roundedtop"
        case .square: return "rectangle"
        }
    }
}

// MARK: - Supporting Components

/// Section header for overlay categories
struct OverlaySectionHeader: View {
    let category: SwiftUIPresetCategory
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(category.color)
            
            Text(category.rawValue.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))
                )
        }
        .padding(.horizontal, 4)
    }
}

/// Individual overlay row in list format
struct OverlayListRow: View {
    let overlay: SwiftUIPresetInfo
    let isSelected: Bool
    let isHovered: Bool
    let style: OverlayStyle
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Preview thumbnail
                previewThumbnail
                
                // Overlay info
                VStack(alignment: .leading, spacing: 2) {
                    Text(overlay.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(overlay.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: style == .rounded ? 8 : 4)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ? nil : .easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {
            onSelect()
        }
    }
    
    private var previewThumbnail: some View {
        RoundedRectangle(cornerRadius: style == .rounded ? 6 : 3)
            .fill(
                LinearGradient(
                    colors: [overlay.category.color.opacity(0.3), overlay.category.color.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 48, height: 30)
            .overlay(
                VStack(spacing: 1) {
                    Image(systemName: overlay.category.icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(overlay.category.color)
                    
                    if overlay.name.count <= 8 {
                        Text(overlay.name.prefix(4))
                            .font(.system(size: 6, weight: .medium))
                            .foregroundColor(overlay.category.color.opacity(0.8))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: style == .rounded ? 6 : 3)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.12)
        } else if isHovered {
            return Color.primary.opacity(0.06)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Preview

#if DEBUG
struct OverlaySettingsMenu_Previews: PreviewProvider {
    static var previews: some View {
        // Single, simplified preview to avoid timeout
        OverlaySettingsMenu(
            viewModel: .createMinimalMock(),
            onBack: { }
        )
        .frame(width: 320, height: 500)
        .previewDisplayName("Overlay Settings Menu")
        .previewLayout(.sizeThatFits)
    }
}

// Separate preview for dark mode if needed
struct OverlaySettingsMenuDark_Previews: PreviewProvider {
    static var previews: some View {
        OverlaySettingsMenu(
            viewModel: .createMinimalMock(),
            onBack: { }
        )
        .frame(width: 320, height: 500)
        .preferredColorScheme(.dark)
        .previewDisplayName("Overlay Settings - Dark")
        .previewLayout(.sizeThatFits)
    }
}
#endif
