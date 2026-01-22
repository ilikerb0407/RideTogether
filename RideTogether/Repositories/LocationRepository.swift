//
//  LocationRepository.swift
//  RideTogether
//
//  Created by Auto on 2026/01/23.
//

import Combine
import CoreLocation
import Foundation

/// Protocol defining location-related operations
protocol LocationRepositoryProtocol {
    func observeLocationUpdates() -> AnyPublisher<CLLocation, Error>
    func observeAuthorizationStatus() -> AnyPublisher<CLAuthorizationStatus, Never>
    func requestLocationPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    var currentLocation: CLLocation? { get }
}

/// Repository handling location operations with Combine
/// Wraps CLLocationManager with reactive Publishers
final class LocationRepository: NSObject, LocationRepositoryProtocol {
    // MARK: - Properties
    private let locationManager: CLLocationManager

    // Subjects for publishing location updates
    private let locationSubject = PassthroughSubject<CLLocation, Error>()
    private let authorizationSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)

    private var cancellables = Set<AnyCancellable>()

    var currentLocation: CLLocation? {
        locationManager.location
    }

    // MARK: - Init
    override init() {
        self.locationManager = CLLocationManager()
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 2 // meters
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = false

        // Initialize authorization status
        if #available(iOS 14.0, *) {
            authorizationSubject.send(locationManager.authorizationStatus)
        } else {
            authorizationSubject.send(CLLocationManager.authorizationStatus())
        }
    }

    // MARK: - Public Methods

    /// Observe location updates as a Combine Publisher
    func observeLocationUpdates() -> AnyPublisher<CLLocation, Error> {
        locationSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Observe authorization status changes
    func observeAuthorizationStatus() -> AnyPublisher<CLAuthorizationStatus, Never> {
        authorizationSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Request location permission
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    /// Start receiving location updates
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    /// Stop receiving location updates
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    deinit {
        stopUpdatingLocation()
        cancellables.removeAll()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationRepository: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationSubject.send(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationSubject.send(completion: .failure(error))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            authorizationSubject.send(manager.authorizationStatus)
        } else {
            authorizationSubject.send(CLLocationManager.authorizationStatus())
        }
    }

    // Legacy method for iOS 13 and earlier
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationSubject.send(status)
    }
}
