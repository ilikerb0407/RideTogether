//
//  GPXWaypoint+MKAnnotation.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import MapKit
import CoreGPX

extension GPXWaypoint: MKAnnotation {
    
    convenience init (coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)

        let timeFormat = DateFormatter()
        timeFormat.dateStyle = DateFormatter.Style.none
        timeFormat.timeStyle = DateFormatter.Style.medium
        
        let subtitleFormat = DateFormatter()

        subtitleFormat.dateStyle = DateFormatter.Style.medium
        subtitleFormat.timeStyle = DateFormatter.Style.medium
        
        let now = Date()
        self.time = now
        self.title = timeFormat.string(from: now)
        self.subtitle = subtitleFormat.string(from: now)
    }
    
    convenience init (coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance?) {
        self.init(coordinate: coordinate)
        self.elevation = altitude
    }

    public var title: String? {
        get {
            return self.name
        }
        set {
            self.name = newValue
        }
    }
    
    public var subtitle: String? {
        get {
            return self.desc
        }
        set {
            self.desc = newValue
        }
    }

    public var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude!, longitude: CLLocationDegrees(self.longitude!))
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }
}

