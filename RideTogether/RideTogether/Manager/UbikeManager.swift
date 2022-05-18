//
//  UbikeManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/13.
//

import Foundation
import CoreLocation
import MapKit


protocol bikeProvider {
    func provideBike(bike : Bike)
}

class BikeManager {
    
    static let shared = BikeManager()
    
    var delegate : bikeProvider?
    
    func getBikeAPI(completion: @escaping ([Bike]) -> Void) {
        
        var bikes : [Bike] = []
        
        let firstDataRequest = URLRequest(url: URL(string: "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json")!)
        
        URLSession.shared.dataTask(with: firstDataRequest, completionHandler: { [self] (data, response, error) in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                
                let bikeData = try decoder.decode(Array<Bike>.self, from: data)
                
                completion(bikeData)
                
              
//                for count in 0..<20 {
//                    bikes.append(bikeData[count]) }
//                completion(bikes)
                
                LKProgressHUD.showSuccess(text: "讀取成功")
               
            } catch {
                print(error)
                LKProgressHUD.showFailure(text: "目前僅提供台北市的資料，陸續增加中")
            }
            
        }) .resume()
    }
    
    
    
//    func addBikeAnnotation(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
//    
//    }
    
    
}


// MARK: - BikeElement

struct Bike: Codable {
    let sno, sna: String
    let tot, sbi: Int
    let sarea, mday: String
    let lat, lng: Double
    let ar, sareaen, snaen, aren: String
    let bemp: Int
    let act, srcUpdateTime, updateTime, infoTime: String
    let infoDate: String
}

