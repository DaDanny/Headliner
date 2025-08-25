//
//  MediaPane.swift
//  Headliner
//
//  Reusable media container for the center panel of onboarding steps
//

import SwiftUI

struct MediaPane<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            
            content()
        }
        .frame(minWidth: 380, minHeight: 360)
    }
}

#if DEBUG
struct MediaPane_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MediaPane {
                VStack(spacing: 12) {
                    Image(systemName: "video.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    
                    Text("Sample Media Content")
                        .font(.headline)
                    
                    Text("This is where the step-specific content will appear")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 400, height: 400)
            
            MediaPane {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .padding()
                    .overlay(
                        Text("Camera Preview Area")
                            .foregroundStyle(.white)
                            .font(.title2)
                    )
            }
            .frame(width: 400, height: 300)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}
#endif