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
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        if annotation.isKind(of: MKUserLocation.self) { return nil }
        
        let annotationView = MKPinAnnotationView()
        
        annotationView.canShowCallout = true
        
        annotationView.pinTintColor = .B3
       
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            
            let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
            
            polyLineRenderer.alpha = 0.8
            
            polyLineRenderer.strokeColor = UIColor.B5
            
            if overlay.title == "guide"{
                polyLineRenderer.strokeColor = UIColor.orange
            } else
            if overlay.title == "ride" {
              polyLineRenderer.strokeColor = UIColor.B6
            }
            
            polyLineRenderer.lineWidth = 3
            
            return polyLineRenderer
        }
        
        return MKOverlayRenderer()
        
    }
    

}
