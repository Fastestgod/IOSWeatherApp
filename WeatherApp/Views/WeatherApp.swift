//
//  WeatherApp.swift
//  WeatherApp
//
//  Created by Stanley Yu on 4/5/25.
//

import SwiftUI

// The main view of the Weather application that displays current, hourly, and weekly forecasts
struct WeatherApp: View {
    // MARK: - State Properties
    
    // The view model that manages weather data and business logic
    @StateObject private var viewModel = WeatherViewModel()
    
    //The list of saved locations that can be quickly accessed
    @State private var savedLocations: [String] = ["New York"]
    
    // The currently selected tab view ("current", "hourly", or "weekly")
    @State private var currentView: String = "current"
    
    // MARK: - Formatters
    
    // Date formatter for displaying hours in 12-hour format (e.g., "2PM", "5AM")
    private let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha" // Example: "2PM", "5AM"
        return formatter
    }()
    
    // MARK: - Helper Methods
    
    // Determines the appropriate color for a weather icon based on its type
    // - Parameter icon: The SF Symbol name of the icon
    // - Returns: A Color that matches the weather condition
    private func iconColor(for icon: String) -> Color {
        if icon.contains("sun") { return .yellow }
        else if icon.contains("moon") { return .blue }
        else if icon.contains("cloud") { return .gray }
        else if icon.contains("snow") { return .cyan }
        else if icon.contains("bolt") { return .orange }
        else { return .black }
    }
    
    // - Parameter code: The OpenWeatherMap icon code (e.g., "01d", "10n")
    // - Returns: The corresponding SF Symbol name
    private func weatherIcon(from code: String) -> String {
        switch code {
        case "01d": return "sun.max.fill"          // Clear sky (day)
        case "01n": return "moon.fill"            // Clear sky (night)
        case "02d", "02n": return "cloud.sun.fill" // Few clouds
        case "03d", "03n": return "cloud.fill"     // Scattered clouds
        case "04d", "04n": return "smoke.fill"    // Broken clouds
        case "09d", "09n": return "cloud.drizzle.fill" // Shower rain
        case "10d", "10n": return "cloud.rain.fill"    // Rain
        case "11d", "11n": return "cloud.bolt.fill"    // Thunderstorm
        case "13d", "13n": return "snowflake"          // Snow
        case "50d", "50n": return "cloud.fog.fill"      // Mist/fog
        default: return "questionmark.circle"           // Unknown weather condition
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // MARK: - Header Section
                    HStack {
                        VStack(alignment: .leading) {
                            Text(viewModel.location)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Updated just now")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        // Settings navigation link
                        NavigationLink(destination: SettingsView(savedLocations: $savedLocations, viewModel: viewModel)) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .padding()
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Tab View Section
                    TabView(selection: $currentView) {
                        // Current Weather Tab
                        VStack(spacing: 16) {
                            if let icon = viewModel.weather?.iconName {
                                Image(systemName: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(iconColor(for: icon))
                            }

                            if let weather = viewModel.weather {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: weather.iconName)
                                            .font(.largeTitle)
                                            .foregroundColor(iconColor(for: weather.iconName))
                                        Text("Current Weather")
                                            .font(.title2)
                                            .bold()
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "thermometer")
                                            Text("Temperature: \(weather.temperature, specifier: "%.1f")°F")
                                        }
                                        HStack {
                                            Image(systemName: "wind")
                                            Text("Wind: \(weather.windSpeed, specifier: "%.1f") mph")
                                        }
                                        HStack {
                                            Image(systemName: "cloud.rain")
                                            Text("Rain (1h): \(weather.rainChance, specifier: "%.1f") mm")
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(16)
                            } else if viewModel.isLoading {
                                ProgressView("Loading weather...")
                            } else if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                        .tag("current")

                        // Hourly Forecast Tab
                        VStack(alignment: .leading, spacing: 16) {
                            Text("24-Hour Forecast")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            if viewModel.hourlyForecast.isEmpty {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    Text("No hourly data available")
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            } else {
                                // Grid layout with 4 columns and 6 rows
                                let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
                                
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(viewModel.hourlyForecast.prefix(24)) { forecast in
                                            VStack(spacing: 8) {
                                                Text(hourFormatter.string(from: forecast.date))
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                                
                                                // Modified icon with color
                                                Image(systemName: weatherIcon(from: forecast.iconCode))
                                                    .symbolRenderingMode(.multicolor)
                                                    .font(.title2)
                                                    .foregroundColor(iconColor(for: weatherIcon(from: forecast.iconCode)))
                                                
                                                Text("\(Int(forecast.temperature))°")
                                                    .font(.headline)
                                                    .fontWeight(.medium)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.white.opacity(0.3))
                                            .cornerRadius(12)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .tag("hourly")
                        // Weekly Forecast Tab (Placeholder)
                        // Replace the weekly forecast placeholder with this:
                        VStack(spacing: 16) {
                            Text("7-Day Forecast")
                                .font(.title2)
                                .bold()
                            
                            if viewModel.weeklyForecast.isEmpty {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    Text("No weekly data available")
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.weeklyForecast) { day in
                                            HStack {
                                                Text(day.date.formatted(.dateTime.weekday(.wide)))
                                                    .frame(width: 100, alignment: .leading)
                                                
                                                Image(systemName: day.iconName)
                                                    .foregroundColor(iconColor(for: day.iconName))
                                                    .frame(width: 30)
                                                
                                                Spacer()
                                                
                                                Text("H: \(Int(day.maxTemp))°")
                                                    .frame(width: 50, alignment: .trailing)
                                                
                                                Text("L: \(Int(day.minTemp))°")
                                                    .frame(width: 50, alignment: .trailing)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .tag("weekly")
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 500)

                    // MARK: - Saved Locations Section
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(savedLocations, id: \.self) { loc in
                                Button(action: {
                                    viewModel.location = loc
                                    viewModel.fetchWeather(for: loc)
                                }) {
                                    Text(loc)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.2))
                                        .foregroundColor(.black)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .onAppear {
                    // Fetch weather data when view appears
                    viewModel.fetchWeather(for: viewModel.location)
                }
            }
        }
    }
}
