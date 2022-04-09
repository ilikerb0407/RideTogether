//
//  MapViewDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import CoreGPX
import MapKit

class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            
            let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
            
            polyLineRenderer.alpha = 0.8
            // MARK: routeLine color
            polyLineRenderer.strokeColor = .systemOrange
            
            polyLineRenderer.lineWidth = 2
            
            return polyLineRenderer
        }
        
        return MKOverlayRenderer()
    }
}
