//
//  SettingsView.swift
//  WeatherApp
//
//  Created by Stanley Yu on 4/12/25.
//
import SwiftUI

// A view for managing saved weather locations and adding new ones
struct SettingsView: View {
    // Binding to the array of saved location names from the parent view
    @Binding var savedLocations: [String]
    
    // The shared weather view model for fetching weather data
    @ObservedObject var viewModel: WeatherViewModel
    
    // Temporary storage for the new location being added
    @State private var newLocation: String = ""
    
    // Controls whether to show an alert message
    @State private var showAlert = false
    
    // The message to display in the alert
    @State private var alertMessage = ""
    
    // Array of location data including coordinates and official names
    @State private var locationData: [LocationData] = {
        // Attempt to load saved locations from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "locationData"),
           let decoded = try? JSONDecoder().decode([LocationData].self, from: data) {
            return decoded
        }
        return []
    }()
    
    // Maximum number of locations that can be saved
    private let maxSavedLocations = 3
    
    // MARK: - Main View
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Section for adding new locations
                addLocationSection
                
                // Section displaying saved locations
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
    
    // MARK: - View Components
    
    // The add location section with text field and button
    private var addLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add New Location")
                .font(.headline)
                .padding(.horizontal)
            
            HStack {
                // Text field for entering new location
                TextField("Enter city name", text: $newLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .autocapitalization(.words)
                
                // Clear button that appears when text is entered
                if !newLocation.isEmpty {
                    Button(action: { newLocation = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            
            // Button to add the new location
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
    
    //The saved locations list section
    private var savedLocationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved Locations")
                .font(.headline)
                .padding(.horizontal)
            
            if locationData.isEmpty {
                // Placeholder when no locations are saved
                Text("No saved locations")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // List of saved locations with delete and set current actions
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
                    .onDelete(perform: deleteLocations) // Enables swipe-to-delete
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Location Management Methods
    
    //Validates and adds a new location to the saved locations
    private func addLocation() {
        let trimmed = newLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Check if maximum saved locations reached
        if locationData.count >= maxSavedLocations {
            alertMessage = "You can save up to \(maxSavedLocations) locations."
            showAlert = true
            return
        }
        
        // Check for duplicate locations
        if locationData.contains(where: { $0.userInput.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            alertMessage = "This location is already saved."
            showAlert = true
            return
        }
        
        // Fetch location data from API
        fetchLocationData(for: trimmed)
    }
    private func fetchLocationData(for location: String) {
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location)&limit=1&appid=\(viewModel.apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        // Make network request to geocoding API
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    // Decode API response
                    let response = try JSONDecoder().decode([GeocodingResponse].self, from: data)
                    if let firstLocation = response.first {
                        // Format coordinates string
                        let coordinates = String(format: "Lat: %.4f, Lon: %.4f", firstLocation.lat, firstLocation.lon)
                        
                        // Create new location data object
                        let newData = LocationData(
                            id: UUID(),
                            userInput: location,
                            officialName: "\(firstLocation.name), \(firstLocation.country)",
                            coordinates: coordinates
                        )
                        
                        // Update UI on main thread
                        DispatchQueue.main.async {
                            locationData.append(newData)
                            saveLocationData()
                            viewModel.location = location
                            viewModel.fetchWeather(for: location)
                            newLocation = ""
                        }
                    }
                } catch {
                    // Handle API error
                    DispatchQueue.main.async {
                        alertMessage = "Could not find this location"
                        showAlert = true
                    }
                }
            }
        }.resume()
    }
    
    // Removes a specific location by its ID
    // - Parameter id: The ID of the location to remove
    private func removeLocation(_ id: UUID) {
        locationData.removeAll { $0.id == id }
        saveLocationData()
        
        // Update current location if needed
        if let firstLocation = locationData.first {
            viewModel.location = firstLocation.userInput
            viewModel.fetchWeather(for: firstLocation.userInput)
        } else {
            viewModel.location = ""
        }
    }
    
    //Deletes locations at the specified indices (used for swipe-to-delete)
    // Parameter offsets: The indices of locations to delete
    private func deleteLocations(at offsets: IndexSet) {
        locationData.remove(atOffsets: offsets)
        saveLocationData()
        
        // Update current location if needed
        if let firstLocation = locationData.first {
            viewModel.location = firstLocation.userInput
            viewModel.fetchWeather(for: firstLocation.userInput)
        } else {
            viewModel.location = ""
        }
    }
    
    // Saves the current locations to persistent storage (UserDefaults)
    private func saveLocationData() {
        if let encoded = try? JSONEncoder().encode(locationData) {
            UserDefaults.standard.set(encoded, forKey: "locationData")
            // Update the simple savedLocations array for compatibility
            savedLocations = locationData.map { $0.userInput }
        }
    }
}

// A struct representing a saved location with its metadata
struct LocationData: Identifiable, Codable {
    // Unique identifier for the location
    let id: UUID
    
    // The original user input for the location
    let userInput: String
    
    // The official location name from the API
    let officialName: String
    
    // Formatted coordinates string
    let coordinates: String
}

// A view representing a single row in the saved locations list
struct LocationRow: View {
    // The official location name to display
    let location: String
    
    // Whether this location is currently selected
    let isCurrent: Bool
    
    // The coordinates string to display (optional)
    let coordinates: String?
    
    //Action to perform when setting as current location
    let onSetCurrent: () -> Void
    
    // Action to perform when deleting the location
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Location name
                Text(location)
                    .font(.body)
                
                Spacer()
                
                // Button to set as current location
                Button(action: onSetCurrent) {
                    Image(systemName: "location.fill")
                        .foregroundColor(isCurrent ? .blue : .gray)
                }
                .buttonStyle(.borderless)
                
                // Button to delete location
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
            
            // Display coordinates if available
            if let coordinates = coordinates {
                Text(coordinates)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}
