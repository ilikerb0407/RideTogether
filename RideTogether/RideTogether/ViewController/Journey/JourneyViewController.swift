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

class JourneyViewController: BaseViewController {
    
    let userId = { UserManager.shared.userInfo }
    
    private var isDisplayingLocationServicesDenied: Bool = false
    
    @IBOutlet weak var map: GPXMap!
    
    private var stopWatch = StopWatch()
    
    private var lastLocation: CLLocation?
    
    private let locationManager: CLLocationManager = {
        
        let manager = CLLocationManager()
        
        manager.requestAlwaysAuthorization()
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
//        manager.distanceFilter = kCLDistanceFilterNone
        manager.distanceFilter = 2
        
        manager.pausesLocationUpdatesAutomatically = false

//        manager.allowsBackgroundLocationUpdates = true
//
//        manager.startUpdatingLocation()
        
        return manager
    }()
    
    private let mapViewDelegate = MapViewDelegate()
    
    enum GpxTrackingStatus {
        
        case notStarted
        
        case tracking
        
        case paused
    }
    
    private var gpxTrackingStatus: GpxTrackingStatus = GpxTrackingStatus.notStarted {
        
        didSet {
            
            switch gpxTrackingStatus {
                
            case .notStarted:
                
                trackerButton.setTitle("Start", for: .normal)
                
                stopWatch.reset()
                
//                waveLottieView.isHidden = true
                
                timeLabel.text = stopWatch.elapsedTimeString
                
                map.clearMap()
                
                totalTrackedDistanceLabel.distance = (map.session.totalTrackedDistance)
                
                currentSegmentDistanceLabel.distance = (map.session.currentSegmentDistance)
                
            case .tracking:
                
                trackerButton.setTitle("Pause", for: .normal)
                
                self.stopWatch.start()
                
//                waveLottieView.isHidden = false
                
//                waveLottieView.play()
                
                
            case .paused:
                
                self.trackerButton.setTitle("Resume", for: .normal)
                
                self.stopWatch.stop()
                
//                waveLottieView.isHidden = true
                
                self.map.startNewTrackSegment()
            }
        }
    }
    
    private var followUser: Bool = true {
        
        didSet {
            
            if followUser {
                // MARK: 定位的符號
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
        button.setTitle("Start", for: .normal)
        button.titleLabel?.font = UIFont.regular(size: 18)
        button.titleLabel?.textAlignment = .center
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Reset", for: .normal)
        button.titleLabel?.font = UIFont.regular(size: 16)
        button.titleLabel?.textAlignment = .center
        button.alpha = 0.5
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = UIFont.regular(size: 16)
        button.titleLabel?.textAlignment = .center
        button.alpha = 0.5
        return button
    }()
    
    private lazy var followUserButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        let image = UIImage(systemName: "location.fill",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        return button
    }()
    
    private lazy var pinButton: UIButton = {
//        // Pin Button (on the left of start)
        let button = UIButton()
        button.layer.cornerRadius = 24.0
        button.backgroundColor = UIColor(red: 254.0/255.0, green: 254.0/255.0, blue: 254.0/255.0, alpha: 0.90)
        button.setImage(UIImage(named: "mappin"), for: UIControl.State())
        button.setImage(UIImage(named: "mappin.circle.fill"), for: .highlighted)
        button.addTarget(self, action: #selector(JourneyViewController.addPinAtMyLocation), for: .touchUpInside)
        return button
    }()
    
    @objc func addPinAtMyLocation() {
        print("Adding Pin at my location")
        let altitude = locationManager.location?.altitude
        let waypoint = GPXWaypoint(coordinate: locationManager.location?.coordinate ?? map.userLocation.coordinate, altitude: altitude)
        map.addWaypoint(waypoint)
//        map.coreDataHelper.add(toCoreData: waypoint)
        self.hasWaypoints = true
    }
    
    @objc func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
        if  gesture.state == UIGestureRecognizer.State.began {
            print("Adding Pin map Long Press Gesture")
            let point: CGPoint = gesture.location(in: self.map)
            map.addWaypointAtViewPoint(point)
            //Allows save and reset
            self.hasWaypoints = true
        }
    }
    /// Has the map any waypoint?
    var hasWaypoints: Bool = false {
        /// Whenever it is updated, if it has waypoints it sets the save and reset button
        didSet {
            if hasWaypoints {
                saveButton.backgroundColor = .blue
                resetButton.backgroundColor = .red
            }
        }
    }
    
    private lazy var waveLottieView: AnimationView = {
        let view = AnimationView(name: "wave")
        view.loopMode = .loop
        view.frame = CGRect(x: 0, y: 0, width: 130, height: 130)
        view.center = buttonStackView.center
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        self.view.bringSubviewToFront(buttonStackView)
        return view
    }()
    
    private lazy var buttonStackView: UIStackView = {
        
        let view = UIStackView(arrangedSubviews: [followUserButton, pinButton , trackerButton, saveButton, resetButton])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .equalSpacing
        view.alignment = .bottom
        return view
    }()
    
    // MARK: 之後再改字體
    
     var coordsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = UIFont.regular(size: 14)
        label.textColor = UIColor.white
        return label
    }()
    
     var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = UIFont.regular(size: 26)
        label.textColor = UIColor.white
        label.text = "00:00"
        return label
    }()
    
