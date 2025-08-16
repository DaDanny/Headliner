//
//  Logging.swift
//  Headliner
//
//  Application-wide logger instance.
//

import OSLog

// Use the shared logger configuration for consistency
let logger = HeadlinerLogger.logger(for: .application)
