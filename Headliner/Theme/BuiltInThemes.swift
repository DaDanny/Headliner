import SwiftUI

// MARK: - Built-in Themes

extension Theme {
    enum BaseFontSize {
        static let small: CGFloat = 28
        static let body: CGFloat = 26
        static let title: CGFloat = 32
        static let display: CGFloat = 44
        static let emoji: CGFloat = 32
    }
    
    enum BaseEffectSize {
        static let blurRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let cornerRadius: CGFloat = 18
        static let strokeWidth: CGFloat = 1
        static let insetSmall: CGFloat = 8
        static let insetMedium: CGFloat = 12
        static let insetLarge: CGFloat = 16
    }
    
    static let classic = Theme(
        id: "classic",
        name: "Classic Glass",
        colors: ThemeColors(
            surface: Color.black.opacity(0.50),
            surfaceStroke: Color.white.opacity(0.18),
            surfaceAccent: Color.white.opacity(0.08),
            textPrimary: .white,
            textSecondary: .white.opacity(0.8),
            accent: Color(hex: "#FFD700"), // warm gold
            shadow: .black.opacity(0.45)
        ),
        typography: ThemeTypography(
            baseSmall: BaseFontSize.small,
            baseBody: BaseFontSize.body,
            baseTitle: BaseFontSize.title,
            baseDisplay: BaseFontSize.display,
            baseEmoji: BaseFontSize.emoji
            
        ),
        effects: ThemeEffects(
            blurRadius: BaseEffectSize.blurRadius,
            shadowRadius: BaseEffectSize.shadowRadius,
            cornerRadius: BaseEffectSize.cornerRadius,
            strokeWidth: BaseEffectSize.strokeWidth,
            insetSmall: BaseEffectSize.insetSmall,
            insetMedium: BaseEffectSize.insetMedium,
            insetLarge: BaseEffectSize.insetLarge
        )
    )

    static let midnight = Theme(
        id: "midnight",
        name: "Midnight Pro",
        colors: ThemeColors(
            surface: Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.55),
            surfaceStroke: Color.white.opacity(0.16),
            surfaceAccent: Color(red: 0.32, green: 0.65, blue: 1.0).opacity(0.12),
            textPrimary: .white,
            textSecondary: .white.opacity(0.78),
            accent: Color(red: 0.32, green: 0.65, blue: 1.0), // cool blue
            shadow: .black.opacity(0.5)
        ),
        typography: ThemeTypography(
            baseSmall: BaseFontSize.small,
            baseBody: BaseFontSize.body,
            baseTitle: BaseFontSize.title,
            baseDisplay: BaseFontSize.display,
            baseEmoji: BaseFontSize.emoji
            
        ),
        effects: ThemeEffects(
            blurRadius: BaseEffectSize.blurRadius,
            shadowRadius: BaseEffectSize.shadowRadius,
            cornerRadius: BaseEffectSize.cornerRadius,
            strokeWidth: BaseEffectSize.strokeWidth,
            insetSmall: BaseEffectSize.insetSmall,
            insetMedium: BaseEffectSize.insetMedium,
            insetLarge: BaseEffectSize.insetLarge
        )
    )
    
    static let dawn = Theme(
        id: "dawn",
        name: "Dawn Light",
        colors: ThemeColors(
            surface: Color(red: 0.95, green: 0.94, blue: 0.93).opacity(0.45),
            surfaceStroke: Color(red: 0.2, green: 0.18, blue: 0.16).opacity(0.20),
            surfaceAccent: Color(red: 1.0, green: 0.68, blue: 0.51).opacity(0.15),
            textPrimary: Color(red: 0.1, green: 0.08, blue: 0.06),
            textSecondary: Color(red: 0.1, green: 0.08, blue: 0.06).opacity(0.75),
            accent: Color(red: 1.0, green: 0.52, blue: 0.37), // warm coral
            shadow: .black.opacity(0.25)
        ),
        typography: ThemeTypography(
            baseSmall: BaseFontSize.small,
            baseBody: BaseFontSize.body,
            baseTitle: BaseFontSize.title,
            baseDisplay: BaseFontSize.display,
            baseEmoji: BaseFontSize.emoji
            
        ),
        effects: ThemeEffects(
            blurRadius: BaseEffectSize.blurRadius,
            shadowRadius: BaseEffectSize.shadowRadius,
            cornerRadius: BaseEffectSize.cornerRadius,
            strokeWidth: BaseEffectSize.strokeWidth,
            insetSmall: BaseEffectSize.insetSmall,
            insetMedium: BaseEffectSize.insetMedium,
            insetLarge: BaseEffectSize.insetLarge
        )
    )
}
