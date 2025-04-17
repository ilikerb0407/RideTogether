//
//  TPBikeModel.swift
//  RideTogether
//
//  Created by 00591630 on 2022/10/26.
//

import Foundation

// MARK: - 台北市腳踏車
struct TPBikeModel: Codable {
    let sno, sna: String
    let tot, sbi: Int
    let sarea, mday: String
    let lat, lng: Double
    let ar, sareaen, snaen, aren: String
    let bemp: Int
    let act, srcUpdateTime, infoTime: String
    let infoDate: String
}

// MARK: - BikeStation 實作
extension TPBikeModel: BikeStation {
    var stationID: String { sno }
    var stationName: String { sna }
    var totalBikes: Int { tot }
    var availableBikes: Int { sbi }
    var area: String { sarea }
    var updateTime: String { mday }
    var latitude: Double { lat }
    var longitude: Double { lng }
    var areaDescription: String { ar }
    var areaNameEn: String { sareaen }
    var stationNameEn: String { snaen }
    var areaDescriptionEn: String { aren }
    var emptyBikes: Int { bemp }
    var isActive: Bool { act == "1" }
}
