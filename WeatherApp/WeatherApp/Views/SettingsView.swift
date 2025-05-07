import SwiftUI

struct SettingsView: View {
    @Binding var savedLocations: [String]
    @ObservedObject var viewModel: WeatherViewModel
    @State private var newLocation: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Store both user input and API's official location names
    @State private var locationData: [LocationData] = {
        if let data = UserDefaults.standard.data(forKey: "locationData"),
           let decoded = try? JSONDecoder().decode([LocationData].self, from: data) {
            return decoded
        }
        return []
    }()
    
    private let maxSavedLocations = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                addLocationSection
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
        }
    }
    
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
            
            if locationData.isEmpty {
                Text("No saved locations")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                List {
                    ForEach(locationData, id: \.id) { data in
                        LocationRow(
                            location: data.officialName,
                            isCurrent: viewModel.location == data.userInput,
                            coordinates: data.coordinates,
                            onSetCurrent: {
                                viewModel.location = data.userInput
                                viewModel.fetchWeather(for: data.userInput)
                            },
                            onDelete: { removeLocation(data.id) }
                        )
                    }
                    .onDelete(perform: deleteLocations)
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func addLocation() {
        let trimmed = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if locationData.count >= maxSavedLocations {
            alertMessage = "You can save up to \(maxSavedLocations) locations."
            showAlert = true
            return
        }
        
        if locationData.contains(where: { $0.userInput.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            alertMessage = "This location is already saved."
            showAlert = true
            return
        }
        
        fetchLocationData(for: trimmed)
    }
    
    private func fetchLocationData(for location: String) {
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location)&limit=1&appid=\(viewModel.apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let response = try JSONDecoder().decode([GeocodingResponse].self, from: data)
                    if let firstLocation = response.first {
                        let coordinates = String(format: "Lat: %.4f, Lon: %.4f", firstLocation.lat, firstLocation.lon)
                        let newData = LocationData(
                            id: UUID(),
                            userInput: location,
                            officialName: "\(firstLocation.name), \(firstLocation.country)",
                            coordinates: coordinates
                        )
                        
                        DispatchQueue.main.async {
                            locationData.append(newData)
                            saveLocationData()
                            viewModel.location = location
                            viewModel.fetchWeather(for: location)
                            newLocation = ""
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        alertMessage = "Could not find this location"
                        showAlert = true
                    }
                }
            }
        }.resume()
    }
    
    private func removeLocation(_ id: UUID) {
        locationData.removeAll { $0.id == id }
        saveLocationData()
        
        if let firstLocation = locationData.first {
            viewModel.location = firstLocation.userInput
            viewModel.fetchWeather(for: firstLocation.userInput)
        } else {
            viewModel.location = ""
        }
    }
    
    private func deleteLocations(at offsets: IndexSet) {
        locationData.remove(atOffsets: offsets)
        saveLocationData()
        
        if let firstLocation = locationData.first {
            viewModel.location = firstLocation.userInput
            viewModel.fetchWeather(for: firstLocation.userInput)
        } else {
            viewModel.location = ""
        }
    }
    
    private func saveLocationData() {
        if let encoded = try? JSONEncoder().encode(locationData) {
            UserDefaults.standard.set(encoded, forKey: "locationData")
            // Update savedLocations binding for compatibility
            savedLocations = locationData.map { $0.userInput }
        }
    }
}

struct LocationData: Identifiable, Codable {
    let id: UUID
    let userInput: String
    let officialName: String
    let coordinates: String
}

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
            }
        }
        .padding(.vertical, 8)
    }
}
