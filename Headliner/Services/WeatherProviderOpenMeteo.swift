import Foundation
import CoreLocation

final class OpenMeteoProvider: WeatherProvider {
    func currentWeather(at coordinate: CLLocationCoordinate2D, timeZone: TimeZone) async throws -> (emoji: String, text: String) {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: String(coordinate.latitude)),
            .init(name: "longitude", value: String(coordinate.longitude)),
            .init(name: "current", value: "weather_code"),
            .init(name: "timezone", value: timeZone.identifier)
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        
        struct Response: Decodable {
            struct Current: Decodable {
                let weather_code: Int
            }
            let current: Current
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        return map(code: response.current.weather_code)
    }
    
    private func map(code: Int) -> (String, String) {
        switch code {
        case 0:
            return ("☀️", "Sunny")
        case 1, 2:
            return ("🌤️", "Mostly Sunny")
        case 3:
            return ("⛅️", "Partly Cloudy")
        case 45, 48:
            return ("🌫️", "Foggy")
        case 51, 53, 55, 61:
            return ("🌧️", "Light Rain")
        case 63, 65:
            return ("🌧️", "Rain")
        case 66, 67:
            return ("🌧️", "Freezing Rain")
        case 71, 73, 75, 77:
            return ("❄️", "Snow")
        case 80, 81, 82:
            return ("🌦️", "Showers")
        case 95, 96, 99:
            return ("⛈️", "Stormy")
        default:
            return ("🌤️", "Fair")
        }
    }
}