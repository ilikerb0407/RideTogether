//
//  UBikeViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/14.
//

import CoreGPX
import CoreLocation
import MapKit
import UIKit

class UBikeViewController: BaseViewController, CLLocationManagerDelegate {
    var bikeData: [TPBikeModel] = []

    var taichungBikeData: TCBikeModel?

    @IBOutlet var bikeMapView: MKMapView!

    private let locationManager = LocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self

        self.locationManager.requestAlwaysAuthorization()

        BikeManager.shared.getTPBikeData { [weak self] result in
            LKProgressHUD.show(.success("讀取UBike資料成功"))

            self?.bikeData.append(contentsOf: result)

            self?.layOutTaipeiBike()
        }

        BikeManager.getTCBikeData { [weak self] result in

            LKProgressHUD.show(.success("讀取UBike資料成功"))

            self?.taichungBikeData = result

            self?.layOutTaichungBike()
        }

        let center = locationManager.location?.coordinate ??
            CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)

        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: center, span: span)

        bikeMapView.setRegion(region, animated: true)

        self.title = "附近的 UBike 2.0"

        view.backgroundColor = .B2
    }

    // MARK: - show bikes -

    func layOutTaipeiBike() {
        for bike in bikeData {
            let coordinate = CLLocationCoordinate2D(latitude: bike.latitude, longitude: bike.longitude)

            let title = bike.sna

            let subtitle = "可還數量:\(bike.bemp), 可租數量 :\(bike.sbi)"

            let annotation = BikeAnnotation(title: title, subtitle: subtitle, coordinate: coordinate)

            let usersCoordinate = CLLocation(latitude: bikeMapView.userLocation.coordinate.latitude, longitude: bikeMapView.userLocation.coordinate.longitude)

            let bikeStopCoordinate = CLLocation(latitude: Double(bike.latitude), longitude: Double(bike.longitude))

            let distance = usersCoordinate.distance(from: bikeStopCoordinate)

            if distance < 1000 {
                DispatchQueue.main.async {
                    self.bikeMapView.addAnnotation(annotation)
                }
            }
        }
    }

    func layOutTaichungBike() {
        for bike in taichungBikeData!.retVal {
            let coordinate = CLLocationCoordinate2D(latitude: Double(bike.value.latitude) ?? 0.0, longitude: Double(bike.value.longitude) ?? 0.0)

            let title = bike.value.stationName

            let subtitle = "可還數量:\(bike.value.emptyBikes), 可租數量 :\(bike.value.availableBikes)"

            let annotation = BikeAnnotation(title: title, subtitle: subtitle, coordinate: coordinate)

            let usersCoordinate = CLLocation(latitude: bikeMapView.userLocation.coordinate.latitude, longitude: bikeMapView.userLocation.coordinate.longitude)

            let bikeStopCoordinate = CLLocation(latitude: Double(bike.value.latitude) ?? 0.0, longitude: Double(bike.value.longitude) ?? 0.0)

            let distance = usersCoordinate.distance(from: bikeStopCoordinate)

            if distance < 1000 {
                bikeMapView.addAnnotation(annotation)
            }
        }
    }
}
