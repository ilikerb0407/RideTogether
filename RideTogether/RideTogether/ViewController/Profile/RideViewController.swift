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
    
    
    @IBOutlet weak var map2: GPXMapView!
    
    var lastGpxFilename: String = ""
    
    // MARK: == === ====

//    func showMap() {
//        let button = ShowMapButton(frame: CGRect(x: 30, y: 30, width: 50, height: 50))
//        button.addTarget(self, action: #selector(addRoute), for: .touchUpInside)
//        view.addSubview(button)
//    }
//
//    @objc func addRoute() {
//        guard let points = Park.plist("Taipei1") as? [String] else { return }
//
//        let cgPoints = points.map { NSCoder.cgPoint(for: $0) }
//        let coords = cgPoints.map { CLLocationCoordinate2D(
//            latitude: CLLocationDegrees($0.x),
//            longitude: CLLocationDegrees($0.y))
//        }
//        let myPolyline = MKPolyline(coordinates: coords, count: coords.count)
//        print ("===========Pleaseprint")
//        map2.addOverlay(myPolyline)
//    }
    
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
        
        map2.importFromGPXRoot(gpxRoot)
        
        map2.regionToGPXExtent()
        
    }
    

    // MARK: - Polyline -
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        updatePolylineColor()
    }
    
    func updatePolylineColor() {
        
        for overlay in map2.overlays where overlay is MKPolyline {
            
            map2.removeOverlay(overlay)
            
            map2.addOverlay(overlay)
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
    
    enum GpxTrackingStatus {
        
        case notStarted
        
        case tracking
        
        case paused
    }
    
    private lazy var bikeLottieView: AnimationView = {
            let view = AnimationView(name: "49908-bike-ride")
            view.loopMode = .loop
        self.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 100),
            view.heightAnchor.constraint(equalToConstant: 100),
            view.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            view.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
            view.contentMode = .scaleAspectFit
            view.play()
            
            return view
        }()
    
    private var gpxTrackingStatus: GpxTrackingStatus = GpxTrackingStatus.notStarted {
        
        didSet {
            
            switch gpxTrackingStatus {
                
            case .notStarted:
                
                trackerButton.setTitle("開始", for: .normal)
                
                stopWatch.reset()
                
                waveLottieView.isHidden = true
                
                bikeLottieView.isHidden = false
                
                timeLabel.text = stopWatch.elapsedTimeString
                
                map2.clearMap()
                
                totalTrackedDistanceLabel.distance = (map2.session.totalTrackedDistance)
                
                currentSegmentDistanceLabel.distance = (map2.session.currentSegmentDistance)
                
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
                
                self.map2.startNewTrackSegment()
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
                
                map2.setCenter((map2.userLocation.coordinate), animated: true)
                
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
    
    
    private lazy var sendSMSButton: UIButton = {
        let button = UIButton()
        button.tintColor = .B5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .B2?.withAlphaComponent(0.75)
        let image = UIImage(systemName: "message",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 24
        return button
    }()
        
    private lazy var followUserButton: UIButton = {
        
        let button = UIButton()
        button.tintColor = .B5
        button.backgroundColor = .B2?.withAlphaComponent(0.75)
        let image = UIImage(systemName: "location.fill",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        button.setImage(image, for: .normal)
        return button
    }()
    
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
 
        let view = UIStackView(arrangedSubviews: [followUserButton, sendSMSButton])
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

            let usersCoordinate = CLLocation(latitude: map2.userLocation.coordinate.latitude, longitude: map2.userLocation.coordinate.longitude)
            let bikeStopCoordinate = CLLocation(latitude: Double(bike.lat), longitude: Double(bike.lng))

            let distance = usersCoordinate.distance(from: bikeStopCoordinate)
       
                    if  distance < 1000 {
                        map2.addAnnotation(annotation)
                    }
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar(title: "查看路線")
        
        locationManager.delegate = self
        
        stopWatch.delegate = self
        
        setUpMap()
        
        setUpButtonsStackView()
        
        setUpLabels()
        
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
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let trakerRadius = trackerButton.frame.height / 2
        
        let otherRadius = saveButton.frame.height / 2
        
        followUserButton.roundCorners(cornerRadius: otherRadius)
        
        sendSMSButton.roundCorners(cornerRadius: otherRadius)
        
        trackerButton.roundCorners(cornerRadius: trakerRadius)
        
        saveButton.roundCorners(cornerRadius: otherRadius)
        
        resetButton.roundCorners(cornerRadius: otherRadius)
        
    }
    
    // MARK: - Action
    
    func setUpMap() {
    
        map2.delegate = bikeViewDelegate
        
        map2.rotationGesture.delegate = self
        
        self.view.addSubview(map2)
        
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
        
        let defaultFileName = "\(userName) 紀錄了從..到.."
        
        let alertController = UIAlertController(title: "Save Record",
                                                message: "Please enter the title",
                                                preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: { (textField) in
            
            textField.clearButtonMode = .always
            
            textField.text =  defaultFileName
        })
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .default) { _ in
            
            let gpxString = self.map2.exportToGPXString()
            
            guard let fileName = alertController.textFields?[0].text else { return }

            self.lastGpxFilename = fileName
  
            GPXFileManager.save( fileName, gpxContents: gpxString)
            self.lastGpxFilename = fileName
     
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
        view.addSubview(leftStackView)
        
        NSLayoutConstraint.activate([
            
            buttonStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 80),
            
            buttonStackView.widthAnchor.constraint(equalToConstant: 120),
            
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            
            buttonStackView.heightAnchor.constraint(equalToConstant: 80),
            
            leftStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            
            leftStackView.widthAnchor.constraint(equalToConstant: 100),
            
            leftStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -200),
            
            leftStackView.heightAnchor.constraint(equalToConstant: 200)
        ] )
        
        buttonStackView.addArrangedSubview(followUserButton)
        
        buttonStackView.addArrangedSubview(sendSMSButton)
        
        leftStackView.addArrangedSubview(saveButton)
        
        leftStackView.addArrangedSubview(trackerButton)
        
        leftStackView.addArrangedSubview(resetButton)
        
        // MARK: button constraint
        
        NSLayoutConstraint.activate([
            
            followUserButton.heightAnchor.constraint(equalToConstant: 50),
            
            followUserButton.widthAnchor.constraint(equalToConstant: 50),
            
            sendSMSButton.widthAnchor.constraint(equalToConstant: 50),
            
            sendSMSButton.heightAnchor.constraint(equalToConstant: 50),
            
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
    
    func setUpLabels() {

        map2.addSubview( altitudeLabel)
        // 座標 - 改成時速
        altitudeLabel.frame = CGRect(x: 10, y: 90, width: 200, height: 100)
        
        map2.addSubview(speedLabel)
        
        speedLabel.frame = CGRect(x: 10, y: 60, width: 200, height: 100)
        
        map2.addSubview(timeLabel)
        // 時間
        timeLabel.frame = CGRect(x: UIScreen.width - 110, y: 30, width: 100, height: 80)
        
        map2.addSubview(totalTrackedDistanceLabel)
        // 距離
        totalTrackedDistanceLabel.frame = CGRect(x: UIScreen.width - 110, y: 90, width: 100, height: 30)
        
        map2.addSubview(currentSegmentDistanceLabel)
        
        currentSegmentDistanceLabel.frame = CGRect(x: UIScreen.width - 110, y: 120, width: 100, height: 30)
    }

func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    let newLocation = locations.first!
    
    let altitude = newLocation.altitude.toAltitude()
    
    let text = "高度 : \(altitude)"
    
    altitudeLabel.text = text
    
    let rUnknownSpeedText = "0.00"
    
    //  MARK: Update_speed
    
    speedLabel.text = "時速 : \((newLocation.speed < 0) ? rUnknownSpeedText : newLocation.speed.toSpeed())"
    
    if followUser {
        
        map2.setCenter(newLocation.coordinate, animated: true)
    }
    
    if gpxTrackingStatus == .tracking {
        
        map2.addPointToCurrentTrackSegmentAtLocation(newLocation)
        
        totalTrackedDistanceLabel.distance = map2.session.totalTrackedDistance
        
        currentSegmentDistanceLabel.distance = map2.session.currentSegmentDistance
    }
}
    
}
// MARK: - StopWatchDelegate methods

extension RideViewController: StopWatchDelegate {
    func stopWatch(_ stropWatch: StopWatch, didUpdateElapsedTimeString elapsedTimeString: String) {
        
        timeLabel.text = elapsedTimeString
    }
}
// MARK: - CLLocationManager Delegate -

extension RideViewController: CLLocationManagerDelegate {
  
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        map2.heading = newHeading // updates heading variable
        map2.updateHeading() // updates heading view's rotation
    }
}