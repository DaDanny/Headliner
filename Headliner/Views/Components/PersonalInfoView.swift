//
//  PersonalInfoView.swift
//  Headliner
//
//  Allows users to edit their display name and tagline that will appear in overlays.
//

import SwiftUI

/// A view for editing personal information (display name and tagline)
struct PersonalInfoView: View {
    @ObservedObject var appState: AppState
    @State private var displayName: String = ""
    @State private var tagline: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Personal Information")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
            }
            
            // Display Name Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Display Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                TextField("Your name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: displayName) {
                        saveChanges()
                    }
            }
            
            // Tagline Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Title or Tagline (Optional)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                TextField("e.g., Product Manager · NYC or 'Bagel Brigade'", text: $tagline)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: tagline) {
                        saveChanges()
                    }
            }
            
            // Info text
            Text("This information will appear in your camera overlays")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            loadCurrentValues()
        }
    }
    
    // MARK: - Data Management
    
    private func loadCurrentValues() {
        displayName = appState.overlaySettings.userName.isEmpty ? NSUserName() : appState.overlaySettings.userName
        if let existingTagline = appState.overlaySettings.overlayTokens?.tagline {
            tagline = existingTagline
        }
    }
    
    private func saveChanges() {
        // Update display name
        if !displayName.isEmpty {
            appState.overlaySettings.userName = displayName
        }
        
        // Update or create overlay tokens with display name and tagline
        let updatedTokens = OverlayTokens(
            displayName: displayName.isEmpty ? NSUserName() : displayName,
            tagline: tagline.isEmpty ? nil : tagline,
            accentColorHex: appState.overlaySettings.overlayTokens?.accentColorHex ?? "#007AFF",
            localTime: appState.overlaySettings.overlayTokens?.localTime,
            logoText: appState.overlaySettings.overlayTokens?.logoText,
            extras: appState.overlaySettings.overlayTokens?.extras
        )
        
        // Use AppState's method to properly save and persist changes
        appState.updateOverlayTokens(updatedTokens)
        
        logger.debug("PersonalInfoView: Saved and persisted changes - name: \(displayName), tagline: \(tagline)")
    }
}

// MARK: - Preview

#if DEBUG
struct PersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalInfoView(appState: AppState(
            systemExtensionManager: SystemExtensionRequestManager(logText: ""),
            propertyManager: CustomPropertyManager(),
            outputImageManager: OutputImageManager()
        ))
        .frame(width: 400)
        .padding()
    }
}
#endif
