import Foundation
import CoreLocation

final class PersonalInfoLive: PersonalInfoProvider {
    private let location = LocationService()
    private let weatherProvider: WeatherProvider
    
    init() {
        // Use WeatherKit if available (macOS 13.0+) and not explicitly disabled
        if #available(macOS 13.0, *), ProcessInfo.processInfo.environment["WEATHERKIT_DISABLED"] == nil {
            self.weatherProvider = WeatherKitProvider()
        } else {
            self.weatherProvider = OpenMeteoProvider()
        }
    }
    
    func fetch() async throws -> PersonalInfo {
        do {
            let (city, localTime, timeZone, coordinate) = try await location.requestCityTimeAndCoordinate()
            
            var emoji = "🌤️"
            var text = "Fair"
            
            if let coordinate = coordinate {
                if let weather = try? await weatherProvider.currentWeather(at: coordinate, timeZone: timeZone) {
                    emoji = weather.emoji
                    text = weather.text
                }
            }
            
            return PersonalInfo(
                city: city,
                localTime: localTime,
                weatherEmoji: emoji,
                weatherText: text
            )
        } catch {
            // Location denied or failed: return partial info with current time
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let localTime = formatter.string(from: Date())
            
            return PersonalInfo(
                city: nil,
                localTime: localTime,
                weatherEmoji: "🌤️",
                weatherText: "Fair"
            )
        }
    }
}