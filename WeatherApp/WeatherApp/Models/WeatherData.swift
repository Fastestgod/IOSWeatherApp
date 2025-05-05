//
//  WeatherData.swift
//  WeatherApp
//
//  Created by Stanley Yu on 4/5/25.
//
//
//  WeatherData.swift
//  WeatherApp
//

import Foundation

struct WeatherData: Decodable {
    let temperature: Double
    let windSpeed: Double
    let rainChance: Double
    let iconCode: String
    let description: String
    let coordinates: Coordinates?
    
    struct Coordinates: Decodable {
        let lat: Double
        let lon: Double
    }

    enum CodingKeys: String, CodingKey {
        case main, wind, weather, rain, coord
    }

    enum MainKeys: String, CodingKey {
        case temp
    }

    enum WindKeys: String, CodingKey {
        case speed
    }

    enum RainKeys: String, CodingKey {
        case oneHour = "1h"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode coordinates (optional)
        coordinates = try? container.decode(Coordinates.self, forKey: .coord)

        // Decode main weather data
        let main = try container.nestedContainer(keyedBy: MainKeys.self, forKey: .main)
        temperature = try main.decode(Double.self, forKey: .temp)

        // Decode wind data
        let wind = try container.nestedContainer(keyedBy: WindKeys.self, forKey: .wind)
        windSpeed = try wind.decode(Double.self, forKey: .speed)

        // Decode rain chance (optional)
        let rainContainer = try? container.nestedContainer(keyedBy: RainKeys.self, forKey: .rain)
        rainChance = try rainContainer?.decode(Double.self, forKey: .oneHour) ?? 0.0

        // Decode weather conditions
        var weatherArray = try container.nestedUnkeyedContainer(forKey: .weather)
        let weather = try weatherArray.nestedContainer(keyedBy: WeatherKeys.self)
        iconCode = try weather.decode(String.self, forKey: .icon)
        description = try weather.decode(String.self, forKey: .description)
    }

    enum WeatherKeys: String, CodingKey {
        case icon
        case description
    }

    var iconName: String {
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d", "02n": return "cloud.sun.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snowflake"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "questionmark.circle"
        }
    }
}

// Geocoding Response Model (nested in same file)
struct GeocodingResponse: Decodable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
    let state: String?
    
    enum CodingKeys: String, CodingKey {
        case name, lat, lon, country, state
    }
}
