//
//  GPXExtentCoordinates.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import MapKit

class GPXExtentCoordinates: NSObject {
    var topLeftCoordinate = CLLocationCoordinate2D(latitude: 0.00, longitude: 0.00)

    var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 0.00, longitude: 0.00)

    // Was tracked implicitly via `topLeftCoordinate.latitude == 0.00` /
    // `bottomRightCoordinate.longitude == 0.00` as an "unset" sentinel
    // (see the old `extendAreaToIncludeLocation` below, kept here for
    // reference):
    //
    //   if (topLeftCoordinate.latitude == 0.00) || (location.latitude < topLeftCoordinate.latitude) { ... }
    //
    // That breaks for any route whose very first recorded point sits
    // exactly on the equator or the prime meridian (latitude or
    // longitude == 0.0): a legitimately-recorded 0.0 is indistinguishable
    // from "not set yet", so it gets silently overwritten by the next
    // point instead of being treated as the initial bound. Tracked
    // explicitly with this flag instead, so 0.0 is just a normal
    // coordinate value like any other.
    private var hasLocation = false

    func extendAreaToIncludeLocation(_ location: CLLocationCoordinate2D) {
        guard hasLocation else {
            topLeftCoordinate = location
            bottomRightCoordinate = location
            hasLocation = true
            return
        }

        if location.latitude < topLeftCoordinate.latitude {
            topLeftCoordinate.latitude = location.latitude
        }
        if location.latitude > bottomRightCoordinate.latitude {
            bottomRightCoordinate.latitude = location.latitude
        }

        if location.longitude > topLeftCoordinate.longitude {
            topLeftCoordinate.longitude = location.longitude
        }
        if location.longitude < bottomRightCoordinate.longitude {
            bottomRightCoordinate.longitude = location.longitude
        }
    }

    var region: MKCoordinateRegion {
        get {
            let centerLat = (bottomRightCoordinate.latitude + topLeftCoordinate.latitude) / 2
            let centerLon = (bottomRightCoordinate.longitude + topLeftCoordinate.longitude) / 2
            let center: CLLocationCoordinate2D = .init(latitude: centerLat, longitude: centerLon)
            let latitudeDelta = bottomRightCoordinate.latitude - topLeftCoordinate.latitude
            let longitudeDelta = topLeftCoordinate.longitude - bottomRightCoordinate.longitude
            let span: MKCoordinateSpan = .init(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )

            return MKCoordinateRegion(center: center, span: span)
        }

        set {
            topLeftCoordinate.latitude = newValue.center.latitude - newValue.span.latitudeDelta / 2
            topLeftCoordinate.longitude = newValue.center.longitude + newValue.span.longitudeDelta / 2
            bottomRightCoordinate.latitude = newValue.center.latitude + newValue.span.latitudeDelta / 2
            bottomRightCoordinate.longitude = newValue.center.longitude - newValue.span.longitudeDelta / 2
        }
    }
}
