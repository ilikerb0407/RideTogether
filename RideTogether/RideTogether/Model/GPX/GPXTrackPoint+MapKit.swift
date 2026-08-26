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
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        time = Date()
        elevation = location.altitude
    }
}
