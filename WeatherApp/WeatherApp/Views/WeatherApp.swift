//
//  WeatherApp.swift
//  WeatherApp
//
//  Created by Stanley Yu on 4/5/25.
//

//
//  WeatherApp.swift
//  WeatherApp
//
//  Created by Stanley Yu on 4/5/25.
//

import SwiftUI

struct WeatherApp: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var savedLocations: [String] = ["New York"]
    @State private var currentView: String = "current"

    // Icon color based on type
    private func iconColor(for icon: String) -> Color {
        if icon.contains("sun") {
            return .yellow
        } else if icon.contains("moon") {
            return .blue
        } else if icon.contains("cloud") {
            return .gray
        } else if icon.contains("snow") {
            return .cyan
        } else if icon.contains("bolt") {
            return .orange
        } else {
            return .black
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Top bar with location and gear icon
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
                        NavigationLink(destination: SettingsView(savedLocations: $savedLocations, viewModel: viewModel)) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .padding()
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)

                    // Main content view (current and weekly forecast)
                    TabView(selection: $currentView) {
                        // Current weather view
                        VStack(spacing: 16) {
                            if let icon = viewModel.weather?.iconName {
                                Image(systemName: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(iconColor(for: icon))
                            }

                            if let weather = viewModel.weather {
                                // Inline WeatherCardView
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
                                        HStack {
                                            Image(systemName: "aqi.medium")
                                            Text("Air Quality: N/A")
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(16)
                            } else {
                                ProgressView("Loading weather...")
                            }
                        }
                        .tag("current")

                        // Weekly forecast placeholder
                        VStack(spacing: 16) {
                            Text("Weekly forecast coming soon...")
                                .foregroundColor(.gray)
                        }
                        .tag("weekly")
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 600)

                    // Saved locations scrollable bar
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
                    viewModel.fetchWeather(for: viewModel.location)
                }
            }
        }
    }
}
