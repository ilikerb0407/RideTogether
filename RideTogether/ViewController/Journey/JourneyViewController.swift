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
    private let stopWatch = StopWatch()

    @IBOutlet var mapView: GPXMapView!

    private var hasWaypoints: Bool = false

    private let mapPin = MapPin()

    private let locationManager = LocationManager()

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

                totalTrackedDistanceLabel.distance = (mapView.session.totalTrackedDistance)

                currentSegmentDistanceLabel.distance = (mapView.session.currentSegmentDistance)

            case .tracking:

                trackerButton.setTitle("暫停", for: .normal)

                self.stopWatch.start()

                locationManager.allowsBackgroundLocationUpdates = true

                waveLottieView.isHidden = false

                waveLottieView.play()

                bikeLottieView.play()

            case .paused:

                trackerButton.setTitle("繼續", for: .normal)

                locationManager.allowsBackgroundLocationUpdates = false
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
                                    withConfiguration: imagePointSize)

                followUserButton.setImage(image, for: .normal)

                mapView.setCenter(mapView.userLocation.coordinate, animated: true)

            } else {
                let image = UIImage(systemName: "location",
                                    withConfiguration: imagePointSize)
                followUserButton.setImage(image, for: .normal)
            }
        }
    }

    // MARK: - UIButton Setting -

    private(set) lazy var saveButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B5,
                                         tintColor: .B2,
                                         alpha: 0.5,
                                         cornerRadius: 25,
                                         title: "儲存",
                                         titleLabelFont: .systemFont(ofSize: 16) ,
                                         pointSize: 50)
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()

    private(set) lazy var trackerButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B5,
                                         tintColor: .B2,
                                         alpha: 0.5,
                                         cornerRadius: 35,
                                         title: "開始",
                                         titleLabelFont: .systemFont(ofSize: 16),
                                         imageName: nil)
        button.addTarget(self, action: #selector(trackerButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var resetButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B5, tintColor: .B2,
                                         alpha: 0.5,
                                         cornerRadius: 25,
                                         titleLabelFont: .systemFont(ofSize: 16),
                                         pointSize: 50)
        button.setTitle("重置", for: .normal)
        button.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        return button
    }()

    let imagePointSize = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)

    private lazy var followUserButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B2?.withAlphaComponent(0.75),
                                         tintColor: .B5,
                                         cornerRadius: 24,
                                         imageName: "location.fill",
                                         weight: .medium,
                                         pointSize: 30)
        button.addTarget(self, action: #selector(followButtonToggle), for: .touchUpInside)
        return button
    }()

    private lazy var showBike: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B2?.withAlphaComponent(0.75), alpha: 1, cornerRadius: 12, imageName: "ubike2.0", weight: .medium, pointSize: 10)
        button.addTarget(self, action: #selector(showBikeViewController), for: .touchUpInside)
        return button
    }()

    private lazy var presentViewControllerButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B2?.withAlphaComponent(0.75), tintColor: .B5, cornerRadius: 24, imageName: "info.circle", weight: .medium,  pointSize: 30)
        button.addTarget(self, action: #selector(presentRouteSelectionViewController), for: .touchUpInside)
        return button
    }()

    private lazy var sendSMSButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B2?.withAlphaComponent(0.75), tintColor: .B5, cornerRadius: 24, imageName: "message", weight: .medium,  pointSize: 30)
        button.addTarget(self, action: #selector(sendSMS), for: .touchUpInside)
        return button
    }()

    private lazy var pinButton: UIButton = {
        let button = ButtonFactory.build(backgroundColor: .B2?.withAlphaComponent(0.75), tintColor: .B5, cornerRadius: 24, imageName: "mappin.and.ellipse", weight: .medium,  pointSize: 30)
        button.addTarget(self, action: #selector(addPinAtMyLocation), for: .touchUpInside)
        return button
    }()

    @objc
    func addPinAtMyLocation() {
        let altitude = locationManager.location?.altitude
        let waypoint = GPXWaypoint(coordinate: locationManager.location?.coordinate ?? mapView.userLocation.coordinate, altitude: altitude)
        mapView.addWaypoint(waypoint)
        self.hasWaypoints = true
    }

    @objc
    func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            mapView.clearOverlays()
            let point: CGPoint = gesture.location(in: self.mapView)
            mapView.addWaypointAtViewPoint(point)
            self.hasWaypoints = true
        }
    }

    // MARK: - View -

    private lazy var waveLottieView: LottieAnimationView = {
        let view = LottieAnimationView(name: "circle")
        view.loopMode = .loop
        view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.center = leftStackView.center
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        self.view.bringSubviewToFront(leftStackView)
        return view
    }()

    private lazy var bikeLottieView: LottieAnimationView = {
        let view = LottieAnimationView(name: "bike-ride")
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

    private lazy var buttonStackView: UIStackView = {
        let buttonArray = [followUserButton, pinButton, sendSMSButton, presentViewControllerButton, showBike]
        let view = UIStackView(arrangedSubviews: buttonArray)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .equalSpacing
        view.alignment = .bottom
        return view
    }()

    private lazy var leftStackView: UIStackView = {
        let buttonArray = [saveButton, trackerButton, resetButton]
        let view = UIStackView(arrangedSubviews: buttonArray)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 8
        view.distribution = .equalSpacing
        view.alignment = .center
        return view
    }()

    // MARK: - Label -

    private var altitudeLabel = LabelFactory.build(text: "", font: .systemFont(ofSize: 20, weight: .regular), textColor: .B5, textAlignment: .left)

    private var speedLabel = LabelFactory.build(text: "", font: .systemFont(ofSize: 20, weight: .regular), textColor: .B5, textAlignment: .left)

    private var timeLabel = LabelFactory.build(text: "00:00", font: .boldSystemFont(ofSize: 30), textColor: .B5, textAlignment: .right)

    private var totalTrackedDistanceLabel = DistanceLabel()

    private lazy var currentSegmentDistanceLabel = DistanceLabel()

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        LKProgressHUD.dismiss()

        locationManager.delegate = self

        locationManager.setUpLocationManager()

        stopWatch.delegate = self

        setUpMap()

        setUpLabels()

        setUpButtonsStackView()

        addSegment()

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

    func addSegment() {
        let segmentControl = UISegmentedControl(items: ["一般", "衛星"])
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.B2 ?? UIColor.B1 as Any], for: .normal)
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.B5 ?? UIColor.B1 as Any], for: .selected)
        segmentControl.backgroundColor = UIColor.B5
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(onChange), for: .valueChanged)
        segmentControl.frame.size = CGSize(width: 150, height: 30)
        segmentControl.center = CGPoint(x: 80, y: 130)
        self.view.addSubview(segmentControl)
    }

    // TODO: test something
    @objc
    func onChange(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = .mutedStandard
            speedLabel.textColor = .B5
            timeLabel.textColor = .B5
            altitudeLabel.textColor = .B5
            currentSegmentDistanceLabel.textColor = .B5
            totalTrackedDistanceLabel.textColor = .B5
        case 1:
            mapView.mapType = .hybridFlyover
            speedLabel.textColor = .B2
            timeLabel.textColor = .B2
            altitudeLabel.textColor = .B2
            currentSegmentDistanceLabel.textColor = .B2
            totalTrackedDistanceLabel.textColor = .B2
        default:
            mapView.mapType = .standard
        }
    }

    // MARK: - Action -
    func setBeginningRegion() {
        // give default latitude & longtitude when user didn't accept tracking privacy
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

        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(addPinAtTappedLocation(_:))))
    }

    @objc
    func sendSMS() {
        let msgViewController = MFMessageComposeViewController()
        msgViewController.messageComposeDelegate = self
        msgViewController.recipients = ["請輸入電話號碼"]
        let lng = locationManager.location?.coordinate.longitude
        let lat = locationManager.location?.coordinate.latitude
        msgViewController.body = "傳送我的位置 經度 : \(lng ?? 25.04), 緯度: \(lat ?? 121.56)"

        if !MFMessageComposeViewController.canSendText() {
            print("SMS services are not available")
            LKProgressHUD.show(.failure("請開啟定位"))
        } else {
            LKProgressHUD.dismiss()
            self.present(msgViewController, animated: true, completion: nil)
        }
    }

    @objc
    func trackerButtonTapped() {
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

    @objc
    func saveButtonTapped(withReset: Bool = false) {
        if trackingStatus == .notStarted && !self.hasWaypoints {
            return
        }

        let defaultFileName = "從..到.."

        let alertController = UIAlertController(title: "儲存路線", message: "路線標題", preferredStyle: .alert)

        alertController.addTextField(configurationHandler: { textField in

            textField.clearButtonMode = .always

            textField.text = defaultFileName
        })

        let saveAction = UIAlertAction(title: "儲存",
                                       style: .default) { _ in

            let gpxString = self.mapView.exportToGPXString()

            let fileName = alertController.textFields?[0].text

            if let fileName {
                GPXFileManager.shared.save(fileName, gpxContents: gpxString)
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

    @objc
    func resetButtonTapped() {
        if trackingStatus == .notStarted {
            return
        }

        let cancelOption = UIAlertAction(title: "取消", style: .cancel)

        let resetOption = UIAlertAction(title: "重置", style: .destructive) { _ in
            self.trackingStatus = .notStarted

            UIView.animate(withDuration: 0.3) {
                self.saveButton.alpha = 0.5
                self.resetButton.alpha = 0.5
            }
        }

        let sheet = UIAlertController()
        sheet.addAction(cancelOption)
        sheet.addAction(resetOption)
        present(sheet, animated: true)
//        showAlertAction(title: nil, message: nil, preferredStyle: .actionSheet, actions: [cancelOption, resetOption])
    }

    @objc
    func followButtonToggle() {
        self.followUser = !self.followUser

        if followUser {
            // 开始更新位置
            locationManager.startUpdatingLocation()
            // 立即更新到当前位置
            if let currentLocation = locationManager.location?.coordinate {
                mapView.setCenter(currentLocation, animated: true)
            }
        } else {
            // 停止更新位置
            locationManager.stopUpdatingLocation()
        }
    }

    @objc
    func stopFollowingUser(_: UIPanGestureRecognizer) {
        if self.followUser {
            self.followUser = false
        }
    }

    func gestureRecognizer(_: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        true
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

            leftStackView.heightAnchor.constraint(equalToConstant: 200),
        ])

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
    func stopWatch(_: StopWatch, didUpdateElapsedTimeString elapsedTimeString: String) {
        timeLabel.text = "\(elapsedTimeString)"
    }
}

// MARK: - CLLocationManager Delegate -

extension JourneyViewController: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.first else { return }

        if followUser {
            mapView.setCenter(newLocation.coordinate, animated: true)
        }

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

    func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.heading = newHeading
        mapView.updateHeading()
    }
}