    private lazy var totalTrackedDistanceLabel: DistanceLabel = {
        let distaneLabel = DistanceLabel()
        distaneLabel.textAlignment = .right
        distaneLabel.font = UIFont.regular(size: 26)
        distaneLabel.textColor = UIColor.white
        distaneLabel.distance = 0.00
        return distaneLabel
    }()
    
    private lazy var currentSegmentDistanceLabel: DistanceLabel = {
        let distaneLabel = DistanceLabel()
        distaneLabel.textAlignment = .right
        distaneLabel.font = UIFont.regular(size: 18)
        distaneLabel.textColor = UIColor.white
        distaneLabel.distance = 0.00
        return distaneLabel
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopWatch.delegate = self
        
//        RecordManager.shared.detectDeviceAndUpload()
        
        setUpMap()
        
        setUpButtonsStackView()
        
        setUpLabels()
        
        navigationController?.isNavigationBarHidden = true
        
        self.locationManager.requestAlwaysAuthorization()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let trakerRadius = trackerButton.frame.height / 2
        
        let otherRadius = saveButton.frame.height / 2
        
        followUserButton.roundCorners(cornerRadius: otherRadius)
        
        trackerButton.roundCorners(cornerRadius: trakerRadius)
        
        saveButton.roundCorners(cornerRadius: otherRadius)
        
        resetButton.roundCorners(cornerRadius: otherRadius)
        
        pinButton.roundCorners(cornerRadius: otherRadius)
        
        trackerButton.applyButtonGradient(
            colors: [UIColor.hexStringToUIColor(hex: "#C4E0F8"),.orange],
            direction: .leftSkewed)
        
        saveButton.applyButtonGradient(
            colors: [UIColor.hexStringToUIColor(hex: "#F3F9A7"),
                     UIColor.hexStringToUIColor(hex: "#45B649")],
            direction: .leftSkewed)
        
        resetButton.applyButtonGradient(
            colors: [UIColor.hexStringToUIColor(hex: "#e1eec3"),
                     UIColor.hexStringToUIColor(hex: "#f05053")],
            direction: .leftSkewed)
        
    }
    
    // MARK: - Action
    
    func setUpMap() {
        
        map.delegate = mapViewDelegate
        
        map.showsUserLocation = true
        
        locationManager.delegate = self
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(stopFollowingUser(_:)))
        
        panGesture.delegate = self
        
        map.addGestureRecognizer(panGesture)
        
        locationManager.startUpdatingLocation()
        
