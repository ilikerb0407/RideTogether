//
//  BikeStation.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2025/1/21.
//

// MARK: - 共用腳踏車站點協議
protocol BikeStation {
    var stationID: String { get }        // 站點編號
    var stationName: String { get }      // 站點名稱
    var totalBikes: Int { get }          // 總車位數
    var availableBikes: Int { get }      // 可借車數
    var area: String { get }             // 區域名稱
    var updateTime: String { get }        // 更新時間
    var latitude: Double { get }          // 緯度
    var longitude: Double { get }         // 經度
    var areaDescription: String { get }   // 地區描述
    var areaNameEn: String { get }        // 區域英文名稱
    var stationNameEn: String { get }     // 站點英文名稱
    var areaDescriptionEn: String { get } // 地區描述英文
    var emptyBikes: Int { get }          // 可還空位數
    var isActive: Bool { get }           // 站點是否活躍
}
