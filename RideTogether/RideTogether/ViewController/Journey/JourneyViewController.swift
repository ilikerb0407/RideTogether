//
//  JourneyViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import UIKit
import MapKit
import CoreGPX
import CoreLocation
import Firebase
import Lottie
import MessageUI
import JGProgressHUD
 //

class JourneyViewController: BaseViewController {
    
    @IBOutlet weak var mapView: GPXMapView!
    
    private var hasWaypoints: Bool = false
    
    private let locationManager: CLLocationManager = {
        
        let manager = CLLocationManager()
        
        manager.requestAlwaysAuthorization()
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        manager.distanceFilter = 2 // meters
        
        manager.pausesLocationUpdatesAutomatically = false
        
        manager.allowsBackgroundLocationUpdates = false
        
        return manager
    }()
    
    private let mapPin = MapPin()
    
    enum GPXTrackingStatus {
        
        case notStarted
        
        case tracking
        
        case paused
        
    }
    
    private var trackingStatus: GPXTrackingStatus = GPXTrackingStatus.notStarted {
        
        didSet {
            
            switch trackingStatus {
                
            case .notStarted:
                
                trackerButton.setTitle("開始", for: .normal)
                
                stopWatch.reset()
                
                waveLottieView.isHidden = true
                
                bikeLottieView.isHidden = false
                
                timeLabel.text = stopWatch.elapsedTimeString
                
                mapView.clearMap()
                
                totalTrackedDistanceLabel.distance = (mapView.session.totalTrackedDistance)
                
                currentSegmentDistanceLabel.distance = (mapView.session.currentSegmentDistance)
                
            case .tracking:
                
                trackerButton.setTitle("暫停", for: .normal)
                
                self.stopWatch.start()
                
                waveLottieView.isHidden = false
                
                waveLottieView.play()
                
                bikeLottieView.play()
                
            case .paused:
                
                self.trackerButton.setTitle("繼續", for: .normal)
                
                self.stopWatch.stop()
                
                waveLottieView.isHidden = true
                
                bikeLottieView.stop()
                
                self.mapView.startNewTrackSegment()
            }
        }
    }
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
    
    // MARK: - UIButton Setting -
    //
    
    private lazy var saveButton: UIButton = {
        let button = LeftButton()
        button.setTitle("儲存", for: .normal)
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var trackerButton: UIButton = {
        let button = TrackButton()
        button.setTitle("開始", for: .normal)
        button.addTarget(self, action: #selector(trackerButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = LeftButton()
        button.setTitle("重置", for: .normal)
        button.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var followUserButton: UIButton = {
        let button = BottomButton()
        let image = UIImage(systemName: "location.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(followButtonToggle), for: .touchUpInside)
        return button
    }()
    
    private lazy var showBike: UIButton = {
        let button = UBikeButton()
        button.addTarget(self, action: #selector(showBikeViewController), for: .touchUpInside)
        return button
    }()
    
    private lazy var presentViewControllerButton: UIButton = {
        let button = BottomButton()
        let image = UIImage(systemName: "info.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(presentRouteSelectionViewController), for: .touchUpInside)
        return button
    }()
    
    private lazy var sendSMSButton: UIButton = {
        let button = BottomButton()
        let image = UIImage(systemName: "message", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(sendSMS), for: .touchUpInside)
        return button
    }()
    
    private lazy var pinButton: UIButton = {
        let button = BottomButton()
        let mappin = UIImage(systemName: "mappin.and.ellipse",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium ))
        button.setImage(mappin, for: UIControl.State())
        button.addTarget(self, action: #selector(addPinAtMyLocation), for: .touchUpInside)
        return button
    }()
    
    @objc func addPinAtMyLocation() {
        let altitude = locationManager.location?.altitude
        let waypoint = GPXWaypoint(coordinate: locationManager.location?.coordinate ?? mapView.userLocation.coordinate, altitude: altitude)
        mapView.addWaypoint(waypoint)
        self.hasWaypoints = true
        
    }
    
    @objc func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            mapView.clearOverlays()
            let point: CGPoint = gesture.location(in: self.mapView)
            mapView.addWaypointAtViewPoint(point)
            self.hasWaypoints = true
        }
    }
    
    // MARK: - View -
    
    private lazy var waveLottieView: AnimationView = {
        let view = AnimationView(name: "circle")
        view.loopMode = .loop
        view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.center = leftStackView.center
        view.contentMode = .scaleAspectFit
        view.play()
        
        self.view.addSubview(view)
        self.view.bringSubviewToFront(leftStackView)
        return view
    }()
    
    private lazy var bikeLottieView: AnimationView = {
        let view = AnimationView(name: "49908-bike-ride")
        view.loopMode = .loop
        self.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 60),
            view.heightAnchor.constraint(equalToConstant: 60),
            view.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -40),
            view.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -45)
        ])
        view.contentMode = .scaleAspectFit
        view.play()
        
