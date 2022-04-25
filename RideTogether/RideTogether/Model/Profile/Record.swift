//
//  Record.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import FirebaseFirestore

// 使用者個人騎乘紀錄

struct Record: Codable, Hashable {
    
    var uid: String
    var createdTime: Timestamp
    var recordId: String
    var recordName: String
    var recordRef: String
    
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
