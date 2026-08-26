//
//  GPXTrackSegment+MapKit.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import Foundation
import MapKit
import UIKit

public extension GPXTrackSegment {
    var overlay: MKPolyline {
        var coords: [CLLocationCoordinate2D] = trackPointsToCoordinates()
        let polyLine = MKPolyline(coordinates: &coords, count: coords.count)
        return polyLine
    }
}

extension GPXTrackSegment {
    func trackPointsToCoordinates() -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        for point in points {
            coords.append(point.coordinate)
        }
        return coords
    }

    func length() -> CLLocationDistance {
        var length: CLLocationDistance = 0.0
        var distanceTwoPoints: CLLocationDistance
        if points.count < 2 {
            return length
        }
        var prev: CLLocation?
        for point in points {
            let point = CLLocation(latitude: Double(point.latitude!), longitude: Double(point.longitude!))
            if prev == nil {
                prev = point
                continue
            }
            distanceTwoPoints = point.distance(from: prev!)
            length += distanceTwoPoints
            prev = point
        }
        return length
    }

    func distanceFromOrigin() -> [Double] {
        var distanceFromOrigin = [0.0]
        var length = 0.0
        var interval = 0.0
        if points.count < 2 {
            return distanceFromOrigin
        }
        var prev: CLLocation?
        for point in points {
            let point = CLLocation(latitude: Double(point.latitude!), longitude: Double(point.longitude!))
            if prev == nil {
                prev = point
                continue
            }
            interval = point.distance(from: prev!)
            length += interval
            distanceFromOrigin.append(length)
            prev = point
        }
        return distanceFromOrigin
    }
}
