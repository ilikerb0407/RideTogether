//
//  RecommenMap.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/13.
//

import Foundation
import FirebaseFirestore

// MARK: RecommendMap = Route
struct RecommendMap: Codable, Hashable {
    
    var uid: String
    var createdTime: Timestamp
    var recordId: String?
    var recordName: String
    var recordRef: String
    
//    let trailId: String
//    let trailName: String
//    let trailLocation: String
//    let trailLevel: Int
//    let trailLength: Double
//    let trailInfo: String
//    let trailTraffic: String
//    let trailMap: String?
    
    enum CodingKeys: String, CodingKey {
        
        case uid
        case createdTime = "created_time"
        case recordId = "record_id"
        case recordName = "record_name"
        case recordRef = "record_ref"
        
    }
    
    init() {
        self.uid = ""
        self.createdTime = Timestamp()
        self.recordId = ""
        self.recordName = ""
        self.recordRef = ""
    }
    
}
