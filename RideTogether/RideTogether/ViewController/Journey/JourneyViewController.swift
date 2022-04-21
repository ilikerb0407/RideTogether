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

class JourneyViewController: BaseViewController, GPXFilesTableViewControllerDelegate, MKLocalSearchCompleterDelegate {
    
    //    let userId = { UserManager.shared.userInfo }
    
    private var isDisplayingLocationServicesDenied: Bool = false
    
    @IBOutlet weak var map: GPXMapView!
    
    private var mapRoutes: [MKRoute] = []
    
    var directionsResponse =  MKDirections.Response()
    
    var route = MKRoute()
    
    let completer = MKLocalSearchCompleter()
    
    var lastGpxFilename: String = ""
    
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
                
                waveLottieView.isHidden = true
                
                timeLabel.text = stopWatch.elapsedTimeString
                
                map.clearMap()
                
                totalTrackedDistanceLabel.distance = (map.session.totalTrackedDistance)
                
                currentSegmentDistanceLabel.distance = (map.session.currentSegmentDistance)
                
            case .tracking:
                
                trackerButton.setTitle("Pause", for: .normal)
                
                self.stopWatch.start()
                
                waveLottieView.isHidden = false
                
                waveLottieView.play()
                
                
                
            case .paused:
                
                self.trackerButton.setTitle("Resume", for: .normal)
                
                self.stopWatch.stop()
                
                waveLottieView.isHidden = true
                
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
    private lazy var guideButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        let image = UIImage(named: "information", in: nil, with: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 24
        return button
    }()
    
    private lazy var sendSMSButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        let image = UIImage(systemName: "message",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 24
        return button
    }()
    
    
    
    private lazy var offlineMapButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        let image = UIImage(systemName: "map",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 24
        return button
    }()
    
