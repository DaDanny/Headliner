//
//  ThemeReader.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//
import SwiftUI

struct ThemeReader<Content: View>: View {
    @Environment(\.theme) private var theme
    let content: (Theme) -> Content
    var body: some View { content(theme) }
}
