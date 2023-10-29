/// 騎乘頁面
///
/// Created by TWINB00591630 on 2023/10/30.
/// Copyright © 2023 Cathay United Bank. All rights reserved.

import Combine
import MapKit
import UIKit

internal class KFMapViewController: UIViewController {

    var viewModel: KFMapViewModel

    private var cancellables: Set<AnyCancellable>

    private let mapView: MKMapView

    private let locationManager: CLLocationManager

    private let startBtn: UIButton

    init() {
        viewModel = .init()
        cancellables = .init()
        mapView = .init()
        locationManager = .init()
        startBtn = .init()
        super.init(nibName: nil, bundle: nil)
        setupUI()
        setupBinding()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

extension KFMapViewController {
    private func setupUI() {
        addSubviews()
        setUpConstraints()
        setUpStyle()
        setupEvent()
    }

    private func addSubviews() {
        [mapView, startBtn].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),

            startBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            startBtn.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            startBtn.widthAnchor.constraint(equalToConstant: 80),
            startBtn.heightAnchor.constraint(equalToConstant: 80),
        ])

        startBtn.layer.cornerRadius = 40
        startBtn.clipsToBounds = true
    }

    private func setUpStyle() {
        mapView.showsUserLocation = true
        let taipeiCoordinate = CLLocationCoordinate2D(latitude: locationManager.location?.coordinate.latitude ?? 37, longitude: locationManager.location?.coordinate.longitude ?? 131)
        let region = MKCoordinateRegion(center: taipeiCoordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)

        startBtn.setTitle("開始", for: .normal)
        startBtn.setTitleColor(.white, for: .normal)
        startBtn.backgroundColor = .darkGray
        startBtn.isUserInteractionEnabled = true
    }

    private func setupEvent() {
        startBtn.addTarget(self, action: #selector(startRecord), for: .touchUpInside)
    }

    @objc final func startRecord() {
        viewModel.start()
    }

    private func setupBinding() {
        viewModel.tapStartSubject
            .sink { _ in
                print("開始")
            }.store(in: &cancellables)
    }
}
