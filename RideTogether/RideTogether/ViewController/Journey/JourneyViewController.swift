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

class JourneyViewController: BaseViewController, MKLocalSearchCompleterDelegate, sendRouteSecond, weatherProvider {
    
    var userName: String { UserManager.shared.userInfo.userName ?? ""}
    
    func sendRouteTwice(map: DrawRoute) {
        mapData = map
    }
    var mapData: DrawRoute?
    
    private let buttonPanelView = ButtonPanelView()
    
    var routeVc =  RouteSelectionViewController()
    
    private var isDisplayingLocationServicesDenied: Bool = false
    
    @IBOutlet weak var map: GPXMapView!
    
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
    
    private let mapViewDelegate = MapView()
    
    func provideWeather(weather: ResponseBody) {
        weatherdata = weather
    }
    
    var weatherdata : ResponseBody?
    
    let weatherManger = WeatherManager()
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        let annotationView = MKPinAnnotationView()

        //  let annotationView: MKPinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "mapping")
        annotationView.canShowCallout = true
        annotationView.isDraggable = true
        //
        let rightbtn: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightbtn.clipsToBounds = true
        rightbtn.tintColor = .B5
        let rightImg = UIImage(systemName: "info.circle",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light))
        rightbtn.setImage(rightImg, for: .normal)
        //        deleteButton.setImage(UIImage(named: "deleteHigh"), for: .highlighted)
        rightbtn.tag = kDeleteWaypointButtonTag
        annotationView.rightCalloutAccessoryView = rightbtn
        //        annotationView.pinTintColor = .red
        let leftbtn: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        leftbtn.tintColor = .B5
        let leftImg = UIImage(systemName: "pencil.circle",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light))
        leftbtn.setImage(leftImg, for: .normal)
        //        editButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .highlighted)
        leftbtn.tag = kEditWaypointButtonTag
        annotationView.leftCalloutAccessoryView = leftbtn
        
        return annotationView
    }
    
    let kDeleteWaypointButtonTag = 666
    
    let kEditWaypointButtonTag = 333
    
    var destination: CLPlacemark?
    
    var waypointBeingEdited: GPXWaypoint = GPXWaypoint()
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        weatherManger.delegate = self
        
        guard let button = control as? UIButton else { return }
        
        guard let map = mapView as? GPXMapView else { return }
        
        guard let polyLine = route.polyline as? MKPolyline else { return }
        
        guard let waypoint = view.annotation as? GPXWaypoint else { return }
        
        self.weatherManger.getGroupAPI(latitude: waypoint.latitude!, longitude: waypoint.longitude!) { [weak self] result in
            
            self?.weatherdata = result
            
            DispatchQueue.main.async {
                markMarkers()
            }
            
        }
    func markMarkers() {
        
        switch button.tag {
            
        case kDeleteWaypointButtonTag:
            
            guard let weatherdata = weatherdata else { return }
            
            let destination = "\(destination?.thoroughfare ?? "鄉間小路")"
            let distance = "\(self.route.distance.toDistance())"
            let time = "\((self.route.expectedTravelTime/3).tohmsTimeFormat())"
            let weather = "\(weatherdata.weather[0].main)"
            
            let alertSheet = UIAlertController(title: "\(destination)", message: "距離 = \(distance), 時間 = \(time), 天氣 = \(weather) ", preferredStyle: .actionSheet)
            
            let removeOption = UIAlertAction(title: NSLocalizedString("移除", comment: "no comment"), style: .destructive) { _ in
                map.removeWaypoint(waypoint)
                map.removeOverlays(map.overlays)
            }
            
            let routeName = UIAlertAction(title: "導航至該地點", style: .default) {_ in
               
                self.route.polyline.title = "one"
                
                if polyLine == nil {
                    LKProgressHUD.showFailure(text: "別鬧喔，快回家洗洗睡")
                } else {
                    map.addOverlay(polyLine, level: MKOverlayLevel.aboveRoads)
                }
                
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: "no comment"), style: .cancel) { _ in }
            
            alertSheet.addAction(routeName)
            alertSheet.addAction(removeOption)
            alertSheet.addAction(cancelAction)
            
            
            guard let firstView = UIApplication.shared.windows.first else {
                return LKProgressHUD.showFailure(text: "無法顯示")
            }
            
            //  Optional<UIViewController>
//                ▿ some : <RideTogether.LoginViewController: 0x108942150>
            
            self.present(alertSheet, animated: true, completion: nil)
           
            present(alertSheet, animated: true, completion: nil)
//            showAlertAction(title: nil, message: nil, preferredStyle: .actionSheet, actions: [routeName, removeOption, cancelAction])
            
            // ▿ Optional<UIViewController>
//                ▿ some : <RideTogether.TabBarController: 0x12982c800>
            
            
            // iPad specific code
            
            alertSheet.popoverPresentationController?.sourceView = firstView.rootViewController?.view

            let xOrigin = (firstView.rootViewController?.view.bounds.width)! / 2

            let popoverRect = CGRect(x: xOrigin, y: 0, width: 1, height: 1)

            alertSheet.popoverPresentationController?.sourceRect = popoverRect

            alertSheet.popoverPresentationController?.permittedArrowDirections = .unknown
            
            
        case kEditWaypointButtonTag:
            print("[calloutAccesoryControlTapped: EDIT] editing waypoint with name \(waypoint.name ?? "''")")
            
            let indexofEditedWaypoint = map.session.waypoints.firstIndex(of: waypoint)
            
    
            let alertController = UIAlertController(title: "請輸入座標說明", message: nil, preferredStyle: .alert)
            
            alertController.addTextField { (textField) in
                textField.text = waypoint.title
                textField.tintColor = .B5
                textField.clearButtonMode = .always
            }
            let saveAction = UIAlertAction(title: NSLocalizedString("儲存", comment: "no comment"), style: .default) { _ in
                print("Edit waypoint alert view")
                self.waypointBeingEdited.title = alertController.textFields?[0].text
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("取消", comment: "no comment"), style: .cancel) { _ in }
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            let firstView = UIApplication.shared.windows.first
//            firstView!.rootViewController?.present(alertController, animated: true)
            present(alertController, animated: true, completion: nil)
            self.waypointBeingEdited = waypoint
            
        default:
            print("[calloutAccesoryControlTapped ERROR] unknown control")
            LKProgressHUD.showFailure(text: "網路問題，無法顯示")
        }
     }
    }
    
    enum GPXTrackingStatus {
        
        case notStarted
        
        case tracking
        
        case paused
    }
    
    private var gpxTrackingStatus: GPXTrackingStatus = GPXTrackingStatus.notStarted {
        
        didSet {
            
            switch gpxTrackingStatus {
                
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
        button.backgroundColor = .B5
        button.tintColor = .B2
        button.setTitle("開始", for: .normal)
        button.titleLabel?.font = UIFont.regular(size: 18)
        button.titleLabel?.textAlignment = .center
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
        return button
    }()
    
    private lazy var weatherButton: UIButton = {
        let button = UIButton()
        button.tintColor = .B5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .B2?.withAlphaComponent(0.75)
        let image = UIImage(systemName: "info.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 24
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
        return button
    }()
    
    private lazy var followUserButton: UIButton = {
        
        let button = UIButton()
        button.tintColor = .B5
        button.backgroundColor = .B2?.withAlphaComponent(0.75)
        let image = UIImage(systemName: "location.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
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
        button.addTarget(self, action: #selector(JourneyViewController.addPinAtMyLocation), for: .touchUpInside)
        return button
    }()
    
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
    var hasWaypoints: Bool = false

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
 
        let view = UIStackView(arrangedSubviews: [followUserButton, pinButton, sendSMSButton, weatherButton])
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
    
    var altitudeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.textColor = UIColor.B5
        return label
    }()
    
    var speedLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.textColor = UIColor.B5
        return label
    }()
    
    var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textColor = UIColor.B5
        label.text = "00:00"
        return label
    }()
    
    private lazy var totalTrackedDistanceLabel: DistanceLabel = {
        let distaneLabel = DistanceLabel()
        distaneLabel.textAlignment = .right
        distaneLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        distaneLabel.textColor = UIColor.B5
        distaneLabel.distance = 0.00
        return distaneLabel
    }()
    
    private lazy var currentSegmentDistanceLabel: DistanceLabel = {
        let distaneLabel = DistanceLabel()
        distaneLabel.textAlignment = .right
        distaneLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        distaneLabel.textColor = UIColor.B5
        distaneLabel.distance = 0.00
        return distaneLabel
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
        
        self.locationManager.requestAlwaysAuthorization()
        
        addSegment()
        
        completer.delegate = self
        
        completer.region = map.region
        
        routeVc.delegate = self
        
        mapViewDelegate.route.polyline.title = "two"
        
        backToJourneyButton()
        
    }
    
    func backToJourneyButton() {
        let button = UbikeBtn(frame: CGRect(x: 245, y: 550, width: 50, height: 50) )
        button.addTarget(self, action: #selector(presentBike), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func presentBike(_ sender: UIButton) {
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "UbikeViewController") as? UbikeViewController {
            let navBar = UINavigationController.init(rootViewController: rootVC)
            if #available(iOS 15.0, *) {
                if let presentVc = navBar.sheetPresentationController {
                    presentVc.detents = [.medium(), .large()]
                    self.navigationController?.present(navBar, animated: true, completion: .none)
                }
            } else { }}
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if gpxTrackingStatus == .tracking {
            bikeLottieView.play()
            waveLottieView.play()
        }
    }
    private func addConstraints() {
      buttonPanelView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
      buttonPanelView.bottomAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
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
    
    // 切換選項時執行動作的方法
    @objc func onChange(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0 :
            map.mapType = .mutedStandard
            map.showsTraffic = true
            speedLabel.textColor = .B5
            timeLabel.textColor = .B5
            altitudeLabel.textColor = .B5
            currentSegmentDistanceLabel.textColor = .B5
            totalTrackedDistanceLabel.textColor = .B5
        case 1 :
            map.mapType = .hybridFlyover
            map.showsTraffic = true
            speedLabel.textColor = .B2
            timeLabel.textColor = .B2
            altitudeLabel.textColor = .B2
            currentSegmentDistanceLabel.textColor = .B2
            totalTrackedDistanceLabel.textColor = .B2
        default :
            map.mapType = .standard
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let trakerRadius = trackerButton.frame.height / 2
        
        let otherRadius = saveButton.frame.height / 2
        
        followUserButton.roundCorners(cornerRadius: otherRadius)
        
        sendSMSButton.roundCorners(cornerRadius: otherRadius)
        
        weatherButton.roundCorners(cornerRadius: otherRadius)
        
        trackerButton.roundCorners(cornerRadius: trakerRadius)
        
        saveButton.roundCorners(cornerRadius: otherRadius)
        
        resetButton.roundCorners(cornerRadius: otherRadius)
        
        pinButton.roundCorners(cornerRadius: otherRadius)
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
        
        map.addGestureRecognizer(UILongPressGestureRecognizer( target: self,
                                                               action: #selector(JourneyViewController.addPinAtTappedLocation(_:))))
    
        self.view.addSubview(map)
        
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
        
        if let rootVC = storyboard?.instantiateViewController(withIdentifier: "RouteSelectionViewController") as? RouteSelectionViewController {
            let navBar = UINavigationController.init(rootViewController: rootVC)
            if #available(iOS 15.0, *) {
                if let presentVc = navBar.sheetPresentationController {
                    presentVc.detents = [ .medium(), .large()]
                    self.navigationController?.present(navBar, animated: true, completion: .none)
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    @objc func saveButtonTapped(withReset: Bool = false) {
        
        if gpxTrackingStatus == .notStarted && !self.hasWaypoints { return }
        
        let date = Date()
        
        let time = TimeFormater.preciseTimeForFilename.dateToString(time: date)
        
        // MARK: 要改
//        let defaultFileName = "\(userName)紀錄了從..."
        
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
            // "2022-04-10_04-21"
            print ("1\(fileName)1")
            
            self.lastGpxFilename = fileName!
            
            if let fileName = fileName {
                
                GPXFileManager.save( fileName, gpxContents: gpxString)
            
            print ("2\(fileName)2")
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
        
        let sheet = showAlertAction(title: nil, message: nil, preferredStyle: .actionSheet, actions: [cancelOption, resetOption])
        
        // iPad specific code
        
        sheet.popoverPresentationController?.sourceView = self.view
                
        let xOrigin = self.view.bounds.width / 2
        
        let popoverRect = CGRect(x: xOrigin, y: 0, width: 1, height: 1)
            
        sheet.popoverPresentationController?.sourceRect = popoverRect
                
        sheet.popoverPresentationController?.permittedArrowDirections = .up
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
            buttonStackView.widthAnchor.constraint(equalToConstant: 230),
            
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
        buttonStackView.addArrangedSubview(weatherButton)
        
        leftStackView.addArrangedSubview(saveButton)
        leftStackView.addArrangedSubview(trackerButton)
        leftStackView.addArrangedSubview(resetButton)
        
        // MARK: button constraint
        
        NSLayoutConstraint.activate([
            
            followUserButton.heightAnchor.constraint(equalToConstant: 50),
            
            followUserButton.widthAnchor.constraint(equalToConstant: 50),
            
            pinButton.heightAnchor.constraint(equalToConstant: 50),
            
            pinButton.widthAnchor.constraint(equalToConstant: 50),
            
            sendSMSButton.widthAnchor.constraint(equalToConstant: 50),
            
            sendSMSButton.heightAnchor.constraint(equalToConstant: 50),
            
            weatherButton.widthAnchor.constraint(equalToConstant: 50),
            
            weatherButton.heightAnchor.constraint(equalToConstant: 50),
            
            trackerButton.heightAnchor.constraint(equalToConstant: 70),
            
            trackerButton.widthAnchor.constraint(equalToConstant: 70),
            
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            saveButton.widthAnchor.constraint(equalToConstant: 50),
            
            resetButton.heightAnchor.constraint(equalToConstant: 50),
            
            resetButton.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        trackerButton.addTarget(self, action: #selector(trackerButtonTapped), for: .touchUpInside)
        
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        
        followUserButton.addTarget(self, action: #selector(followButtonTroggler), for: .touchUpInside)
        
        sendSMSButton.addTarget(self, action: #selector(sendSMS), for: .touchUpInside)
        
        weatherButton.addTarget(self, action: #selector(searchLocation), for: .touchUpInside)
    }
    func setUpLabels() {
        
        map.addSubview( altitudeLabel)
        // 座標 - 改成時速
        altitudeLabel.frame = CGRect(x: 10, y: 80, width: 200, height: 100)
        
        map.addSubview(speedLabel)
        
        speedLabel.frame = CGRect(x: 10, y: 50, width: 200, height: 100)
        
        map.addSubview(timeLabel)
        // 時間
        timeLabel.frame = CGRect(x: UIScreen.width - 110, y: 30, width: 100, height: 80)
        
        map.addSubview(totalTrackedDistanceLabel)
        // 距離
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
    
    //MARK: 桌面更新資料
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let newLocation = locations.first!
        
        let altitude = newLocation.altitude.toAltitude()
        
        let text = "高度 : \(altitude)"
        
        altitudeLabel.text = text
        
        let rUnknownSpeedText = "0.00"
        
        //  MARK: Update_speed
        
        speedLabel.text = "時速 : \((newLocation.speed < 0) ? rUnknownSpeedText : newLocation.speed.toSpeed())"
        
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
//        map.updateHeading() // updates heading view's rotation
    }
}
