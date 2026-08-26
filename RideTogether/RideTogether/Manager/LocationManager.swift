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
        startUpdatingLocation()

        startUpdatingHeading()

        requestAlwaysAuthorization()

        desiredAccuracy = kCLLocationAccuracyBest

        distanceFilter = 2 // meters

        pausesLocationUpdatesAutomatically = false

        allowsBackgroundLocationUpdates = false
    }
}
