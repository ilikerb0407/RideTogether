//
//  JourneyViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import CoreLocation
import Lottie
import MapKit
import MessageUI
import UIKit

class JourneyViewController: BaseViewController {
    // MARK: - Outlets

    @IBOutlet var mapView: GPXMapView!

    // MARK: - Properties

    private var hasWaypoints: Bool = false

    private let mapPin = MapPin()

    private let locationManager = LocationManager()

    // MARK: - Tracking State Machine

    enum GPXTrackingStatus {
        case notStarted
        case tracking
        case paused
    }

    private var trackingStatus: GPXTrackingStatus = .notStarted {
        didSet {
            switch trackingStatus {
            case .notStarted:
                trackerButton.setTitle("開始", for: .normal)
                stopWatch.reset()
                waveLottieView.isHidden = true
                bikeLottieView.isHidden = false
                timeLabel.text = stopWatch.elapsedTimeString
                mapView.clearMap()
                totalTrackedDistanceLabel.distance = mapView.session.totalTrackedDistance
                currentSegmentDistanceLabel.distance = mapView.session.currentSegmentDistance

            case .tracking:
                trackerButton.setTitle("暫停", for: .normal)
                stopWatch.start()
                waveLottieView.isHidden = false
                waveLottieView.play()
                bikeLottieView.play()

            case .paused:
                trackerButton.setTitle("繼續", for: .normal)
                stopWatch.stop()
                waveLottieView.isHidden = true
                bikeLottieView.stop()
                mapView.startNewTrackSegment()
            }
        }
    }

    private var followUser: Bool = true {
        didSet {
            let imageName = followUser ? "location.fill" : "location"
            let image = UIImage(systemName: imageName, withConfiguration: imagePointSize)
            followUserButton.setImage(image, for: .normal)
            if followUser {
                mapView.setCenter(mapView.userLocation.coordinate, animated: true)
            }
        }
    }

    // MARK: - UI Components

    let imagePointSize = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)

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
        let image = UIImage(systemName: "location.fill", withConfiguration: imagePointSize)
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
        let image = UIImage(systemName: "info.circle", withConfiguration: imagePointSize)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(presentRouteSelectionViewController), for: .touchUpInside)
        return button
    }()

    private lazy var sendSMSButton: UIButton = {
        let button = BottomButton()
        let image = UIImage(systemName: "message", withConfiguration: imagePointSize)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(sendSMS), for: .touchUpInside)
        return button
    }()

    private lazy var pinButton: UIButton = {
        let button = BottomButton()
        let mappin = UIImage(systemName: "mappin.and.ellipse", withConfiguration: imagePointSize)
        button.setImage(mappin, for: UIControl.State())
        button.addTarget(self, action: #selector(addPinAtMyLocation), for: .touchUpInside)
        return button
    }()

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
            view.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -45),
        ])
        view.contentMode = .scaleAspectFit
        view.play()
        return view
    }()

    // 底部橫排按鈕列
    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [followUserButton, pinButton, sendSMSButton, presentViewControllerButton, showBike])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .equalSpacing
        view.alignment = .bottom
        return view
    }()

    // 左側垂直操作按鈕列
    private lazy var leftStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [saveButton, trackerButton, resetButton])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 8
        view.distribution = .equalSpacing
        view.alignment = .center
        return view
    }()

    // MARK: - Labels

    private var altitudeLabel = LeftLabel()
    private var speedLabel = LeftLabel()
    private var timeLabel = RightLabel()
    private var totalTrackedDistanceLabel = DistanceLabel()
    private lazy var currentSegmentDistanceLabel = DistanceLabel()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        LKProgressHUD.dismiss()

        locationManager.delegate = self
        locationManager.setUpLocationManager()
        stopWatch.delegate = self

        setUpMap()
        setUpLabels()
        setUpButtonsStackView()
        addMapTypeSegment()

        mapPin.route.polyline.title = "ride"
        navigationController?.isNavigationBarHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if trackingStatus == .tracking {
            bikeLottieView.play()
            waveLottieView.play()
        }
    }
}

// MARK: - Map Setup

