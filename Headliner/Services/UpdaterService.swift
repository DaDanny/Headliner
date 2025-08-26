//
//  UpdaterService.swift
//  Headliner
//
//  Created by Danny Francken on 8/25/25.
//
import Foundation
import Sparkle

@MainActor
final class UpdaterService: ObservableObject {
    let controller: SPUStandardUpdaterController
    @Published var canCheckForUpdates = false

    init(updaterDelegate: SPUUpdaterDelegate? = nil) {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,               // starts periodic checks (if enabled)
            updaterDelegate: updaterDelegate,    // pass your AppCoordinator if you have one
            userDriverDelegate: nil
        )
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
