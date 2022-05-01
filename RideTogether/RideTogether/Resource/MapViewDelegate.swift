//
//  MapViewDelegate.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import CoreGPX
import MapKit
import CoreLocation
import SwiftUI

class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    /// Current session of GPX location logging. Handles all background tasks and recording.
    let session = GPXSession()
    
    /// The Waypoint is being edited (if there is any)
    var waypointBeingEdited: GPXWaypoint = GPXWaypoint()
    
    var directionsResponse =  MKDirections.Response()
    var route = MKRoute()
    
    var polyLineRenderer = MKPolylineRenderer()
    
    var step: [String] = []
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            
            var polyLineRenderer = MKPolylineRenderer(overlay: overlay)
            
            polyLineRenderer.alpha = 0.8
            
            polyLineRenderer.strokeColor = .orange
            
            polyLineRenderer.lineWidth = 3
            
            return polyLineRenderer
        }
        
        return MKOverlayRenderer()
    }
    
    var destination: CLPlacemark?
    
    func guide(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let annotationView = MKPinAnnotationView()
        guard let waypoint = view.annotation as? GPXWaypoint else { return }
        guard let map = mapView as? GPXMapView else { return }
        let renderer = MKPolylineRenderer()
        let targetCoordinate = annotationView.annotation?.coordinate
        let targetPlacemark = MKPlacemark(coordinate: targetCoordinate ?? waypoint.coordinate)
        let targetItem = MKMapItem(placemark: targetPlacemark)
        let userMapItem = MKMapItem.forCurrentLocation()
        
        let request = MKDirections.Request()
        
        request.source = userMapItem
        request.destination = targetItem
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [self]  response ,error in
            if error == nil {
                self.directionsResponse = response!
                
                self.route = self.directionsResponse.routes[0]
                // route.step
                
                //                map.addOverlay(self.route.polyline, level: MKOverlayLevel.aboveRoads)
            } else {
                print("\(error)")
            }
        }
        let ceo: CLGeocoder = CLGeocoder()
        let loc: CLLocation = CLLocation(latitude: targetPlacemark.coordinate.latitude, longitude: targetPlacemark.coordinate.longitude)
        
        let locale = Locale(identifier: "zh_TW")
        if #available(iOS 11.0, *) {
            ceo.reverseGeocodeLocation(loc, preferredLocale: locale) {
                (placemarks, error) in
                if error == nil {
                    let pm = placemarks! as [CLPlacemark]
                    if pm.count > 0 {
                        let pm = placemarks![0]
                        self.destination = pm
                    }
                }
            }
        }
        
    }
    
    // MARK:  Displays a pin with whose annotation (bubble) will include delete buttons.
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        let annotationView = MKPinAnnotationView()
        
        //        let annotationView: MKPinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "mapping")
        annotationView.canShowCallout = true
        annotationView.isDraggable = true
        
        
        //
        let deleteButton: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        //        deleteButton.setImage(UIImage(named: "information"), for: UIControl.State())
        deleteButton.setImage(UIImage(named: "information"), for: UIControl.State())
        //        deleteButton.setImage(UIImage(named: "deleteHigh"), for: .highlighted)
        deleteButton.tag = kDeleteWaypointAccesoryButtonTag
        annotationView.rightCalloutAccessoryView = deleteButton
        //        annotationView.pinTintColor = .red
        
        let editButton: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        editButton.setImage(UIImage(named: "edit"), for: UIControl.State())
        //        editButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .highlighted)
        
        editButton.tag = kEditWaypointAccesoryButtonTag
        annotationView.leftCalloutAccessoryView = editButton
        
        return annotationView
    }
    
    let kDeleteWaypointAccesoryButtonTag = 666
    
    let kEditWaypointAccesoryButtonTag = 333
    
    
    
    // MARK: 刪除 Pin
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        print("calloutAccesoryControlTapped ")
        guard let waypoint = view.annotation as? GPXWaypoint else { return }
        guard let button = control as? UIButton else { return }
        guard let map = mapView as? GPXMapView else { return }
        
        var routeStep = ""
        
        for (index, item) in self.route.steps.enumerated() {
            routeStep = "\(item.instructions)"
        }
        switch button.tag {
            
        case kDeleteWaypointAccesoryButtonTag:
            print("[calloutAccesoryControlTapped: DELETE button] deleting waypoint with name \(waypoint.name ?? "''")")
            //            map.removeWaypoint(waypoint)
            //            guide(mapView, didSelect: view)
            
            let sheet = UIAlertController(title: nil, message: NSLocalizedString("Information", comment: "no comment"), preferredStyle: .actionSheet)
            
            let removeOption = UIAlertAction(title: NSLocalizedString("Remove", comment: "no comment"), style: .destructive) { _ in
                map.removeWaypoint(waypoint)
                map.removeOverlays(map.overlays)
            }
            
            let distance = UIAlertAction(title: "Distance = \(self.route.distance.toDistance())", style: .default)
            let time = UIAlertAction(title: "Time = \((self.route.expectedTravelTime/3).tohmsTimeFormat())", style: .default)
            
            let routeName = UIAlertAction(title: "Destionation = \(destination?.thoroughfare ?? "鄉間小路")", style: .default) {_ in
                
                map.addOverlay(self.route.polyline, level: MKOverlayLevel.aboveRoads)
                
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "no comment"), style: .cancel)
            
            sheet.addAction(distance)
            sheet.addAction(time)
            sheet.addAction(routeName)
            sheet.addAction(removeOption)
            sheet.addAction(cancelAction)
            
            UIApplication.shared.keyWindow?.rootViewController?.present(sheet, animated: true)
            
        case kEditWaypointAccesoryButtonTag:
            print("[calloutAccesoryControlTapped: EDIT] editing waypoint with name \(waypoint.name ?? "''")")
            
            let indexofEditedWaypoint = map.session.waypoints.firstIndex(of: waypoint)
            
            let alertController = UIAlertController(title: NSLocalizedString("EDIT_WAYPOINT_NAME_TITLE", comment: "no comment"),
                                                    message: NSLocalizedString("EDIT_WAYPOINT_NAME_MESSAGE", comment: "no comment"),
                                                    preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.text = waypoint.title
                textField.clearButtonMode = .always
            }
            let saveAction = UIAlertAction(title: NSLocalizedString("SAVE", comment: "no comment"), style: .default) { _ in
                print("Edit waypoint alert view")
                self.waypointBeingEdited.title = alertController.textFields?[0].text
                //                map.coreDataHelper.update(toCoreData: self.waypointBeingEdited, from: indexofEditedWaypoint!)
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "no comment"), style: .cancel) { _ in }
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true)
            
            self.waypointBeingEdited = waypoint
            
        default:
            print("[calloutAccesoryControlTapped ERROR] unknown control")
        }
    }
    
    //MARK:  Adds the pin to the map with an animation (comes from the top of the screen)
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        
        var num = 0
        // swiftlint:disable force_cast
