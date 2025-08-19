//
//  SettingsView.swift
//  Headliner
//
//  Main settings interface that uses reusable components
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var personalInfoVM = PersonalInfoSettingsVM()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and close button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Configure app preferences and features")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                        .background(Circle().fill(Color.clear))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close Settings")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Settings Content
            ScrollView {
                VStack(spacing: 16) {
                    // Personal Info Editing Section
                    PersonalInfoView(appState: appState)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Location Services Section
                    LocationInfoView(
                        appState: appState,
                        showHeader: true,
                        showInfoSection: true,
                        showRefreshButton: true
                    )
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 20)
                    
                    // Future settings sections can go here
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            logger.debug("📋 SettingsView: View appeared")
            logger.debug("📋 Current location status: \(appState.locationPermissionStatus.rawValue)")
            personalInfoVM.onAppear()
        }
        .onDisappear {
            logger.debug("📋 SettingsView: View disappearing")
            personalInfoVM.onDisappear()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(appState: AppState(
            systemExtensionManager: SystemExtensionRequestManager(logText: "Preview"),
            propertyManager: CustomPropertyManager(),
            outputImageManager: OutputImageManager()
        ))
        .previewDisplayName("Settings View")
    }
}
#endif
