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
import Firebase
import Lottie
import MessageUI
import SwiftUI
import JGProgressHUD

class UBikeViewController: BaseViewController, CLLocationManagerDelegate {
    

    var bikeData : [Bike] = []
    
    var taichungBikeData : TaichungBike?
    
    var bikeManager = BikeManager()
    
    @IBOutlet weak var bikemap: MKMapView!
    
    private let locationManager: CLLocationManager = {
        
        let manager = CLLocationManager()
        
        manager.requestAlwaysAuthorization()
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        manager.distanceFilter = 2 // meters
        
        manager.pausesLocationUpdatesAutomatically = false
        
        manager.allowsBackgroundLocationUpdates = true
        
        return manager
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        self.locationManager.requestAlwaysAuthorization()
        
        bikeManager.getBikeAPI { [ weak self ] result in
            
            LKProgressHUD.showSuccess(text: "讀取資料中")
            
            
        self?.bikeData = result
            
        self?.layOutTaipeiBike()
            
        }
        
        bikeManager.getTCAPI { [weak self] result in
            
            
            LKProgressHUD.showSuccess(text: "讀取資料中")
            
            self?.taichungBikeData = result
            
            self?.layOutTaichungBike()

        }
        
        let center = locationManager.location?.coordinate ??
        CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: center, span: span)
        
        bikemap.setRegion(region, animated: true)
        
        self.title = "附近的 Ubike 2.0"
        
        view.backgroundColor = .B2

    }
    
    // MARK: - show bikes
    func layOutTaipeiBike() {
        
        for bike in bikeData {
            
            let coordinate = CLLocationCoordinate2D(latitude: bike.lat, longitude: bike.lng)
            
            let title = bike.sna
             
            let subtitle = "可還數量:\(bike.bemp), 可租數量 :\(bike.sbi)"
            
            let annotation = BikeAnnotation(title: title, subtitle: subtitle, coordinate: coordinate)

            let usersCoordinate = CLLocation(latitude: bikemap.userLocation.coordinate.latitude, longitude: bikemap.userLocation.coordinate.longitude)
            
            let bikeStopCoordinate = CLLocation(latitude: Double(bike.lat), longitude: Double(bike.lng))

            let distance = usersCoordinate.distance(from: bikeStopCoordinate)
       
                    if  distance < 1000 {
                        bikemap.addAnnotation(annotation)
                    }
            
        }
        
    }
    
    func layOutTaichungBike() {
        
        for bike in taichungBikeData!.retVal {
            
            let coordinate = CLLocationCoordinate2D(latitude: Double(bike.value.lat) ?? 0.0, longitude: Double(bike.value.lng) ?? 0.0)
            
            let title = bike.value.sna
             
            let subtitle = "可還數量:\(bike.value.bemp), 可租數量 :\(bike.value.sbi)"
            
            let annotation = BikeAnnotation(title: title, subtitle: subtitle, coordinate: coordinate)

            let usersCoordinate = CLLocation(latitude: bikemap.userLocation.coordinate.latitude, longitude: bikemap.userLocation.coordinate.longitude)
            
            let bikeStopCoordinate = CLLocation(latitude: Double(bike.value.lat) ?? 0.0, longitude: Double(bike.value.lng) ?? 0.0 )
            
            let distance = usersCoordinate.distance(from: bikeStopCoordinate)

                    if  distance < 1000 {
                        bikemap.addAnnotation(annotation)
                    }
        }
        
    }
    
}
