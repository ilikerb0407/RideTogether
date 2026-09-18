//
//  MapPin.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//
//  This used to also contain the business logic for the info callout:
//  calling MKDirections, CLGeocoder, and WeatherManager.shared directly,
//  and caching their results in instance properties shared across every
//  pin on the map (a real bug — see WaypointInfoViewModel's header comment
//  for details). That logic now lives in WaypointInfoViewModel, injected
//  below. MapPin itself is now only responsible for what an
//  MKMapViewDelegate should be responsible for: rendering overlays,
//  building annotation views, presenting the resulting UI, and mutating
//  the map (add/remove overlay, waypoint).

import CoreGPX
import CoreLocation
import MapKit
import UIKit

class MapPin: NSObject, MKMapViewDelegate {
    // Injected with a default so existing call sites (`MapPin()`) don't
    // need to change, while tests can substitute a ViewModel wired with
    // fake DirectionsProviding / ReverseGeocoding / WeatherManaging.
    let viewModel: WaypointInfoViewModel

    var waypointBeingEdited: GPXWaypoint = .init()

    init(viewModel: WaypointInfoViewModel = WaypointInfoViewModel()) {
        self.viewModel = viewModel
        super.init()
    }

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

    func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        let annotationView = MKMarkerAnnotationView()

        annotationView.canShowCallout = true

        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.clipsToBounds = true
        rightButton.tintColor = .B5
        let rightImage = UIImage(systemName: "info.circle",
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light))
        rightButton.setImage(rightImage, for: .normal)

        rightButton.tag = informationButtonTag
        annotationView.rightCalloutAccessoryView = rightButton
        let leftButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
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
        guard let button = control as? UIButton else { return }

        guard let map = mapView as? GPXMapView else { return }

        guard let waypoint = view.annotation as? GPXWaypoint else { return }

        switch button.tag {
        case informationButtonTag:
            // Computed fresh for this specific waypoint every time — no
            // shared mutable state between pins (see WaypointInfoViewModel).
            viewModel.loadInfo(for: waypoint) { [weak self] result in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    switch result {
                    case let .success(data):
                        self.presentInfoActionSheet(for: data, waypoint: waypoint, map: map)
                    case .failure:
                        LKProgressHUD.showFailure(text: "無法導航")
                    }
                }
            }

        case editButtonTag:
            presentEditAlert(for: waypoint)

        default:
            LKProgressHUD.showFailure(text: "網路問題，無法顯示")
        }
    }

    private func presentInfoActionSheet(for data: WaypointInfoDisplayData, waypoint: GPXWaypoint, map: GPXMapView) {
        let alertSheet = UIAlertController(
            title: data.destinationName,
            message: "距離 = \(data.distanceText), 時間 = \(data.travelTimeText), 天氣 = \(data.weatherDescription) ",
            preferredStyle: .actionSheet
        )

        let removeOption = UIAlertAction(title: NSLocalizedString("移除", comment: "no comment"), style: .destructive) { _ in
            map.removeWaypoint(waypoint)
            // Was `map.removeOverlays(map.overlays)`, which also wiped
            // the user's in-progress recorded route (it briefly
            // disappeared until the next location update rebuilt it).
            // Only remove the guide/navigation overlay, keep the track.
            map.removeNavigationOverlays()
        }

        let routeName = UIAlertAction(title: "導航至該地點", style: .default) { _ in
            data.route.polyline.title = "guide"
            map.addOverlay(data.route.polyline, level: MKOverlayLevel.aboveRoads)
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: "no comment"), style: .cancel) { _ in }

        alertSheet.addAction(routeName)
        alertSheet.addAction(removeOption)
        alertSheet.addAction(cancelAction)

        let lastVC = UIViewController.getLastPresentedViewController()
        lastVC?.present(alertSheet, animated: true)

        // iPad specific code

        alertSheet.popoverPresentationController?.sourceView = lastVC?.view

        let xOrigin = (lastVC?.view.bounds.width ?? 0) / 2

        let popoverRect = CGRect(x: xOrigin, y: 0, width: 1, height: 1)

        alertSheet.popoverPresentationController?.sourceRect = popoverRect

        alertSheet.popoverPresentationController?.permittedArrowDirections = .unknown
    }

    private func presentEditAlert(for waypoint: GPXWaypoint) {
        let alertController = UIAlertController(title: "請輸入座標說明", message: nil, preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.text = waypoint.title
            textField.clearButtonMode = .always
        }
        let saveAction = UIAlertAction(title: NSLocalizedString("儲存", comment: "no comment"), style: .default) { [weak self] _ in
            self?.waypointBeingEdited.title = alertController.textFields?[0].text
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: "no comment"), style: .cancel) { _ in }

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        let VC = UIViewController.getLastPresentedViewController()
        VC?.present(alertController, animated: true)

        waypointBeingEdited = waypoint
    }

    // MARK: - userPin -

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        guard let gpxMapView = mapView as? GPXMapView else { return }

        // adds the pins with an animation
        for object in views {
            let annotationView = object as MKAnnotationView

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
            let point = MKMapPoint(annotationView.annotation!.coordinate)

            if !mapView.visibleMapRect.contains(point) { continue }

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
