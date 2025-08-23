//
//  DependencyContainer.swift
//  Headliner
//
//  Provides dependency injection container with composition root
//

import Foundation

/// Dependency injection container for clean service composition
@MainActor
enum DependencyContainer {
  
  // MARK: - Production Dependencies
  
  /// Create live dependencies
  static func makeLiveCoordinator() -> AppCoordinator {
    AppCoordinator()
  }
  
  // MARK: - Test Dependencies
  
  #if DEBUG
  
  /// Create mock coordinator for testing/previews
  static func makeMockCoordinator() -> AppCoordinator {
    // For now, use live coordinator since services already handle mocking internally
    // TODO: Create proper mock services when needed for unit testing
    AppCoordinator()
  }
  #endif
}

/// Composition root - single place where all dependencies are wired together
enum CompositionRoot {
  /// Create the main app coordinator with live dependencies
  @MainActor
  static func makeCoordinator() -> AppCoordinator {
    DependencyContainer.makeLiveCoordinator()
  }
  
  #if DEBUG
  /// Create mock coordinator for testing
  @MainActor
  static func makeMockCoordinator() -> AppCoordinator {
    DependencyContainer.makeMockCoordinator()
  }
  #endif
}