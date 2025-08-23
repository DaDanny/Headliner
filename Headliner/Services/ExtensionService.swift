//
//  ExtensionService.swift
//  Headliner
//
//  Manages system extension lifecycle and status monitoring
//

import Foundation
import Combine
import SystemExtensions
import AppKit

// MARK: - Protocol

protocol ExtensionServiceProtocol: ObservableObject {
  var status: ExtensionStatus { get }
  var statusMessage: String { get }
  
  func install()
  func checkStatus()
  func waitForInstallation() async
}

// MARK: - Implementation

@MainActor
final class ExtensionService: ObservableObject {
  // MARK: - Published Properties
  
  @Published private(set) var status: ExtensionStatus = .unknown
  @Published private(set) var statusMessage: String = ""
  
  // MARK: - Dependencies
  
  private let requestManager: SystemExtensionRequestManager
  private let propertyManager: CustomPropertyManager
  private let logger = HeadlinerLogger.logger(for: .systemExtension)
  
  // MARK: - Private Properties
  
  private var cancellables = Set<AnyCancellable>()
  private var pollTimer: Timer?
  private var pollCount = 0
  
  // Smart polling configuration
  private var currentPollInterval: TimeInterval = 1.0
  private let maxPollInterval: TimeInterval = 4.0
  private let pollWindow: TimeInterval = 60.0
  
  // MARK: - Constants
  
  private enum Keys {
    static let extensionProviderReady = "ExtensionProviderReady"
  }
  
  // MARK: - Initialization
  
  init(requestManager: SystemExtensionRequestManager,
       propertyManager: CustomPropertyManager) {
    self.requestManager = requestManager
    self.propertyManager = propertyManager
    
    setupBindings()
    checkStatus()
  }
  
  deinit {
    pollTimer?.invalidate()
  }
  
  // MARK: - Public Methods
  
  func install() {
    status = .installing
    statusMessage = "Installing system extension..."
    requestManager.install()
    startPolling()
  }
  
  func checkStatus() {
    logger.debug("Checking extension status...")
    
    // Fast check via provider flag
    if isProviderReady {
      status = .installed
      statusMessage = "Extension is installed and ready"
      logger.debug("Extension ready via provider flag")
      return
    }
    
    // Fallback to device scan
    propertyManager.refreshExtensionStatus()
    if propertyManager.deviceObjectID != nil {
      status = .installed
      statusMessage = "Extension is installed and ready"
      logger.debug("Extension detected via device scan")
    } else {
      status = .notInstalled
      statusMessage = "Extension needs to be installed"
      logger.debug("Extension not detected")
    }
  }
  
  func waitForInstallation() async {
    guard status != .installed else { return }
    
    // Wait up to 60 seconds for installation
    for _ in 0..<60 {
      if status == .installed { return }
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      checkStatus()
    }
  }
  
  // MARK: - Private Methods
  
  private func setupBindings() {
    // Monitor installation progress
    requestManager.$logText
      .receive(on: DispatchQueue.main)
      .sink { [weak self] logText in
        self?.handleInstallationLog(logText)
      }
      .store(in: &cancellables)
    
    requestManager.$phase
      .receive(on: DispatchQueue.main)
      .sink { [weak self] phase in
        self?.handleInstallationPhase(phase)
      }
      .store(in: &cancellables)
    
    // Recheck on app activation
    NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.checkStatus()
      }
      .store(in: &cancellables)
  }
  
  private func handleInstallationLog(_ logText: String) {
    statusMessage = logText
    
    if logText.contains("success") {
      status = .installed
      Task {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        checkStatus()
      }
    } else if logText.contains("fail") || logText.contains("error") {
      status = .notInstalled
    }
  }
  
  private func handleInstallationPhase(_ phase: ExtensionInstallPhase) {
    switch phase {
    case .needsApproval:
      status = .installing
      statusMessage = "Approve the extension in System Settings…"
    case .installed:
      status = .installed
      statusMessage = "Extension installed. Finalizing…"
      startPolling()
    default:
      break
    }
  }
  
  // MARK: - Smart Polling
  
  private func startPolling() {
    pollTimer?.invalidate()
    pollCount = 0
    currentPollInterval = 1.0
    
    let deadline = Date().addingTimeInterval(pollWindow)
    scheduleNextPoll(deadline: deadline)
  }
  
  private func scheduleNextPoll(deadline: Date) {
    pollTimer = Timer.scheduledTimer(withTimeInterval: currentPollInterval, repeats: false) { [weak self] _ in
      Task { @MainActor in
        self?.performPoll(deadline: deadline)
      }
    }
    
    // Exponential backoff
    currentPollInterval = min(currentPollInterval * 1.5, maxPollInterval)
  }
  
  private func performPoll(deadline: Date) {
    pollCount += 1
    
    // Check provider flag first (fast)
    if isProviderReady {
      pollTimer?.invalidate()
      status = .installed
      statusMessage = "Extension installed and ready"
      logger.debug("✅ Extension ready (poll #\(self.pollCount))")
      return
    }
    
    // Device scan fallback
    propertyManager.refreshExtensionStatus()
    if propertyManager.deviceObjectID != nil {
      pollTimer?.invalidate()
      status = .installed
      statusMessage = "Extension installed and ready"
      logger.debug("✅ Extension detected (poll #\(self.pollCount))")
    } else if Date() > deadline {
      pollTimer?.invalidate()
      logger.debug("⌛ Extension polling timed out after \(self.pollCount) attempts")
    } else {
      scheduleNextPoll(deadline: deadline)
    }
  }
  
  // MARK: - Computed Properties
  
  private var isProviderReady: Bool {
    UserDefaults(suiteName: Identifiers.appGroup)?
      .bool(forKey: Keys.extensionProviderReady) ?? false
  }
  
  var isInstalled: Bool {
    status == .installed
  }
  
  var isInstalling: Bool {
    status == .installing
  }
}

// MARK: - ExtensionServiceProtocol Conformance

extension ExtensionService: ExtensionServiceProtocol {}