//
//  LocationManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/19.
//

import CoreGPX
import CoreLocation
import Foundation

class LocationManager: CLLocationManager {
    func setUpLocationManager() {
        self.startUpdatingLocation()

        self.startUpdatingHeading()

        self.requestAlwaysAuthorization()

        self.desiredAccuracy = kCLLocationAccuracyBest

        self.distanceFilter = 2 // meters

        self.pausesLocationUpdatesAutomatically = false

        self.allowsBackgroundLocationUpdates = false
    }
}