        let center = locationManager.location?.coordinate ??
        CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: center, span: span)
        
        map.setRegion(region, animated: true)
        
        //If user long presses the map, it will add a Pin (waypoint) at that point
        map.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(JourneyViewController.addPinAtTappedLocation(_:)))
        )
        
        self.view.addSubview(map)
    }
    
    @objc func trackerButtonTapped() {
        
        switch gpxTrackingStatus {
            
        case .notStarted:
            
            UIView.animate(withDuration: 0.3) {
                self.saveButton.alpha = 1.0
                self.resetButton.alpha = 1.0
                self.pinButton.alpha = 1.0
            }
            
            gpxTrackingStatus = .tracking
            
        case .tracking:
            
            gpxTrackingStatus = .paused
            
        case .paused:
            
            gpxTrackingStatus = .tracking
        }
    }
    
    @objc func saveButtonTapped(withReset: Bool = false) {
        
        if gpxTrackingStatus == .notStarted { return }
        
        let date = Date()
        
        let time = TimeFormater.preciseTimeForFilename.dateToString(time: date)
        
        let defaultFileName = "\(time)"
        
        let alertController = UIAlertController(title: "儲存至裝置",
                                                message: "請輸入檔案名稱",
                                                preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: { (textField) in
            
            textField.clearButtonMode = .always
            
            textField.text =  defaultFileName
        })
        
        let saveAction = UIAlertAction(title: "儲存",
                                       style: .default) { _ in
            
            let gpxString = self.map.exportToGPXString()
            
            let fileName = alertController.textFields?[0].text
            // "2022-04-10_04-21"
            if let fileName = fileName {
                GPXFileManager.save(filename: fileName, gpxContents: gpxString)
            }
            
            if withReset {
                self.gpxTrackingStatus = .notStarted
            }
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alertController.addAction(saveAction)
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @objc func resetButtonTapped() {
        
        if gpxTrackingStatus == .notStarted { return }

        let cancelOption = UIAlertAction(title: "取消", style: .cancel)
        
        let resetOption = UIAlertAction(title: "重置", style: .destructive) { _ in
            self.gpxTrackingStatus = .notStarted
            
            UIView.animate(withDuration: 0.3) {
                self.saveButton.alpha = 0.5
                self.resetButton.alpha = 0.5
            }
        }
        
        showAlertAction(title: nil, message: nil, preferredStyle: .actionSheet, actions: [cancelOption, resetOption])
    }
    
    @objc func followButtonTroggler() {
        
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
        
        if !([.authorizedAlways, .authorizedWhenInUse]
                .contains(locationManager.authorizationStatus)) {
            
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
                UIApplication.shared.open(url, options: [:])
            }
        }
        let cancelAction = UIAlertAction(title: "取消",
                                         style: .cancel)
        
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
        
        NSLayoutConstraint.activate([
            
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            buttonStackView.widthAnchor.constraint(equalToConstant: UIScreen.width * 0.85),
            
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            
            buttonStackView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
//        let button = UIButton()
        
        buttonStackView.addArrangedSubview(followUserButton)
        
        buttonStackView.addArrangedSubview(pinButton)
        
        buttonStackView.addArrangedSubview(trackerButton)
        
        buttonStackView.addArrangedSubview(saveButton)
        
        buttonStackView.addArrangedSubview(resetButton)
        
        // MARK: button constraint
        
        NSLayoutConstraint.activate([
            
            followUserButton.heightAnchor.constraint(equalToConstant: 50),
            
            followUserButton.widthAnchor.constraint(equalToConstant: 50),
            
            pinButton.heightAnchor.constraint(equalToConstant: 50),
            
            pinButton.widthAnchor.constraint(equalToConstant: 50),
            
            trackerButton.heightAnchor.constraint(equalToConstant: 80),
            
            trackerButton.widthAnchor.constraint(equalToConstant: 80),
            
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            saveButton.widthAnchor.constraint(equalToConstant: 50),
            
            resetButton.heightAnchor.constraint(equalToConstant: 50),
            
            resetButton.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        trackerButton.addTarget(self, action: #selector(trackerButtonTapped), for: .touchUpInside)
        
//        pinButton.addTarget(self, action:  #selector(addPinAtTappedLocation), for: .touchUpInside)
        
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        
        followUserButton.addTarget(self, action: #selector(followButtonTroggler), for: .touchUpInside)
    }
    
    func setUpLabels() {
        
        map.addSubview(coordsLabel)
        
        coordsLabel.frame = CGRect(x: 10, y: 30, width: 200, height: 100)
        
        map.addSubview(timeLabel)
        
        timeLabel.frame = CGRect(x: UIScreen.width - 100, y: 40, width: 80, height: 30)
        
        map.addSubview(totalTrackedDistanceLabel)
        
        totalTrackedDistanceLabel.frame = CGRect(x: UIScreen.width - 100, y: 70, width: 80, height: 30)
        
        map.addSubview(currentSegmentDistanceLabel)
        
        currentSegmentDistanceLabel.frame = CGRect(x: UIScreen.width - 100, y: 100, width: 80, height: 30)
    }
}

// MARK: - StopWatchDelegate methods

extension JourneyViewController: StopWatchDelegate {
    func stopWatch(_ stropWatch: StopWatch, didUpdateElapsedTimeString elapsedTimeString: String) {
        
        timeLabel.text = elapsedTimeString
    }
}

// MARK: - CLLocationManager Delegate -

extension JourneyViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("didFailWithError \(error)")
        
        let locationError = error as? CLError
        
        switch locationError?.code {
            
        case CLError.locationUnknown:
            
            print("Location Unknown")
            
        case CLError.denied:
            
            print("Access to location services denied. Display message")
            
            checkLocationServicesStatus()
            
        default:
            
            print("Default error")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let newLocation = locations.first!
        
        let latFormat = String(format: "%.5f", newLocation.coordinate.latitude)
        
        let lonFormat = String(format: "%.5f", newLocation.coordinate.longitude)
        
        let altitude = newLocation.altitude.toAltitude()
        
        let text = "latitude: \(latFormat) \rlontitude: \(lonFormat) \raltitude: \(altitude)"
        
        coordsLabel.text = text
        
        if followUser {
            map.setCenter(newLocation.coordinate, animated: true)
        }
        
        if gpxTrackingStatus == .tracking {
            
            map.addPointToCurrentTrackSegmentAtLocation(newLocation)
            
            totalTrackedDistanceLabel.distance = map.session.totalTrackedDistance
            
            currentSegmentDistanceLabel.distance = map.session.currentSegmentDistance
        }
    }
}
