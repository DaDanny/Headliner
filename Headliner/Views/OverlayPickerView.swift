//
//  OverlayPickerView.swift
//  Headliner
//
//  UI for selecting and configuring SwiftUI overlays.
//

import SwiftUI
import Combine

// MARK: - Overlay Picker View

struct OverlayPickerView: View {
    @StateObject private var viewModel = OverlayPickerViewModel()
    @State private var selectedTheme: OverlayTheme = .professional
    @State private var selectedAspectBucket: AspectBucket = .widescreen
    @State private var userTitle: String = ""
    @State private var userSubtitle: String = ""
    @State private var overlayEnabled: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Video Overlays")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Enable/Disable toggle
                Toggle("Enable Overlays", isOn: $overlayEnabled)
                    .onChange(of: overlayEnabled) { enabled in
                        if enabled {
                            viewModel.updateOverlay()
                        } else {
                            viewModel.clearOverlay()
                        }
                    }
            }
            
            if overlayEnabled {
                // Overlay preset selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overlay Style")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(OverlayCatalog.availablePresets) { preset in
                                OverlayPresetCard(
                                    preset: preset,
                                    isSelected: viewModel.selectedPresetID == preset.id,
                                    onSelect: {
                                        viewModel.selectPreset(preset.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Configuration section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Customization")
                        .font(.headline)
                    
                    // User text inputs
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter your name", text: $userTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: userTitle) { _ in
                                viewModel.updateContent(title: userTitle, subtitle: userSubtitle)
                            }
                    }
                    
                    // Subtitle (if selected preset supports it)
                    if viewModel.selectedPresetSupportsSubtitle {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Title")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your title/role", text: $userSubtitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: userSubtitle) { _ in
                                    viewModel.updateContent(title: userTitle, subtitle: userSubtitle)
                                }
                        }
                    }
                    
                    // Theme selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Theme")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Theme", selection: $selectedTheme) {
                            ForEach(OverlayTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedTheme) { theme in
                            viewModel.updateTheme(theme)
                        }
                    }
                    
                    // Aspect ratio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Video Format")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Aspect Ratio", selection: $selectedAspectBucket) {
                            ForEach(AspectBucket.allCases, id: \.self) { aspect in
                                Text(aspect.displayName).tag(aspect)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedAspectBucket) { aspect in
                            viewModel.updateAspectBucket(aspect)
                        }
                    }
                }
            }
            
            // Status/Debug info (if enabled)
            if viewModel.showDebugInfo {
                OverlayStatusView(viewModel: viewModel)
                
                // Advanced diagnostics
                OverlayDiagnosticsView()
            }
        }
        .padding()
        .onAppear {
            // Load saved settings
            viewModel.loadSettings()
            userTitle = viewModel.currentTitle
            userSubtitle = viewModel.currentSubtitle
            selectedTheme = viewModel.currentTheme
            selectedAspectBucket = viewModel.currentAspectBucket
            overlayEnabled = viewModel.overlayEnabled
        }
    }
}

// MARK: - Overlay Preset Card

struct OverlayPresetCard: View {
    let preset: OverlayPresetDescriptor
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Preview thumbnail (simplified)
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .frame(width: 120, height: 68) // 16:9 aspect ratio thumbnail
                .overlay(
                    VStack(spacing: 2) {
                        Text("Preview")
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white : .secondary)
                        
                        // Simple overlay representation
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSelected ? Color.white.opacity(0.8) : Color.gray.opacity(0.6))
                            .frame(width: 80, height: 12)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
            
            // Preset info
            VStack(spacing: 2) {
                Text(preset.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                
                Text(preset.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Overlay Status View (Debug)

struct OverlayStatusView: View {
    @ObservedObject var viewModel: OverlayPickerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overlay Status")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(viewModel.overlayActive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.overlayActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Last updated: \(viewModel.lastUpdateTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let error = viewModel.lastError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct OverlayPickerView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayPickerView()
            .frame(width: 600, height: 800)
    }
}