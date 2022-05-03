//
//  RouteRideViewController.swift
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


class RouteRideViewController: BaseViewController, StopWatchDelegate, CLLocationManagerDelegate {
    
    func stopWatch(_ stropWatch: StopWatch, didUpdateElapsedTimeString elapsedTimeString: String) {
        timeLabel.text = elapsedTimeString
    }
    

    @IBOutlet weak var map3: GPXMapView!
    
    
    var routes = Route()

    
        private var isDisplayingLocationServicesDenied: Bool = false
        
        
        /// Name of the last file that was saved (without extension)
        var lastGpxFilename: String = ""
        
        
        func backButton() {
            let button = PreviousPageButton(frame: CGRect(x: 20, y: 150, width: 50, height: 50))
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
            
            if let inputUrl = URL(string: routes.routeMap) {
                
                print("FollowDetail=======:\(inputUrl)======")
                guard let gpx = GPXParser(withURL: inputUrl)?.parsedData() else { return }
                
                didLoadGPXFile(gpxRoot: gpx)
                
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
        
        // MARK: =========
        
        private var stopWatch = StopWatch()
        
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
                    
                    //   waveLottieView.isHidden = true
                    
                    timeLabel.text = stopWatch.elapsedTimeString
                    
                    //MARK: 怕把線清掉
                    map3.clearMap()
                    
                    totalTrackedDistanceLabel.distance = (map3.session.totalTrackedDistance)
                    
                    currentSegmentDistanceLabel.distance = (map3.session.currentSegmentDistance)
                    
                case .tracking:
                    
                    trackerButton.setTitle("Pause", for: .normal)
                    
                    self.stopWatch.start()
                    
                    //                waveLottieView.isHidden = false
                    //                waveLottieView.play()
                    
                    
                case .paused:
                    
                    self.trackerButton.setTitle("Resume", for: .normal)
                    
                    self.stopWatch.stop()
                    
                    //                waveLottieView.isHidden = true
                    
                    self.map3.startNewTrackSegment()
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
                    
                    map3.setCenter((map3.userLocation.coordinate), animated: true)
                    
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
            button.backgroundColor = .clear
            let mappin = UIImage(systemName: "mappin",
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium ))
            let mappinHighlighted = UIImage(systemName: "mappin.circle.fill",
                                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium ))
            button.setImage(mappin, for: UIControl.State())
            button.setImage(mappinHighlighted, for: .highlighted)
            //        button.setImage(UIImage(named: "mappin"), for: UIControl.State())
            //        button.setImage(UIImage(named: "mappin.circle.fill"), for: .highlighted)
            button.addTarget(self, action: #selector(FollowJourneyViewController.addPinAtMyLocation), for: .touchUpInside)
            return button
        }()
        
        @objc func addPinAtMyLocation() {
            print("Adding Pin at my location")
            let altitude = locationManager.location?.altitude
            let waypoint = GPXWaypoint(coordinate: locationManager.location?.coordinate ?? map3.userLocation.coordinate, altitude: altitude)
            map3.addWaypoint(waypoint)

            self.hasWaypoints = true
        }
        
        // MARK: 長按功能_ UILongPressGestureRecognizer
        @objc func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
            