        return view
    }()
    
    private lazy var buttonStackView: UIStackView = {
        
        let view = UIStackView(arrangedSubviews: [followUserButton, pinButton, sendSMSButton, presentViewControllerButton, showBike])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .equalSpacing
        view.alignment = .bottom
        return view
    }()
    
    private lazy var leftStackView: UIStackView = {
        
        let view = UIStackView(arrangedSubviews: [saveButton, trackerButton, resetButton])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 8
        view.distribution = .equalSpacing
        view.alignment = .center
        return view
    }()
    
    // MARK: - Label -
    
    private var altitudeLabel = LeftLabel()
       
    private var speedLabel = LeftLabel()
    
    private var timeLabel = RightLabel()
       
    private var totalTrackedDistanceLabel = DistanceLabel()
    
    private lazy var currentSegmentDistanceLabel = DistanceLabel()
   
    // MARK: - View Life Cycle -
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        LKProgressHUD.dismiss()
        
        setUpLocationManager()
        
        stopWatch.delegate = self
        
//        RecordManager.shared.detectDeviceAndUpload()
        
        setUpMap()
        
        setUpLabels()
        
        setUpButtonsStackView()
        
        addSegment()
        
        mapPin.route.polyline.title = "two"
        
        navigationController?.isNavigationBarHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if trackingStatus == .tracking {
            bikeLottieView.play()
            waveLottieView.play()
        }
    }
    
    func setUpLocationManager() {
        
        locationManager.delegate = self
        
        locationManager.startUpdatingLocation()
        
        locationManager.startUpdatingHeading()
    }
    
    func addSegment() {
        let segmentControl = UISegmentedControl(items: ["一般", "衛星"])
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.B2], for: .normal)
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.B5], for: .selected)
        segmentControl.backgroundColor = UIColor.B5
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(onChange), for: .valueChanged)
        segmentControl.frame.size = CGSize(width: 150, height: 30)
        segmentControl.center = CGPoint(x: 80, y: 65)
        self.view.addSubview(segmentControl)
    }
    
    @objc func onChange(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0 :
            mapView.mapType = .mutedStandard
            speedLabel.textColor = .B5
            timeLabel.textColor = .B5
            altitudeLabel.textColor = .B5
            currentSegmentDistanceLabel.textColor = .B5
            totalTrackedDistanceLabel.textColor = .B5
        case 1 :
            mapView.mapType = .hybridFlyover
            speedLabel.textColor = .B2
            timeLabel.textColor = .B2
            altitudeLabel.textColor = .B2
            currentSegmentDistanceLabel.textColor = .B2
            totalTrackedDistanceLabel.textColor = .B2
        default :
            mapView.mapType = .standard
        }
        
    }
    
    // MARK: - Action -
    
    fileprivate func setBeginningRegion() {
        //
        let center = locationManager.location?.coordinate ??
        CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    func setUpMap() {
        
        setBeginningRegion()
        
        mapView.delegate = mapPin
        
        mapView.showsUserLocation = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(stopFollowingUser(_:)))
        
        panGesture.delegate = self
        
        mapView.addGestureRecognizer(panGesture)
        
        mapView.rotationGesture.delegate = self
        
        mapView.addGestureRecognizer(UILongPressGestureRecognizer( target: self,
                                                               action: #selector(addPinAtTappedLocation(_:))))
    }
    
    @objc func sendSMS() {
        
        LKProgressHUD.show()
        
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        
        composeVC.recipients = ["請輸入電話號碼"]
        composeVC.body = "傳送我的位置 經度 : \(locationManager.location!.coordinate.longitude), 緯度: \(locationManager.location!.coordinate.latitude)"
        
        if MFMessageComposeViewController.canSendText() {
            self.present(composeVC, animated: true, completion: nil)
            LKProgressHUD.dismiss()
        }
    }
    
    @objc func trackerButtonTapped() {
        
        switch trackingStatus {
            
        case .notStarted:
            
            UIView.animate(withDuration: 0.2) {
                self.trackerButton.alpha = 1.0
                self.saveButton.alpha = 1.0
                self.resetButton.alpha = 1.0
            }
            
            trackingStatus = .tracking
            
        case .tracking:
            
            trackingStatus = .paused
            
        case .paused:
            
            trackingStatus = .tracking
        }
    }
    
    @objc func saveButtonTapped(withReset: Bool = false) {
        
        if trackingStatus == .notStarted && !self.hasWaypoints { return }
        
        let date = Date()
        
        let time = TimeFormater.preciseTimeForFilename.dateToString(time: date)
        
        let defaultFileName = "從..到.."
        
        let alertController = UIAlertController(title: "儲存路線",
                                                message: "路線標題",
                                                preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: { (textField) in
            
            textField.clearButtonMode = .always
            
            textField.text =  defaultFileName
        })
        
        let saveAction = UIAlertAction(title: "儲存",
                                       style: .default) { _ in
            
            let gpxString = self.mapView.exportToGPXString()
            
            let fileName = alertController.textFields?[0].text
            
            if let fileName = fileName {
                
                GPXFileManager.save( fileName, gpxContents: gpxString)
                
            }
            
            if withReset {
                self.trackingStatus = .notStarted
            }
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alertController.addAction(saveAction)
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @objc func resetButtonTapped() {
        
        if trackingStatus == .notStarted { return }
        
        let cancelOption = UIAlertAction(title: "取消", style: .cancel)
        
        let resetOption = UIAlertAction(title: "重置", style: .destructive) { _ in
            self.trackingStatus = .notStarted
            
            UIView.animate(withDuration: 0.3) {
                self.saveButton.alpha = 0.5
                self.resetButton.alpha = 0.5
            }
        }
        
        showAlertAction(title: nil, message: nil, preferredStyle: .actionSheet, actions: [cancelOption, resetOption])
        
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
            if #available(iOS 14.0, *) {
                if !([.authorizedAlways, .authorizedWhenInUse]
                    .contains(locationManager.authorizationStatus)) {
                    
                    displayLocationServicesDeniedAlert()
                    
                    return
                }
            } else {
                // Fallback on earlier versions
            }
            displayLocationServicesDeniedAlert()
            
            return
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        updatePolylineColor()
    }
    
    // MARK: - Polyline -
    
    func updatePolylineColor() {
        
        for overlay in mapView.overlays where overlay is MKPolyline {
            
            mapView.removeOverlay(overlay)
            
            mapView.addOverlay(overlay)
        }
    }
    // MARK: - UI Settings -
    
    func setUpButtonsStackView() {
        
        view.addSubview(buttonStackView)
        view.addSubview(leftStackView)
        
        NSLayoutConstraint.activate([
            
            buttonStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 150),
            
            buttonStackView.widthAnchor.constraint(equalToConstant: 280),
            
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            
            buttonStackView.heightAnchor.constraint(equalToConstant: 80),
            
            leftStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            
            leftStackView.widthAnchor.constraint(equalToConstant: 100),
            
            leftStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -200),
            
            leftStackView.heightAnchor.constraint(equalToConstant: 200)
        ] )
        
        buttonStackView.addArrangedSubview(followUserButton)
        
        buttonStackView.addArrangedSubview(pinButton)
        
        buttonStackView.addArrangedSubview(sendSMSButton)
        
        buttonStackView.addArrangedSubview(presentViewControllerButton)
        
        buttonStackView.addArrangedSubview(showBike)
        
        leftStackView.addArrangedSubview(saveButton)
        
        leftStackView.addArrangedSubview(trackerButton)
        
        leftStackView.addArrangedSubview(resetButton)
    }
    func setUpLabels() {
        
        mapView.addSubview(altitudeLabel)
        
        altitudeLabel.frame = CGRect(x: 10, y: 80, width: 200, height: 100)
        
        mapView.addSubview(speedLabel)
        
        speedLabel.frame = CGRect(x: 10, y: 50, width: 200, height: 100)
        
        mapView.addSubview(timeLabel)
        
        timeLabel.frame = CGRect(x: UIScreen.width - 110, y: 30, width: 100, height: 80)
        
        mapView.addSubview(totalTrackedDistanceLabel)
        
        totalTrackedDistanceLabel.frame = CGRect(x: UIScreen.width - 110, y: 90, width: 100, height: 30)
        
        mapView.addSubview(currentSegmentDistanceLabel)
        
        currentSegmentDistanceLabel.frame = CGRect(x: UIScreen.width - 110, y: 120, width: 100, height: 30)
    }
    
}
// MARK: - StopWatchDelegate methods
extension JourneyViewController: StopWatchDelegate {
    func stopWatch(_ stropWatch: StopWatch, didUpdateElapsedTimeString elapsedTimeString: String) {
        
        timeLabel.text = "\(elapsedTimeString)"
    }
}
// MARK: - CLLocationManager Delegate -

extension JourneyViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let newLocation = locations.first!
        
        let altitude = newLocation.altitude.toAltitude()
        
        let text = "高度 : \(altitude)"
        
        altitudeLabel.text = text
        
        let rUnknownSpeedText = "0.00"
        
        speedLabel.text = "時速 : \((newLocation.speed < 0) ? rUnknownSpeedText : newLocation.speed.toSpeed())"
        
        if followUser {
            
            mapView.setCenter(newLocation.coordinate, animated: true)
        }
        
        if trackingStatus == .tracking {
            
            mapView.addPointToCurrentTrackSegmentAtLocation(newLocation)
            
            totalTrackedDistanceLabel.distance = mapView.session.totalTrackedDistance
            
            currentSegmentDistanceLabel.distance = mapView.session.currentSegmentDistance
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        mapView.heading = newHeading
        mapView.updateHeading()
    }
}
