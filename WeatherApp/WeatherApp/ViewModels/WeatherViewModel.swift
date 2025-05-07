//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Stanley Yu on 4/5/25.
//
import Foundation
import Combine

class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherData?
    @Published var location: String = "New York"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let apiKey = "3535447ce362cc4b8779463161ecbee7"
    private var cancellables = Set<AnyCancellable>()
    
    func fetchWeather(for city: String) {
        isLoading = true
        errorMessage = nil
        location = city
        
        fetchCoordinates(for: city)
            .flatMap { coordinates in
                self.fetchWeatherData(lat: coordinates.lat, lon: coordinates.lon)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] weatherData in
                    self?.weather = weatherData
                }
            )
            .store(in: &cancellables)
    }
    
    private func fetchCoordinates(for city: String) -> AnyPublisher<(lat: Double, lon: Double), Error> {
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city)&limit=1&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [GeocodingResponse].self, decoder: JSONDecoder())
            .tryMap { responses in
                guard let first = responses.first else {
                    throw URLError(.cannotFindHost)
                }
                return (lat: first.lat, lon: first.lon)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchWeatherData(lat: Double, lon: Double) -> AnyPublisher<WeatherData, Error> {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherData.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
