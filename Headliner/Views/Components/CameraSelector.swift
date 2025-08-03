//
//  CameraSelector.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct CameraSelector: View {
    @ObservedObject var appState: AppState
    
    var selectedCamera: CameraDevice? {
        appState.availableCameras.first { $0.id == appState.selectedCameraID }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Camera Source")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { appState.refreshCameras() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Menu {
                ForEach(appState.availableCameras) { camera in
                    Button(action: { appState.selectCamera(camera) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(camera.name)
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text(camera.deviceType)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if camera.id == appState.selectedCameraID {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if appState.availableCameras.isEmpty {
                    Text("No cameras available")
                        .foregroundColor(.secondary)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: cameraIcon(for: selectedCamera))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedCamera?.name ?? "No Camera Selected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if let camera = selectedCamera {
                            Text(camera.deviceType)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                        .stroke(.separator, lineWidth: 1)
                )
            }
            .menuStyle(BorderlessButtonMenuStyle())
        }
    }
    
    private func cameraIcon(for camera: CameraDevice?) -> String {
        guard let camera = camera else { return "camera.slash" }
        
        if camera.deviceType.contains("iPhone") || camera.deviceType.contains("Continuity") {
            return "iphone"
        } else if camera.deviceType.contains("External") {
            return "camera.on.rectangle"
        } else if camera.deviceType.contains("Desk View") {
            return "camera.macro"
        } else {
            return "camera"
        }
    }
}

// MARK: - Preview

struct CameraSelector_Previews: PreviewProvider {
    static var previews: some View {
        CameraSelector(
            appState: AppState(
                systemExtensionManager: SystemExtensionRequestManager(logText: ""),
                propertyManager: CustomPropertyManager(),
                outputImageManager: OutputImageManager()
            )
        )
        .padding()
        .frame(width: 400)
        .background(Color.gray.opacity(0.1))
    }
}