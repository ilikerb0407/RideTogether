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

extension GPXTrackSegment {
    public var overlay: MKPolyline {
        var coords: [CLLocationCoordinate2D] = self.trackPointsToCoordinates()
        let polyLine = MKPolyline(coordinates: &coords, count: coords.count)
        return polyLine
    }
}

extension GPXTrackSegment {
    func trackPointsToCoordinates() -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        for point in self.points {
            coords.append(point.coordinate)
        }
        return coords
    }

    func length() -> CLLocationDistance {
        var length: CLLocationDistance = 0.0
        var distanceTwoPoints: CLLocationDistance
        if self.points.count < 2 {
            return length
        }
        var prev: CLLocation?
        for point in self.points {
            let point: CLLocation = .init(latitude: Double(point.latitude!), longitude: Double(point.longitude!))
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
        var distanceFromOrigin: [Double] = [0.0]
        var length: Double = 0.0
        var interval: Double = 0.0
        if self.points.count < 2 {
            return distanceFromOrigin
        }
        var prev: CLLocation?
        for point in self.points {
            let point: CLLocation = .init(latitude: Double(point.latitude!), longitude: Double(point.longitude!))
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
