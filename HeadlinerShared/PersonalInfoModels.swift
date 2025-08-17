import Foundation

public struct PersonalInfo: Codable, Equatable {
    public var city: String?
    public var localTime: String?      // e.g. "4:10 PM"
    public var weatherEmoji: String?
    public var weatherText: String?    // e.g. "Sunny"
    
    public init(city: String? = nil, localTime: String? = nil, weatherEmoji: String? = nil, weatherText: String? = nil) {
        self.city = city
        self.localTime = localTime
        self.weatherEmoji = weatherEmoji
        self.weatherText = weatherText
    }
}

public protocol PersonalInfoProvider {
    func fetch() async throws -> PersonalInfo
}