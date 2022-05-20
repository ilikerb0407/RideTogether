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

class MapPin: NSObject, MKMapViewDelegate, weatherProvider {
    
    
    let baseVC = BaseViewController()
    
    func provideWeather(weather: ResponseBody) {
        weatherData = weather
    }
    var weatherData : ResponseBody?
    
    let weatherManger = WeatherManager()

    let session = GPXSession()

    var waypointBeingEdited: GPXWaypoint = GPXWaypoint()
    
    var directionsResponse =  MKDirections.Response()
    
    var route = MKRoute()
    
    var step: [String] = []
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        
        if overlay is MKPolyline {
            
            let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
            
            polyLineRenderer.alpha = 0.8
            
            polyLineRenderer.strokeColor = UIColor.B5
            
            if overlay.title == "one"{
                polyLineRenderer.strokeColor = UIColor.orange
            } else
            if overlay.title == "two" {
              polyLineRenderer.strokeColor = UIColor.B6
            }
            
            polyLineRenderer.lineWidth = 3
            
            return polyLineRenderer
        }
        
        return MKOverlayRenderer()
        
    }

    var destination: CLPlacemark?
    
    func guide(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let annotationView = MKPinAnnotationView()
        guard let waypoint = view.annotation as? GPXWaypoint else { return }
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
        
        directions.calculate { [self]  response, error in
            
            if error == nil {
                
                self.directionsResponse = response!
                
                self.route = self.directionsResponse.routes[0]
                
            } else {
                print("\(error)")
                
                LKProgressHUD.showFailure(text: "無法導航")
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

        //  let annotationView: MKPinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "mapping")
        annotationView.canShowCallout = true
        annotationView.isDraggable = true
        //
        let rightButton: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.clipsToBounds = true
        rightButton.tintColor = .B5
        let rightImage = UIImage(systemName: "info.circle",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light))
        rightButton.setImage(rightImage, for: .normal)
        //        deleteButton.setImage(UIImage(named: "deleteHigh"), for: .highlighted)
        rightButton.tag = kDeleteWaypointButtonTag
        annotationView.rightCalloutAccessoryView = rightButton
        //        annotationView.pinTintColor = .red
        let leftButton: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        leftButton.tintColor = .B5
        let leftImg = UIImage(systemName: "pencil.circle",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light))
        leftButton.setImage(leftImg, for: .normal)
        //        editButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .highlighted)
        leftButton.tag = kEditWaypointButtonTag
        annotationView.leftCalloutAccessoryView = leftButton
        
        return annotationView
    }
    
    let kDeleteWaypointButtonTag = 666
    
    let kEditWaypointButtonTag = 333
    
    // MARK: - map Annotation -
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        weatherManger.delegate = self
        
        guard let button = control as? UIButton else { return }
        
        guard let map = mapView as? GPXMapView else { return }
        
        guard let polyLine = route.polyline as? MKPolyline else { return }
        
        guard let waypoint = view.annotation as? GPXWaypoint else { return }
        
        self.weatherManger.getGroupAPI(latitude: waypoint.latitude!, longitude: waypoint.longitude!) { [weak self] result in
            
            self?.weatherData = result
            
            DispatchQueue.main.async {
                markMarkers()
            }
        }
       
        func markMarkers() {
            
            switch button.tag {
                
            case kDeleteWaypointButtonTag:
                
                guard let weatherData = weatherData else { return }
                
                let destination = "\(destination?.thoroughfare ?? "鄉間小路")"
                let distance = "\(self.route.distance.toDistance())"
                let time = "\((self.route.expectedTravelTime/3).tohmsTimeFormat())"
                let weather = "\(weatherData.weather[0].main)"
                
                let alertSheet = UIAlertController(title: "\(destination)", message: "距離 = \(distance), 時間 = \(time), 天氣 = \(weather) ", preferredStyle: .actionSheet)
                
                let removeOption = UIAlertAction(title: NSLocalizedString("移除", comment: "no comment"), style: .destructive) { _ in
                    map.removeWaypoint(waypoint)
                    map.removeOverlays(map.overlays)
                }
                
                let routeName = UIAlertAction(title: "導航至該地點", style: .default) {_ in
                   
                    self.route.polyline.title = "one"
                    
                    if polyLine == nil {
                        LKProgressHUD.showFailure(text: "無法導航")
                    } else {
                        map.addOverlay(polyLine, level: MKOverlayLevel.aboveRoads)
                    }
                    
                }
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: "no comment"), style: .cancel) { _ in }
                
                alertSheet.addAction(routeName)
                alertSheet.addAction(removeOption)
                alertSheet.addAction(cancelAction)
                
                let lastVC = UIViewController.getLastPresentedViewController()
                lastVC?.present(alertSheet, animated: true)
    
                // iPad specific code
                
                alertSheet.popoverPresentationController?.sourceView = lastVC?.view

                let xOrigin = (lastVC?.view.bounds.width)! / 2

                let popoverRect = CGRect(x: xOrigin, y: 0, width: 1, height: 1)

                alertSheet.popoverPresentationController?.sourceRect = popoverRect

                alertSheet.popoverPresentationController?.permittedArrowDirections = .unknown
                
            case kEditWaypointButtonTag:
                
                let alertController = UIAlertController(title: "請輸入座標說明", message: nil, preferredStyle: .alert)
                
                alertController.addTextField { (textField) in
                    textField.text = waypoint.title
                    textField.tintColor = .B5
                    textField.clearButtonMode = .always
                }
                let saveAction = UIAlertAction(title: NSLocalizedString("儲存", comment: "no comment"), style: .default) { _ in
                    print("Edit waypoint alert view")
                    self.waypointBeingEdited.title = alertController.textFields?[0].text
                }
                let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: "no comment"), style: .cancel) { _ in }
                
                alertController.addAction(saveAction)
                alertController.addAction(cancelAction)
                
                let VC = UIViewController.getLastPresentedViewController()
                VC?.present(alertController, animated: true)
                
                self.waypointBeingEdited = waypoint
                
            default:
                LKProgressHUD.showFailure(text: "網路問題，無法顯示")
            }
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
                    
                    gpxMapView.headingImageView?.layer.cornerRadius = 20
                    
                    gpxMapView.headingImageView?.layer.masksToBounds = true
                    
                    gpxMapView.headingImageView?.loadImage(UserManager.shared.userInfo.pictureRef, placeHolder: image)
                    
                    gpxMapView.headingImageView!.frame = CGRect(x: (annotationView.frame.size.width - image.size.width)/2,
                                                                y: (annotationView.frame.size.height - image.size.height)/2,
                                                                width: image.size.width,
                                                                height: image.size.height)
                    annotationView.insertSubview(gpxMapView.headingImageView!, at: 0)
                    
//                    gpxMapView.headingImageView!.isHidden = true
                }
                continue
            }
            let point: MKMapPoint = MKMapPoint.init(annotationView.annotation!.coordinate)
            
            if !mapView.visibleMapRect.contains(point) { continue }
            
            let endFrame: CGRect = annotationView.frame
            
            annotationView.frame = CGRect(x: annotationView.frame.origin.x, y: annotationView.frame.origin.y - mapView.superview!.frame.size.height,
                                          
                                          width: annotationView.frame.size.width, height: annotationView.frame.size.height)
            
            let interval: TimeInterval = 0.04 * 1.1
            
            UIView.animate(withDuration: 0.3, delay: interval, options: UIView.AnimationOptions.curveLinear, animations: { () -> Void in
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

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}

extension UIViewController {
    static func getLastPresentedViewController() -> UIViewController? {
        let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
        let window = sceneDelegate?.window
        var presentedViewController = window?.rootViewController
        while presentedViewController?.presentedViewController != nil {
            presentedViewController = presentedViewController?.presentedViewController
        }
        return presentedViewController
    }
}
