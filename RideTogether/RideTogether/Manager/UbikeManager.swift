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
        // 1. 修正命名：清楚區分 String 與 URL 物件
        let urlString = "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json"
        guard let url = URL(string: urlString) else { return }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            // 2. 先檢查是不是網路連線本身出問題（例如：手機沒網路）
            if let error = error {
                print("網路連線失敗: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    LKProgressHUD.showFailure(text: "網路連線失敗，請檢查網路")
                }
                return
            }
            
            guard let data = data else { return }
            let decoder = JSONDecoder()
            
            do {
                let bikeData = try decoder.decode([Bike].self, from: data)
                
                // 3. 💡【關鍵】回到主執行緒更新 UI 與回傳資料
                DispatchQueue.main.async {
                    completion(bikeData)
                    LKProgressHUD.showSuccess(text: "讀取成功")
                }
                   
            } catch {
                // 💡 印出最真實的 JSON 長相，看看到底有沒有 "tot" 這個字
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 接收到的原始 JSON 內容前 500 字元: \(String(jsonString.prefix(500)))")
                }
                print("‼️ 解碼失敗: \(error)")
                DispatchQueue.main.async {
                    LKProgressHUD.showFailure(text: "目前僅提供台北市的資料，陸續增加中")
                }
            }
        }.resume()
    }
    
}

// MARK: - BikeElement

struct Bike: Codable {
    let sno, sna: String
    let sarea, mday: String
    let ar, sareaen, snaen, aren: String
    let act, srcUpdateTime, updateTime, infoTime: String
    let infoDate: String
    
    // 這些欄位名稱變了，定義為你想要的名稱
    let tot, sbi, bemp: Int
    let lat, lng: Double

    // 💡【關鍵】透過 CodingKeys，將新 API 的欄位名稱對照回你原本的變數名稱
    enum CodingKeys: String, CodingKey {
        // 沒變的欄位正常配對
        case sno, sna, sarea, mday, ar, sareaen, snaen, aren
        case act, srcUpdateTime, updateTime, infoTime, infoDate
        
        // 變動的欄位： 你的變數名 = "新 JSON 欄位名"
        case tot = "Quantity"
        case sbi = "available_rent_bikes"
        case bemp = "available_return_bikes"
        case lat = "latitude"
        case lng = "longitude"
    }
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
