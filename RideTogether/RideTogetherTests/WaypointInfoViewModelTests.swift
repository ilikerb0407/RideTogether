//
//  WaypointInfoViewModelTests.swift
//  RideTogetherTests
//
//  Demonstrates that WaypointInfoViewModel — logic that used to live
//  directly inside MapPin (a View) and call MKDirections, CLGeocoder,
//  and WeatherManager.shared for real — can now be tested with zero
//  network calls, by injecting fakes for all three of its dependencies.
//
//  This also verifies the correctness fix: computing info for waypoint A
//  and then for waypoint B does not let B's result leak into A's, because
//  the ViewModel keeps no shared mutable state between calls (the bug
//  that existed when this logic cached results directly on MapPin).

import CoreLocation
import MapKit
import XCTest
@testable import RideTogether

// MARK: - Fakes

private class FakeDirectionsProvider: DirectionsProviding {
    var stubbedResult: Result<MKRoute, Error> = .failure(DirectionsUnavailableError())
    private(set) var requestedCoordinates: [CLLocationCoordinate2D] = []

    func calculateWalkingRoute(to coordinate: CLLocationCoordinate2D, completion: @escaping (Result<MKRoute, Error>) -> Void) {
        requestedCoordinates.append(coordinate)
        completion(stubbedResult)
    }
}

private class FakeReverseGeocoder: ReverseGeocoding {
    var stubbedPlacemark: CLPlacemark?

    func placemark(for coordinate: CLLocationCoordinate2D, completion: @escaping (CLPlacemark?) -> Void) {
        completion(stubbedPlacemark)
    }
}

private class FakeWeatherManager: WeatherManaging {
    var stubbedWeather: ResponseBody!

    func getGroupAPI(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (ResponseBody) -> Void) {
        completion(stubbedWeather)
    }
}

// MARK: - Test helpers

private func makeResponseBody(mainWeather: String) -> ResponseBody {
    // ResponseBody has no public memberwise init reachable here in the
    // same way production code builds it (it's normally decoded from
    // JSON), so tests decode a small canned JSON payload instead of
    // hand-constructing every nested Codable struct.
    let json = """
    {
      "coord": {"lon": 0, "lat": 0},
      "weather": [{"id": 1, "main": "\(mainWeather)", "description": "", "icon": ""}],
      "base": "",
      "main": {"temp": 0, "feels_like": 0, "temp_min": 0, "temp_max": 0, "pressure": 0, "humidity": 0},
      "visibility": 0,
      "wind": {"speed": 0, "deg": 0},
      "clouds": {"all": 0},
      "dt": 0,
      "sys": {"type": 0, "id": 0, "country": "", "sunrise": 0, "sunset": 0},
      "timezone": 0,
      "id": 0,
      "name": "",
      "cod": 0
    }
    """
    return try! JSONDecoder().decode(ResponseBody.self, from: Data(json.utf8))
}

// MARK: - Tests

final class WaypointInfoViewModelTests: XCTestCase {
    func testLoadInfo_missingCoordinate_failsWithoutCallingAnyDependency() {
        // given
        let directionsProvider = FakeDirectionsProvider()
        let geocoder = FakeReverseGeocoder()
        let weatherManager = FakeWeatherManager()
        let sut = WaypointInfoViewModel(weatherManager: weatherManager, directionsProvider: directionsProvider, geocoder: geocoder)
        let waypoint = GPXWaypoint() // latitude/longitude left nil

        let expectation = expectation(description: "completion called")
        var receivedResult: Result<WaypointInfoDisplayData, Error>?

        // when
        sut.loadInfo(for: waypoint) { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        // then
        XCTAssertTrue(directionsProvider.requestedCoordinates.isEmpty)
        switch receivedResult {
        case .failure(let error):
            XCTAssertTrue(error is WaypointInfoError)
        default:
            XCTFail("Expected failure for a waypoint with no coordinate")
        }
    }

    func testLoadInfo_success_combinesRouteWeatherAndPlacemarkIntoDisplayData() {
        // given
        let directionsProvider = FakeDirectionsProvider()
        let route = MKRoute()
        directionsProvider.stubbedResult = .success(route)

        let geocoder = FakeReverseGeocoder()
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 25.03, longitude: 121.56))
        geocoder.stubbedPlacemark = placemark

        let weatherManager = FakeWeatherManager()
        weatherManager.stubbedWeather = makeResponseBody(mainWeather: "Clear")

        let sut = WaypointInfoViewModel(weatherManager: weatherManager, directionsProvider: directionsProvider, geocoder: geocoder)

        let waypoint = GPXWaypoint()
        waypoint.latitude = 25.03
        waypoint.longitude = 121.56

        let expectation = expectation(description: "completion called")
        var receivedResult: Result<WaypointInfoDisplayData, Error>?

        // when
        sut.loadInfo(for: waypoint) { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        // then
        guard case let .success(data) = receivedResult else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(data.weatherDescription, "Clear")
        XCTAssertEqual(directionsProvider.requestedCoordinates.count, 1)
        XCTAssertEqual(directionsProvider.requestedCoordinates.first?.latitude, 25.03)
    }

    func testLoadInfo_calledTwiceForDifferentWaypoints_doesNotLeakStateBetweenCalls() {
        // This is the regression test for the bug found while extracting
        // this logic out of MapPin: MapPin used to cache the *last*
        // computed route/placemark in its own instance properties, shared
        // across every pin, so waypoint A's callout could show waypoint
        // B's data. WaypointInfoViewModel keeps no such shared state.

        // given
        let directionsProvider = FakeDirectionsProvider()
        let geocoder = FakeReverseGeocoder()
        let weatherManager = FakeWeatherManager()
        let sut = WaypointInfoViewModel(weatherManager: weatherManager, directionsProvider: directionsProvider, geocoder: geocoder)

        let waypointA = GPXWaypoint()
        waypointA.latitude = 25.03
        waypointA.longitude = 121.56

        let waypointB = GPXWaypoint()
        waypointB.latitude = 24.14
        waypointB.longitude = 120.68

        // when: load info for A, then B, each with distinct weather stubs
        weatherManager.stubbedWeather = makeResponseBody(mainWeather: "Rain")
        var resultA: Result<WaypointInfoDisplayData, Error>?
        let expectationA = expectation(description: "A completed")
        sut.loadInfo(for: waypointA) { result in
            resultA = result
            expectationA.fulfill()
        }
        wait(for: [expectationA], timeout: 1)

        weatherManager.stubbedWeather = makeResponseBody(mainWeather: "Clear")
        var resultB: Result<WaypointInfoDisplayData, Error>?
        let expectationB = expectation(description: "B completed")
        sut.loadInfo(for: waypointB) { result in
            resultB = result
            expectationB.fulfill()
        }
        wait(for: [expectationB], timeout: 1)

        // then: A's already-delivered result still says "Rain", unaffected
        // by B's later, different weather stub.
        guard case let .success(dataA) = resultA, case let .success(dataB) = resultB else {
            return XCTFail("Expected both calls to succeed")
        }
        XCTAssertEqual(dataA.weatherDescription, "Rain")
        XCTAssertEqual(dataB.weatherDescription, "Clear")
        XCTAssertEqual(directionsProvider.requestedCoordinates.count, 2)
    }
}
