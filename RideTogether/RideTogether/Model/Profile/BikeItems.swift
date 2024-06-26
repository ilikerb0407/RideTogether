//
//  BikeItems.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/13.
//

import CoreLocation
import Foundation
import MapKit

class BikeAnnotation: NSObject, MKAnnotation {
    let title: String?

    let subtitle: String?

    let coordinate: CLLocationCoordinate2D

    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title

        self.subtitle = subtitle

        self.coordinate = coordinate
    }
}
