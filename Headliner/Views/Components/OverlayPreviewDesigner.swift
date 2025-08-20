//
//  OverlayPreviewDesigner.swift
//  Headliner
//
//  Visual preview tool for overlay presets.
//  Use Xcode Canvas to see exactly how your overlays will look!
//

import SwiftUI

/// Live preview of overlay presets - use Xcode Canvas to see your overlays!
struct OverlayPreviewDesigner: View {
    @State private var selectedPresetIndex = 0
    @State private var selectedAspectRatio: CGFloat = 16.0/9.0
    @State private var showGrid = true
    
    // Sample data for preview
    @State private var displayName = "Sarah Chen"
    @State private var tagline = "Senior Product Designer"
    @State private var accentColor = "#8b5cf6"
    @State private var city = "San Francisco"
    @State private var localTime = "2:30 PM"
    @State private var weatherEmoji = "☀️"
    @State private var weatherText = "72°F Sunny"
    
    private var availablePresets: [OverlayPreset] {
        return OverlayPresets.allPresets.filter { $0.id != "fallback" }
    }
    
    private var currentPreset: OverlayPreset {
        guard selectedPresetIndex < availablePresets.count else { return availablePresets.first! }
        return availablePresets[selectedPresetIndex]
    }
    
    private var sampleTokens: OverlayTokens {
        OverlayTokens(
            displayName: displayName,
            tagline: tagline.isEmpty ? nil : tagline,
            accentColorHex: accentColor,
            aspect: abs(selectedAspectRatio - 16.0/9.0) < 0.01 ? .widescreen : .fourThree,
            city: city.isEmpty ? nil : city,
            localTime: localTime.isEmpty ? nil : localTime,
            weatherEmoji: weatherEmoji.isEmpty ? nil : weatherEmoji,
            weatherText: weatherText.isEmpty ? nil : weatherText
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("🎨 Overlay Preview Designer")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Preview your overlays exactly as they'll appear in the camera extension")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("✨ Edit coordinates in OverlayPresets.swift and see changes here instantly!")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            // Controls
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Preset:")
                        .font(.headline)
                    Picker("Preset", selection: $selectedPresetIndex) {
                        ForEach(Array(availablePresets.enumerated()), id: \.offset) { index, preset in
                            Text(preset.name).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading) {
                    Text("Aspect Ratio:")
                        .font(.headline)
                    Picker("Aspect", selection: $selectedAspectRatio) {
                        Text("16:9 Widescreen").tag(16.0/9.0)
                        Text("4:3 Standard").tag(4.0/3.0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Toggle("Show Grid", isOn: $showGrid)
                
                Spacer()
                
                // Preset info
                VStack(alignment: .trailing) {
                    Text("ID: \(currentPreset.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(currentPreset.nodes.count) nodes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Visual Preview
            SimpleOverlayPreview(
                preset: currentPreset,
                tokens: sampleTokens,
                aspectRatio: selectedAspectRatio,
                showGrid: showGrid
            )
            .frame(maxWidth: 1000, maxHeight: 700)
            
            // Sample Data Controls
            GroupBox("Sample Data (adjust to see how your overlay responds)") {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Display Name")
                            .font(.caption)
                            .fontWeight(.medium)
                        TextField("Name", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tagline")
                            .font(.caption)
                            .fontWeight(.medium)
                        TextField("Role/Title", text: $tagline)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accent Color")
                            .font(.caption)
                            .fontWeight(.medium)
                        TextField("Hex", text: $accentColor)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("City")
                            .font(.caption)
                            .fontWeight(.medium)
                        TextField("Location", text: $city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weather")
                            .font(.caption)
                            .fontWeight(.medium)
                        HStack {
                            TextField("🌤️", text: $weatherEmoji)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 40)
                            TextField("Description", text: $weatherText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time")
                            .font(.caption)
                            .fontWeight(.medium)
                        TextField("Time", text: $localTime)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

/// Actual overlay preview that renders the real overlay nodes
struct SimpleOverlayPreview: View {
    let preset: OverlayPreset
    let tokens: OverlayTokens
    let aspectRatio: CGFloat
    let showGrid: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.size.width
            let frameHeight = frameWidth / aspectRatio
            let containerSize = CGSize(width: frameWidth, height: frameHeight)
            
            ZStack {
                // Simulated video background
                LinearGradient(
                    colors: [Color.black.opacity(0.8), Color.gray.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: frameWidth, height: frameHeight)
                
                // Grid overlay for positioning guidance
                if showGrid {
                    SimpleGrid()
                        .frame(width: frameWidth, height: frameHeight)
                }
                
                // Render the actual overlay nodes
                let isWidescreen = abs(aspectRatio - 16.0/9.0) < 0.01
                let placements = isWidescreen ? preset.layout.widescreen : preset.layout.fourThree
                
                ForEach(Array(placements.enumerated()), id: \.offset) { _, placement in
                    if placement.index < preset.nodes.count {
                        let node = preset.nodes[placement.index]
                        // Convert to Core Graphics coordinates (bottom-left origin)
                        let cgFrame = placement.frame.toCGRect(in: containerSize)
                        // Flip Y coordinate for SwiftUI (top-left origin)
                        let swiftUIFrame = CGRect(
                            x: cgFrame.origin.x,
                            y: containerSize.height - cgFrame.origin.y - cgFrame.height,
                            width: cgFrame.width,
                            height: cgFrame.height
                        )
                        
                        SimpleNodeView(node: node, tokens: tokens, frame: swiftUIFrame)
                            .opacity(placement.opacity)
                            .zIndex(Double(placement.zIndex))
                    }
                }
                
                // Aspect ratio label
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(aspectRatioLabel)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.trailing, 8)
                            .padding(.bottom, 4)
                    }
                }
                .frame(width: frameWidth, height: frameHeight)
            }
        }
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    private var aspectRatioLabel: String {
        if abs(aspectRatio - 16.0/9.0) < 0.01 {
            return "16:9 (Widescreen)"
        } else if abs(aspectRatio - 4.0/3.0) < 0.01 {
            return "4:3 (Standard)"
        } else {
            return String(format: "%.2f:1", aspectRatio)
        }
    }
}

/// Simple node renderer
struct SimpleNodeView: View {
    let node: OverlayNode
    let tokens: OverlayTokens
    let frame: CGRect
    
    var body: some View {
        Group {
            switch node {
            case .text(let textNode):
                let text = replaceTokens(textNode.text, with: tokens)
                let color = Color(hex: replaceTokens(textNode.colorHex, with: tokens)) ?? .white
                let fontSize = frame.height * 0.7
                let weight = fontWeight(textNode.fontWeight)
                let alignment = textAlignment(textNode.alignment)
                
                if !text.isEmpty && !text.contains("{") {
                    Text(text)
                        .font(.system(size: fontSize, weight: weight))
                        .foregroundColor(color)
                        .multilineTextAlignment(alignment)
                        .frame(width: frame.width, height: frame.height, alignment: swiftUIAlignment(textNode.alignment))
                }
                
            case .rect(let rectNode):
                let color = Color(hex: replaceTokens(rectNode.colorHex, with: tokens)) ?? .black
                RoundedRectangle(cornerRadius: rectNode.cornerRadius * frame.height)
                    .fill(color)
                    .frame(width: frame.width, height: frame.height)
                
            case .gradient(let gradientNode):
                let startColor = Color(hex: replaceTokens(gradientNode.startColorHex, with: tokens)) ?? .black
                let endColor = Color(hex: replaceTokens(gradientNode.endColorHex, with: tokens)) ?? .white
                let angle = gradientNode.angle * .pi / 180.0
                let startPoint = UnitPoint(x: 0.5 - cos(angle) * 0.5, y: 0.5 - sin(angle) * 0.5)
                let endPoint = UnitPoint(x: 0.5 + cos(angle) * 0.5, y: 0.5 + sin(angle) * 0.5)
                
                LinearGradient(colors: [startColor, endColor], startPoint: startPoint, endPoint: endPoint)
                    .frame(width: frame.width, height: frame.height)
            }
        }
        .position(x: frame.midX, y: frame.midY)
    }
    
    private func replaceTokens(_ text: String, with tokens: OverlayTokens) -> String {
        return text
            .replacingOccurrences(of: "{displayName}", with: tokens.displayName)
            .replacingOccurrences(of: "{tagline}", with: tokens.tagline ?? "")
            .replacingOccurrences(of: "{accentColor}", with: tokens.accentColorHex)
            .replacingOccurrences(of: "{city}", with: tokens.city ?? "")
            .replacingOccurrences(of: "{localTime}", with: tokens.localTime ?? "")
            .replacingOccurrences(of: "{weatherEmoji}", with: tokens.weatherEmoji ?? "")
            .replacingOccurrences(of: "{weatherText}", with: tokens.weatherText ?? "")
    }
    
    private func fontWeight(_ weight: String) -> Font.Weight {
        switch weight.lowercased() {
        case "heavy": return .heavy
        case "bold": return .bold
        case "semibold": return .semibold
        case "medium": return .medium
        case "light": return .light
        default: return .regular
        }
    }
    
    private func textAlignment(_ alignment: String) -> TextAlignment {
        switch alignment.lowercased() {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }
    
    private func swiftUIAlignment(_ alignment: String) -> Alignment {
        switch alignment.lowercased() {
        case "left": return .leading
        case "right": return .trailing
        default: return .center
        }
    }
}

/// Simple grid overlay
struct SimpleGrid: View {
    var body: some View {
        ZStack {
            // Rule of thirds lines
            VStack(spacing: 0) {
                Spacer()
                Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                Spacer()
            }
            HStack(spacing: 0) {
                Spacer()
                Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1)
                Spacer()
                Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1)
                Spacer()
            }
        }
    }
}

// MARK: - SwiftUI Preview

#if DEBUG
struct OverlayPreviewDesigner_Previews: PreviewProvider {
    static var previews: some View {
        OverlayPreviewDesigner()
            .frame(width: 1200, height: 900)
    }
}
#endif