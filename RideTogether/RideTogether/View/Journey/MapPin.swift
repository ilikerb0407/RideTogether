//
//  MapPin.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import CoreLocation
import MapKit
import UIKit

class MapPin: NSObject, MKMapViewDelegate {
    var weatherData: ResponseBody?

    let weatherManger = WeatherManager()

    var waypointBeingEdited = GPXWaypoint()

    var directionsResponse = MKDirections.Response()

    var route = MKRoute()

    func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polyLineRenderer = MKPolylineRenderer(overlay: overlay)

            polyLineRenderer.alpha = 0.8

            polyLineRenderer.strokeColor = UIColor.B5

            if overlay.title == "guide" {
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

    var destination: CLPlacemark?

    func guide(_: MKMapView, didSelect view: MKAnnotationView) {
        let annotationView = MKPinAnnotationView()
        guard let waypoint = view.annotation as? GPXWaypoint else {
            return
        }
        let targetCoordinate = annotationView.annotation?.coordinate
        let targetPlaceMark = MKPlacemark(coordinate: targetCoordinate ?? waypoint.coordinate)
        let targetItem = MKMapItem(placemark: targetPlaceMark)
        let userMapItem = MKMapItem.forCurrentLocation()

        let request = MKDirections.Request()

        request.source = userMapItem
        request.destination = targetItem
        request.transportType = .walking
        request.requestsAlternateRoutes = true

        let directions = MKDirections(request: request)

        directions.calculate { [self] response, error in

            if error == nil {
                self.directionsResponse = response!

                self.route = self.directionsResponse.routes[0]

            } else {
                LKProgressHUD.showFailure(text: "無法導航")
            }
        }
        let geoCoder: CLGeocoder = .init()

        let location: CLLocation = .init(latitude: targetPlaceMark.coordinate.latitude, longitude: targetPlaceMark.coordinate.longitude)

        let locale = Locale(identifier: "zh_TW")
        if #available(iOS 11.0, *) {
            geoCoder.reverseGeocodeLocation(location, preferredLocale: locale) { placeMarks, error in
                if error == nil {
                    let placeMarks = placeMarks! as [CLPlacemark]
                    if placeMarks.count > 0 {
                        let placeMark = placeMarks[0]
                        self.destination = placeMark
                    }
                }
            }
        }
    }

    func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        let annotationView = MKMarkerAnnotationView()

        annotationView.canShowCallout = true

        let rightButton: UIButton = .init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.clipsToBounds = true
        rightButton.tintColor = .B5
        let rightImage = UIImage(systemName: "info.circle",
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light))
        rightButton.setImage(rightImage, for: .normal)

        rightButton.tag = informationButtonTag
        annotationView.rightCalloutAccessoryView = rightButton
        let leftButton: UIButton = .init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        leftButton.tintColor = .B5
        let leftImg = UIImage(systemName: "pencil.circle",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light))
        leftButton.setImage(leftImg, for: .normal)

        leftButton.tag = editButtonTag
        annotationView.leftCalloutAccessoryView = leftButton

        return annotationView
    }

    let informationButtonTag = 0

    let editButtonTag = 1

    // MARK: - map Annotation -

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let button = control as? UIButton else {
            return
        }

        guard let map = mapView as? GPXMapView else {
            return
        }

        guard let polyLine = route.polyline as? MKPolyline else {
            return
        }

        guard let waypoint = view.annotation as? GPXWaypoint else {
            return
        }

        self.weatherManger.getWeatherInfo(latitude: waypoint.latitude!, longitude: waypoint.longitude!) { [weak self] result in

            self?.weatherData = result

            DispatchQueue.main.async {
                markMarkers()
            }
        }

        func markMarkers() {
            switch button.tag {
            case informationButtonTag:

                guard let weatherData else {
                    return
                }

                let destination = "\(destination?.thoroughfare ?? "鄉間小路")"
                let distance = "\(self.route.distance.toDistance())"
                let time = "\((self.route.expectedTravelTime / 3).tohmsTimeFormat())"
                let weather = "\(weatherData.weather[0].main)"

                let alertSheet = UIAlertController(title: "\(destination)", message: "距離 = \(distance), 時間 = \(time), 天氣 = \(weather) ", preferredStyle: .actionSheet)

                let removeOption = UIAlertAction(title: NSLocalizedString("移除", comment: "no comment"), style: .destructive) { _ in
                    map.removeWaypoint(waypoint)
                    map.removeOverlays(map.overlays)
                }

                let routeName = UIAlertAction(title: "導航至該地點", style: .default) { _ in

                    self.route.polyline.title = "guide"

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

            case editButtonTag:

                let alertController = UIAlertController(title: "請輸入座標說明", message: nil, preferredStyle: .alert)

                alertController.addTextField { textField in
                    textField.text = waypoint.title
                    textField.clearButtonMode = .always
                }
                let saveAction = UIAlertAction(title: NSLocalizedString("儲存", comment: "no comment"), style: .default) { _ in

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

    // MARK: - userPin -

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        var num = 0

        guard let gpxMapView = mapView as? GPXMapView else {
            return
        }

        // adds the pins with an animation
        for object in views {
            num += 1
            let annotationView = object as MKAnnotationView
            guide(gpxMapView, didSelect: annotationView)

            // The only exception is the user location, we add to this the heading icon.
            if annotationView.annotation!.isKind(of: MKUserLocation.self) {
                if gpxMapView.headingImageView == nil {
                    let image = UIImage(named: "heading")!

                    gpxMapView.headingImageView = UIImageView(image: image)

                    gpxMapView.headingImageView?.layer.cornerRadius = 20

                    gpxMapView.headingImageView?.layer.masksToBounds = true

                    gpxMapView.headingImageView?.loadImage(UserManager.shared.userInfo.pictureRef, placeHolder: image)

                    annotationView.insertSubview(gpxMapView.headingImageView!, at: 0)
                }
                continue
            }
            let point: MKMapPoint = .init(annotationView.annotation!.coordinate)

            if !mapView.visibleMapRect.contains(point) {
                continue
            }

            let endFrame: CGRect = annotationView.frame

            annotationView.frame = CGRect(x: annotationView.frame.origin.x, y: annotationView.frame.origin.y - mapView.superview!.frame.size.height,
                                          width: annotationView.frame.size.width, height: annotationView.frame.size.height)

            let interval: TimeInterval = 0.04

            UIView.animate(withDuration: 0.3, delay: interval, options: UIView.AnimationOptions.curveLinear, animations: { () in
                annotationView.frame = endFrame

            }, completion: { finished in
                if finished {
                    UIView.animate(withDuration: 0.05, animations: { () in

                        annotationView.transform = CGAffineTransform(a: 1.0, b: 0, c: 0, d: 0.8, tx: 0, ty: annotationView.frame.size.height * 0.1)

                    }, completion: { _ in
                        UIView.animate(withDuration: 0.1, animations: { () in
                            annotationView.transform = CGAffineTransform.identity
                        })

                    })
                }
            })
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
