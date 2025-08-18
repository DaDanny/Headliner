
//
//  PersonalInfoReader.swift
//  HeadlinerShared
//
//  Reads personal info from App Group UserDefaults for the camera extension.
//

import Foundation
/// Reads personal info from App Group UserDefaults.
///
/// IMPORTANT: The camera extension CANNOT fetch location itself - it doesn't have permission.
/// The main app is responsible for:
/// 1. Requesting location permission from the user
/// 2. Fetching the actual location using CoreLocation
/// 3. Writing the data to App Group storage
/// 
/// This reader only reads what the main app has written.
public class PersonalInfoReader {
    private let userDefaults: UserDefaults?
    
    public init() {
        self.userDefaults = UserDefaults(suiteName: Identifiers.appGroup)
    }
    
    /// Read the current personal info from App Group storage
    public func readPersonalInfo() -> PersonalInfo? {
        guard let data = userDefaults?.data(forKey: "overlay.personalInfo.v1"),
              let info = try? JSONDecoder().decode(PersonalInfo.self, from: data) else {
            // No data yet - main app hasn't fetched location
            // We return nil for city/weather to indicate "no data available"
            // rather than showing fake data
            print("[PersonalInfoReader] No personal info data found in App Group storage")
            return PersonalInfo(
                city: nil,  // Will be populated once main app fetches real location
                localTime: formatCurrentTime(),
                weatherEmoji: nil,
                weatherText: nil
            )
        }
        print("[PersonalInfoReader] Loaded personal info: city=\(info.city ?? "nil"), weather=\(info.weatherEmoji ?? "nil")")
        return info
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
}