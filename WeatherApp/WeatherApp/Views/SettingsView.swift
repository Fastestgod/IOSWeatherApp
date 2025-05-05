import SwiftUI

struct SettingsView: View {
    @Binding var savedLocations: [String]
    @ObservedObject var viewModel: WeatherViewModel
    @State private var newLocation: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Load coordinates from UserDefaults
    @State private var locationCoordinates: [String: String] = {
        UserDefaults.standard.dictionary(forKey: "locationCoordinates") as? [String: String] ?? [:]
    }()
    
    private let maxSavedLocations = 3
    private let coordinatesKey = "locationCoordinates"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Add Location Section
                addLocationSection
                
                // Saved Locations Section
                savedLocationsSection
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Locations")
            .alert("Notice", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Fetch coordinates for any locations that don't have them
                fetchMissingCoordinates()
            }
        }
    }
    
    // MARK: - View Components
    private var addLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add New Location")
                .font(.headline)
                .padding(.horizontal)
            
            HStack {
                TextField("Enter city name", text: $newLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .autocapitalization(.words)
                
                if !newLocation.isEmpty {
                    Button(action: { newLocation = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            
            Button(action: addLocation) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Location")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(newLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal)
        }
    }
    
    private var savedLocationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved Locations")
                .font(.headline)
                .padding(.horizontal)
            
            if savedLocations.isEmpty {
                Text("No saved locations")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                List {
                    ForEach(savedLocations, id: \.self) { location in
                        LocationRow(
                            location: location,
                            isCurrent: viewModel.location == location,
                            coordinates: locationCoordinates[location],
                            onSetCurrent: {
                                viewModel.location = location
                                viewModel.fetchWeather(for: location)
                            },
                            onDelete: { removeLocation(location) }
                        )
                    }
                    .onDelete(perform: deleteLocations)
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Location Management Methods
    private func addLocation() {
        let trimmed = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Check if already at max locations
        if savedLocations.count >= maxSavedLocations {
            alertMessage = "You can save up to \(maxSavedLocations) locations."
            showAlert = true
            return
        }
        
        // Check for duplicate location
        if savedLocations.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            alertMessage = "This location is already saved."
            showAlert = true
            return
        }
        
        // Add new location
        savedLocations.append(trimmed)
        viewModel.location = trimmed
        viewModel.fetchWeather(for: trimmed)
        fetchCoordinates(for: trimmed)
        newLocation = ""
    }
    
    private func removeLocation(_ location: String) {
        savedLocations.removeAll { $0 == location }
        locationCoordinates.removeValue(forKey: location)
        saveCoordinatesToStorage()
        
        // Update current location if needed
        if viewModel.location == location {
            viewModel.location = savedLocations.first ?? ""
            if !savedLocations.isEmpty {
                viewModel.fetchWeather(for: viewModel.location)
            }
        }
    }
    
    private func deleteLocations(at offsets: IndexSet) {
        // Get locations to be deleted
        let locationsToRemove = offsets.map { savedLocations[$0] }
        
        // Remove from both arrays
        locationsToRemove.forEach { locationCoordinates.removeValue(forKey: $0) }
        savedLocations.remove(atOffsets: offsets)
        saveCoordinatesToStorage()
        
        // Update current location if needed
        if !savedLocations.contains(viewModel.location) {
            viewModel.location = savedLocations.first ?? ""
            if !savedLocations.isEmpty {
                viewModel.fetchWeather(for: viewModel.location)
            }
        }
    }
    
    // MARK: - Coordinate Management
    private func fetchMissingCoordinates() {
        for location in savedLocations where locationCoordinates[location] == nil {
            fetchCoordinates(for: location)
        }
    }
    
    private func fetchCoordinates(for location: String) {
        // Check if we already have coordinates
        if locationCoordinates[location] != nil { return }
        
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location)&limit=1&appid=\(viewModel.apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let response = try JSONDecoder().decode([GeocodingResponse].self, from: data)
                    if let firstLocation = response.first {
                        let coordString = String(format: "Lat: %.4f, Lon: %.4f",
                                                firstLocation.lat,
                                                firstLocation.lon)
                        DispatchQueue.main.async {
                            locationCoordinates[location] = coordString
                            saveCoordinatesToStorage()
                        }
                    }
                } catch {
                    print("Error decoding coordinates: \(error)")
                }
            }
        }.resume()
    }
    
    private func saveCoordinatesToStorage() {
        UserDefaults.standard.set(locationCoordinates, forKey: coordinatesKey)
    }
}

// MARK: - Location Row View
struct LocationRow: View {
    let location: String
    let isCurrent: Bool
    let coordinates: String?
    let onSetCurrent: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(location)
                    .font(.body)
                Spacer()
                
                Button(action: onSetCurrent) {
                    Image(systemName: "location.fill")
                        .foregroundColor(isCurrent ? .blue : .gray)
                }
                .buttonStyle(.borderless)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
            
            if let coordinates = coordinates {
                Text(coordinates)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("Fetching coordinates...")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}
