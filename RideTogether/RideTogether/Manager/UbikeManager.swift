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
    
    func provideBike(bike: Bike)
    
}

class BikeManager {
    
    static let shared = BikeManager()
    
    var bikes: [Bike] = []
    
    var delegate: bikeProvider?
    
    func getBikeAPI(completion: @escaping ([Bike]) -> Void) {
      
        let urlString = URL(string: "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json")
        
        guard let urlString = urlString else { return }
        let url = URLRequest(url: urlString)
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, _, error) in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                
                let bikeData = try decoder.decode(Array<Bike>.self, from: data)
                
                completion(bikeData)
                
                LKProgressHUD.showSuccess(text: "讀取成功")
               
            } catch {
                print(error)
                LKProgressHUD.showFailure(text: "目前僅提供台北市的資料，陸續增加中")
            }
            
        }) .resume()
    }
    
    func getTCAPI(completion: @escaping (TaichungBike) -> Void) {
        
        let urlString = URL(string: "https://datacenter.taichung.gov.tw/swagger/OpenData/34c2aa94-7924-40cc-96aa-b8d090f0ab69")
        
        guard let urlString = urlString else { return }
        let url = URLRequest(url: urlString)
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                
                let tBikeData = try decoder.decode(TaichungBike.self, from: data)
                
                completion(tBikeData)
                
//                for count in 0..<20 {
//                    bikes.append(bikeData[count]) }
//                completion(bikes)
                print("\(tBikeData)")
                LKProgressHUD.showSuccess(text: "讀取成功")
               
            } catch {
                print(error)
                LKProgressHUD.showFailure(text: "目前僅提供台北市的資料，陸續增加中")
            }
            
        }) .resume()
        
    }
    
}
