//
//  RideViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/15.
//

import CoreGPX
import CoreLocation
import Firebase
import JGProgressHUD
import MapKit
import MessageUI
import SwiftUI
import UIKit

class RideViewController: BaseViewController {
    var record = Record()

    let userName = UserManager.shared.userInfo.userName!

    private var isDisplayingLocationServicesDenied: Bool = false

    @IBOutlet var mapView: GPXMapView!

    func backButton() {
        let button = ButtonFactory.build(backgroundColor: .B5 ?? .white,
                                             tintColor: .B2 ?? .white,
                                             cornerRadius: 20,
                                             imageName: "chevron.left",
                                             weight: .light, pointSize: 40,
                                             xPoint: 20,
                                             yPoint: 200)
        button.addTarget(self, action: #selector(popToPreviosPage), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc
    func popToPreviosPage(_: UIButton) {
        let count = self.navigationController!.viewControllers.count
        if let preController = self.navigationController?.viewControllers[count - 1] {
            self.navigationController?.popToViewController(preController, animated: true)
        }
        navigationController?.popViewController(animated: true)
    }

    func praseGPXFile() {
//       if let inputUrl = URL(string: inputUrlString)
        if let inputUrl = URL(string: record.recordRef) {
            print("FollowDetail=======:\(inputUrl)======")

            guard let gpx = GPXParser(withURL: inputUrl)?.parsedData() else {
                return
            }

            didLoadGPXFile(gpxRoot: gpx)
        }
    }

    func didLoadGPXFile(gpxRoot: GPXRoot) {
        mapView.importFromGPXRoot(gpxRoot)

        mapView.regionToGPXExtent()
    }

    // MARK: - Polyline -

    override func traitCollectionDidChange(_: UITraitCollection?) {
        updatePolylineColor()
    }

    func updatePolylineColor() {
        for overlay in mapView.overlays where overlay is MKPolyline {
            mapView.removeOverlay(overlay)

            mapView.addOverlay(overlay)
        }
    }

    // MARK: =========

    private var lastLocation: CLLocation?

    private let locationManager: CLLocationManager = {
        let manager = CLLocationManager()

        manager.requestAlwaysAuthorization()

        manager.desiredAccuracy = kCLLocationAccuracyBest

        manager.distanceFilter = 2 // meters

        manager.pausesLocationUpdatesAutomatically = false

        manager.allowsBackgroundLocationUpdates = true

        return manager
    }()

    private let bikeViewDelegate = BikeView()

    private var followUser: Bool = true {
        didSet {
            if followUser {
                let image = UIImage(systemName: "location.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))

                followUserButton.setImage(image, for: .normal)

                mapView.setCenter(mapView.userLocation.coordinate, animated: true)

            } else {
                let image = UIImage(systemName: "location",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))

                followUserButton.setImage(image, for: .normal)
            }
        }
    }

    private lazy var sendSMSButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor:
                .B2?.withAlphaComponent(0.75),
                                         tintColor: .B5,
                                         cornerRadius: 24,
                                         imageName: "message",
                                         weight: .medium,
                                         pointSize: 30)
        return button
    }()

    private lazy var followUserButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B2?.withAlphaComponent(0.75),
                                         tintColor: .B5,
                                         cornerRadius: 24,
                                         imageName: "location.fill",
                                         weight: .medium,
                                         pointSize: 30)
        return button
    }()

    private lazy var showBikeButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B2?.withAlphaComponent(0.75),
                                         cornerRadius: 12,
                                         imageName: "ubike2.0",
                                         weight: .medium,
                                         pointSize: 10)
        button.addTarget(self, action: #selector(showBikeViewController), for: .touchUpInside)
        return button
    }()

    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [followUserButton, sendSMSButton, showBikeButton])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .equalSpacing
        view.alignment = .bottom
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setNavigationBar(title: "查看路線")

        locationManager.delegate = self

        setUpMap()

        setUpButtonsStackView()

        LKProgressHUD.dismiss()

        self.locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Action

    func setUpMap() {
        mapView.delegate = bikeViewDelegate

        mapView.rotationGesture.delegate = self

        self.view.addSubview(mapView)

        praseGPXFile()
    }

    @objc
    func followButtonToggle() {
        self.followUser = !self.followUser
    }

    func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = .green
            return lineView
        }
        return MKOverlayRenderer()
    }

    @objc
    func stopFollowingUser(_: UIPanGestureRecognizer) {
        if self.followUser {
            self.followUser = false
        }
    }

    func gestureRecognizer(_: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        true
    }

    func checkLocationServicesStatus() {
        if !CLLocationManager.locationServicesEnabled() {
            displayLocationServicesDisabledAlert()

            return
        }

        if #available(iOS 14.0, *) {
            if !([.authorizedAlways, .authorizedWhenInUse]
                .contains(locationManager.authorizationStatus)) {
                displayLocationServicesDeniedAlert()

                return
            }
        } else {
            // Fallback on earlier versions
        }
    }

    // MARK: - UI Settings -

    func setUpButtonsStackView() {
        view.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            buttonStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 120),

            buttonStackView.widthAnchor.constraint(equalToConstant: 200),

            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),

            buttonStackView.heightAnchor.constraint(equalToConstant: 80),
        ])

        buttonStackView.addArrangedSubview(followUserButton)

        buttonStackView.addArrangedSubview(sendSMSButton)

        buttonStackView.addArrangedSubview(showBikeButton)

        // MARK: button constraint

        NSLayoutConstraint.activate([
            followUserButton.heightAnchor.constraint(equalToConstant: 50),

            followUserButton.widthAnchor.constraint(equalToConstant: 50),

            sendSMSButton.widthAnchor.constraint(equalToConstant: 50),

            sendSMSButton.heightAnchor.constraint(equalToConstant: 50),

        ])

        followUserButton.addTarget(self, action: #selector(followButtonToggle), for: .touchUpInside)

        sendSMSButton.addTarget(self, action: #selector(sendSMS), for: .touchUpInside)
    }

    @objc
    func sendSMS() {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self

        // Configure the fields of the interface.
        composeVC.recipients = ["請輸入電話號碼"]

        let lng = locationManager.location?.coordinate.longitude
        let lat = locationManager.location?.coordinate.latitude
        composeVC.body = "傳送我的位置 經度 : \(lng ?? 25.04), 緯度: \(lat ?? 121.56)"
        if !MFMessageComposeViewController.canSendText() {
            print("SMS services are not available")
            LKProgressHUD.show(.failure("請開啟定位"))
        } else {
            LKProgressHUD.dismiss()
            self.present(composeVC, animated: true, completion: nil)
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.first!

        // MARK: Update_speed

        if followUser {
            mapView.setCenter(newLocation.coordinate, animated: true)
        }
    }
}

// MARK: - CLLocationManager Delegate -

extension RideViewController: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.heading = newHeading // updates heading variable
        mapView.updateHeading() // updates heading view's rotation
    }
}
