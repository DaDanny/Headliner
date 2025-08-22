import SwiftUI

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    @AppStorage("selectedThemeID") private var storedThemeID = Theme.classic.id
    @Published var current: Theme = .classic

    let availableThemes: [Theme] = [.classic, .midnight, .dawn]

    init() {
        selectTheme(id: storedThemeID)
    }

    func selectTheme(id: String) {
        current = availableThemes.first { $0.id == id } ?? .classic
        storedThemeID = current.id
    }
}
