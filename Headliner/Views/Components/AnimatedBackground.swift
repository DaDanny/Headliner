//
//  AnimatedBackground.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct AnimatedBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.6),
                Color.purple.opacity(0.6),
                Color.pink.opacity(0.4),
                Color.blue.opacity(0.6)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct FloatingParticles: View {
    @State private var animateParticles = false
    
    var body: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.1), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 20...80))
                    .position(
                        x: animateParticles ?
                            CGFloat.random(in: 50...800) :
                            CGFloat.random(in: 100...700),
                        y: animateParticles ?
                            CGFloat.random(in: 50...600) :
                            CGFloat.random(in: 100...500)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...8))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: animateParticles
                    )
            }
        }
        .onAppear {
            animateParticles = true
        }
    }
}

// MARK: - Preview

struct AnimatedBackground_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AnimatedBackground()
            FloatingParticles()
        }
        .frame(width: 800, height: 600)
    }
}