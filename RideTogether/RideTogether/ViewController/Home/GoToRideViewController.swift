//
//  GoToRideViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/24.
//

import UIKit
import MapKit
import CoreGPX
import CoreLocation
import Firebase
import Lottie
import MessageUI

class GoToRideViewController: BaseViewController, CLLocationManagerDelegate {
    
    var userName = UserManager.shared.userInfo.userName!
    
    //    var userName = Auth.auth().currentUser?.displayName
    
    @IBOutlet weak var map3: GPXMapView!
    
    var routes = Route()
    
    private var isDisplayingLocationServicesDenied: Bool = false
    
    var lastGPXFilename: String = ""
    
    func parseGPXFile() {

            if let inputUrl = URL(string: self.routes.routeMap) {
                print("FollowDetail=======:\(inputUrl)======")
                
                DispatchQueue.global().async {
                    guard let gpx = GPXParser(withURL: inputUrl)?.parsedData() else { return
                    }
                    DispatchQueue.main.async {
                        self.didLoadGPXFile(gpxRoot: gpx)
    //                time3:675762963.180959
                    }
                }
               
                print("time3:\(CFAbsoluteTimeGetCurrent())")
//                675762887.290653 no main
        }
    }
    
    func didLoadGPXFile(gpxRoot: GPXRoot) {
        
        map3.importFromGPXRoot(gpxRoot)
        
        map3.regionToGPXExtent()
    }
    
    // MARK: - Polyline -
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        updatePolylineColor()
    }
    
    func updatePolylineColor() {
        
        for overlay in map3.overlays where overlay is MKPolyline {
            
            map3.removeOverlay(overlay)
            
            map3.addOverlay(overlay)
        }
    }
    
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
    
    private let mapViewDelegate = MapPin()
    
    private var followUser: Bool = true {
        
        didSet {
            
            if followUser {
                // MARK: 定位的符號
                let image = UIImage(systemName: "location.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
                
                followUserButton.setImage(image, for: .normal)
                
                map3.setCenter((map3.userLocation.coordinate), animated: true)
                
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
    
    private lazy var buttonStackView: UIStackView = {
        
        let view = UIStackView(arrangedSubviews: [followUserButton, sendSMSButton, showBikeButton])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .equalSpacing
        view.alignment = .bottom
        return view
    }()
    
    private lazy var showBikeButton: UIButton = {
        let button = UBikeButton()
        button.addTarget(self, action: #selector(showBikeViewController), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        setUpMap()
        
        setUpButtonsStackView()
        
        setNavigationBar(title: "探索路線")
        
        navigationController?.isNavigationBarHidden = false
//        self.parseGPXFile()
//        LKProgressHUD.show()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LKProgressHUD.dismiss()
    }
    
    // MARK: - Action
    
    let group: DispatchGroup = DispatchGroup()
    func setUpMap() {
        
        DispatchQueue.main.async {
            self.parseGPXFile()
            LKProgressHUD.showSuccess(text: "下載成功")
        }
           
        map3.delegate = mapViewDelegate
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(stopFollowingUser(_:)))
        
        panGesture.delegate = self
        
        map3.addGestureRecognizer(panGesture)
        
        map3.rotationGesture.delegate = self
        
        self.view.addSubview(map3)
        
        print("time2:\(CFAbsoluteTimeGetCurrent())")
        
    }
    
    @objc func followButtonToggle() {
        
        self.followUser = !self.followUser
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
        
        self.present(composeVC, animated: true, completion: nil)
        if !MFMessageComposeViewController.canSendText() {
            print("SMS services are not available")
            LKProgressHUD.showFailure(text: "請開啟定位")
        } else {
            self.present(composeVC, animated: true, completion: nil)
            LKProgressHUD.dismiss()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let newLocation = locations.first!
        
        if followUser {
            
            map3.setCenter(newLocation.coordinate, animated: true)
        }
    }
    
}
