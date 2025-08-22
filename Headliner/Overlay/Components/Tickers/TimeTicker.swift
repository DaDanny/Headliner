//
//  TimeTicker.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

/// Current time display ticker
struct TimeTicker: View {
    let time: String?
    
    init(time: String? = nil) {
        self.time = time
    }
    
    var body: some View {
        if let time = time, !time.isEmpty {
            Text(time)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.thinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )
                )
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        TimeTicker(time: "8:04 PM")
        TimeTicker(time: "14:32")
        TimeTicker(time: "2:15 AM")
    }
    .padding()
    .background(.black)
}
#endif
