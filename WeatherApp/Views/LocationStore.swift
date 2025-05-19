//
//  LocationStore.swift
//  WeatherApp
//
//  Created by Stanley Yu on 5/6/25.

import Foundation
import Combine

class LocationStore: ObservableObject {
    @Published var savedLocations: [String]
    @Published var locationCoordinates: [String: String]
    
    private let apiKey: String
    private var cancellables = Set<AnyCancellable>()
    private let userDefaultsKey = "savedLocations"
    private let coordinatesKey = "locationCoordinates"
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.savedLocations = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] ?? ["New York"]
        self.locationCoordinates = UserDefaults.standard.dictionary(forKey: coordinatesKey) as? [String: String] ?? [:]
        
        // Fetch coordinates for any locations that don't have them
        fetchMissingCoordinates()
    }
    
    func addLocation(_ location: String) -> AnyPublisher<Void, Error> {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for duplicates
        if savedLocations.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return Fail(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Location already exists"])).eraseToAnyPublisher()
        }
        
        savedLocations.append(trimmed)
        saveToUserDefaults()
        
        return fetchCoordinates(for: trimmed)
            .map { coordinates in
                let coordString = String(format: "Lat: %.4f, Lon: %.4f", coordinates.lat, coordinates.lon)
                self.locationCoordinates[trimmed] = coordString
                self.saveCoordinatesToStorage()
                return ()
            }
            .eraseToAnyPublisher()
    }
    
    func removeLocation(_ location: String) {
        savedLocations.removeAll { $0 == location }
        locationCoordinates.removeValue(forKey: location)
        saveToUserDefaults()
        saveCoordinatesToStorage()
    }
    
    private func fetchMissingCoordinates() {
        savedLocations
            .filter { locationCoordinates[$0] == nil }
            .forEach { location in
                fetchCoordinates(for: location)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { coordinates in
                            let coordString = String(format: "Lat: %.4f, Lon: %.4f", coordinates.lat, coordinates.lon)
                            self.locationCoordinates[location] = coordString
                            self.saveCoordinatesToStorage()
                        }
                    )
                    .store(in: &cancellables)
            }
    }
    
    private func fetchCoordinates(for location: String) -> AnyPublisher<(lat: Double, lon: Double), Error> {
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location)&limit=1&appid=\(apiKey)"
        
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
    
    private func saveToUserDefaults() {
        UserDefaults.standard.set(savedLocations, forKey: userDefaultsKey)
    }
    
    private func saveCoordinatesToStorage() {
        UserDefaults.standard.set(locationCoordinates, forKey: coordinatesKey)
    }
}
