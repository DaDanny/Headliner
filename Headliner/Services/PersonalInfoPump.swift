import Foundation

final class PersonalInfoPump {
    private let provider: PersonalInfoProvider
    private var timer: Timer?
    private let defaults: UserDefaults
    
    init(provider: PersonalInfoProvider = PersonalInfoLive()) {
        self.provider = provider
        self.defaults = UserDefaults(suiteName: Identifiers.appGroup)!
    }
    
    func start() {
        // Initial refresh
        Task { @MainActor in
            await refresh()
        }
        
        // Set up timer for every 15 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    func refreshNow() {
        Task { @MainActor in
            await refresh()
        }
    }
    
    private func persist(_ info: PersonalInfo) {
        do {
            let data = try JSONEncoder().encode(info)
            defaults.set(data, forKey: "overlay.personalInfo.v1")
            defaults.synchronize()
            log("Persisted personal info to App Group")
        } catch {
            log("Failed to encode personal info: \(error)")
        }
    }
    
    private func log(_ message: String) {
        print("[PersonalInfoPump] \(message)")
    }
    
    private func refresh() async {
        do {
            let info = try await provider.fetch()
            persist(info)
            log("Updated: \(info)")
        } catch {
            log("Failed to refresh personal info: \(error)")
        }
    }
}