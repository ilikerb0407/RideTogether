//
//  JourneyViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreLocation
import MapKit
import UIKit
import CoreGPX

class JourneyViewController: BaseViewController {
    
    // MARK: - UI Components
    
    private lazy var mapView: GPXMapView = {
        let map = GPXMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()

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

    private lazy var pinButton: UIButton = {
        let button = BottomButton()
        let mappin = UIImage(systemName: "mappin.and.ellipse", withConfiguration: imagePointSize)
        button.setImage(mappin, for: UIControl.State())
        button.addTarget(self, action: #selector(addPinAtMyLocation), for: .touchUpInside)
        return button
    }()

    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [followUserButton, pinButton, showBike])
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

    // MARK: - Labels
    private let altitudeLabel: RegularLabel = {
        let label = RegularLabel()
        label.text = "高度 : --"
        return label
    }()

    private let speedLabel: RegularLabel = {
        let label = RegularLabel()
        label.text = "時速 : --"
        return label
    }()
    private let timeLabel = TimeLabel()
    private let totalTrackedDistanceLabel = DistanceLabel()
    private let currentSegmentDistanceLabel = DistanceLabel()
    
    private lazy var leftLabelsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [altitudeLabel, speedLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var rightLabelsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [timeLabel, totalTrackedDistanceLabel, currentSegmentDistanceLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .trailing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Properties

    private var hasWaypoints: Bool = false
    private let mapPin = MapPin()
    private let locationManager = LocationManager()
    let imagePointSize = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)

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
                timeLabel.text = stopWatch.elapsedTimeString
                mapView.resetMapAndRecordingSession()
                totalTrackedDistanceLabel.distance = mapView.session.totalTrackedDistance
                currentSegmentDistanceLabel.distance = mapView.session.currentSegmentDistance

            case .tracking:
                trackerButton.setTitle("暫停", for: .normal)
                stopWatch.start()

            case .paused:
                trackerButton.setTitle("繼續", for: .normal)
                stopWatch.stop()
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

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        LKProgressHUD.dismiss()

        locationManager.delegate = self
        locationManager.setUpLocationManager()
        stopWatch.delegate = self

        setUpMapView()
        setUpMap()
        setUpLabels()
        setUpButtonsStackView()
        addMapTypeSegment()

        navigationController?.isNavigationBarHidden = true

    }
    
    
    func setUpButtonsStackView() {
        view.addSubview(buttonStackView)
        view.addSubview(leftStackView)

        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 80),

            leftStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            leftStackView.widthAnchor.constraint(equalToConstant: 100),
            leftStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -200),
            leftStackView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    func setUpLabels() {
        view.addSubview(leftLabelsStackView)
        view.addSubview(rightLabelsStackView)

        NSLayoutConstraint.activate([
            // Pinned below the map-type segment control (which sits at
            // safeArea.top + 10, height 30) with a 10pt gap, so the two
            // can never overlap regardless of device size.
            leftLabelsStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            leftLabelsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            leftLabelsStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 200),

            rightLabelsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            rightLabelsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            rightLabelsStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
        ])
    }
}

// MARK: - Map Setup

extension JourneyViewController {
    
    func setUpMapView() {
        mapView.delegate = mapPin
        mapView.showsUserLocation = true

        // 將 mapView 加入目前 View 的最底層
        view.insertSubview(mapView, at: 0)

        // 開啟完整版的 Auto Layout 約束，全螢幕鋪滿
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setUpMap() {
        setBeginningRegion()

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
        segment.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segment)

        NSLayoutConstraint.activate([
            segment.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            segment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segment.widthAnchor.constraint(equalToConstant: 150),
            segment.heightAnchor.constraint(equalToConstant: 30),
        ])
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

    @objc func saveButtonTapped() {
        if trackingStatus == .notStarted, !hasWaypoints { return }

        let alertController = UIAlertController(title: "儲存路線", message: "路線標題", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.clearButtonMode = .always
            textField.text = "從..到.."
        }

        let saveAction = UIAlertAction(title: "儲存", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let gpxString = self.mapView.exportToGPXString()
            guard let fileName = alertController.textFields?[0].text else { return }

            GPXFileManager.save(fileName, gpxContents: gpxString) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.presentClearRouteConfirmation()
                    case .failure:
                        break
                    }
                }
            }
        }

        alertController.addAction(saveAction)
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alertController, animated: true)
    }

    private func presentClearRouteConfirmation() {
        let alert = UIAlertController(
            title: "儲存成功",
            message: "要清除目前記錄的路線嗎？如果要繼續記錄同一趟路線可以選擇保留。",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "清除路線", style: .destructive) { [weak self] _ in
            self?.trackingStatus = .notStarted
        })

        alert.addAction(UIAlertAction(title: "保留繼續記錄", style: .cancel))

        present(alert, animated: true)
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
            mapView.removeNavigationOverlays()
            mapView.addWaypointAtViewPoint(gesture.location(in: mapView))
            hasWaypoints = true
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
