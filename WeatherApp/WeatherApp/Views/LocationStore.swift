//
//  LocationStore.swift
//  WeatherApp
//
//  Created by Stanley Yu on 5/6/25.
//

import Foundation
import SwiftUI
import Combine

class LocationStore: ObservableObject {
    // For simple String array
    @AppStorage("savedLocations") private var savedLocationsData: Data = Data()
    // For coordinates 
    @AppStorage("locationCoordinates") private var locationCoordinatesData: Data = Data()
    
    var savedLocations: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: savedLocationsData)) ?? ["New York"]
        }
        set {
            savedLocationsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    var locationCoordinates: [String: String] {
        get {
            (try? JSONDecoder().decode([String: String].self, from: locationCoordinatesData)) ?? [:]
        }
        set {
            locationCoordinatesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    private let apiKey: String
    private var cancellables = Set<AnyCancellable>()
    
    init(apiKey: String) {
        self.apiKey = apiKey
        fetchMissingCoordinates()
    }
    
    // Rest of your existing methods remain exactly the same
    func addLocation(_ location: String) -> AnyPublisher<Void, Error> {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if savedLocations.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return Fail(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Location already exists"]))
                .eraseToAnyPublisher()
        }
        
        savedLocations.append(trimmed)
        
        return fetchCoordinates(for: trimmed)
            .map { coordinates in
                var currentCoords = self.locationCoordinates
                currentCoords[trimmed] = String(format: "Lat: %.4f, Lon: %.4f", coordinates.lat, coordinates.lon)
                self.locationCoordinates = currentCoords
                return ()
            }
            .eraseToAnyPublisher()
    }
    
    func removeLocation(_ location: String) {
        savedLocations.removeAll { $0 == location }
        var currentCoords = locationCoordinates
        currentCoords.removeValue(forKey: location)
        locationCoordinates = currentCoords
    }
    
    private func fetchMissingCoordinates() {
        savedLocations
            .filter { locationCoordinates[$0] == nil }
            .forEach { location in
                fetchCoordinates(for: location)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { coordinates in
                            var currentCoords = self.locationCoordinates
                            currentCoords[location] = String(format: "Lat: %.4f, Lon: %.4f", coordinates.lat, coordinates.lon)
                            self.locationCoordinates = currentCoords
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
}
