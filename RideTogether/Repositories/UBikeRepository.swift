//
//  UBikeRepository.swift
//  RideTogether
//
//  Created by Auto on 2026/01/23.
//

import Combine
import CoreLocation
import Foundation

/// Protocol defining UBike/YouBike station operations
protocol UBikeRepositoryProtocol {
    func fetchTaipeiBikeStations() -> AnyPublisher<[TPBikeModel], Error>
    func fetchTaichungBikeStations() -> AnyPublisher<TCBikeModel, Error>
    func fetchNearbyStations(location: CLLocation, radius: Double) -> AnyPublisher<[TPBikeModel], Error>
}

/// Repository handling UBike/YouBike station data with Combine
final class UBikeRepository: UBikeRepositoryProtocol {
    // MARK: - Dependencies
    private let manager: BikeManager

    // MARK: - Init
    init(manager: BikeManager = .shared) {
        self.manager = manager
    }

    // MARK: - Public Methods

    /// Fetch Taipei YouBike 2.0 stations with retry and error recovery
    func fetchTaipeiBikeStations() -> AnyPublisher<[TPBikeModel], Error> {
        Future<[TPBikeModel], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown(NSError(domain: "UBikeRepository", code: -1))))
                return
            }

            self.manager.getTPBikeData { bikeStations in
                promise(.success(bikeStations))
            }
        }
        .retry(2) // Retry up to 2 times on network failure
        .catch { error -> AnyPublisher<[TPBikeModel], Error> in
            // Graceful error recovery
            print("Taipei bike data fetch failed: \(error.localizedDescription)")
            return Fail(error: RepositoryError.networkError(error))
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Fetch Taichung bike stations
    func fetchTaichungBikeStations() -> AnyPublisher<TCBikeModel, Error> {
        Future<TCBikeModel, Error> { promise in
            BikeManager.getTCBikeData { bikeData in
                promise(.success(bikeData))
            }
        }
        .retry(2)
        .catch { error -> AnyPublisher<TCBikeModel, Error> in
            print("Taichung bike data fetch failed: \(error.localizedDescription)")
            return Fail(error: RepositoryError.networkError(error))
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Fetch nearby bike stations within a radius (in meters)
    func fetchNearbyStations(location: CLLocation, radius: Double = 1000) -> AnyPublisher<[TPBikeModel], Error> {
        fetchTaipeiBikeStations()
            .map { stations in
                // Filter stations within radius
                stations.filter { station in
                    let stationLocation = CLLocation(
                        latitude: Double(station.latitude) ?? 0,
                        longitude: Double(station.longitude) ?? 0
                    )
                    let distance = location.distance(from: stationLocation)
                    return distance <= radius
                }
                .sorted { station1, station2 in
                    // Sort by distance (closest first)
                    let loc1 = CLLocation(
                        latitude: Double(station1.latitude) ?? 0,
                        longitude: Double(station1.longitude) ?? 0
                    )
                    let loc2 = CLLocation(
                        latitude: Double(station2.latitude) ?? 0,
                        longitude: Double(station2.longitude) ?? 0
                    )
                    return location.distance(from: loc1) < location.distance(from: loc2)
                }
            }
            .eraseToAnyPublisher()
    }

    /// Fetch all stations with caching support using .share()
    /// This prevents multiple simultaneous requests for the same data
    func fetchStationsShared() -> AnyPublisher<[TPBikeModel], Error> {
        fetchTaipeiBikeStations()
            .share() // Share the same network request among multiple subscribers
            .eraseToAnyPublisher()
    }
}
