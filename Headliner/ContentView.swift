//
//  ContentView.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
                    Text("🎤 Headliner is alive!!")
                        .font(.title)
                    Text("Ready to elevate your meetings.")
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 400, minHeight: 300)
                .padding()
    }
}

#Preview {
    ContentView()
}
