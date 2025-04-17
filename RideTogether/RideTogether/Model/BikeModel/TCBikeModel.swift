/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/7/5.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import Foundation

// MARK: - 台中市腳踏車
struct TCBikeModel: Codable {
    let retCode: Int
    let retVal: [String: RetVal]
}

struct RetVal: Codable {
    let sno, sna, tot, sbi: String
    let sarea, mday, lat, lng: String
    let ar, sareaen, snaen, aren: String
    let bemp, act: String
}

// MARK: - BikeStation 實作
extension RetVal: BikeStation {
    var stationID: String { sno }
    var stationName: String { sna }
    var totalBikes: Int { Int(tot) ?? 0 }
    var availableBikes: Int { Int(sbi) ?? 0 }
    var area: String { sarea }
    var updateTime: String { mday }
    var latitude: Double { Double(lat) ?? 0.0 }
    var longitude: Double { Double(lng) ?? 0.0 }
    var areaDescription: String { ar }
    var areaNameEn: String { sareaen }
    var stationNameEn: String { snaen }
    var areaDescriptionEn: String { aren }
    var emptyBikes: Int { Int(bemp) ?? 0 }
    var isActive: Bool { act == "1" }
}
