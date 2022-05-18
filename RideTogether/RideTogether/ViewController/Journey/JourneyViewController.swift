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
import SwiftUI
import JGProgressHUD

class JourneyViewController: BaseViewController {
    
    @IBOutlet weak var map: GPXMapView!
    
    private var isDisplayingLocationServicesDenied: Bool = false
    
    private var lastGPXFilename: String = ""
    
    private let locationManager: CLLocationManager = {
        
        let manager = CLLocationManager()
        
        manager.requestAlwaysAuthorization()
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        manager.distanceFilter = 2 // meters
        
        manager.pausesLocationUpdatesAutomatically = false
        
        manager.allowsBackgroundLocationUpdates = true
        
        return manager
    }()
    
    private var stopWatch = StopWatch()
    
    private let mapViewDelegate = MapView()
    
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
                
                map.clearMap()
                
                totalTrackedDistanceLabel.distance = (map.session.totalTrackedDistance)
                
                currentSegmentDistanceLabel.distance = (map.session.currentSegmentDistance)
                
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
                
                self.map.startNewTrackSegment()
            }
        }
    }
    private var followUser: Bool = true {
        
        didSet {
            
            if followUser {
                
                let image = UIImage(systemName: "location.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
                
                followUserButton.setImage(image, for: .normal)
                
                map.setCenter((map.userLocation.coordinate), animated: true)
                
            } else {
                
                let image = UIImage(systemName: "location",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
                
                followUserButton.setImage(image, for: .normal)
            }
        }
    }
    
    private lazy var trackerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .B5
        button.tintColor = .B2
        button.setTitle("開始", for: .normal)
        button.titleLabel?.font = UIFont.regular(size: 18)
        button.titleLabel?.textAlignment = .center
        button.cornerRadius = 35
        NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 70),
        button.widthAnchor.constraint(equalToConstant: 70)])
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .B5
        button.tintColor = .B2
        button.setTitle("重置", for: .normal)
        button.titleLabel?.font = UIFont.regular(size: 16)
        button.titleLabel?.textAlignment = .center
        button.alpha = 0.5
        button.cornerRadius = 25
        NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 50),
        button.widthAnchor.constraint(equalToConstant: 50)])
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .B5
        button.tintColor = .B2
        button.setTitle("儲存", for: .normal)
        button.titleLabel?.font = UIFont.regular(size: 16)
        button.titleLabel?.textAlignment = .center
        button.alpha = 0.5
        button.cornerRadius = 25
        NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 50),
        button.widthAnchor.constraint(equalToConstant: 50)])
        return button
    }()
    
    private lazy var showBike: UIButton = {
        let button = UBikeButton()
        return button
    }()
    
    private lazy var presentViewControllerButton: UIButton = {
        let button = UIButton()
        button.tintColor = .B5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .B2?.withAlphaComponent(0.75)
        let image = UIImage(systemName: "info.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 24
        NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 50),
        button.widthAnchor.constraint(equalToConstant: 50)])
        return button
    }()
    
    private lazy var sendSMSButton: UIButton = {
        let button = UIButton()
        button.tintColor = .B5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .B2?.withAlphaComponent(0.75)
        let image = UIImage(systemName: "message", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 24
        NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 50),
        button.widthAnchor.constraint(equalToConstant: 50)])
        return button
    }()
    
    private lazy var followUserButton: UIButton = {
        
        let button = UIButton()
        button.tintColor = .B5
        button.backgroundColor = .B2?.withAlphaComponent(0.75)
        let image = UIImage(systemName: "location.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 24
        NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 50),
        button.widthAnchor.constraint(equalToConstant: 50)])
        return button
    }()
    
    private lazy var pinButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 24.0
        button.tintColor = .B5
        button.backgroundColor = .B2?.withAlphaComponent(0.75)
        let mappin = UIImage(systemName: "mappin.and.ellipse",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium ))
        let mappinHighlighted = UIImage(systemName: "mappin.and.ellipse",
                                        withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium ))
        button.setImage(mappin, for: UIControl.State())
        button.setImage(mappinHighlighted, for: .highlighted)
        button.addTarget(self, action: #selector(addPinAtMyLocation), for: .touchUpInside)
        NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 50),
        button.widthAnchor.constraint(equalToConstant: 50)])
        return button
    }()
    
    private var hasWaypoints: Bool = false
    
    @objc func addPinAtMyLocation() {
        print("Adding Pin at my location")
        let altitude = locationManager.location?.altitude
        let waypoint = GPXWaypoint(coordinate: locationManager.location?.coordinate ?? map.userLocation.coordinate, altitude: altitude)
        map.addWaypoint(waypoint)
        self.hasWaypoints = true
    }
    
    // MARK: 長按功能_ UILongPressGestureRecognizer
    
    @objc func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            print("Adding Pin map Long Press Gesture")
            map.clearOverlays()
            let point: CGPoint = gesture.location(in: self.map)
            map.addWaypointAtViewPoint(point)
            self.hasWaypoints = true
        }
    }
    
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
    
    // MARK: 之後再改字體
    
    private var altitudeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.textColor = UIColor.B5
        return label
    }()
    
    private var speedLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.textColor = UIColor.B5
        return label
    }()
    
    private var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textColor = UIColor.B5
        label.text = "00:00"
        return label
    }()
    
    private lazy var totalTrackedDistanceLabel: DistanceLabel = {
        let distanceLabel = DistanceLabel()
        distanceLabel.textAlignment = .right
        distanceLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        distanceLabel.textColor = UIColor.B5
        distanceLabel.distance = 0.00
        return distanceLabel
    }()
    
    private lazy var currentSegmentDistanceLabel: DistanceLabel = {
        let distanceLabel = DistanceLabel()
        distanceLabel.textAlignment = .right
        distanceLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        distanceLabel.textColor = UIColor.B5
        distanceLabel.distance = 0.00
        return distanceLabel
    }()
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        LKProgressHUD.dismiss()
        
        locationManager.delegate = self
        
        stopWatch.delegate = self
        
        RecordManager.shared.detectDeviceAndUpload()
        
        setUpMap()
        
        setUpButtonsStackView()
        
        setUpLabels()
        
        navigationController?.isNavigationBarHidden = true
        
        addSegment()
        
        mapViewDelegate.route.polyline.title = "two"
        
        
    }
    
    @objc func showBikeViewController() {
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "UBikeViewController") as? UBikeViewController {
            let navBar = UINavigationController.init(rootViewController: rootVC)
            if #available(iOS 15.0, *) {
                if let presentVc = navBar.sheetPresentationController {
                    presentVc.detents = [.medium(), .large()]
                    self.navigationController?.present(navBar, animated: true, completion: .none)
                }
            } else {
                LKProgressHUD.showFailure(text: "目前僅提供台北市Ubike")
            }}
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if trackingStatus == .tracking {
            bikeLottieView.play()
            waveLottieView.play()
        }
    }
    
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
            map.mapType = .mutedStandard
            speedLabel.textColor = .B5
            timeLabel.textColor = .B5
            altitudeLabel.textColor = .B5
            currentSegmentDistanceLabel.textColor = .B5
            totalTrackedDistanceLabel.textColor = .B5
        case 1 :
            map.mapType = .hybridFlyover
            speedLabel.textColor = .B2
            timeLabel.textColor = .B2
            altitudeLabel.textColor = .B2
            currentSegmentDistanceLabel.textColor = .B2
            totalTrackedDistanceLabel.textColor = .B2
        default :
            map.mapType = .standard
        }
        
    }
    
    // MARK: - Action -
    
    fileprivate func setBeginningRegion() {
        let center = locationManager.location?.coordinate ??
        CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: center, span: span)
        
        map.setRegion(region, animated: true)
    }
    
    func setUpMap() {
        
        setBeginningRegion()
        
        locationManager.delegate = self
        
        locationManager.startUpdatingLocation()
        
        locationManager.startUpdatingHeading()
        
        map.delegate = mapViewDelegate
        
        map.showsUserLocation = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(stopFollowingUser(_:)))
        
        panGesture.delegate = self
        
        map.addGestureRecognizer(panGesture)
        
        map.rotationGesture.delegate = self
        
        map.addGestureRecognizer(UILongPressGestureRecognizer( target: self,
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
    
    @objc func presentRouteSelectionViewController() {
        
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "RouteSelectionViewController") as? RouteSelectionViewController {
            let navBar = UINavigationController.init(rootViewController: rootVC)
            if #available(iOS 15.0, *) {
                if let presentVc = navBar.sheetPresentationController {
                    presentVc.detents = [ .medium(), .large()]
                    self.navigationController?.present(navBar, animated: true, completion: .none)
                }
            } else {
                LKProgressHUD.showFailure(text: "網路問題，無法跳出")
            }
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
            
            let gpxString = self.map.exportToGPXString()
            
            let fileName = alertController.textFields?[0].text

            self.lastGPXFilename = fileName!
            
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
    
    func displayLocationServicesDisabledAlert() {
        
        let settingsAction = UIAlertAction(title: "設定", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                
                UIApplication.shared.open(url, options: [:])
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        showAlertAction(title: "無法讀取位置", message: "請開啟定位服務", actions: [settingsAction, cancelAction])
        
    }
    
    func displayLocationServicesDeniedAlert() {
        
        if isDisplayingLocationServicesDenied { return }
        
        let settingsAction = UIAlertAction(title: "設定",
                                           style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:]) }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        showAlertAction(title: "無法讀取位置", message: "請開啟定位服務", actions: [settingsAction, cancelAction])
        
        isDisplayingLocationServicesDenied = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        updatePolylineColor()
    }
    
    // MARK: - Polyline -
    
    func updatePolylineColor() {
        
        for overlay in map.overlays where overlay is MKPolyline {
            
            map.removeOverlay(overlay)
            
            map.addOverlay(overlay)
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
        
        // MARK: - button method -
        
        trackerButton.addTarget(self, action: #selector(trackerButtonTapped), for: .touchUpInside)
        
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        
        followUserButton.addTarget(self, action: #selector(followButtonToggle), for: .touchUpInside)
        
        sendSMSButton.addTarget(self, action: #selector(sendSMS), for: .touchUpInside)
        
        presentViewControllerButton.addTarget(self, action: #selector(presentRouteSelectionViewController), for: .touchUpInside)
        
        showBike.addTarget(self, action: #selector(showBikeViewController), for: .touchUpInside)
    }
    func setUpLabels() {
        
        map.addSubview( altitudeLabel)
        
        altitudeLabel.frame = CGRect(x: 10, y: 80, width: 200, height: 100)
        
        map.addSubview(speedLabel)
        
        speedLabel.frame = CGRect(x: 10, y: 50, width: 200, height: 100)
        
        map.addSubview(timeLabel)
 
        timeLabel.frame = CGRect(x: UIScreen.width - 110, y: 30, width: 100, height: 80)
        
        map.addSubview(totalTrackedDistanceLabel)
       
        totalTrackedDistanceLabel.frame = CGRect(x: UIScreen.width - 110, y: 90, width: 100, height: 30)
        
        map.addSubview(currentSegmentDistanceLabel)
        
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
            
            map.setCenter(newLocation.coordinate, animated: true)
        }
        
        if trackingStatus == .tracking {
            
            map.addPointToCurrentTrackSegmentAtLocation(newLocation)
            
            totalTrackedDistanceLabel.distance = map.session.totalTrackedDistance
            
            currentSegmentDistanceLabel.distance = map.session.currentSegmentDistance
        }
    }
 
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        map.heading = newHeading
        map.updateHeading()
    }
}
