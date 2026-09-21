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
// TODO: 我在想要不要把這個頁面拿掉，把搜尋腳踏車的功能，變成一個 toggle，然後可以顯示使用者滑動到的中心範圍方圓 1 公里以內的腳踏車，然後如果再按一次 toggle 就會取消顯示，這是我自己想到的功能，不過會不會很不符合邏輯？
// TODO: 我想要讓 Pin 的圖片好看一點，不是原生的
// TODO: 移除掉，或是思考一下，有沒有一個寫一個統一的格式(model)，然後可以讓使用者可以搜尋全台灣的 UBike，因為台灣政府很奇怪的地方是，他們的 API 沒有統一格式，所以讓我在擴充的時候很麻煩

class UBikeViewController: BaseViewController, CLLocationManagerDelegate {
    var bikeData: [Bike] = []

    var taichungBikeData: TaichungBike?

    // Was `var bikeManager = BikeManager()`, which bypassed the `.shared`
    // singleton and created its own separate instance — inconsistent with
    // every other call site (e.g. `UbikeManager.swift` itself uses
    // `.shared`). Typing this as `BikeManaging` also lets tests inject a
    // mock instead of hitting the real network API.
    var bikeManager: BikeManaging = UbikeManager.shared

    // Was `@IBOutlet var bikeMapView: MKMapView!`. This scene used to be
    // duplicated byte-for-byte across THREE separate storyboards (Home,
    // Profile, Journey) — the same empty MKMapView + full-bleed
    // constraints, copy-pasted three times — purely to work around
    // `storyboard?.instantiateViewController(withIdentifier:)` resolving
    // to "whichever storyboard the calling screen happens to belong to".
    // Building it here in code means every caller (RideViewController,
    // GoToRideViewController, JourneyViewController) reaches the exact
    // same implementation, and none of those three storyboard copies are
    // needed anymore.
    private lazy var bikeMapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()

    private let locationManager = LocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(bikeMapView)

        NSLayoutConstraint.activate([
            bikeMapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bikeMapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bikeMapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bikeMapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        locationManager.delegate = self

        locationManager.requestAlwaysAuthorization()

        bikeManager.getBikeAPI { [weak self] result in

            LKProgressHUD.showSuccess(text: "讀取UBike資料成功")

            self?.bikeData = result

            self?.layOutTaipeiBike()
        }

        let center = locationManager.location?.coordinate ??
            CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)

        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: center, span: span)

        bikeMapView.setRegion(region, animated: true)

        title = "附近的 UBike 2.0"

        view.backgroundColor = .B2
    }

    // MARK: - show bikes -

    func layOutTaipeiBike() {
        for bike in bikeData {
            let coordinate = CLLocationCoordinate2D(latitude: bike.lat, longitude: bike.lng)

            let title = bike.sna

            let subtitle = "可還數量:\(bike.bemp), 可租數量 :\(bike.sbi)"

            let annotation = BikeAnnotation(title: title, subtitle: subtitle, coordinate: coordinate)

            let usersCoordinate = CLLocation(latitude: bikeMapView.userLocation.coordinate.latitude, longitude: bikeMapView.userLocation.coordinate.longitude)

            let bikeStopCoordinate = CLLocation(latitude: Double(bike.lat), longitude: Double(bike.lng))

            let distance = usersCoordinate.distance(from: bikeStopCoordinate)

            if distance < 500 {
                bikeMapView.addAnnotation(annotation)
            }
        }
    }

    func layOutTaichungBike() {
        for bike in taichungBikeData!.retVal {
            let coordinate = CLLocationCoordinate2D(latitude: Double(bike.value.lat) ?? 0.0, longitude: Double(bike.value.lng) ?? 0.0)

            let title = bike.value.sna

            let subtitle = "可還數量:\(bike.value.bemp), 可租數量 :\(bike.value.sbi)"

            let annotation = BikeAnnotation(title: title, subtitle: subtitle, coordinate: coordinate)

            let usersCoordinate = CLLocation(latitude: bikeMapView.userLocation.coordinate.latitude, longitude: bikeMapView.userLocation.coordinate.longitude)

            let bikeStopCoordinate = CLLocation(latitude: Double(bike.value.lat) ?? 0.0, longitude: Double(bike.value.lng) ?? 0.0)

            let distance = usersCoordinate.distance(from: bikeStopCoordinate)

            if distance < 1000 {
                bikeMapView.addAnnotation(annotation)
            }
        }
    }
}
