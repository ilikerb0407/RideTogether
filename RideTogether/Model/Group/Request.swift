//
//  Request.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/24.
//

import FirebaseFirestore
import Foundation

struct Request: Codable, Hashable {
    var groupId: String
    var groupName: String
    var hostId: String
    var requestId: String
    var createdTime: Timestamp

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case groupId = "group_id"
        case groupName = "group_name"
        case hostId = "host_id"
        case createdTime = "created_time"
    }
}
