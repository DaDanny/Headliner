//
//  ThemePickerView.swift
//  Headliner
//
//  Created by AI Assistant on 8/21/25.
//

import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Choose the visual style for your overlays")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Theme", selection: Binding(
                get: { themeManager.current.id },
                set: { themeManager.selectTheme(id: $0) }
            )) {
                ForEach(themeManager.availableThemes) { theme in
                    Text(theme.name).tag(theme.id)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
#Preview {
    ThemePickerView()
        .environmentObject(ThemeManager())
        .padding()
}
#endif