            if gesture.state == UIGestureRecognizer.State.began {
                print("Adding Pin map Long Press Gesture")
                let point: CGPoint = gesture.location(in: self.map3)
                map3.addWaypointAtViewPoint(point)
                //Allows save and reset
                self.hasWaypoints = true
            }
        }
        /// Has the map any waypoint?
        var hasWaypoints: Bool = false
        
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
            
            let view = UIStackView(arrangedSubviews: [followUserButton, pinButton, trackerButton, saveButton, resetButton])
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
            label.font = UIFont.regular(size: 20)
            label.textColor = UIColor.white
            return label
        }()
        
        var speedLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.textAlignment = .left
            label.font = UIFont.regular(size: 30)
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
            
            locationManager.delegate = self
            
            stopWatch.delegate = self
            
            RecordManager.shared.detectDeviceAndUpload()
            
            setUpMap()
            
            setUpButtonsStackView()
            
            setUpLabels()
            
            backButton()

            navigationController?.isNavigationBarHidden = true
            
            self.locationManager.requestAlwaysAuthorization()
            
            praseGPXFile()
            
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
                colors: [UIColor.hexStringToUIColor(hex: "#C4E0F8"),  .orange],
                direction: .leftSkewed)
            
            saveButton.applyButtonGradient(
                colors: [UIColor.hexStringToUIColor(hex: "#F3F9A7"),
                         UIColor.hexStringToUIColor(hex: "#1273DE")],
                direction: .leftSkewed)
            
            resetButton.applyButtonGradient(
                colors: [UIColor.hexStringToUIColor(hex: "#e1eec3"),
                         UIColor.hexStringToUIColor(hex: "#FCCB00")],
                direction: .leftSkewed)
            
        }
        
        
        // MARK: - Action
        
        func setUpMap() {
            
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            
            map3.delegate = mapViewDelegate
            
            map3.showsUserLocation = true
            
            // 移動 map 的方式
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(stopFollowingUser(_:)))
            
            panGesture.delegate = self
            
            map3.addGestureRecognizer(panGesture)
            
            map3.rotationGesture.delegate = self
            
            let center = locationManager.location?.coordinate ??
            CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: center, span: span)
            
            map3.setRegion(region, animated: true)
            
            //   If user long presses the map, it will add a Pin (waypoint) at that point
            
            map3.addGestureRecognizer(UILongPressGestureRecognizer( target: self,
                                                                   action: #selector(JourneyViewController.addPinAtTappedLocation(_:))))
            
            self.view.addSubview(map3)
            
            praseGPXFile()
            
        }
        
        @objc func trackerButtonTapped() {
            
            switch gpxTrackingStatus {
                
            case .notStarted:
                
                UIView.animate(withDuration: 0.2) {
                    self.trackerButton.alpha = 1.0
                    self.saveButton.alpha = 1.0
                    self.resetButton.alpha = 1.0
                }
                
                gpxTrackingStatus = .tracking
                
            case .tracking:
                
                gpxTrackingStatus = .paused
                
            case .paused:
                
                gpxTrackingStatus = .tracking
            }
        }
        @objc func saveButtonTapped(withReset: Bool = false) {
            
            if gpxTrackingStatus == .notStarted && !self.hasWaypoints { return }
            
            let date = Date()
            
            let time = TimeFormater.preciseTimeForFilename.dateToString(time: date)
            
            let defaultFileName = "\(time)"
            
            let alertController = UIAlertController(title: "Save Record",
                                                    message: "Please enter the title",
                                                    preferredStyle: .alert)
            
            alertController.addTextField(configurationHandler: { (textField) in
                
                textField.clearButtonMode = .always
                
                textField.text =  defaultFileName
            })
            
            let saveAction = UIAlertAction(title: "Save",
                                           style: .default) { _ in
                
                let gpxString = self.map3.exportToGPXString()
                
                let fileName = alertController.textFields?[0].text
                // "2022-04-10_04-21"
                print ("1\(fileName)1")
                
                self.lastGpxFilename = fileName!
                
                //            if let fileName = fileName {
                GPXFileManager.save( fileName!, gpxContents: gpxString)
                self.lastGpxFilename = fileName!
            
                print ("2\(fileName)2")
                //            }
                
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
        

        // MARK: - UI Settings -
        
        func setUpButtonsStackView() {
            
            view.addSubview(buttonStackView)
            
            NSLayoutConstraint.activate([
                
                buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                
                buttonStackView.widthAnchor.constraint(equalToConstant: UIScreen.width * 0.85),
                
                buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
                
                buttonStackView.heightAnchor.constraint(equalToConstant: 80)
            ] )
            
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
            
            saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
            
            resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
            
            followUserButton.addTarget(self, action: #selector(followButtonTroggler), for: .touchUpInside)
            
        }
        
        func setUpLabels() {

            map3.addSubview(speedLabel)
            speedLabel.frame = CGRect(x: 10, y: 40, width: 200, height: 100)
            
            map3.addSubview(coordsLabel)
            ////         座標 - 改成時速
            coordsLabel.frame = CGRect(x: 10, y: 60, width: 200, height: 100)
            
            map3.addSubview(timeLabel)
            // 時間
            timeLabel.frame = CGRect(x: UIScreen.width - 100, y: 40, width: 80, height: 30)
            
            map3.addSubview(totalTrackedDistanceLabel)
            // 距離
            totalTrackedDistanceLabel.frame = CGRect(x: UIScreen.width - 100, y: 70, width: 80, height: 30)
            
            map3.addSubview(currentSegmentDistanceLabel)
            
            currentSegmentDistanceLabel.frame = CGRect(x: UIScreen.width - 100, y: 100, width: 80, height: 30)
        }
        
    }

