import SwiftUI

/// Single source of truth for painting a theme-aware surface with a chosen shape.
struct SurfaceBackground: View {
    let theme: Theme
    let scale: CGFloat
    let style: SurfaceStyle

    var body: some View {
        let strokeW = theme.effects.strokeWidth * scale

        Group {
            switch style {
            case .rounded:
                RoundedRectangle(cornerRadius: theme.effects.cornerRadius * scale, style: .continuous)
                    .fill(theme.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.effects.cornerRadius * scale, style: .continuous)
                            .stroke(theme.colors.surfaceStroke, lineWidth: strokeW)
                    )

            case .square:
                RoundedRectangle(cornerRadius: theme.effects.squareRadius * scale, style: .continuous)
                    .fill(theme.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.effects.squareRadius * scale, style: .continuous)
                            .stroke(theme.colors.surfaceStroke, lineWidth: strokeW)
                    )
            }
        }
        .shadow(color: theme.colors.shadow,
                radius: theme.effects.shadowRadius * scale,
                y: 2 * scale)
    }
}
