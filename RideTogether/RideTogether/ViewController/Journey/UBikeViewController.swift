//
//  UBikeViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/14.
//

import UIKit
import MapKit
import CoreGPX
import CoreLocation

class UBikeViewController: BaseViewController, CLLocationManagerDelegate {
    
    var bikeData: [Bike] = []
    
    var taichungBikeData: TaichungBike?
    
    @IBOutlet weak var bikeMapView: MKMapView!
    
    private let locationManager = LocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        self.locationManager.requestAlwaysAuthorization()
        
        BikeManager.getBikeAPI { [ weak self ] result in
            
            LKProgressHUD.showSuccess(text: "讀取UBike資料成功")
            
        self?.bikeData = result
            
        self?.layOutTaipeiBike()
            
        }
        
        BikeManager.getTCAPI { [weak self] result in
            
            LKProgressHUD.showSuccess(text: "讀取UBike資料成功")
            
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
            
            let coordinate = CLLocationCoordinate2D(latitude: bike.lat, longitude: bike.lng)
            
            let title = bike.sna
             
            let subtitle = "可還數量:\(bike.bemp), 可租數量 :\(bike.sbi)"
            
            let annotation = BikeAnnotation(title: title, subtitle: subtitle, coordinate: coordinate)

            let usersCoordinate = CLLocation(latitude: bikeMapView.userLocation.coordinate.latitude, longitude: bikeMapView.userLocation.coordinate.longitude)
            
            let bikeStopCoordinate = CLLocation(latitude: Double(bike.lat), longitude: Double(bike.lng))

            let distance = usersCoordinate.distance(from: bikeStopCoordinate)
       
                    if  distance < 1000 {
                        DispatchQueue.main.async {
                            self.bikeMapView.addAnnotation(annotation)
                        }
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
            
            let bikeStopCoordinate = CLLocation(latitude: Double(bike.value.lat) ?? 0.0, longitude: Double(bike.value.lng) ?? 0.0 )
            
            let distance = usersCoordinate.distance(from: bikeStopCoordinate)

                    if  distance < 1000 {
                        bikeMapView.addAnnotation(annotation)
                    }
        }
        
    }
    
}
