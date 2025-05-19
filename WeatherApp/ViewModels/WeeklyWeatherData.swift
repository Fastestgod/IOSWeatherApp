//
//  WeeklyWeatherData.swift
//  WeatherApp
//
//  Created by Stanley Yu on 5/19/25.
//
//
//  WeeklyWeatherData.swift
//  WeatherApp
//
//  Created by Stanley Yu on 4/12/25.
//

import Foundation

struct DailyWeatherData: Decodable, Identifiable {
    let id = UUID()
    let date: Date
    let dayTemp: Double
    let minTemp: Double
    let maxTemp: Double
    let iconCode: String
    let weatherDescription: String
    
    enum CodingKeys: String, CodingKey {
        case dt, temp, weather
    }
    
    enum TempKeys: String, CodingKey {
        case day, min, max
    }
    
    enum WeatherKeys: String, CodingKey {
        case icon, description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Timestamp conversion
        let timestamp = try container.decode(TimeInterval.self, forKey: .dt)
        date = Date(timeIntervalSince1970: timestamp)
        
        // Temperature
        let temp = try container.nestedContainer(keyedBy: TempKeys.self, forKey: .temp)
        dayTemp = try temp.decode(Double.self, forKey: .day)
        minTemp = try temp.decode(Double.self, forKey: .min)
        maxTemp = try temp.decode(Double.self, forKey: .max)
        
        // Weather info
        var weatherArray = try container.nestedUnkeyedContainer(forKey: .weather)
        let weather = try weatherArray.nestedContainer(keyedBy: WeatherKeys.self)
        iconCode = try weather.decode(String.self, forKey: .icon)
        weatherDescription = try weather.decode(String.self, forKey: .description)
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

struct WeeklyForecastResponse: Decodable {
    let list: [DailyWeatherData]
}
