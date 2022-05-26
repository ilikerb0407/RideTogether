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

class RideViewController: BaseViewController, bikeProvider {
    
    func provideBike(bike: Bike) {
        bikeData = [bike]
    }
    var bikeData : [Bike] = []
    
    var bikeManager = BikeManager()
    
    var record = Record()
    
    let userName = UserManager.shared.userInfo.userName!

    //    let userId = { UserManager.shared.userInfo }
    
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
                // MARK: 定位的符號
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
    
    var hasWaypoints: Bool = false

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
    
    // MARK: - View Life Cycle
    
//    func GetDistance(latitude: Double, longitude: Double) -> Double {
//        let selectedCoordinate = CLLocation(latitude: latitude, longitude: longitude)
//        let busStopCoordinate = CLLocation(latitude: Double(self.latitude), longitude: self.longitude)
//
//        return busStopCoordinate.distance(from: selectedCoordinate)
//    }
    
//
    func layOutBike() {
        
        for bike in bikeData {
            
            let coordinate = CLLocationCoordinate2D(latitude: bike.lat, longitude: bike.lng)
            
            let title = bike.sna
            
            let subtitle = "可還車位置 :\(bike.bemp), 可租車數量 :\(bike.sbi)"

            let annotation = BikeAnnotation(title: title, subtitle: subtitle, coordinate: coordinate)

            let usersCoordinate = CLLocation(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude)
            let bikeStopCoordinate = CLLocation(latitude: Double(bike.lat), longitude: Double(bike.lng))

            let distance = usersCoordinate.distance(from: bikeStopCoordinate)
       
                    if  distance < 1000 {
                        mapView.addAnnotation(annotation)
                    }
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar(title: "查看路線")
        
        locationManager.delegate = self
        
        setUpMap()
        
        setUpButtonsStackView()
        
        LKProgressHUD.dismiss()
        
//        backButton()

//        navigationController?.isNavigationBarHidden = true
        
        self.locationManager.requestAlwaysAuthorization()
        
        bikeManager.delegate = self
        
        bikeManager.getBikeAPI { [ weak self ] result in
            
        self?.bikeData = result
            
        self?.layOutBike()
            
        }
        
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
        
        composeVC.body = "傳送我的位置 經度 :\(locationManager.location!.coordinate.longitude), 緯度: \(locationManager.location!.coordinate.latitude)"
        
        // Present the view controller modally.
        if MFMessageComposeViewController.canSendText() {
            self.present(composeVC, animated: true, completion: nil)
            LKProgressHUD.dismiss()
        }
    }
    

func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    let newLocation = locations.first!
    
   
    
    
    //  MARK: Update_speed
    
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