extension JourneyViewController {
    func setUpMap() {
        setBeginningRegion()
        mapView.delegate = mapPin
        mapView.showsUserLocation = true

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(stopFollowingUser(_:)))
        panGesture.delegate = self
        mapView.addGestureRecognizer(panGesture)
        mapView.rotationGesture.delegate = self
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(addPinAtTappedLocation(_:))))
    }

    func setBeginningRegion() {
        let center = locationManager.location?.coordinate ??
            CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }

    func addMapTypeSegment() {
        let segment = UISegmentedControl(items: ["一般", "衛星"])
        segment.setTitleTextAttributes([.foregroundColor: UIColor.B2 ?? UIColor.B1 as Any], for: .normal)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.B5 ?? UIColor.B1 as Any], for: .selected)
        segment.backgroundColor = UIColor.B5
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(onMapTypeChanged), for: .valueChanged)
        segment.frame.size = CGSize(width: 150, height: 30)
        segment.center = CGPoint(x: 80, y: 65)
        view.addSubview(segment)
    }

    @objc func onMapTypeChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = .mutedStandard
            [speedLabel, timeLabel, altitudeLabel, currentSegmentDistanceLabel, totalTrackedDistanceLabel].forEach { $0.textColor = .B5 }
        case 1:
            mapView.mapType = .hybridFlyover
            [speedLabel, timeLabel, altitudeLabel, currentSegmentDistanceLabel, totalTrackedDistanceLabel].forEach { $0.textColor = .B2 }
        default:
            mapView.mapType = .standard
        }
    }
}

// MARK: - UI Setup

extension JourneyViewController {
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
            leftStackView.heightAnchor.constraint(equalToConstant: 200),
        ])
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

// MARK: - Actions

extension JourneyViewController {
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
        if trackingStatus == .notStarted, !hasWaypoints { return }

        let alertController = UIAlertController(title: "儲存路線", message: "路線標題", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.clearButtonMode = .always
            textField.text = "從..到.."
        }

        let saveAction = UIAlertAction(title: "儲存", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let gpxString = self.mapView.exportToGPXString()
            if let fileName = alertController.textFields?[0].text {
                GPXFileManager.save(fileName, gpxContents: gpxString)
            }
            if withReset {
                self.trackingStatus = .notStarted
            }
        }

        alertController.addAction(saveAction)
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alertController, animated: true)
    }

    @objc func resetButtonTapped() {
        if trackingStatus == .notStarted { return }

        let sheet = UIAlertController()
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.addAction(UIAlertAction(title: "重置", style: .destructive) { [weak self] _ in
            self?.trackingStatus = .notStarted
            UIView.animate(withDuration: 0.3) {
                self?.saveButton.alpha = 0.5
                self?.resetButton.alpha = 0.5
            }
        })
        present(sheet, animated: true)
    }

    @objc func followButtonToggle() {
        followUser = !followUser
    }

    @objc func stopFollowingUser(_: UIPanGestureRecognizer) {
        if followUser { followUser = false }
    }

    @objc func addPinAtMyLocation() {
        let altitude = locationManager.location?.altitude
        let waypoint = GPXWaypoint(
            coordinate: locationManager.location?.coordinate ?? mapView.userLocation.coordinate,
            altitude: altitude
        )
        mapView.addWaypoint(waypoint)
        hasWaypoints = true
    }

    @objc func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            mapView.clearOverlays()
            mapView.addWaypointAtViewPoint(gesture.location(in: mapView))
            hasWaypoints = true
        }
    }

    @objc func sendSMS() {
        LKProgressHUD.show()
        let msgViewController = MFMessageComposeViewController()
        msgViewController.messageComposeDelegate = self
        msgViewController.recipients = ["請輸入電話號碼"]
        msgViewController.body = "傳送我的位置 經度 : \(locationManager.location!.coordinate.longitude), 緯度: \(locationManager.location!.coordinate.latitude)"
        if MFMessageComposeViewController.canSendText() {
            present(msgViewController, animated: true)
            LKProgressHUD.dismiss()
        }
    }

    func checkLocationServicesStatus() {
        if !CLLocationManager.locationServicesEnabled() {
            displayLocationServicesDisabledAlert()
            if #available(iOS 14.0, *) {
                if ![.authorizedAlways, .authorizedWhenInUse].contains(locationManager.authorizationStatus) {
                    displayLocationServicesDeniedAlert()
                    return
                }
            }
            displayLocationServicesDeniedAlert()
        }
    }

    func gestureRecognizer(_: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool
    {
        return true
    }
}

// MARK: - StopWatch Delegate

extension JourneyViewController: StopWatchDelegate {
    func stopWatch(_: StopWatch, didUpdateElapsedTimeString elapsedTimeString: String) {
        timeLabel.text = elapsedTimeString
    }
}

// MARK: - CLLocationManager Delegate

extension JourneyViewController: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.first!
        altitudeLabel.text = "高度 : \(newLocation.altitude.toAltitude())"
        speedLabel.text = "時速 : \((newLocation.speed < 0) ? "0.00" : newLocation.speed.toSpeed())"

        if followUser {
            mapView.setCenter(newLocation.coordinate, animated: true)
        }

        if trackingStatus == .tracking {
            mapView.addPointToCurrentTrackSegmentAtLocation(newLocation)
            totalTrackedDistanceLabel.distance = mapView.session.totalTrackedDistance
            currentSegmentDistanceLabel.distance = mapView.session.currentSegmentDistance
        }
    }

    func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.heading = newHeading
        mapView.updateHeading()
    }
}
