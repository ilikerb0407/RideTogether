//
//  UbikeViewController.swift
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

class UbikeViewController: BaseViewController, bikeProvider, CLLocationManagerDelegate {
    
    func provideBike(bike: Bike) {
        bikeData = [bike]
    }
    var bikeData : [Bike] = []
    
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
        
        bikeManager.delegate = self
        
        bikeManager.getBikeAPI { [ weak self ] result in
            
        self?.bikeData = result
            
        self?.layOutBike()
            
        }
        
        let center = locationManager.location?.coordinate ??
        CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: center, span: span)
        
        bikemap.setRegion(region, animated: true)
        
        self.title = "附近的 Ubike 2.0"
        
        view.backgroundColor = .B2

    }
    
    func layOutBike() {
        
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
}
