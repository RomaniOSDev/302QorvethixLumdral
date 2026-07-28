import Foundation

struct WorldClockCity: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var timezoneOffset: Double

    init(id: String = UUID().uuidString, name: String, timezoneOffset: Double) {
        self.id = id
        self.name = name
        self.timezoneOffset = timezoneOffset
    }
}

struct StaticCityOption: Identifiable, Hashable {
    let id: String
    let name: String
    let timezoneOffset: Double

    static let catalog: [StaticCityOption] = [
        StaticCityOption(id: "utc", name: "UTC", timezoneOffset: 0),
        StaticCityOption(id: "london", name: "London", timezoneOffset: 0),
        StaticCityOption(id: "paris", name: "Paris", timezoneOffset: 1),
        StaticCityOption(id: "berlin", name: "Berlin", timezoneOffset: 1),
        StaticCityOption(id: "cairo", name: "Cairo", timezoneOffset: 2),
        StaticCityOption(id: "moscow", name: "Moscow", timezoneOffset: 3),
        StaticCityOption(id: "dubai", name: "Dubai", timezoneOffset: 4),
        StaticCityOption(id: "delhi", name: "New Delhi", timezoneOffset: 5.5),
        StaticCityOption(id: "bangkok", name: "Bangkok", timezoneOffset: 7),
        StaticCityOption(id: "singapore", name: "Singapore", timezoneOffset: 8),
        StaticCityOption(id: "hongkong", name: "Hong Kong", timezoneOffset: 8),
        StaticCityOption(id: "tokyo", name: "Tokyo", timezoneOffset: 9),
        StaticCityOption(id: "sydney", name: "Sydney", timezoneOffset: 10),
        StaticCityOption(id: "auckland", name: "Auckland", timezoneOffset: 12),
        StaticCityOption(id: "honolulu", name: "Honolulu", timezoneOffset: -10),
        StaticCityOption(id: "anchorage", name: "Anchorage", timezoneOffset: -9),
        StaticCityOption(id: "la", name: "Los Angeles", timezoneOffset: -8),
        StaticCityOption(id: "denver", name: "Denver", timezoneOffset: -7),
        StaticCityOption(id: "chicago", name: "Chicago", timezoneOffset: -6),
        StaticCityOption(id: "nyc", name: "New York", timezoneOffset: -5),
        StaticCityOption(id: "sao", name: "São Paulo", timezoneOffset: -3),
        StaticCityOption(id: "buenos", name: "Buenos Aires", timezoneOffset: -3)
    ]
}
