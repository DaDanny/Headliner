//
//  Logging.swift
//  Headliner
//
//  Centralized logger for the application.
//

import OSLog

let logger = Logger(
  subsystem: Identifiers.orgIDAndProduct.rawValue.lowercased(),
  category: "Application"
)
