//
//  GPXTrackSegmentTests.swift
//  RideTogetherTests
//
//  Unit tests for the pure distance-calculation logic on GPXTrackSegment:
//  `length()` and `distanceFromOrigin()`. Both power real user-facing
//  numbers (the total distance shown during a ride, and the X-axis of the
//  elevation chart in TrackDetailsViewController), take plain coordinate
//  arrays as input, and don't touch the network, Firebase, or UIKit — they
//  were the most straightforward candidates in the project for unit
//  testing with no mocking required at all.

import CoreGPX
import CoreLocation
import XCTest
@testable import RideTogether

final class GPXTrackSegmentTests: XCTestCase {
    // MARK: - Helpers

    private func makePoint(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> GPXTrackPoint {
        GPXTrackPoint(location: CLLocation(latitude: latitude, longitude: longitude))
    }

    private func makeSegment(_ coordinates: [(CLLocationDegrees, CLLocationDegrees)]) -> GPXTrackSegment {
        let segment = GPXTrackSegment()
        for (latitude, longitude) in coordinates {
            segment.add(trackpoint: makePoint(latitude: latitude, longitude: longitude))
        }
        return segment
    }

    // A handful of real Taipei-area coordinates, just so distances are
    // non-trivial and non-degenerate (not all on the same point).
    private let pointA = (25.0330, 121.5654) // 台北 101 一帶
    private let pointB = (25.0478, 121.5319) // 台北車站一帶
    private let pointC = (25.0630, 121.5460) // 士林一帶

    // MARK: - length()

    func testLength_noPoints_isZero() {
        XCTAssertEqual(makeSegment([]).length(), 0.0)
    }

    func testLength_singlePoint_isZero() {
        XCTAssertEqual(makeSegment([pointA]).length(), 0.0)
    }

    func testLength_twoPoints_equalsDirectDistanceBetweenThem() {
        let segment = makeSegment([pointA, pointB])

        let a = CLLocation(latitude: pointA.0, longitude: pointA.1)
        let b = CLLocation(latitude: pointB.0, longitude: pointB.1)
        let expected = a.distance(from: b)

        XCTAssertEqual(segment.length(), expected, accuracy: 0.001)
    }

    func testLength_threePoints_sumsConsecutiveLegsRatherThanTheStraightLineTotal() {
        // This is the behavior that actually distinguishes `length()`
        // (a path length) from a naive point-to-point distance: for a
        // bent path A → B → C, the summed leg lengths must be strictly
        // greater than the direct distance from A to C.
        let segment = makeSegment([pointA, pointB, pointC])

        let a = CLLocation(latitude: pointA.0, longitude: pointA.1)
        let b = CLLocation(latitude: pointB.0, longitude: pointB.1)
        let c = CLLocation(latitude: pointC.0, longitude: pointC.1)

        let expectedLength = a.distance(from: b) + b.distance(from: c)
        let directDistanceAtoC = a.distance(from: c)

        XCTAssertEqual(segment.length(), expectedLength, accuracy: 0.001)
        XCTAssertGreaterThan(segment.length(), directDistanceAtoC)
    }

    // MARK: - distanceFromOrigin()

    func testDistanceFromOrigin_noPoints_returnsSingleZero() {
        XCTAssertEqual(makeSegment([]).distanceFromOrigin(), [0.0])
    }

    func testDistanceFromOrigin_singlePoint_returnsSingleZero() {
        XCTAssertEqual(makeSegment([pointA]).distanceFromOrigin(), [0.0])
    }

    func testDistanceFromOrigin_multiplePoints_hasOneEntryPerPointAndIsMonotonicallyIncreasing() {
        let coordinates = [pointA, pointB, pointC, (25.0700, 121.5500)]
        let segment = makeSegment(coordinates)

        let distances = segment.distanceFromOrigin()

        XCTAssertEqual(distances.count, coordinates.count, "one cumulative-distance entry per track point")
        XCTAssertEqual(distances.first, 0.0, "the first point is always distance 0 from itself")
        XCTAssertEqual(distances.last, segment.length(), accuracy: 0.001, "the last entry should equal the segment's total length")

        for index in 1 ..< distances.count {
            XCTAssertGreaterThanOrEqual(distances[index], distances[index - 1], "cumulative distance must never decrease")
        }
    }
}