    private lazy var loadMapButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        let image = UIImage(systemName: "folder",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 24
        return button
    }()
    
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
        let mappin = UIImage(systemName: "mappin.and.ellipse",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium ))
        let mappinHighlighted = UIImage(systemName: "mappin.and.ellipse",
                                        withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium ))
        button.setImage(mappin, for: UIControl.State())
        button.setImage(mappinHighlighted, for: .highlighted)
        //        button.setImage(UIImage(named: "mappin"), for: UIControl.State())
        //        button.setImage(UIImage(named: "mappin.circle.fill"), for: .highlighted)
        button.addTarget(self, action: #selector(JourneyViewController.addPinAtMyLocation), for: .touchUpInside)
        return button
    }()
    
    @objc func addPinAtMyLocation() {
        print("Adding Pin at my location")
        let altitude = locationManager.location?.altitude
        let waypoint = GPXWaypoint(coordinate: locationManager.location?.coordinate ?? map.userLocation.coordinate, altitude: altitude)
        map.addWaypoint(waypoint)
        map.coreDataHelper.add(toCoreData: waypoint)
        self.hasWaypoints = true
    }
    
    // MARK: 長按功能_ UILongPressGestureRecognizer
    @objc func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            print("Adding Pin map Long Press Gesture")
            
            map.clearOverlays()
            let point: CGPoint = gesture.location(in: self.map)
            map.addWaypointAtViewPoint(point)
            //Allows save and reset
            self.hasWaypoints = true
        }
    }
    
    /// Has the map any waypoint?
    var hasWaypoints: Bool = false
    
    private lazy var waveLottieView: AnimationView = {
        let view = AnimationView(name: "95671-wave-animation")
        view.loopMode = .loop
//        view.translatesAutoresizingMaskIntoConstraints = false
        view.frame = CGRect(x: 0, y: 0, width: 100 , height: 100)
        view.center = leftStackView.center
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        self.view.bringSubviewToFront(leftStackView)
        // buttonStackView要改成 left
        return view
    }()
    
    private lazy var buttonStackView: UIStackView = {
        //        let view = UIStackView(arrangedSubviews: [followUserButton, pinButton, trackerButton, saveButton, resetButton])
        let view = UIStackView(arrangedSubviews: [followUserButton, pinButton, sendSMSButton, guideButton])
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
//        view.centerXAnchor.
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
        label.font = UIFont.regular(size: 40)
        label.textColor = UIColor.white
        label.text = "Timer"
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
        
        navigationController?.isNavigationBarHidden = true
        
        self.locationManager.requestAlwaysAuthorization()
        
        addSegment()
        
        
        completer.delegate = self
        completer.region = map.region
                
    }
    
    func addSegment() {
        let segmentControl = UISegmentedControl(items: ["hybrid", "standard" ])
        segmentControl.tintColor = UIColor.black
        segmentControl.backgroundColor =
        UIColor.lightGray
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(onChange), for: .valueChanged)
        segmentControl.frame.size = CGSize(
            width: 150, height: 30)
        segmentControl.center = CGPoint(
            x: 80,
            y: 65)
        self.view.addSubview(segmentControl)
    }
    
    
    // 切換選項時執行動作的方法
    @objc func onChange(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0 :
            map.mapType = .hybridFlyover
            map.showsTraffic = true
            speedLabel.textColor = .white
            timeLabel.textColor = .white
            coordsLabel.textColor = .white
            currentSegmentDistanceLabel.textColor = .white
            totalTrackedDistanceLabel.textColor = .white
        case 1 :
            map.mapType = .standard
            map.showsTraffic = true
            speedLabel.textColor = .black
            timeLabel.textColor = .black
            coordsLabel.textColor = .black
            currentSegmentDistanceLabel.textColor = .black
            totalTrackedDistanceLabel.textColor = .black
        default :
            map.mapType = .standard
        }
    }
    
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let trakerRadius = trackerButton.frame.height / 2
        
        let otherRadius = saveButton.frame.height / 2
        
        
        //        offlineMapButton.roundCorners(cornerRadius: otherRadius)
        //
        //        loadMapButton.roundCorners(cornerRadius: otherRadius)
        
        followUserButton.roundCorners(cornerRadius: otherRadius)
        
        sendSMSButton.roundCorners(cornerRadius: otherRadius)
        
        guideButton.roundCorners(cornerRadius: otherRadius)
        
        trackerButton.roundCorners(cornerRadius: trakerRadius)
        
        saveButton.roundCorners(cornerRadius: otherRadius)
        
        resetButton.roundCorners(cornerRadius: otherRadius)
        
        pinButton.roundCorners(cornerRadius: otherRadius)
        
        trackerButton.applyButtonGradient(
            colors: [UIColor.hexStringToUIColor(hex: "#C4E0F8"),.orange],
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
        
        map.delegate = mapViewDelegate
        
        map.showsUserLocation = true
        
        // 移動 map 的方式
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(stopFollowingUser(_:)))
        
        panGesture.delegate = self
        
        map.addGestureRecognizer(panGesture)
        
        map.rotationGesture.delegate = self
        
        let center = locationManager.location?.coordinate ??
        CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: center, span: span)
        
        map.setRegion(region, animated: true)
        
        //   If user long presses the map, it will add a Pin (waypoint) at that point
        
        map.addGestureRecognizer(UILongPressGestureRecognizer( target: self,
                                                               action: #selector(JourneyViewController.addPinAtTappedLocation(_:))))
        
        self.view.addSubview(map)
    }
    
    var taichung = CLLocationCoordinate2D(latitude: 24.18352165572669, longitude: 120.62348601471712)
    
    
    @objc func sendSMS() {
        
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.recipients = ["請輸入收件人"]
        composeVC.body = "分享我的位置 經度 :\(locationManager.location!.coordinate.longitude), 緯度: \(locationManager.location!.coordinate.latitude)"
        
        // Present the view controller modally.
        if MFMessageComposeViewController.canSendText() {
            self.present(composeVC, animated: true, completion: nil)
        }
        
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
    
    
    @objc func searchLocation() {
        
        map.clearOverlays()
        
        let alertController = UIAlertController(title: "Search_Destination", message: "Please enter Location", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(textField) in
            textField.clearButtonMode = .always
            textField.text = "台北"
        })
        let searchAction = UIAlertAction(title: "Search", style: .default) { [self]_ in
            var fileName = alertController.textFields?[0].text
        

            let geoCoder = CLGeocoder()
            
            geoCoder.geocodeAddressString(fileName!) { (placemarks, error) in
                guard
                    let placemarks = placemarks,
                    let location = placemarks.first?.location
                else {
                    print("location not found")
                    return
                }
                self.taichung.latitude = location.coordinate.latitude
                self.taichung.longitude = location.coordinate.longitude
                let targetPlacemark = MKPlacemark(coordinate: taichung)
                let targetItem = MKMapItem(placemark: targetPlacemark)
                let userMapItem = MKMapItem.forCurrentLocation()
                let request = MKDirections.Request()
                request.source = userMapItem
                request.destination = targetItem
                request.transportType = .walking
                request.requestsAlternateRoutes = true
                let directions = MKDirections(request: request)
                
                directions.calculate { [self]  response ,error in
                if error == nil {
                                self.directionsResponse = response!
                
                                self.route = self.directionsResponse.routes[0]
                
                                map.addOverlay(self.route.polyline, level: MKOverlayLevel.aboveLabels)
                            } else {
                                print("\(error)")
                            }
                        }
                
                
            }
            
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(searchAction)
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
        
    }
    
    
    @objc func saveButtonTapped(withReset: Bool = false) {
        
        if gpxTrackingStatus == .notStarted && !self.hasWaypoints { return }
        
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
            print ("1\(fileName)1")
            
            self.lastGpxFilename = fileName!
            
            //            if let fileName = fileName {
            GPXFileManager.save( fileName!, gpxContents: gpxString)
            self.lastGpxFilename = fileName!
            self.map.coreDataHelper.coreDataDeleteAll(of: CDRoot.self)
            //deleteCDRootFromCoreData()
            self.map.coreDataHelper.clearAllExceptWaypoints()
            self.map.coreDataHelper.add(toCoreData: fileName!, willContinueAfterSave: true)
            
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
    
    
    //原本放在folder button 裡面
    
    @objc func openOfflineMap() {
        addRoute()
    }
    
    @objc func openFolderViewController() {
        print("openFolderViewController")
        let vc = GPXFilesTableViewController(nibName: nil, bundle: nil)
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true) { () -> Void in }
    }
    
    
    // MARK: 離線地圖
    func addRoute() {
        guard let points = Park.plist("Taipei1") as? [String] else { return }
        
        let cgPoints = points.map { NSCoder.cgPoint(for: $0) }
        let coords = cgPoints.map { CLLocationCoordinate2D(
            latitude: CLLocationDegrees($0.x),
            longitude: CLLocationDegrees($0.y))
        }
        let myPolyline = MKPolyline(coordinates: coords, count: coords.count)
        print ("===========Pleaseprint")
        map.addOverlay(myPolyline)
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
        view.addSubview(leftStackView)
        
        NSLayoutConstraint.activate([
            
            buttonStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 120),
            // widthAnchor.constraint = UIScreen.width * 0.85
            buttonStackView.widthAnchor.constraint(equalToConstant: 220),
            
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
        buttonStackView.addArrangedSubview(guideButton)
        
        leftStackView.addArrangedSubview(saveButton)
        leftStackView.addArrangedSubview(trackerButton)
        leftStackView.addArrangedSubview(resetButton)
        
        // MARK: button constraint
        
        NSLayoutConstraint.activate([
            
            followUserButton.heightAnchor.constraint(equalToConstant: 50),
            
            followUserButton.widthAnchor.constraint(equalToConstant: 50),
            
            pinButton.heightAnchor.constraint(equalToConstant: 50),
            
            pinButton.widthAnchor.constraint(equalToConstant: 50),
            
            sendSMSButton.widthAnchor.constraint(equalToConstant: 70),
            
            sendSMSButton.heightAnchor.constraint(equalToConstant: 50),
            
            guideButton.widthAnchor.constraint(equalToConstant: 50),
            
            guideButton.heightAnchor.constraint(equalToConstant: 50),
            
            trackerButton.heightAnchor.constraint(equalToConstant: 70),
            
            trackerButton.widthAnchor.constraint(equalToConstant: 70),
            
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            saveButton.widthAnchor.constraint(equalToConstant: 50),
            
            resetButton.heightAnchor.constraint(equalToConstant: 50),
            
            resetButton.widthAnchor.constraint(equalToConstant: 50),
            
            offlineMapButton.heightAnchor.constraint(equalToConstant: 50),
            
            offlineMapButton.widthAnchor.constraint(equalToConstant: 50),
            
            loadMapButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadMapButton.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        trackerButton.addTarget(self, action: #selector(trackerButtonTapped), for: .touchUpInside)
        
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        
        followUserButton.addTarget(self, action: #selector(followButtonTroggler), for: .touchUpInside)
        
        offlineMapButton.addTarget(self, action: #selector(openOfflineMap), for: .touchUpInside)
        
        loadMapButton.addTarget(self, action: #selector(openFolderViewController), for: .touchUpInside)
        
        sendSMSButton.addTarget(self, action: #selector(sendSMS), for: .touchUpInside)
        
        guideButton.addTarget(self, action: #selector(searchLocation), for: .touchUpInside)
    }
    
    func setUpLabels() {
        
        map.addSubview(coordsLabel)
        ////         座標 - 改成時速
        coordsLabel.frame = CGRect(x: 10, y: 60, width: 200, height: 100)
        
        map.addSubview(speedLabel)
        speedLabel.frame = CGRect(x: 10, y: 40, width: 200, height: 100)
        
        map.addSubview(timeLabel)
        // 時間
        timeLabel.frame = CGRect(x: UIScreen.width - 100, y: 40, width: 80, height: 30)
        
        map.addSubview(totalTrackedDistanceLabel)
        // 距離
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
    
    //MARK: 桌面更新資料
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let newLocation = locations.first!
        
        
        let altitude = newLocation.altitude.toAltitude()
        let text = "Height : \(altitude)"
        coordsLabel.text = text
        
        let rUnknownSpeedText = "0.00"
        
        //  MARK: Update_speed
        
        speedLabel.text = "speed : \((newLocation.speed < 0) ? rUnknownSpeedText : newLocation.speed.toSpeed())"
        
        if followUser {
            map.setCenter(newLocation.coordinate, animated: true)
        }
        
        if gpxTrackingStatus == .tracking {
            
            map.addPointToCurrentTrackSegmentAtLocation(newLocation)
            
            totalTrackedDistanceLabel.distance = map.session.totalTrackedDistance
            
            currentSegmentDistanceLabel.distance = map.session.currentSegmentDistance
        }
    }
    
    //   Pin direction
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        map.heading = newHeading // updates heading variable
        map.updateHeading() // updates heading view's rotation
    }
    // MARK: 選擇路線後導航 (有時間在做)
    func didLoadGPXFileWithName(_ gpxFilename: String, gpxRoot: GPXRoot) {
        //emulate a reset button tap
        self.resetButtonTapped()
        //println("Loaded GPX file", gpx.gpx())
        lastGpxFilename = gpxFilename
        // adds last file name to core data as well
        //        self.map.coreDataHelper.add(toCoreData: gpxFilename, willContinueAfterSave: false)
        //force reset timer just in case reset does not do it
        self.stopWatch.reset()
        //load data
        self.map.importFromGPXRoot(gpxRoot)
        //stop following user
        self.followUser = false
        //center map in GPX data
        self.map.regionToGPXExtent()
        
        self.gpxTrackingStatus = .paused
        
        self.totalTrackedDistanceLabel.distance = self.map.session.totalTrackedDistance
    }
    
}

extension Notification.Name {
    static let loadRecoveredFile = Notification.Name("loadRecoveredFile")
    static let updateAppearance = Notification.Name("updateAppearance")
    // swiftlint:disable file_length
}


 
  


