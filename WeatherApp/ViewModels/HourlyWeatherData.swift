//
//  HourlyWeatherData.swift
//  WeatherApp
//
//  Created by Stanley Yu on 4/12/25.
//

import Foundation

// Represents hourly weather data for a specific time period
// Conforms to Decodable for JSON parsing and Identifiable for SwiftUI list views
struct HourlyWeatherData: Decodable, Identifiable {
    // Unique identifier for each hourly weather data point (required by Identifiable)
    let id = UUID()
    
    // The date and time of the weather forecast
    let date: Date
    
    // The temperature in the specified unit (Fahrenheit)
    let temperature: Double
    
    // The weather icon code from OpenWeatherMap API (e.g., "01d" for clear sky day)
    let iconCode: String
    
    // Text description of the weather conditions (e.g., "clear sky")
    let weatherDescription: String
    
    //Coding keys for the top-level JSON structure
    enum CodingKeys: String, CodingKey {
        case dt      // Unix timestamp
        case main    // Main weather data container
        case weather // Weather conditions array
    }
    
    enum MainKeys: String, CodingKey {
        case temp   // Temperature field
    }
    
    // Coding keys for weather condition objects
    enum WeatherKeys: String, CodingKey {
        case icon         // Weather icon code
        case description  // Weather description
    }
    
    // Custom initializer for decoding from JSON
    //- Parameter decoder: The decoder containing the JSON data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Convert Unix timestamp to Date
        let timestamp = try container.decode(TimeInterval.self, forKey: .dt)
        date = Date(timeIntervalSince1970: timestamp)
        
        // Decode temperature from nested "main" object
        let main = try container.nestedContainer(keyedBy: MainKeys.self, forKey: .main)
        temperature = try main.decode(Double.self, forKey: .temp)
        
        // Decode weather information from first item in weather array
        var weatherArray = try container.nestedUnkeyedContainer(forKey: .weather)
        let weather = try weatherArray.nestedContainer(keyedBy: WeatherKeys.self)
        iconCode = try weather.decode(String.self, forKey: .icon)
        weatherDescription = try weather.decode(String.self, forKey: .description)
    }
    
    var iconName: String {
        switch iconCode {
        case "01d": return "sun.max.fill"          // Clear sky (day)
        case "01n": return "moon.fill"             // Clear sky (night)
        case "02d", "02n": return "cloud.sun.fill" // Few clouds
        case "03d", "03n": return "cloud.fill"    // Scattered clouds
        case "04d", "04n": return "smoke.fill"    // Broken clouds
        case "09d", "09n": return "cloud.drizzle.fill" // Shower rain
        case "10d", "10n": return "cloud.rain.fill"    // Rain
        case "11d", "11n": return "cloud.bolt.fill"    // Thunderstorm
        case "13d", "13n": return "snowflake"          // Snow
        case "50d", "50n": return "cloud.fog.fill"     // Mist/fog
        default: return "questionmark.circle"          // Unknown weather condition
        }
    }
}

// The top-level response structure for hourly forecast API calls
struct HourlyForecastResponse: Decodable {
    //Array of hourly weather forecasts
    let list: [HourlyWeatherData]
}
