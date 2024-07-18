/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/7/5.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import Foundation

// MARK: 台中市腳踏車
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
