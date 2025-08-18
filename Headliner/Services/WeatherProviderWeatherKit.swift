import Foundation
import WeatherKit
import CoreLocation

protocol WeatherProvider {
    func currentWeather(at coordinate: CLLocationCoordinate2D, timeZone: TimeZone) async throws -> (emoji: String, text: String)
}

@available(macOS 13.0, *)
final class WeatherKitProvider: WeatherProvider {
    private let service = WeatherService.shared
    
    func currentWeather(at coordinate: CLLocationCoordinate2D, timeZone: TimeZone) async throws -> (emoji: String, text: String) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let weather = try await service.weather(for: location)
        let condition = weather.currentWeather.condition
        let (emoji, text) = map(condition: condition)
        return (emoji, text)
    }
    
    private func map(condition: WeatherCondition) -> (String, String) {
        switch condition {
        case .clear:
            return ("☀️", "Sunny")
        case .mostlyClear:
            return ("🌤️", "Mostly Sunny")
        case .partlyCloudy:
            return ("⛅️", "Partly Cloudy")
        case .cloudy:
            return ("☁️", "Cloudy")
        case .foggy, .haze, .smoky:
            return ("🌫️", "Foggy")
        case .drizzle:
            return ("🌧️", "Light Rain")
        case .rain:
            return ("🌧️", "Rain")
        case .thunderstorms:
            return ("⛈️", "Stormy")
        case .snow, .blizzard, .blowingSnow, .flurries, .heavySnow, .sleet:
            return ("❄️", "Snow")
        default:
            return ("🌤️", "Fair")
        }
    }
}