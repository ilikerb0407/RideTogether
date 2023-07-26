//
//  RideViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/15.
//

import UIKit
import MapKit
import CoreGPX
import CoreLocation
import Firebase
import Lottie
import MessageUI
import SwiftUI
import JGProgressHUD

class RideViewController: BaseViewController {
    
    var record = Record()
    
    let userName = UserManager.shared.userInfo.userName!
    
    private var isDisplayingLocationServicesDenied: Bool = false
    
    @IBOutlet weak var mapView: GPXMapView!
    
    func backButton() {
        
        let button = PreviousPageButton(frame: CGRect(x: 20, y: 200, width: 40, height: 40))
        button.addTarget(self, action: #selector(popToPreviosPage), for: .touchUpInside)
        view.addSubview(button)
        
    }
    
    @objc func popToPreviosPage(_ sender: UIButton) {
        let count = self.navigationController!.viewControllers.count
        if let preController = self.navigationController?.viewControllers[count-1] {
            self.navigationController?.popToViewController(preController, animated: true)
        }
        navigationController?.popViewController(animated: true)
        
    }
    
    func praseGPXFile() {
        
//       if let inputUrl = URL(string: inputUrlString)
        if let inputUrl = URL(string: record.recordRef) {
            
            print("FollowDetail=======:\(inputUrl)======")
            
            guard let gpx = GPXParser(withURL: inputUrl)?.parsedData() else { return
            }
            
            didLoadGPXFile(gpxRoot: gpx)
            
        }
    }
    
    func didLoadGPXFile(gpxRoot: GPXRoot) {
        
        mapView.importFromGPXRoot(gpxRoot)
        
        mapView.regionToGPXExtent()
        
    }
    
    // MARK: - Polyline -
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
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
                
                mapView.setCenter((mapView.userLocation.coordinate), animated: true)
                
            } else {
                
                let image = UIImage(systemName: "location",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
                
                followUserButton.setImage(image, for: .normal)
            }
        }
    }
    
    private lazy var sendSMSButton: UIButton = {
        let button = BottomButton()
        let image = UIImage(systemName: "message",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        
        return button
    }()
        
    private lazy var followUserButton: UIButton = {
        let button = BottomButton()
        let image = UIImage(systemName: "location.fill",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        return button
    }()

    private lazy var showBikeButton: UIButton = {
        let button = UBikeButton()
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
    
    @objc func followButtonToggle() {
        
        self.followUser = !self.followUser
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = .green
            return lineView
            
        }
        return MKOverlayRenderer()
    }
    
    @objc func stopFollowingUser(_ gesture: UIPanGestureRecognizer) {
        
        if self.followUser {
            
            self.followUser = false
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
            
            buttonStackView.heightAnchor.constraint(equalToConstant: 80)
            ] )
        
        buttonStackView.addArrangedSubview(followUserButton)
        
        buttonStackView.addArrangedSubview(sendSMSButton)
        
        buttonStackView.addArrangedSubview(showBikeButton)
        
        // MARK: button constraint
        
        NSLayoutConstraint.activate([
            
            followUserButton.heightAnchor.constraint(equalToConstant: 50),
            
            followUserButton.widthAnchor.constraint(equalToConstant: 50),
            
            sendSMSButton.widthAnchor.constraint(equalToConstant: 50),
            
            sendSMSButton.heightAnchor.constraint(equalToConstant: 50)
                
        ])
        
        followUserButton.addTarget(self, action: #selector(followButtonToggle), for: .touchUpInside)
        
        sendSMSButton.addTarget(self, action: #selector(sendSMS), for: .touchUpInside)
        
    }
    
    @objc func sendSMS() {
        
        LKProgressHUD.show()
        
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self

        // Configure the fields of the interface.
        composeVC.recipients = ["請輸入電話號碼"]
        
        let lng = locationManager.location?.coordinate.longitude
        let lat = locationManager.location?.coordinate.latitude
        composeVC.body = "傳送我的位置 經度 : \(lng ?? 25.04), 緯度: \( lat ?? 121.56)"
    if !MFMessageComposeViewController.canSendText() {
        print("SMS services are not available")
        LKProgressHUD.showFailure(text: "請開啟定位")
    } else {
        LKProgressHUD.dismiss()
        self.present(composeVC, animated: true, completion: nil)
    }
    }

func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    let newLocation = locations.first!
    
    // MARK: Update_speed
    
    if followUser {
        
        mapView.setCenter(newLocation.coordinate, animated: true)
    }
    
}
    
}

// MARK: - CLLocationManager Delegate -

extension RideViewController: CLLocationManagerDelegate {
  
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.heading = newHeading // updates heading variable
        mapView.updateHeading() // updates heading view's rotation
    }
}
