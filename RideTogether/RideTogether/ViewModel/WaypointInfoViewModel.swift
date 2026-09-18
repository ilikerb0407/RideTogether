//
//  WaypointInfoViewModel.swift
//  RideTogether
//
//  Extracts the business logic that used to live directly inside
//  `MapPin` (a `MKMapViewDelegate`, in the View layer): calculating a
//  walking route to a dropped pin, fetching current weather there, and
//  reverse-geocoding a human-readable place name.
//
//  Why this was moved out of MapPin:
//  1. Testability — MapPin called `MKDirections`, `CLGeocoder`, and
//     `WeatherManager.shared` directly, so none of this logic could be
//     unit tested without hitting real network/MapKit services. Here,
//     `DirectionsProviding` and `ReverseGeocoding` are protocols with a
//     real MapKit/CoreLocation-backed default implementation, exactly
//     like `WeatherManaging` — a test can inject fakes for all three.
//  2. Correctness — MapPin previously cached the result of these calls in
//     its own instance properties (`route`, `destination`, `weatherData`),
//     shared across every pin on the map. With multiple pins, only the
//     *last* pin's route/destination survived, so tapping the info button
//     on an earlier pin could show another pin's distance, weather, or
//     place name. This ViewModel takes no shared mutable state between
//     waypoints — every call to `loadInfo(for:)` computes fresh, keyed to
//     the specific waypoint passed in.
//
//  This ViewModel deliberately knows nothing about UIKit presentation
//  (no UIAlertController, no MKMapView mutation). It hands the View a
//  plain `WaypointInfoDisplayData` value; the View decides how to display
//  it and what to do if the user taps "navigate here".

import CoreLocation
import Foundation
import MapKit
import CoreGPX

// MARK: - DirectionsProviding

/// Abstraction over `MKDirections`, so `WaypointInfoViewModel` can be
/// tested without making a real MapKit directions request.
protocol DirectionsProviding {
    func calculateWalkingRoute(to coordinate: CLLocationCoordinate2D, completion: @escaping (Result<MKRoute, Error>) -> Void)
}

struct DirectionsUnavailableError: Error {}

class MapKitDirectionsProvider: DirectionsProviding {
    func calculateWalkingRoute(to coordinate: CLLocationCoordinate2D, completion: @escaping (Result<MKRoute, Error>) -> Void) {
        let targetPlacemark = MKPlacemark(coordinate: coordinate)
        let targetItem = MKMapItem(placemark: targetPlacemark)
        let userMapItem = MKMapItem.forCurrentLocation()

        let request = MKDirections.Request()
        request.source = userMapItem
        request.destination = targetItem
        request.transportType = .walking
        request.requestsAlternateRoutes = true

        MKDirections(request: request).calculate { response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let route = response?.routes.first else {
                completion(.failure(DirectionsUnavailableError()))
                return
            }
            completion(.success(route))
        }
    }
}

// MARK: - ReverseGeocoding

/// Abstraction over `CLGeocoder`, so `WaypointInfoViewModel` can be tested
/// without making a real reverse-geocoding request.
protocol ReverseGeocoding {
    func placemark(for coordinate: CLLocationCoordinate2D, completion: @escaping (CLPlacemark?) -> Void)
}

class CLGeocoderReverseGeocoder: ReverseGeocoding {
    private let geocoder = CLGeocoder()

    func placemark(for coordinate: CLLocationCoordinate2D, completion: @escaping (CLPlacemark?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let locale = Locale(identifier: "zh_TW")

        geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, error in
            if error != nil {
                completion(nil)
                return
            }
            completion(placemarks?.first)
        }
    }
}

// MARK: - WaypointInfoDisplayData

/// Plain data for the View to render. No UIKit/MapKit-presentation logic
/// here — just the strings the alert needs, plus the `MKRoute` itself in
/// case the user chooses "navigate here" and the View needs to draw its
/// polyline as an overlay.
struct WaypointInfoDisplayData {
    let destinationName: String
    let distanceText: String
    let travelTimeText: String
    let weatherDescription: String
    let route: MKRoute
}

enum WaypointInfoError: Error {
    case missingCoordinate
}

// MARK: - WaypointInfoViewModel

class WaypointInfoViewModel {
    private let weatherManager: WeatherManaging
    private let directionsProvider: DirectionsProviding
    private let geocoder: ReverseGeocoding

    init(
        weatherManager: WeatherManaging = WeatherManager.shared,
        directionsProvider: DirectionsProviding = MapKitDirectionsProvider(),
        geocoder: ReverseGeocoding = CLGeocoderReverseGeocoder()
    ) {
        self.weatherManager = weatherManager
        self.directionsProvider = directionsProvider
        self.geocoder = geocoder
    }

    /// Computes everything needed to show the info callout for `waypoint`,
    /// fresh, with no dependency on any previous call's result.
    func loadInfo(for waypoint: GPXWaypoint, completion: @escaping (Result<WaypointInfoDisplayData, Error>) -> Void) {
        guard let latitude = waypoint.latitude, let longitude = waypoint.longitude else {
            completion(.failure(WaypointInfoError.missingCoordinate))
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        directionsProvider.calculateWalkingRoute(to: coordinate) { [weak self] routeResult in
            guard let self = self else { return }

            switch routeResult {
            case let .failure(error):
                completion(.failure(error))

            case let .success(route):
                self.weatherManager.getGroupAPI(latitude: latitude, longitude: longitude) { weather in
                    self.geocoder.placemark(for: coordinate) { placemark in
                        let data = WaypointInfoDisplayData(
                            destinationName: placemark?.thoroughfare ?? "鄉間小路",
                            distanceText: route.distance.toDistance(),
                            travelTimeText: (route.expectedTravelTime / 3).tohmsTimeFormat(),
                            weatherDescription: weather.weather.first?.main ?? "",
                            route: route
                        )
                        completion(.success(data))
                    }
                }
            }
        }
    }
}
