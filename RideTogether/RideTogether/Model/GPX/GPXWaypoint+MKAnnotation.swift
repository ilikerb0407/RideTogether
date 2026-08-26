//
//  GPXWaypoint+MKAnnotation.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import Foundation
import MapKit

extension GPXWaypoint: MKAnnotation {
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)

        let timeFormat = DateFormatter()
        timeFormat.dateStyle = DateFormatter.Style.none
        timeFormat.timeStyle = DateFormatter.Style.medium

        let subtitleFormat = DateFormatter()

        subtitleFormat.dateStyle = DateFormatter.Style.medium
        subtitleFormat.timeStyle = DateFormatter.Style.medium

        let now = Date()
        time = now
        title = timeFormat.string(from: now)
        subtitle = subtitleFormat.string(from: now)
    }

    convenience init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance?) {
        self.init(coordinate: coordinate)
        elevation = altitude
    }

    public var title: String? {
        get {
            return name
        }
        set {
            name = newValue
        }
    }

    public var subtitle: String? {
        get {
            return desc
        }
        set {
            desc = newValue
        }
    }

    public var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude!, longitude: CLLocationDegrees(longitude!))
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}
