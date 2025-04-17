//
//  Record.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import FirebaseFirestore
import Foundation

struct Record: Codable, Hashable {
    var uid: String
    var createdTime: Timestamp
    var recordId: String
    var recordName: String
    var recordRef: String
    var pictureRef: String?
    var routeTypes: Int?

    enum CodingKeys: String, CodingKey {
        case uid
        case createdTime = "created_time"
        case recordId = "record_id"
        case recordName = "record_name"
        case recordRef = "record_ref"
        case pictureRef = "picture_ref"
        case routeTypes = "route_types"
    }

    init() {
        self.uid = ""
        self.createdTime = Timestamp()
        self.recordId = ""
        self.recordName = ""
        self.recordRef = ""
        self.pictureRef = ""
        self.routeTypes = 0
    }
}
