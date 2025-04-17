//
//  RouteAnnotation.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/19.
//

import MapKit

class RouteAnnotation: NSObject {
    private let item: MKMapItem

    init(item: MKMapItem) {
        self.item = item

        super.init()
    }
}

// MARK: - MKAnnotation

extension RouteAnnotation: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        item.placemark.coordinate
    }

    var title: String? {
        item.name
    }
}
