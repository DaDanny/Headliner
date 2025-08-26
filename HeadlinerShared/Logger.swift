//
//  Logger.swift
//  HeadlinerShared
//
//  Centralized logger configuration for consistent logging across all components.
//

import OSLog

/// Centralized logger factory for Headliner components.
/// Provides consistent subsystem naming and category management across the app and extension.
public struct HeadlinerLogger {
    
    // MARK: - Private Properties
    
    private static let subsystem = Identifiers.orgIDAndProduct.lowercased()
    
    // MARK: - Logger Categories
    
    /// Logger category for the main application
    public enum Category: String {
        case application = "Application"
        case appState = "AppState"
        case systemExtension = "SystemExtension"
        case customProperty = "CustomProperty"
        case outputImage = "OutputImage"
        case cameraExtension = "Extension"
        case captureSession = "CaptureSession"
        case notifications = "Notifications"
        case overlays = "Overlays"
        case analytics = "Analytics"
        case performance = "Performance"
        case diagnostics = "Diagnostics"
        // Focused notification logging categories
        case internalNotifications = "notifications.internal"
        case crossAppNotifications = "notifications.crossapp"
    }
    
    // MARK: - Factory Methods
    
    /// Creates a logger for the specified category.
    /// - Parameter category: The logging category to use
    /// - Returns: A configured Logger instance
    public static func logger(for category: Category) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }
    
    /// Creates a logger with a custom category name.
    /// Use this only when the predefined categories don't fit your needs.
    /// - Parameter customCategory: Custom category name
    /// - Returns: A configured Logger instance
    public static func logger(customCategory: String) -> Logger {
        Logger(subsystem: subsystem, category: customCategory)
    }
    
    // MARK: - Convenience Properties
    
    /// Logger for the main application
    public static var application: Logger { logger(for: .application) }
    
    /// Logger for AppState
    public static var appState: Logger { logger(for: .appState) }
    
    /// Logger for system extension management
    public static var systemExtension: Logger { logger(for: .systemExtension) }
    
    /// Logger for custom property management
    public static var customProperty: Logger { logger(for: .customProperty) }
    
    /// Logger for output image processing
    public static var outputImage: Logger { logger(for: .outputImage) }
    
    /// Logger for camera extension
    public static var cameraExtension: Logger { logger(for: .cameraExtension) }
    
    /// Logger for capture session management
    public static var captureSession: Logger { logger(for: .captureSession) }
    
    /// Logger for notifications
    public static var notifications: Logger { logger(for: .notifications) }
    
    /// Logger for overlay functionality
    public static var overlays: Logger { logger(for: .overlays) }
}
