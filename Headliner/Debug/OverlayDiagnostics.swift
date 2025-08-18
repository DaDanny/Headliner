//
//  OverlayDiagnostics.swift
//  Headliner
//
//  Debug and diagnostic tools for the SwiftUI overlay system.
//

import SwiftUI
import Foundation

// MARK: - Overlay Diagnostics View

struct OverlayDiagnosticsView: View {
    @StateObject private var diagnostics = OverlayDiagnostics()
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    
                    Text("Overlay Diagnostics")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
            
            if isExpanded {
                Divider()
                
                // Status Overview
                statusOverview
                
                Divider()
                
                // File System Info
                fileSystemInfo
                
                Divider()
                
                // Actions
                actionButtons
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .onAppear {
            diagnostics.refresh()
        }
    }
    
    // MARK: - Status Overview
    
    private var statusOverview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status Overview")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack {
                StatusIndicator(
                    label: "Asset Store",
                    isHealthy: diagnostics.assetStoreHealthy,
                    details: diagnostics.assetStoreStatus
                )
                
                Spacer()
                
                StatusIndicator(
                    label: "App Group",
                    isHealthy: diagnostics.appGroupAccessible,
                    details: diagnostics.appGroupStatus
                )
            }
            
            if let lastOverlay = diagnostics.currentOverlayInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Overlay")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Preset: \(lastOverlay.presetID)")
                        .font(.caption2)
                        .fontFamily(.monospaced)
                    
                    Text("Hash: \(lastOverlay.hash.prefix(12))...")
                        .font(.caption2)
                        .fontFamily(.monospaced)
                    
                    Text("Size: \(lastOverlay.width)x\(lastOverlay.height)")
                        .font(.caption2)
                        .fontFamily(.monospaced)
                    
                    Text("Updated: \(lastOverlay.formattedUpdateTime)")
                        .font(.caption2)
                        .fontFamily(.monospaced)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
            } else {
                Text("No active overlay")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    // MARK: - File System Info
    
    private var fileSystemInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("File System")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            if let overlayDir = diagnostics.overlayDirectoryPath {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Overlay Directory:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(overlayDir)
                        .font(.caption2)
                        .fontFamily(.monospaced)
                        .textSelection(.enabled)
                }
            }
            
            HStack(spacing: 16) {
                FileStatusView(
                    filename: "overlay.png",
                    exists: diagnostics.overlayImageExists,
                    size: diagnostics.overlayImageSize
                )
                
                FileStatusView(
                    filename: "overlay.json",
                    exists: diagnostics.overlayMetadataExists,
                    size: diagnostics.overlayMetadataSize
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 8) {
            Text("Actions")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button("Refresh") {
                    diagnostics.refresh()
                }
                .controlSize(.small)
                
                Button("Clear Overlay") {
                    diagnostics.clearOverlay()
                }
                .controlSize(.small)
                
                Button("Open Directory") {
                    diagnostics.openOverlayDirectory()
                }
                .controlSize(.small)
            }
        }
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let label: String
    let isHealthy: Bool
    let details: String?
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isHealthy ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                
                if let details = details {
                    Text(details)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - File Status View

struct FileStatusView: View {
    let filename: String
    let exists: Bool
    let size: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: exists ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(exists ? .green : .red)
                    .font(.caption2)
                
                Text(filename)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            
            if let size = size {
                Text(size)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Overlay Diagnostics Model

@MainActor
final class OverlayDiagnostics: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var assetStoreHealthy: Bool = false
    @Published var assetStoreStatus: String? = nil
    @Published var appGroupAccessible: Bool = false
    @Published var appGroupStatus: String? = nil
    
    @Published var overlayImageExists: Bool = false
    @Published var overlayImageSize: String? = nil
    @Published var overlayMetadataExists: Bool = false
    @Published var overlayMetadataSize: String? = nil
    @Published var overlayDirectoryPath: String? = nil
    
    @Published var currentOverlayInfo: OverlayInfo? = nil
    
    // MARK: - Private Properties
    
    private let assetStore: OverlayAssetStore?
    
    // MARK: - Initialization
    
    init() {
        self.assetStore = OverlayAssetStore()
    }
    
    // MARK: - Public Methods
    
    func refresh() {
        checkAssetStore()
        checkAppGroup()
        checkFileSystem()
        checkCurrentOverlay()
    }
    
    func clearOverlay() {
        guard let assetStore = assetStore else { return }
        let success = assetStore.clearOverlay()
        
        if success {
            NotificationManager.postOverlayCleared()
        }
        
        // Refresh after clear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.refresh()
        }
    }
    
    func openOverlayDirectory() {
        guard let assetStore = assetStore else { return }
        let directoryURL = assetStore.debugOverlayDirectory
        NSWorkspace.shared.open(directoryURL)
    }
    
    // MARK: - Private Methods
    
    private func checkAssetStore() {
        if let assetStore = assetStore {
            assetStoreHealthy = true
            assetStoreStatus = "Available"
        } else {
            assetStoreHealthy = false
            assetStoreStatus = "Failed to initialize"
        }
    }
    
    private func checkAppGroup() {
        let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Identifiers.appGroup
        )
        
        if let _ = appGroupURL {
            appGroupAccessible = true
            appGroupStatus = "Accessible"
        } else {
            appGroupAccessible = false
            appGroupStatus = "Not accessible"
        }
    }
    
    private func checkFileSystem() {
        guard let assetStore = assetStore else {
            overlayImageExists = false
            overlayMetadataExists = false
            overlayDirectoryPath = nil
            return
        }
        
        let fileManager = FileManager.default
        let urls = assetStore.debugFileURLs
        
        overlayDirectoryPath = assetStore.debugOverlayDirectory.path
        
        // Check overlay image
        overlayImageExists = fileManager.fileExists(atPath: urls.image.path)
        if overlayImageExists {
            if let attributes = try? fileManager.attributesOfItem(atPath: urls.image.path),
               let fileSize = attributes[.size] as? Int64 {
                overlayImageSize = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } else {
            overlayImageSize = nil
        }
        
        // Check overlay metadata
        overlayMetadataExists = fileManager.fileExists(atPath: urls.metadata.path)
        if overlayMetadataExists {
            if let attributes = try? fileManager.attributesOfItem(atPath: urls.metadata.path),
               let fileSize = attributes[.size] as? Int64 {
                overlayMetadataSize = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } else {
            overlayMetadataSize = nil
        }
    }
    
    private func checkCurrentOverlay() {
        guard let assetStore = assetStore,
              let metadata = assetStore.readOverlayMeta() else {
            currentOverlayInfo = nil
            return
        }
        
        currentOverlayInfo = OverlayInfo(
            presetID: metadata.presetID,
            hash: metadata.hash,
            width: metadata.width,
            height: metadata.height,
            updatedAt: metadata.updatedAt
        )
    }
}

// MARK: - Overlay Info

struct OverlayInfo {
    let presetID: String
    let hash: String
    let width: Int
    let height: Int
    let updatedAt: String
    
    var formattedUpdateTime: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: updatedAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .none
            displayFormatter.timeStyle = .medium
            return displayFormatter.string(from: date)
        }
        return updatedAt
    }
}

// MARK: - Preview

struct OverlayDiagnosticsView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayDiagnosticsView()
            .frame(width: 400)
            .padding()
    }
}