//        guard let gpxMapView = mapView as? GPXMapView else { return }
        let gpxMapView = mapView as! GPXMapView
        var hasImpacted = false
        //adds the pins with an animation
        for object in views {
            num += 1
            let annotationView = object as MKAnnotationView
            guide(gpxMapView, didSelect: annotationView)
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
                        
                    })
                }
            })
        }
    }
    
    private var mapRoutes: [MKRoute] = []
    
    var routes: DrawRoute?
    
    private var groupedRoutes: [(startItem: MKMapItem, endItem: MKMapItem)] = []
    
    private func groupAndRequestDirections() {
        guard let firstStop = routes!.stops.first else {
            return
        }
        
        groupedRoutes.append((routes!.origin, firstStop))
        
        if routes!.stops.count == 2 {
            let secondStop = routes!.stops[1]
            
            groupedRoutes.append((firstStop, secondStop))
            
            groupedRoutes.append((secondStop, routes!.origin))
        }
        
        fetchNextRoute()
    }
    
    private func fetchNextRoute() {
        guard !groupedRoutes.isEmpty else {
            return
        }
        
        let nextGroup = groupedRoutes.removeFirst()
        let request = MKDirections.Request()
        
        request.source = nextGroup.startItem
        request.destination = nextGroup.endItem
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [self] response, error in
            guard let mapRoute = response?.routes.first else {
                return
            }
            
            self.fetchNextRoute()
        }
    }
}
