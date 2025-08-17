import Foundation
import SwiftUI

@MainActor
final class PersonalInfoSettingsVM: ObservableObject {
    private let pump = PersonalInfoPump()
    
    @Published var useLocation: Bool = true {
        didSet {
            if useLocation {
                pump.start()
            } else {
                pump.stop()
            }
        }
    }
    
    func onAppear() {
        if useLocation {
            pump.start()
        }
    }
    
    func onDisappear() {
        pump.stop()
    }
    
    func refreshNowTapped() {
        pump.refreshNow()
    }
}