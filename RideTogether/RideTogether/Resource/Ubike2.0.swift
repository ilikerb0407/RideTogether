//
//  Ubike2.0.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/13.
//

import UIKit
import CoreGPX
import MapKit
import CoreLocation
import SwiftUI


class BikeView: NSObject, MKMapViewDelegate {
    
    
    /// Current session of GPX location logging. Handles all background tasks and recording.
    let session = GPXSession()
    
    /// The Waypoint is being edited (if there is any)
    var waypointBeingEdited: GPXWaypoint = GPXWaypoint()
    
 
    
    // MARK:  Displays a pin with whose annotation (bubble) will include delete buttons.
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        let annotationView = MKPinAnnotationView()

        annotationView.canShowCallout = true
        annotationView.isDraggable = true
       
        return annotationView
    }
    

}
