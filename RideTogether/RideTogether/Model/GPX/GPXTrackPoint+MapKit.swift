//
//  GPXTrackPoint+MapKit.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import Foundation
import MapKit
import UIKit

extension GPXTrackPoint {
    convenience init(location: CLLocation) {
        self.init()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.time = Date()
        self.elevation = location.altitude
    }
}
