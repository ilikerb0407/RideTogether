//
//  BikeItems.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/13.
//

import Foundation
import CoreLocation
import MapKit

class BikeAnnotation: NSObject, MKAnnotation {
    
    // 站名
    let title: String?
    
    let coordinate: CLLocationCoordinate2D
    
    let canRent: Int?
    
    let canDocks: Int?
    
    init(title: String, coordinate: CLLocationCoordinate2D, canRent: Int, canDocks: Int) {
        
        self.title = title
        
        self.coordinate = coordinate
        
        self.canRent = canRent
        
        self.canDocks = canRent
        
    }
}

