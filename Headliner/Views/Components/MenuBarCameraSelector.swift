//
//  MenuBarCameraSelector.swift
//  Headliner
//
//  Created by AI Assistant on 8/22/25.
//

import SwiftUI

/// Camera selector optimized for MenuBar interface
/// Uses MenuBarViewModel instead of direct AppState access
struct MenuBarCameraSelector: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var isExpanded = false
    @State private var hoveringID: String? = nil
    
    private var selectedCamera: CameraDevice? {
        viewModel.cameras.first { $0.id == viewModel.selectedCameraID }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current selection display
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 10) {
                    Image(systemName: symbol(for: selectedCamera))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(selectedCamera?.name ?? "No Camera")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(selectedCamera?.deviceType ?? "Select a camera")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.05))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded camera list
            if isExpanded {
                VStack(spacing: 2) {
                    // "No Camera" option
                    CameraMenuRow(
                        id: "",
                        name: "No Camera",
                        deviceType: "Disable input",
                        symbol: "video.slash",
                        isSelected: viewModel.selectedCameraID.isEmpty,
                        hoveringID: $hoveringID
                    ) {
                        viewModel.selectCamera(id: "")
                        isExpanded = false
                    }
                    
                    // Available cameras
                    ForEach(viewModel.cameras, id: \.id) { camera in
                        CameraMenuRow(
                            id: camera.id,
                            name: camera.name,
                            deviceType: camera.deviceType,
                            symbol: symbol(for: camera),
                            isSelected: camera.id == viewModel.selectedCameraID,
                            hoveringID: $hoveringID
                        ) {
                            viewModel.selectCamera(camera)
                            isExpanded = false
                        }
                    }
                }
                .padding(.top, 4)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
    
    private func symbol(for camera: CameraDevice?) -> String {
        guard let camera else { return "video.slash" }
        if camera.deviceType.contains("iPhone") || camera.deviceType.contains("Continuity") { return "iphone" }
        if camera.deviceType.contains("External") { return "camera.on.rectangle" }
        if camera.deviceType.contains("Desk View") { return "camera.macro" }
        return "camera"
    }
}

// MARK: - Supporting Components

/// Individual camera row in the menu
private struct CameraMenuRow: View {
    let id: String
    let name: String
    let deviceType: String
    let symbol: String
    let isSelected: Bool
    @Binding var hoveringID: String?
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 14)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(deviceType)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering in
            hoveringID = isHovering ? id : nil
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if hoveringID == id {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }
}

#if DEBUG
struct MenuBarCameraSelector_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarCameraSelector(viewModel: .createMinimalMock())
            .frame(width: 280)
            .padding()
            .previewDisplayName("MenuBar Camera Selector")
            .previewLayout(.sizeThatFits)
    }
}
#endif