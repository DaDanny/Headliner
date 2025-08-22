//
//  EnvironmentManager.swift
//  Headliner
//
//  Created by Danny Francken on 8/21/25.
//

import SwiftUI

// MARK: - Theme (env key)

struct ThemeEnvironmentKey: EnvironmentKey {
    public static let defaultValue: Theme = .classic
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Overlay Render Size (env key)

public struct OverlayRenderSizeKey: EnvironmentKey {
    public static let defaultValue: CGSize = .init(width: 1920, height: 1080)
}
public extension EnvironmentValues {
    var overlayRenderSize: CGSize {
        get { self[OverlayRenderSizeKey.self] }
        set { self[OverlayRenderSizeKey.self] = newValue }
    }
}

// MARK: - Convenience modifiers

public struct OverlayRenderSizeModifier: ViewModifier {
    let size: CGSize
    public func body(content: Content) -> some View {
        content.environment(\.overlayRenderSize, size)
    }
}
public extension View {
    func overlayRenderSize(_ size: CGSize) -> some View {
        modifier(OverlayRenderSizeModifier(size: size))
    }
}

// MARK: - ThemeProvider (inject ThemeManager.current into env)

public struct ThemeProvider<Content: View>: View {
    @StateObject private var manager = ThemeManager()
    private let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    public var body: some View {
        content().environment(\.theme, manager.current)
    }
}
