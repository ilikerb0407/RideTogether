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
    
    var delegate: bikeProvider?
    
    func getBikeAPI(completion: @escaping ([Bike]) -> Void) {
        
        var bikes: [Bike] = []
        
        let firstDataRequest = URLRequest(url: URL(string: "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json")!)
        
        URLSession.shared.dataTask(with: firstDataRequest, completionHandler: { (data, response, error) in
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
        
        let firstDataRequest = URLRequest(url: URL(string: "https://datacenter.taichung.gov.tw/swagger/OpenData/34c2aa94-7924-40cc-96aa-b8d090f0ab69")!)
        
        URLSession.shared.dataTask(with: firstDataRequest, completionHandler: { (data, response, error) in
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

struct TaichungBike: Codable {
    let retCode: Int
    let retVal: [String: TBike] 
}

// MARK: - RetVal
struct TBike: Codable {
    let sno, sna, tot, sbi: String
    let sarea, mday, lat, lng: String
    let ar, sareaen, snaen, aren: String
    let bemp, act: String
}
