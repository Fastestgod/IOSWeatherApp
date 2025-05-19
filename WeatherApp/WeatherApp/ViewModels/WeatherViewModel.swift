import Foundation
import Combine

class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherData?
    @Published var hourlyForecast: [HourlyWeatherData] = []
    @Published var location: String = "New York"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var weeklyForecast: [DailyWeatherData] = []
    
    let apiKey = "3535447ce362cc4b8779463161ecbee7" // Replace with your API key
    private var cancellables = Set<AnyCancellable>()
    
    func fetchWeather(for city: String) {
        isLoading = true
        errorMessage = nil
        location = city
        
        fetchCoordinates(for: city)
            .flatMap { coordinates in
                Publishers.Zip3(
                    self.fetchCurrentWeather(lat: coordinates.lat, lon: coordinates.lon),
                    self.fetchHourlyForecast(lat: coordinates.lat, lon: coordinates.lon),
                    self.fetchDailyForecast(lat: coordinates.lat, lon: coordinates.lon)
                )
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
                receiveValue: { [weak self] (currentWeather, hourlyData, weeklyData) in
                    self?.weather = currentWeather
                    self?.hourlyForecast = hourlyData
                    self?.weeklyForecast = weeklyData
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - API Calls
    
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
    
    private func fetchCurrentWeather(lat: Double, lon: Double) -> AnyPublisher<WeatherData, Error> {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherData.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    private func fetchHourlyForecast(lat: Double, lon: Double) -> AnyPublisher<[HourlyWeatherData], Error> {
        let urlString = "https://pro.openweathermap.org/data/2.5/forecast/hourly?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: HourlyForecastResponse.self, decoder: JSONDecoder())
            .map { $0.list }
            .eraseToAnyPublisher()
    }
    private func fetchDailyForecast(lat: Double, lon: Double) -> AnyPublisher<[DailyWeatherData], Error> {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast/daily?lat=\(lat)&lon=\(lon)&cnt=7&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: WeeklyForecastResponse.self, decoder: JSONDecoder())
            .map { $0.list }
            .eraseToAnyPublisher()
    }
    
}
