//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Stanley Yu on 4/5/25.
//
import Foundation

class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherData?
    @Published var location: String = "New York"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let apiKey = "3535447ce362cc4b8779463161ecbee7"
    
    func fetchWeather(for city: String) {
        isLoading = true
        errorMessage = nil
        location = city
        
        let geocodingURLStr = "https://api.openweathermap.org/geo/1.0/direct?q=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city)&limit=1&appid=\(apiKey)"
        
        guard let geocodingURL = URL(string: geocodingURLStr) else {
            handleError(message: "Invalid Geocoding URL")
            return
        }
        
        URLSession.shared.dataTask(with: geocodingURL) { [weak self] geocodingData, _, geocodingError in
            guard let self = self else { return }
            
            if let geocodingError = geocodingError {
                self.handleError(message: "Geocoding error: \(geocodingError.localizedDescription)")
                return
            }
            
            guard let geocodingData = geocodingData else {
                self.handleError(message: "No geocoding data received")
                return
            }
            
            do {
                let geocodingResponse = try JSONDecoder().decode([GeocodingResponse].self, from: geocodingData)
                
                guard let firstLocation = geocodingResponse.first else {
                    self.handleError(message: "Location not found")
                    return
                }
                
                let weatherURLStr = "https://api.openweathermap.org/data/2.5/weather?lat=\(firstLocation.lat)&lon=\(firstLocation.lon)&appid=\(self.apiKey)&units=imperial"
                
                guard let weatherURL = URL(string: weatherURLStr) else {
                    self.handleError(message: "Invalid Weather URL")
                    return
                }
                
                URLSession.shared.dataTask(with: weatherURL) { [weak self] weatherData, _, weatherError in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        if let weatherError = weatherError {
                            self.handleError(message: "Weather error: \(weatherError.localizedDescription)")
                            return
                        }
                        
                        guard let weatherData = weatherData else {
                            self.handleError(message: "No weather data received")
                            return
                        }
                        
                        do {
                            self.weather = try JSONDecoder().decode(WeatherData.self, from: weatherData)
                            self.errorMessage = nil
                        } catch {
                            self.handleError(message: "Weather decoding error: \(error.localizedDescription)")
                        }
                    }
                }.resume()
                
            } catch {
                self.handleError(message: "Geocoding decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func handleError(message: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = message
        }
    }
}
