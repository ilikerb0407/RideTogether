//
//  MapViewDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import CoreGPX
import MapKit
//import CoreLocation

class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        // MARK: change if to guard in case it will crash
        guard overlay is MKPolyline else {
            
            let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
            
            polyLineRenderer.alpha = 0.8
            // MARK: routeLine color
            polyLineRenderer.strokeColor = .systemOrange
            
            polyLineRenderer.lineWidth = 3
            
            polyLineRenderer.lineCap = .round
            
            return polyLineRenderer
        }
        
        return MKOverlayRenderer()
    }
    
    /// Adds the pin to the map with an animation (comes from the top of the screen)
    ///
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        var num = 0
        // swiftlint:disable force_cast
        let gpxMapView = mapView as! GPXMapView
        var hasImpacted = false
        //adds the pins with an animation
        for object in views {
            num += 1
            let annotationView = object as MKAnnotationView
            //The only exception is the user location, we add to this the heading icon.
            if annotationView.annotation!.isKind(of: MKUserLocation.self) {
                if gpxMapView.headingImageView == nil {
                    let image = UIImage(named: "heading")!
                    gpxMapView.headingImageView = UIImageView(image: image)
                    gpxMapView.headingImageView!.frame = CGRect(x: (annotationView.frame.size.width - image.size.width)/2,
                                                                y: (annotationView.frame.size.height - image.size.height)/2,
                                                                width: image.size.width,
                                                                height: image.size.height)
                    annotationView.insertSubview(gpxMapView.headingImageView!, at: 0)
                    gpxMapView.headingImageView!.isHidden = true
                }
                continue
            }
            let point: MKMapPoint = MKMapPoint.init(annotationView.annotation!.coordinate)
            if !mapView.visibleMapRect.contains(point) { continue }
            
            let endFrame: CGRect = annotationView.frame
            
            annotationView.frame = CGRect(x: annotationView.frame.origin.x, y: annotationView.frame.origin.y - mapView.superview!.frame.size.height,
                width: annotationView.frame.size.width, height: annotationView.frame.size.height)
            let interval: TimeInterval = 0.04 * 1.1
            
            UIView.animate(withDuration: 0.5, delay: interval, options: UIView.AnimationOptions.curveLinear, animations: { () -> Void in
                annotationView.frame = endFrame
                }, completion: { (finished) -> Void in
                    if finished {
                        UIView.animate(withDuration: 0.05, animations: { () -> Void in
                            
                            annotationView.transform = CGAffineTransform(a: 1.0, b: 0, c: 0, d: 0.8, tx: 0, ty: annotationView.frame.size.height*0.1)
                            
                            }, completion: { _ -> Void in
                                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                                    annotationView.transform = CGAffineTransform.identity
                                })
                                if #available(iOS 10.0, *), !hasImpacted {
                                    hasImpacted = true
                                    UIImpactFeedbackGenerator(style: num > 2 ? .heavy : .medium).impactOccurred()
                                }
                        })
                    }
            })
        }
    }
}
