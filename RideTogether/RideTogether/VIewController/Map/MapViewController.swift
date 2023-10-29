/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2023/10/27.
/// Copyright © 2023 Cathay United Bank. All rights reserved.

import UIKit
import Combine
import MapKit

internal class MapViewController: UIViewController {
    
	var viewModel: MapViewModel

    private let mapView: MKMapView

	init() {
		viewModel = .init()
        mapView = .init()
		super.init(nibName: nil, bundle: nil)
        setupUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}	
						    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Home"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }    
}

extension MapViewController {
    private func setupUI() {
        addSubviews()
        setUpConstraints()
        setUpStyle()
    }

    private func addSubviews() {
        [mapView].forEach {
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
        ])
    }

    private func setUpStyle() {
        mapView.showsUserLocation = true
    }
}
