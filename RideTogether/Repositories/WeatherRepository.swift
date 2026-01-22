//
//  WeatherRepository.swift
//  RideTogether
//
//  Created by Auto on 2026/01/23.
//

import Combine
import CoreLocation
import Foundation

/// Protocol defining weather-related operations
protocol WeatherRepositoryProtocol {
    func fetchWeather(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> AnyPublisher<ResponseBody, Error>
}

/// Repository handling weather data operations with Combine
final class WeatherRepository: WeatherRepositoryProtocol {
    // MARK: - Dependencies
    private let manager: WeatherManager

    // MARK: - Init
    init(manager: WeatherManager = WeatherManager()) {
        self.manager = manager
    }

    // MARK: - Public Methods

    /// Fetch weather information for a location with retry and error recovery
    func fetchWeather(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> AnyPublisher<ResponseBody, Error> {
        Future<ResponseBody, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "WeatherRepository", code: -1))))
                return
            }

            self.manager.getWeatherInfo(latitude: latitude, longitude: longitude) { weatherData in
                promise(.success(weatherData))
            }
        }
        .retry(2) // Retry up to 2 times on failure
        .catch { error -> AnyPublisher<ResponseBody, Error> in
            // Graceful error recovery - return a default/cached value if available
            print("Weather fetch failed: \(error.localizedDescription)")
            return Fail(error: RepositoryError.networkError(error))
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Fetch weather for current location with location repository integration
    func fetchWeatherForCurrentLocation(location: CLLocation) -> AnyPublisher<ResponseBody, Error> {
        fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
}
