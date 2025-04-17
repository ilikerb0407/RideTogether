//
//  Ubike2.0.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/13.
//

import CoreGPX
import CoreLocation
import MapKit
import UIKit

class BikeView: NSObject, MKMapViewDelegate {
    func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }

        let annotationView = MKMarkerAnnotationView()

        annotationView.canShowCallout = true

        return annotationView
    }

    func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polyLineRenderer = MKPolylineRenderer(overlay: overlay)

            polyLineRenderer.alpha = 0.8

            polyLineRenderer.strokeColor = UIColor.B5

            polyLineRenderer.lineWidth = 3

            return polyLineRenderer
        }

        return MKOverlayRenderer()
    }
}
