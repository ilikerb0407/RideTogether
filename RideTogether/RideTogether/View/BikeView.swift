//
//  BikeView.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/13.
//
//  Renamed from `Ubike2.0.swift` — the dotted filename didn't match its
//  class name (`BikeView`) and could be confused for a version suffix.
//  This file is used (as an MKMapViewDelegate) by RideViewController.
//

import CoreGPX
import CoreLocation
import MapKit
import UIKit

class BikeView: NSObject, MKMapViewDelegate {
    func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) { return nil }

        let annotationView = MKMarkerAnnotationView()

        annotationView.canShowCallout = true

        return annotationView
    }

    // TODO: 我之後想做一個使用者在騎乘的時候 polyLineRenderer 顏色會跟著自動變的效果ＸＤ 不知道會不會很好效能，如果這是 swiftUI 提供的框架的話，就要在思考是不是等之後 refractor 成 swiftUI 的時候再加進去這個功能
    
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
