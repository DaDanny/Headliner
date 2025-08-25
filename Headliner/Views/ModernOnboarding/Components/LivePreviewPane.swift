//
//  LivePreviewPane.swift
//  Headliner
//
//  Aspect-fit preview container with letterboxing for modern onboarding
//

import SwiftUI

struct LivePreviewPane<Content: View>: View {
    let title: String
    let targetAspect: CGFloat?
    @ViewBuilder var content: () -> Content
    
    init(
        title: String,
        targetAspect: CGFloat? = 16.0/9.0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.targetAspect = targetAspect
        self.content = content
    }
    
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            GeometryReader { geo in
                ZStack {
                    
                    // Checkerboard pattern for transparency indication
//                    CheckerboardPattern()
//                        .opacity(0.05)
                    
                    // Aspect-fit content with letterboxing
                    AspectFitBox(
                        containerSize: geo.size,
                        aspect: targetAspect
                    ) {
                        content()
                    }
                }
                .clipShape(shape)
                .overlay(
                    shape.stroke(.quaternary, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
            }
            .frame(minHeight: 320)
            
            Text("This is how you'll appear in video calls")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct AspectFitBox<C: View>: View {
    let containerSize: CGSize
    let aspect: CGFloat?
    @ViewBuilder var content: () -> C
    
    var body: some View {
        let targetAspect = aspect ?? (16.0/9.0)
        let containerAspect = containerSize.width / max(containerSize.height, 1)
        
        let fittedSize: CGSize = {
            if containerAspect > targetAspect {
                // Container wider than content → limit by height
                let height = containerSize.height
                let width = height * targetAspect
                return CGSize(width: width, height: height)
            } else {
                // Container taller than content → limit by width
                let width = containerSize.width
                let height = width / targetAspect
                return CGSize(width: width, height: height)
            }
        }()
        
        content()
            .frame(width: fittedSize.width, height: fittedSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .animation(.easeInOut(duration: 0.2), value: fittedSize)
    }
}

private struct CheckerboardPattern: View {
    var body: some View {
        Canvas { context, size in
            let squareSize: CGFloat = 20
            let rows = Int(size.height / squareSize) + 1
            let cols = Int(size.width / squareSize) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let isEven = (row + col) % 2 == 0
                    if !isEven {
                        let rect = CGRect(
                            x: CGFloat(col) * squareSize,
                            y: CGFloat(row) * squareSize,
                            width: squareSize,
                            height: squareSize
                        )
                        context.fill(
                            Path(rect),
                            with: .color(.primary.opacity(0.1))
                        )
                    }
                }
            }
        }
    }
}

#if DEBUG
struct LivePreviewPane_Previews: PreviewProvider {
    static var previews: some View {
        LivePreviewPane(title: "Live Preview") {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 640, height: 480)
                .overlay(
                    Text("Camera Preview")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                )
        }
        .padding()
        .frame(width: 360, height: 500)
    }
}
#endif
