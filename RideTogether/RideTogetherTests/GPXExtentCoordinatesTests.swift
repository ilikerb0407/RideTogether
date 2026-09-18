//
//  GPXExtentCoordinatesTests.swift
//  RideTogetherTests
//
//  Unit tests for GPXExtentCoordinates: the incremental bounding-box
//  calculation used to auto-frame the map around a recorded or imported
//  route. Includes a regression test for a bug found during code review:
//  the old implementation used `latitude == 0.00` / `longitude == 0.00`
//  as an "unset" sentinel to detect the very first point, which silently
//  misbehaves for any route whose coordinates legitimately land on the
//  equator or the prime meridian. See the comments in
//  GPXExtentCoordinates.swift for the fix (an explicit `hasLocation` flag).

import CoreLocation
import XCTest
@testable import RideTogether

final class GPXExtentCoordinatesTests: XCTestCase {
    func testExtendArea_firstLocation_setsBothCornersToThatSamePoint() {
        let sut = GPXExtentCoordinates()
        let point = CLLocationCoordinate2D(latitude: 25.03, longitude: 121.56)

        sut.extendAreaToIncludeLocation(point)

        XCTAssertEqual(sut.topLeftCoordinate.latitude, point.latitude)
        XCTAssertEqual(sut.topLeftCoordinate.longitude, point.longitude)
        XCTAssertEqual(sut.bottomRightCoordinate.latitude, point.latitude)
        XCTAssertEqual(sut.bottomRightCoordinate.longitude, point.longitude)
    }

    func testExtendArea_multiplePoints_expandsToTheirBoundingBox() {
        let sut = GPXExtentCoordinates()

        sut.extendAreaToIncludeLocation(CLLocationCoordinate2D(latitude: 25.00, longitude: 121.50))
        sut.extendAreaToIncludeLocation(CLLocationCoordinate2D(latitude: 25.10, longitude: 121.40))
        sut.extendAreaToIncludeLocation(CLLocationCoordinate2D(latitude: 24.90, longitude: 121.60))

        // topLeftCoordinate tracks (min latitude, max longitude);
        // bottomRightCoordinate tracks (max latitude, min longitude) —
        // this is the bounding box convention this class already used
        // before this fix; only the "have I seen a first point yet?"
        // detection changed, not this min/max logic.
        XCTAssertEqual(sut.topLeftCoordinate.latitude, 24.90)
        XCTAssertEqual(sut.topLeftCoordinate.longitude, 121.60)
        XCTAssertEqual(sut.bottomRightCoordinate.latitude, 25.10)
        XCTAssertEqual(sut.bottomRightCoordinate.longitude, 121.40)
    }

    // MARK: - Regression tests for the equator / prime-meridian sentinel bug

    func testExtendArea_pointExactlyOnTheEquator_isNotTreatedAsUnset() {
        let sut = GPXExtentCoordinates()

        // First point sits exactly on the equator. With the old
        // `latitude == 0.00` sentinel check, this legitimate 0.0 stayed
        // indistinguishable from "not set yet" even after being recorded,
        // so the *next* point — regardless of whether it was actually
        // smaller — would incorrectly overwrite this bound. The correct
        // behavior: since 0.0 < 5.0, the equator point should remain the
        // (smaller) topLeft-latitude bound.
        sut.extendAreaToIncludeLocation(CLLocationCoordinate2D(latitude: 0.0, longitude: 100.0))
        sut.extendAreaToIncludeLocation(CLLocationCoordinate2D(latitude: 5.0, longitude: 100.0))

        XCTAssertEqual(sut.topLeftCoordinate.latitude, 0.0)
        XCTAssertEqual(sut.bottomRightCoordinate.latitude, 5.0)
    }

    func testExtendArea_pointExactlyOnThePrimeMeridian_isNotTreatedAsUnset() {
        let sut = GPXExtentCoordinates()

        // Same bug, on the longitude/prime-meridian axis: 0.0 > -1.0, so
        // the prime-meridian point should remain the (larger)
        // topLeft-longitude bound.
        sut.extendAreaToIncludeLocation(CLLocationCoordinate2D(latitude: 51.0, longitude: 0.0))
        sut.extendAreaToIncludeLocation(CLLocationCoordinate2D(latitude: 51.0, longitude: -1.0))

        XCTAssertEqual(sut.topLeftCoordinate.longitude, 0.0)
        XCTAssertEqual(sut.bottomRightCoordinate.longitude, -1.0)
    }
}
